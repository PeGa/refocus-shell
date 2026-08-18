#!/usr/bin/env bash
set -euo pipefail
source "$REFOCUS_ROOT/env.sh"
source "$REFOCUS_ROOT/services/database.sh"
source "$REFOCUS_ROOT/core/time.sh"
source "$REFOCUS_ROOT/core/text.sh"
source "$REFOCUS_ROOT/services/help.sh"

wants_help "$@" && show_help report

db_ensure

_report() {
    local label="$1" start="$2" end="$3"

    echo "📊 $label"
    printf '═%.0s' $(seq 1 "${#label}"); echo
    echo "Period: $(ts_format "$start" "$DATE_FORMAT") → $(ts_format "$end" "$DATE_FORMAT")"
    echo ""

    # No associative array: macOS ships bash 3.2 (no `declare -A` at all), so
    # the per-project breakdown is aggregated in SQL (get_project_totals_in_range)
    # instead. This loop only sums scalars, which every bash version supports.
    local total=0 sessions=0
    while IFS='|' read -r id project start_t end_t dur notes duration_only session_date; do
        total=$(( total + dur ))
        sessions=$(( sessions + 1 ))
    done < <(list_sessions_in_range "$start" "$end")

    echo "Total: $(fmt_duration $total) across $sessions session(s)"
    echo ""

    local have_projects=0
    while IFS='|' read -r p pdur pcnt; do
        [[ $have_projects -eq 0 ]] && { echo "Projects:"; have_projects=1; }
        printf "  %-24s %s (%d session(s))\n" "$p" "$(fmt_duration "$pdur")" "$pcnt"
    done < <(get_project_totals_in_range "$start" "$end")
    [[ $have_projects -eq 1 ]] && echo ""

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
        [[ ! "$days" =~ ^[0-9]+$ ]] && usage_error report
        start=$(iso_days_ago "$days")
        end=$(now_iso)
        _report "Last ${days}-day Focus" "$start" "$end"
        ;;
    *)
        usage_error report
        ;;
esac
