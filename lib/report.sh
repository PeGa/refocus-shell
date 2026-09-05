#!/usr/bin/env bash
set -euo pipefail
source "$REFOCUS_ROOT/env.sh"
source "$REFOCUS_ROOT/services/database.sh"
source "$REFOCUS_ROOT/core/time.sh"
source "$REFOCUS_ROOT/core/text.sh"
source "$REFOCUS_ROOT/services/help.sh"

wants_help "$@" && show_help report

db_ensure

# Output is markdown, on stdout — `focus report custom 14 > report.md`.
#
# Notes are hand-written markdown: bullets, **bold**, > blockquotes. The old
# layout indented every note line under a 📝 prefix, which turned all of it
# into code blocks and meant a shareable report had to be reassembled by hand.
# Nothing here reformats a note; it is emitted verbatim and the structure
# survives.

_report() {
    local label="$1" start="$2" end="$3"

    echo "# Focus report"
    echo "## $label"
    echo ""

    # No associative array: macOS ships bash 3.2 (no `declare -A` at all), so
    # the per-project breakdown is aggregated in SQL (get_project_totals_in_range)
    # instead. This loop only sums scalars, which every bash version supports.
    local total=0 sessions=0
    while IFS='|' read -r id project start_t end_t dur notes duration_only session_date; do
        total=$(( total + dur ))
        sessions=$(( sessions + 1 ))
    done < <(list_sessions_in_range "$start" "$end")

    local noun="sessions"
    [[ $sessions -eq 1 ]] && noun="session"
    echo "Period: $(ts_format "$start" "$DATE_FORMAT") → $(ts_format "$end" "$DATE_FORMAT") Total: $(fmt_duration $total) across $sessions $noun"

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
    done < <(get_project_totals_in_range "$start" "$end")
    [[ $have_projects -eq 1 ]] && { echo ""; echo "---"; echo ""; }

    local have_sessions=0 s e
    while IFS='|' read -r id project start_t end_t dur notes duration_only session_date; do
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
    done < <(list_sessions_in_range "$start" "$end")
}

period="${1:-today}"

case "$period" in
    today)
        start=$(iso_days_ago 0)
        end=$(now_iso)
        _report "Today" "$start" "$end"
        ;;
    week)
        start=$(iso_days_ago 7)
        end=$(now_iso)
        _report "This week" "$start" "$end"
        ;;
    month)
        start=$(iso_month_start)
        end=$(now_iso)
        _report "This month" "$start" "$end"
        ;;
    custom)
        days="${2:-7}"
        [[ ! "$days" =~ ^[0-9]+$ ]] && usage_error report
        start=$(iso_days_ago "$days")
        end=$(now_iso)
        day_noun="days"
        [[ "$days" -eq 1 ]] && day_noun="day"
        _report "Last ${days} ${day_noun}" "$start" "$end"
        ;;
    *)
        usage_error report
        ;;
esac
