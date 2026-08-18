#!/usr/bin/env bash
set -euo pipefail
source "$REFOCUS_ROOT/env.sh"
source "$REFOCUS_ROOT/services/database.sh"
source "$REFOCUS_ROOT/core/time.sh"
source "$REFOCUS_ROOT/core/text.sh"

db_ensure

_report() {
    local label="$1" start="$2" end="$3"

    echo "📊 $label"
    printf '═%.0s' $(seq 1 "${#label}"); echo
    echo "Period: $(ts_format "$start" "$DATE_FORMAT") → $(ts_format "$end" "$DATE_FORMAT")"
    echo ""

    local total=0 sessions=0
    # The =() initialisers are load-bearing: a bare `declare -A x` leaves the
    # array unset, so ${#x[@]} on a period with no sessions trips `set -u` and
    # aborted the whole report.
    declare -A proj_dur=() proj_cnt=()

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
            s=$(ts_format "$start_t" "$DATE_SHORT_FORMAT" 2>/dev/null)
            e=$(ts_format "$end_t"   "%H:%M"             2>/dev/null)
            echo "  [$id] $project — $s–$e ($(fmt_duration "$dur"))"
        fi
        if [[ -n "$notes" ]]; then
            notes_block "       📝 " "          " "$(notes_decode "$notes")"
        fi
    done < <(list_sessions_in_range "$start" "$end")
}

period="${1:-today}"

case "$period" in
    today)
        start=$(iso_days_ago 0)
        end=$(now_iso)
        _report "Today's Focus" "$start" "$end"
        ;;
    week)
        start=$(iso_days_ago 7)
        end=$(now_iso)
        _report "This Week's Focus" "$start" "$end"
        ;;
    month)
        start=$(iso_month_start)
        end=$(now_iso)
        _report "This Month's Focus" "$start" "$end"
        ;;
    custom)
        days="${2:-7}"
        [[ ! "$days" =~ ^[0-9]+$ ]] && { echo "Usage: focus report custom <days>" >&2; exit 2; }
        start=$(iso_days_ago "$days")
        end=$(now_iso)
        _report "Last ${days}-day Focus" "$start" "$end"
        ;;
    *)
        echo "Usage: focus report [today|week|month|custom <days>]" >&2; exit 2
        ;;
esac
