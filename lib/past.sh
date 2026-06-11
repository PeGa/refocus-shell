#!/usr/bin/env bash
set -euo pipefail
source "$REFOCUS_ROOT/config.sh"
source "$REFOCUS_ROOT/services/database.sh"

db_ensure

_fmt_duration() {
    local secs="$1"
    local h=$(( secs / 3600 )) m=$(( (secs % 3600) / 60 ))
    [[ $h -gt 0 ]] && echo "${h}h ${m}m" || echo "${m}m"
}

_parse_time() {
    # Accepts: YYYY/MM/DD-HH:MM  HH:MM  natural language
    local raw="$1"
    # YYYY/MM/DD-HH:MM → "YYYY-MM-DD HH:MM" (date-compatible)
    if [[ "$raw" =~ ^([0-9]{4})/([0-9]{2})/([0-9]{2})-([0-9]{2}:[0-9]{2})$ ]]; then
        raw="${BASH_REMATCH[1]}-${BASH_REMATCH[2]}-${BASH_REMATCH[3]} ${BASH_REMATCH[4]}"
    fi
    date --date="$raw" -Iseconds 2>/dev/null || { echo "❌ Can't parse time: $1" >&2; return 1; }
}

sub="${1:-list}"; shift || true

case "$sub" in
    list)
        limit="${1:-$REPORT_LIMIT}"
        printf "%-4s %-22s %-19s %-19s %-8s\n" "ID" "Project" "Start" "End" "Duration"
        echo "─────────────────────────────────────────────────────────────────────────────"
        while IFS='|' read -r id project start end dur notes duration_only session_date; do
            if [[ "$duration_only" == "1" ]]; then
                s="(manual: $session_date)"
                e=""
            else
                s=$(date --date="$start" +"$DATE_SHORT_FORMAT" 2>/dev/null || echo "$start")
                e=$(date --date="$end"   +"$DATE_SHORT_FORMAT" 2>/dev/null || echo "$end")
            fi
            printf "%-4s %-22s %-19s %-19s %-8s\n" "$id" "$project" "$s" "$e" "$(_fmt_duration "$dur")"
            [[ -n "$notes" ]] && echo "     📝 $notes" || true
        done < <(db_list_sessions "$limit")
        ;;

    add)
        project="${1:-}"; shift || true
        [[ -z "$project" ]] && { echo "Usage: focus past add <project> <start> <end> [--duration Xh Ym] [--date YYYY/MM/DD]" >&2; exit 2; }

        # Duration-only mode
        if [[ "${1:-}" == "--duration" ]]; then
            dur_str="${2:-}"; shift 2 || true
            date_str="${2:-today}"
            [[ "${1:-}" == "--date" ]] && { date_str="${2:-today}"; shift 2 || true; }

            # Parse duration
            if [[ "$dur_str" =~ ^([0-9]+)h([0-9]+)m$ ]]; then
                dur=$(( BASH_REMATCH[1]*3600 + BASH_REMATCH[2]*60 ))
            elif [[ "$dur_str" =~ ^([0-9]+)h$ ]]; then
                dur=$(( BASH_REMATCH[1]*3600 ))
            elif [[ "$dur_str" =~ ^([0-9]+)m$ ]]; then
                dur=$(( BASH_REMATCH[1]*60 ))
            else
                echo "❌ Invalid duration: $dur_str (use 1h30m, 2h, 45m)" >&2; exit 2
            fi

            date_iso=$(date --date="$date_str" +"$DATE_FORMAT" 2>/dev/null) || { echo "❌ Bad date: $date_str" >&2; exit 2; }
            echo -n "📝 Notes (Enter to skip): "; read -r notes
            db_insert_duration_session "$project" "$dur" "$date_iso" "$notes"
            echo "✅ Added $project — $dur_str on $date_iso"

        else
            # start / end timestamps
            start_raw="${1:-}"; end_raw="${2:-}"; shift 2 || true
            [[ -z "$start_raw" || -z "$end_raw" ]] && { echo "Usage: focus past add <project> <start> <end>" >&2; exit 2; }

            start=$(_parse_time "$start_raw") || exit 2
            end=$(_parse_time "$end_raw")     || exit 2

            start_ts=$(date --date="$start" +%s)
            end_ts=$(date --date="$end"     +%s)
            [[ $end_ts -le $start_ts ]] && { echo "❌ End must be after start." >&2; exit 2; }
            dur=$(( end_ts - start_ts ))

            echo -n "📝 Notes (Enter to skip): "; read -r notes
            db_insert_session "$project" "$start" "$end" "$dur" "$notes"
            echo "✅ Added $project — $(_fmt_duration "$dur")"
        fi
        ;;

    modify|edit)
        id="${1:-}"; [[ -z "$id" ]] && { echo "Usage: focus past modify <id> [project] [start] [end]" >&2; exit 2; }
        shift

        row=$(db_get_session "$id")
        [[ -z "$row" ]] && { echo "❌ Session $id not found." >&2; exit 1; }
        IFS='|' read -r _ cur_proj cur_start cur_end cur_dur _ _ _ <<< "$row"

        new_proj="${1:-$cur_proj}"
        new_start_raw="${2:-}"
        new_end_raw="${3:-}"

        new_start="${cur_start}"
        new_end="${cur_end}"
        [[ -n "$new_start_raw" ]] && new_start=$(_parse_time "$new_start_raw")
        [[ -n "$new_end_raw"   ]] && new_end=$(_parse_time "$new_end_raw")

        s_ts=$(date --date="$new_start" +%s)
        e_ts=$(date --date="$new_end"   +%s)
        new_dur=$(( e_ts - s_ts ))

        db_update_session "$id" "$new_proj" "$new_start" "$new_end" "$new_dur"
        echo "✅ Session $id updated."
        ;;

    delete|del|rm)
        id="${1:-}"; [[ -z "$id" ]] && { echo "Usage: focus past delete <id>" >&2; exit 2; }
        row=$(db_get_session "$id")
        [[ -z "$row" ]] && { echo "❌ Session $id not found." >&2; exit 1; }
        IFS='|' read -r _ project _ _ dur _ <<< "$row"
        echo -n "Delete session $id ($project, $(_fmt_duration "$dur"))? (y/N): "
        read -r ans
        [[ "${ans:-N}" =~ ^[Yy]$ ]] || { echo "Cancelled."; exit 0; }
        db_delete_session "$id"
        echo "✅ Deleted."
        ;;

    *)
        echo "Usage: focus past <list|add|modify|delete>" >&2; exit 2
        ;;
esac
