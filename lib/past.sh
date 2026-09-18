#!/usr/bin/env bash
set -euo pipefail
source "$REFOCUS_ROOT/env.sh"
source "$REFOCUS_ROOT/services/database.sh"
source "$REFOCUS_ROOT/services/editor.sh"
source "$REFOCUS_ROOT/services/help.sh"
source "$REFOCUS_ROOT/core/time.sh"
source "$REFOCUS_ROOT/core/text.sh"
source "$REFOCUS_ROOT/services/merge.sh"
source "$REFOCUS_ROOT/services/period.sh"

# Before db_ensure and before any parsing: `past modify --help` used to reach
# SQL and die on `WHERE id=--help`, and `past modify 5 --help` used to take
# --help for a new project name and rename the session. [#25]
wants_help "$@" && show_help past

db_ensure

sub="${1:-list}"; shift || true

_merge_or_exit() {
    # modify's half of the duplicate rule [#36]: <project> <seconds> <start>
    # <end> <id>. A rename onto a name another row already holds folds this row
    # into that one and deletes it, so the two never coexist. Returns only when
    # there is no duplicate and the caller should carry on with its UPDATE.
    local id="$5" rc=0
    merge_duplicate_session "$1" "$2" "$3" "$4" "$id" || rc=$?
    if [[ $rc -eq 0 ]]; then
        delete_session "$id"
        echo "✅ Session $id folded in and removed."
        exit 0
    fi
    [[ $rc -eq 2 ]] && { echo "Cancelled — session $id is unchanged."; exit 0; }
    return 0
}

_require_id() {
    # Session ids are integers. The adapter interpolates them into SQL, so a
    # non-numeric id produced a raw sqlite parse error instead of usage. [#25]
    is_session_id "$1" || { echo "❌ Not a session id: $1" >&2; usage_error past; }
}

# Rows arrive in the 8-field session shape from every read here, so one
# renderer serves the plain listing, the period listing and the cycle listing.
# A cycle break is never a table row: it delimits periods, it isn't work, and
# its ~50-char label overflows the %-22s project column and smears the row's
# remaining columns [#46]. With `show_cycles` it renders as the boundary line
# it is — "here starts the new count" — carrying the id that every cycle
# subcommand addresses it by, plus its note when the note is the period's own
# rather than the canned instruction.
_render_rows() {
    local show_cycles="$1"
    while IFS="|" read -r id project start end dur notes duration_only session_date; do
        if is_cycle_label "$project"; then
            [[ "$show_cycles" != "1" ]] && continue
            echo "──── 🔚 id $id · $project ────"
            local decoded; decoded="$(notes_decode "$notes")"
            if [[ -n "$decoded" && "$decoded" != "$(cycle_note_placeholder)" ]]; then
                notes_block "     📝 " "        " "$decoded"
            fi
            continue
        fi
        if [[ "$duration_only" == "1" ]]; then
            start_str="(manual: $session_date)"
            end_str=""
        elif [[ -z "$start" || -z "$end" ]]; then
            # Flagged timestamped but missing its times — import damage. Name
            # the absence; the row stays listed and its stored duration still
            # counts (DM-SESSION), but nothing here dates it (CONV-ABSENT).
            start_str="(no timestamps)"
            end_str=""
        else
            start_str=$(ts_format "$start" "$DATE_SHORT_FORMAT" 2>/dev/null || echo "$start")
            end_str=$(ts_format "$end"   "$DATE_SHORT_FORMAT" 2>/dev/null || echo "$end")
        fi
        printf "%-4s %-22s %-19s %-19s %-8s\n" "$id" "$project" "$start_str" "$end_str" "$(fmt_duration "$dur")"
        if [[ -n "$notes" ]]; then
            notes_block "     📝 " "        " "$(notes_decode "$notes")"
        fi
    done
}

_render_header() {
    printf "%-4s %-22s %-19s %-19s %-8s\n" "ID" "Project" "Start" "End" "Duration"
    echo "─────────────────────────────────────────────────────────────────────────────"
}

case "$sub" in
    list)
        show_cycles=0
        limit=""
        for _arg in "$@"; do
            case "$_arg" in
                --show-cycles) show_cycles=1 ;;
                *)             limit="$_arg"   ;;
            esac
        done

        # The count goes straight into SQL's LIMIT, so its shape is checked
        # here rather than by sqlite: unvalidated, a word leaked a raw parse
        # error (plus a fragment of the adapter's SQL) at rc=1, a decimal
        # leaked sqlite's own rc=20, and a negative read as an *unbounded*
        # LIMIT. 0 stays a legal "show nothing". [#51]
        if [[ -n "$limit" ]] && ! [[ "$limit" =~ ^[0-9]+$ ]]; then
            echo "❌ Not a row count: $limit" >&2
            usage_error past
        fi

        _render_header
        if [[ -n "$limit" ]]; then
            # An explicit count is a count of rows, so the exclusion happens in
            # SQL — LIMIT is applied by the database and filtering afterwards
            # would hand back fewer than were asked for.
            exclude=""
            [[ $show_cycles -eq 0 ]] && exclude="$(cycle_prefix)"
            list_sessions "$limit" "$exclude" | _render_rows "$show_cycles"
        else
            # No count: the full history, uncapped — if it holds 300 sessions,
            # all 300 render. Breaks ride along in the rows and the render loop
            # hides them, safe because nothing here applies a LIMIT;
            # --show-cycles reveals them as recorded.
            list_sessions_by_id_range "" "" | _render_rows "$show_cycles"
        fi
        ;;

    cycles)
        csub="${1:-list}"; shift || true
        case "$csub" in
            list)
                # No table header: every line this prints is a boundary, not a
                # row, and column names over boundaries are noise.
                list_cycles "$(cycle_prefix)" | _render_rows 1
                ;;
            show)
                sel="${1:-0}"
                is_period_selector "$sel" || usage_error past
                window=$(get_period_window "$sel") || exit 1
                _render_header
                list_sessions_by_id_range "${window%|*}" "${window#*|}" | _render_rows 0
                ;;
            *)
                usage_error past
                ;;
        esac
        ;;

    add)
        project="${1:-}"; shift || true
        [[ -z "$project" ]] && usage_error past
        # Sanitize here, not just inside record_session/record_duration_session:
        # both echo "$project" back to the user below, and it must match what
        # actually gets stored.
        project=$(sanitize_pipe "$project")

        if [[ "${1:-}" == "--duration" || "${1:-}" == "--date" ]]; then
            dur_str=""
            date_str="today"
            while [[ $# -gt 0 ]]; do
                case "${1:-}" in
                    --duration)
                        dur_str="${2:-}"; shift 2 || true
                        ;;
                    --date)
                        date_str="${2:-today}"; shift 2 || true
                        ;;
                    *)
                        echo "❌ Unknown argument: ${1:-}" >&2
                        usage_error past
                        ;;
                esac
            done
            [[ -z "$dur_str" ]] && { echo "❌ --duration is required." >&2; usage_error past; }

            dur=$(parse_duration "$dur_str") || exit 2

            date_iso=$(parse_date_to_fmt "$date_str" "$DATE_FORMAT") || { echo "❌ Invalid date: $date_str" >&2; exit 2; }
            [[ -z "$date_iso" ]] && { echo "❌ Invalid date: $date_str" >&2; exit 2; }
            # A duration-only add carries no timestamps, so it contributes no
            # times to the merged row's note — only its length [#36].
            merge_rc=0
            merge_duplicate_session "$project" "$dur" "" "" || merge_rc=$?
            [[ $merge_rc -eq 0 ]] && exit 0
            [[ $merge_rc -eq 2 ]] && { echo "Cancelled — nothing was added."; exit 0; }

            echo "📝 Notes (empty to skip)"; notes=$(capture_notes "")
            record_duration_session "$project" "$dur" "$date_iso" "$notes"
            echo "✅ Added: $project ($dur_str on $date_iso)"

        else
            start_raw="${1:-}"; end_raw="${2:-}"; shift 2 || true
            [[ -z "$start_raw" || -z "$end_raw" ]] && usage_error past

            start=$(parse_time "$start_raw") || exit 2
            end=$(parse_time "$end_raw")     || exit 2

            start_ts=$(iso_to_epoch "$start")
            end_ts=$(iso_to_epoch "$end")
            [[ $end_ts -le $start_ts ]] && { echo "❌ End must be after start." >&2; exit 2; }
            dur=$(( end_ts - start_ts ))

            merge_rc=0
            merge_duplicate_session "$project" "$dur" "$start" "$end" || merge_rc=$?
            [[ $merge_rc -eq 0 ]] && exit 0
            [[ $merge_rc -eq 2 ]] && { echo "Cancelled — nothing was added."; exit 0; }

            echo "📝 Notes (empty to skip)"; notes=$(capture_notes "")
            record_session "$project" "$start" "$end" "$dur" "$notes"
            echo "✅ Added: $project ($(fmt_duration "$dur"))"
        fi
        ;;

    modify|edit)
        id="${1:-}"; [[ -z "$id" ]] && usage_error past
        _require_id "$id"
        shift

        # --notes is orthogonal to renaming and re-timing, so pull it out of the
        # argument list before the duration-only/timestamped split rather than
        # threading it through both. [#25]
        want_notes=0
        _args=()
        for _arg in "$@"; do
            if [[ "$_arg" == "--notes" ]]; then want_notes=1; else _args+=("$_arg"); fi
        done
        set -- ${_args[@]+"${_args[@]}"}

        # A modify that changes nothing used to report "✅ Session N updated."
        # after a no-op UPDATE. Say what the command can do instead. [#25]
        [[ $# -eq 0 && $want_notes -eq 0 ]] && { echo "❌ Nothing to change." >&2; usage_error past; }

        # Recorded before the branches below consume it with `shift`. A bare
        # `modify <id> --notes` touches neither the name nor the timing, so it
        # never needs the duplicate check [#36].
        _had_args=$#

        row=$(get_session "$id")
        [[ -z "$row" ]] && { echo "❌ Session $id not found." >&2; exit 1; }
        IFS="|" read -r _ cur_proj cur_start cur_end cur_dur cur_notes cur_donly _ <<< "$row"

        if [[ "$cur_donly" == "1" ]]; then
            # Leading [project] is optional — only consume $1 as project when it
            # isn't a flag (--duration or --date) (CMD-PAST-ARGS).
            new_proj="$cur_proj"
            if [[ -n "${1:-}" && "${1:-}" != "--duration" && "${1:-}" != "--date" ]]; then
                new_proj="$1"; shift || true
            fi
            new_dur="$cur_dur"
            new_date=""
            # --duration and --date are independent; either or both may appear.
            while [[ $# -gt 0 ]]; do
                case "${1:-}" in
                    --duration)
                        dur_str="${2:-}"; shift 2 || true
                        new_dur=$(parse_duration "$dur_str") || exit 2
                        ;;
                    --date)
                        date_str="${2:-}"; shift 2 || true
                        new_date=$(parse_date_to_fmt "$date_str" "$DATE_FORMAT") || { echo "❌ Invalid date: $date_str" >&2; exit 2; }
                        [[ -z "$new_date" ]] && { echo "❌ Invalid date: $date_str" >&2; exit 2; }
                        ;;
                    *)
                        echo "❌ Session $id is duration-only. Timestamps cannot be edited." >&2
                        usage_error past
                        ;;
                esac
            done
            if [[ $_had_args -gt 0 ]]; then
                _merge_or_exit "$new_proj" "$new_dur" "" "" "$id"
            fi
            update_duration_session "$id" "$new_proj" "$new_dur" "$new_date"
        elif [[ $# -gt 0 ]]; then
            # --duration/--date only mean something on a duration-only row
            # (CMD-PAST-ARGS). Unguarded, this branch took either literally as
            # the new project name — silently renaming the session to
            # "--duration" and then feeding "$2" to parse_time, which GNU
            # date(1) parses as a *relative* time ("1h" -> an hour from now)
            # instead of failing, producing a nonsense duration.
            if [[ "$1" == "--duration" || "$1" == "--date" ]]; then
                echo "❌ Session $id is timestamped; --duration/--date only apply to duration-only sessions." >&2
                usage_error past
            fi
            new_proj="${1:-$cur_proj}"
            new_start_raw="${2:-}"
            new_end_raw="${3:-}"

            new_start="$cur_start"
            new_end="$cur_end"
            [[ -n "$new_start_raw" ]] && new_start=$(parse_time "$new_start_raw")
            [[ -n "$new_end_raw"   ]] && new_end=$(parse_time "$new_end_raw")

            s_ts=$(iso_to_epoch "$new_start")
            e_ts=$(iso_to_epoch "$new_end")
            new_dur=$(( e_ts - s_ts ))

            _merge_or_exit "$new_proj" "$new_dur" "$new_start" "$new_end" "$id"
            update_session "$id" "$new_proj" "$new_start" "$new_end" "$new_dur"
        fi

        # Notes last, and legal on duration-only rows too: a note bolts no
        # timestamps onto them [CONV-DURONLY]. Pre-loaded with what is there.
        if [[ $want_notes -eq 1 ]]; then
            echo "📝 Notes (edit; delete everything and save to clear)"
            new_notes=$(capture_notes "$(notes_decode "$cur_notes")")
            update_session_notes "$id" "$new_notes"
        fi

        echo "✅ Session $id updated."
        ;;

    delete|del|rm)
        id="${1:-}"; [[ -z "$id" ]] && usage_error past
        _require_id "$id"
        row=$(get_session "$id")
        [[ -z "$row" ]] && { echo "❌ Session $id not found." >&2; exit 1; }
        IFS="|" read -r _ project _ _ dur _ <<< "$row"
        echo -n "🗑  Delete session $id ($project, $(fmt_duration "$dur"))? (y/N): "
        read -r ans || true
        [[ "${ans:-N}" =~ ^[Yy]$ ]] || { echo "Cancelled."; exit 0; }
        delete_session "$id"
        echo "✅ Deleted."
        ;;

    *)
        usage_error past
        ;;
esac
