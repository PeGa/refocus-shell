#!/usr/bin/env bash
set -euo pipefail
source "$REFOCUS_ROOT/env.sh"
source "$REFOCUS_ROOT/services/database.sh"
source "$REFOCUS_ROOT/core/time.sh"
source "$REFOCUS_ROOT/core/text.sh"
source "$REFOCUS_ROOT/services/help.sh"
source "$REFOCUS_ROOT/services/period.sh"

wants_help "$@" && show_help report

db_ensure

# Output is markdown, on stdout — `focus report custom 14 > report.md`.
#
# Notes are hand-written markdown: bullets, **bold**, > blockquotes. The old
# layout indented every note line under a 📝 prefix, which turned all of it
# into code blocks and meant a shareable report had to be reassembled by hand.
# Nothing here reformats a note; it is emitted verbatim and the structure
# survives.

# The two range kinds read from different functions but render identically,
# so the mode is resolved once here rather than threaded through the body.
# Cycle breaks are never listed by report: they delimit periods, they are not
# work. The breakdown drops them in SQL because it aggregates there; the row
# loops drop them here, which is safe only because neither applies a LIMIT.
_rows() {
    if [[ "$_mode" == "window" ]]; then
        list_sessions_by_id_range "$_a" "$_b"
    else
        list_sessions_in_range "$_a" "$_b"
    fi
}

_totals() {
    if [[ "$_mode" == "window" ]]; then
        get_project_totals_by_id_range "$_a" "$_b" "$(cycle_prefix)"
    else
        get_project_totals_in_range "$_a" "$_b" "$(cycle_prefix)"
    fi
}

_report() {
    local label="$1"
    _mode="$2" _a="$3" _b="$4"

    echo "# Focus report"
    echo "## $label"
    echo ""

    # No associative array: macOS ships bash 3.2 (no `declare -A` at all), so
    # the per-project breakdown is aggregated in SQL (get_project_totals_in_range)
    # instead. This loop only sums scalars, which every bash version supports.
    local total=0 sessions=0
    while IFS='|' read -r id project start_t end_t dur notes duration_only session_date; do
        is_cycle_label "$project" && continue
        total=$(( total + dur ))
        sessions=$(( sessions + 1 ))
    done < <(_rows)

    local noun="sessions"
    [[ $sessions -eq 1 ]] && noun="session"
    echo "Period: $_from → $_to Total: $(fmt_duration $total) across $sessions $noun"

    # An empty period stops here: a header, the period line, and no rules
    # trailing off the end of an otherwise blank document.
    [[ $sessions -eq 0 ]] && return 0

    echo ""
    echo "---"
    echo ""

    # Project names cannot contain '|' — the sessions table CHECKs for it — so
    # no table cell needs escaping.
    local have_projects=0
    while IFS='|' read -r p pdur pcnt; do
        if [[ $have_projects -eq 0 ]]; then
            echo "## Projects"
            echo ""
            echo "| Project | Time | Sessions |"
            echo "|---|---:|---:|"
            have_projects=1
        fi
        printf "| \`%s\` | %s | %s |\n" "$p" "$(fmt_duration "$pdur")" "$pcnt"
    done < <(_totals)
    [[ $have_projects -eq 1 ]] && { echo ""; echo "---"; echo ""; }

    local have_sessions=0 s e
    while IFS='|' read -r id project start_t end_t dur notes duration_only session_date; do
        is_cycle_label "$project" && continue
        if [[ $have_sessions -eq 0 ]]; then
            echo "## Sessions"
            echo ""
            have_sessions=1
        else
            # Rules separate sessions from each other, so each one is written
            # ahead of the session that follows it — that way the last session
            # isn't left with a rule and a blank line trailing off the end.
            echo ""
            echo "---"
            echo ""
        fi

        echo "### [$id] \`$project\`"
        if [[ "$duration_only" == "1" ]]; then
            echo "**$(fmt_duration "$dur") on $session_date (manual)**"
        else
            # Fall back to the stored string when it won't parse, the way
            # `past list` does — under set -e a bare command substitution here
            # would abort the whole report over one unreadable timestamp.
            s=$(ts_format "$start_t" "$DATE_SHORT_FORMAT" 2>/dev/null || echo "$start_t")
            e=$(ts_format "$end_t"   "%H:%M"             2>/dev/null || echo "$end_t")
            echo "**$s–$e · $(fmt_duration "$dur")**"
        fi

        if [[ -n "$notes" ]]; then
            # Verbatim — reformatting is what broke markdown before. The blank
            # line separating the note from the heading above it is written
            # here rather than unconditionally, so a session with no note
            # doesn't leave two blank lines behind. notes_decode emits no
            # trailing newline; the closing echo supplies it.
            echo ""
            notes_decode "$notes"
            echo ""
        fi
    done < <(_rows)
}

_date_range() {
    _from=$(ts_format "$1" "$DATE_FORMAT")
    _to=$(ts_format "$2" "$DATE_FORMAT")
}

period="${1:-today}"

case "$period" in
    today)
        start=$(iso_days_ago 0); end=$(now_iso)
        _date_range "$start" "$end"
        _report "Today" range "$start" "$end"
        ;;
    week)
        start=$(iso_days_ago 7); end=$(now_iso)
        _date_range "$start" "$end"
        _report "This week" range "$start" "$end"
        ;;
    month)
        start=$(iso_month_start); end=$(now_iso)
        _date_range "$start" "$end"
        _report "This month" range "$start" "$end"
        ;;
    custom)
        days="${2:-7}"
        [[ ! "$days" =~ ^[0-9]+$ ]] && usage_error report
        start=$(iso_days_ago "$days"); end=$(now_iso)
        _date_range "$start" "$end"
        day_noun="days"
        [[ "$days" -eq 1 ]] && day_noun="day"
        _report "Last ${days} ${day_noun}" range "$start" "$end"
        ;;
    cycle)
        sel="${2:-0}"
        is_period_selector "$sel" || usage_error report
        window=$(get_period_window "$sel") || exit 1
        lo="${window%|*}"; hi="${window#*|}"

        # The window is ids; the period line still wants human bounds, so read
        # them off the breaks that open and close it.
        _cycle_moment() {
            local row; row=$(get_session "$1")
            [[ -z "$row" ]] && { printf 'now'; return 0; }
            local e; IFS='|' read -r _ _ _ e _ <<< "$row"
            ts_format "$e" "$DATE_SHORT_FORMAT" 2>/dev/null || printf '%s' "$e"
        }
        if [[ -n "$lo" ]]; then _from=$(_cycle_moment "$lo"); else _from="Beginning"; fi
        if [[ -n "$hi" ]]; then _to=$(_cycle_moment "$hi");   else _to="now"; fi

        label="Cycle ${sel}"
        [[ "$sel" == "0" ]] && label="Current cycle"
        _report "$label" window "$lo" "$hi"
        ;;
    *)
        usage_error report
        ;;
esac
