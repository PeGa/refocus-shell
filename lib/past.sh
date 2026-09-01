#!/usr/bin/env bash
set -euo pipefail
source "$REFOCUS_ROOT/env.sh"
source "$REFOCUS_ROOT/services/database.sh"
source "$REFOCUS_ROOT/services/editor.sh"
source "$REFOCUS_ROOT/services/help.sh"
source "$REFOCUS_ROOT/core/time.sh"
source "$REFOCUS_ROOT/core/text.sh"
source "$REFOCUS_ROOT/services/merge.sh"

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
    [[ "$1" =~ ^[0-9]+$ ]] || { echo "❌ Not a session id: $1" >&2; usage_error past; }
}

case "$sub" in
    list)
        limit="${1:-$REPORT_LIMIT}"
        printf "%-4s %-22s %-19s %-19s %-8s\n" "ID" "Project" "Start" "End" "Duration"
        echo "─────────────────────────────────────────────────────────────────────────────"
        while IFS="|" read -r id project start end dur notes duration_only session_date; do
            if [[ "$duration_only" == "1" ]]; then
                s="(manual: $session_date)"
                e=""
            else
                s=$(ts_format "$start" "$DATE_SHORT_FORMAT" 2>/dev/null || echo "$start")
                e=$(ts_format "$end"   "$DATE_SHORT_FORMAT" 2>/dev/null || echo "$end")
            fi
            printf "%-4s %-22s %-19s %-19s %-8s\n" "$id" "$project" "$s" "$e" "$(fmt_duration "$dur")"
            if [[ -n "$notes" ]]; then
                notes_block "     📝 " "        " "$(notes_decode "$notes")"
            fi
        done < <(list_sessions "$limit")
        ;;

    add)
        project="${1:-}"; shift || true
        [[ -z "$project" ]] && usage_error past
        # Sanitize here, not just inside record_session/record_duration_session:
        # both echo "$project" back to the user below, and it must match what
        # actually gets stored.
        project="${project//|/¦}"

        if [[ "${1:-}" == "--duration" ]]; then
            dur_str="${2:-}"; shift 2 || true
            date_str="today"
            [[ "${1:-}" == "--date" ]] && { date_str="${2:-today}"; shift 2 || true; }

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
        for _a in "$@"; do
            if [[ "$_a" == "--notes" ]]; then want_notes=1; else _args+=("$_a"); fi
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
            # isn't the --duration flag itself (CMD-PAST-ARGS).
            new_proj="$cur_proj"
            if [[ -n "${1:-}" && "${1:-}" != "--duration" ]]; then
                new_proj="$1"; shift || true
            fi
            new_dur="$cur_dur"
            if [[ "${1:-}" == "--duration" ]]; then
                dur_str="${2:-}"; shift 2 || true
                new_dur=$(parse_duration "$dur_str") || exit 2
            elif [[ $# -gt 0 ]]; then
                echo "❌ Session $id is duration-only. Timestamps cannot be edited." >&2
                usage_error past
            fi
            if [[ $_had_args -gt 0 ]]; then
                _merge_or_exit "$new_proj" "$new_dur" "" "" "$id"
            fi
            update_duration_session "$id" "$new_proj" "$new_dur"
        elif [[ $# -gt 0 ]]; then
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
        read -r ans
        [[ "${ans:-N}" =~ ^[Yy]$ ]] || { echo "Cancelled."; exit 0; }
        delete_session "$id"
        echo "✅ Deleted."
        ;;

    *)
        usage_error past
        ;;
esac
