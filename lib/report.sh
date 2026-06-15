#!/usr/bin/env bash
set -euo pipefail
source "$REFOCUS_ROOT/env.sh"
source "$REFOCUS_ROOT/services/database.sh"
source "$REFOCUS_ROOT/core/time.sh"

db_ensure

_report() {
    local label="$1" start="$2" end="$3"

    echo "📊 $label"
    printf '═%.0s' $(seq 1 "${#label}"); echo
    echo "Period: $(_ts_format "$start" "$DATE_FORMAT") → $(_ts_format "$end" "$DATE_FORMAT")"
    echo ""

    local total=0 sessions=0
    declare -A proj_dur proj_cnt

    while IFS='|' read -r id project start_t end_t dur notes duration_only session_date; do
        total=$(( total + dur ))
        sessions=$(( sessions + 1 ))
        proj_dur[$project]=$(( ${proj_dur[$project]:-0} + dur ))
        proj_cnt[$project]=$(( ${proj_cnt[$project]:-0} + 1 ))
    done < <(list_sessions_in_range "$start" "$end")

    echo "Total: $(fmt_duration $total) across $sessions session(s)"
    echo ""

    if [[ ${#proj_dur[@]} -gt 0 ]]; then
        echo "Projects:"
        for p in "${!proj_dur[@]}"; do
            printf "  %-24s %s (%d session(s))\n" "$p" "$(fmt_duration "${proj_dur[$p]}")" "${proj_cnt[$p]}"
        done
        echo ""
    fi

    echo "Sessions:"
    while IFS='|' read -r id project start_t end_t dur notes duration_only session_date; do
        if [[ "$duration_only" == "1" ]]; then
            echo "  [$id] $project — $(fmt_duration "$dur") on $session_date (manual)"
        else
            s=$(_ts_format "$start_t" "$DATE_SHORT_FORMAT" 2>/dev/null)
            e=$(_ts_format "$end_t"   "%H:%M"             2>/dev/null)
            echo "  [$id] $project — $s–$e ($(fmt_duration "$dur"))"
        fi
        if [[ -n "$notes" ]]; then echo "       📝 $notes"; fi
    done < <(list_sessions_in_range "$start" "$end")
}

period="${1:-today}"

case "$period" in
    today)
        start=$(_iso_days_ago 0)
        end=$(date -Iseconds)
        _report "Today's Focus" "$start" "$end"
        ;;
    week)
        start=$(_iso_days_ago 7)
        end=$(date -Iseconds)
        _report "This Week's Focus" "$start" "$end"
        ;;
    month)
        start=$(_iso_month_start)
        end=$(date -Iseconds)
        _report "This Month's Focus" "$start" "$end"
        ;;
    custom)
        days="${2:-7}"
        [[ ! "$days" =~ ^[0-9]+$ ]] && { echo "Usage: focus report custom <days>" >&2; exit 2; }
        start=$(_iso_days_ago "$days")
        end=$(date -Iseconds)
        _report "Last ${days}-day Focus" "$start" "$end"
        ;;
    *)
        echo "Usage: focus report [today|week|month|custom <days>]" >&2; exit 2
        ;;
esac
