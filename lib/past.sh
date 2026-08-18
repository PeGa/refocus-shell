#!/usr/bin/env bash
set -euo pipefail
source "$REFOCUS_ROOT/env.sh"
source "$REFOCUS_ROOT/services/database.sh"
source "$REFOCUS_ROOT/services/editor.sh"
source "$REFOCUS_ROOT/core/time.sh"
source "$REFOCUS_ROOT/core/text.sh"

db_ensure

sub="${1:-list}"; shift || true

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
        [[ -z "$project" ]] && { echo "Usage: focus past add <project> <start> <end> [--duration Xh] [--date YYYY/MM/DD]" >&2; exit 2; }

        if [[ "${1:-}" == "--duration" ]]; then
            dur_str="${2:-}"; shift 2 || true
            date_str="today"
            [[ "${1:-}" == "--date" ]] && { date_str="${2:-today}"; shift 2 || true; }

            dur=$(parse_duration "$dur_str") || exit 2

            date_iso=$(parse_date_to_fmt "$date_str" "$DATE_FORMAT") || { echo "❌ Invalid date: $date_str" >&2; exit 2; }
            [[ -z "$date_iso" ]] && { echo "❌ Invalid date: $date_str" >&2; exit 2; }
            echo "📝 Notes (empty to skip)"; notes=$(capture_notes "")
            record_duration_session "$project" "$dur" "$date_iso" "$notes"
            echo "✅ Added: $project ($dur_str on $date_iso)"

        else
            start_raw="${1:-}"; end_raw="${2:-}"; shift 2 || true
            [[ -z "$start_raw" || -z "$end_raw" ]] && { echo "Usage: focus past add <project> <start> <end>" >&2; exit 2; }

            start=$(parse_time "$start_raw") || exit 2
            end=$(parse_time "$end_raw")     || exit 2

            start_ts=$(iso_to_epoch "$start")
            end_ts=$(iso_to_epoch "$end")
            [[ $end_ts -le $start_ts ]] && { echo "❌ End must be after start." >&2; exit 2; }
            dur=$(( end_ts - start_ts ))

            echo "📝 Notes (empty to skip)"; notes=$(capture_notes "")
            record_session "$project" "$start" "$end" "$dur" "$notes"
            echo "✅ Added: $project ($(fmt_duration "$dur"))"
        fi
        ;;

    modify|edit)
        id="${1:-}"; [[ -z "$id" ]] && { echo "Usage: focus past modify <id> [project] [start] [end]" >&2; exit 2; }
        shift

        row=$(get_session "$id")
        [[ -z "$row" ]] && { echo "❌ Session $id not found." >&2; exit 1; }
        IFS="|" read -r _ cur_proj cur_start cur_end cur_dur _ cur_donly _ <<< "$row"

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
                echo "Usage: focus past modify $id [project] [--duration Xh]" >&2
                exit 2
            fi
            update_duration_session "$id" "$new_proj" "$new_dur"
        else
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

            update_session "$id" "$new_proj" "$new_start" "$new_end" "$new_dur"
        fi
        echo "✅ Session $id updated."
        ;;

    delete|del|rm)
        id="${1:-}"; [[ -z "$id" ]] && { echo "Usage: focus past delete <id>" >&2; exit 2; }
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
        echo "Usage: focus past <list|add|modify|delete>" >&2; exit 2
        ;;
esac
