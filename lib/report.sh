#!/usr/bin/env bash
set -euo pipefail
source "$REFOCUS_ROOT/config.sh"
source "$REFOCUS_ROOT/services/database.sh"

db_ensure

_fmt_dur() {
    local s="$1"
    local h=$(( s/3600 )) m=$(( (s%3600)/60 ))
    [[ $h -gt 0 ]] && echo "${h}h ${m}m" || echo "${m}m"
}

_report() {
    local label="$1" start="$2" end="$3"

    echo "📊 $label"
    echo "$(printf '═%.0s' $(seq 1 ${#label}))"
    echo "Period: $(date --date="$start" +"$DATE_FORMAT") → $(date --date="$end" +"$DATE_FORMAT")"
    echo ""

    local total=0 sessions=0
    declare -A proj_dur proj_cnt

    while IFS='|' read -r id project start_t end_t dur notes duration_only session_date; do
        total=$(( total + dur ))
        sessions=$(( sessions + 1 ))
        proj_dur[$project]=$(( ${proj_dur[$project]:-0} + dur ))
        proj_cnt[$project]=$(( ${proj_cnt[$project]:-0} + 1 ))
    done < <(db_list_sessions_in_range "$start" "$end")

    echo "Total: $(_fmt_dur $total) across $sessions session(s)"
    echo ""

    if [[ ${#proj_dur[@]} -gt 0 ]]; then
        echo "Projects:"
        for p in "${!proj_dur[@]}"; do
            desc=$(db_get_description "$p")
            printf "  %-24s %s (%d session(s))\n" "$p" "$(_fmt_dur "${proj_dur[$p]}")" "${proj_cnt[$p]}"
            [[ -n "$desc" ]] && printf "  %-24s %s\n" "" "↳ $desc"
        done
        echo ""
    fi

    echo "Sessions:"
    while IFS='|' read -r id project start_t end_t dur notes duration_only session_date; do
        if [[ "$duration_only" == "1" ]]; then
            echo "  [$id] $project — $(_fmt_dur "$dur") on $session_date (manual)"
        else
            s=$(date --date="$start_t" +"$DATE_SHORT_FORMAT" 2>/dev/null)
            e=$(date --date="$end_t"   +"%H:%M"               2>/dev/null)
            echo "  [$id] $project — $s–$e ($(_fmt_dur "$dur"))"
        fi
        [[ -n "$notes" ]] && echo "       📝 $notes" || true
    done < <(db_list_sessions_in_range "$start" "$end")
}

period="${1:-today}"

case "$period" in
    today)
        start=$(date --date="today 00:00" -Iseconds)
        end=$(date -Iseconds)
        _report "Today's Focus" "$start" "$end"
        ;;
    week)
        start=$(date --date="7 days ago 00:00" -Iseconds)
        end=$(date -Iseconds)
        _report "This Week's Focus" "$start" "$end"
        ;;
    month)
        start=$(date --date="$(date +%Y-%m-01) 00:00" -Iseconds)
        end=$(date -Iseconds)
        _report "This Month's Focus" "$start" "$end"
        ;;
    custom)
        days="${2:-7}"
        [[ ! "$days" =~ ^[0-9]+$ ]] && { echo "Usage: focus report custom <days>" >&2; exit 2; }
        start=$(date --date="$days days ago 00:00" -Iseconds)
        end=$(date -Iseconds)
        _report "Last ${days}-day Focus" "$start" "$end"
        ;;
    *)
        echo "Usage: focus report [today|week|month|custom <days>]" >&2; exit 2
        ;;
esac
