#!/usr/bin/env bash
# Refocus Shell - Session listing renderer (composer)
#
# Shared table rendering for anything that prints 8-field session rows:
# `focus past list`, `focus cycle list`, `focus cycle show`. One renderer
# means a cycle break always looks like the same boundary line and an
# ordinary session always looks like the same table row, no matter which
# handler is asking [ARCH-COMPOSER — presentation-only sharing counts too].
#
# Sourced by handlers; assumes env.sh, services/database.sh, core/time.sh
# and core/text.sh are already in scope (is_cycle_label, notes_decode,
# notes_block, cycle_note_placeholder, ts_format, fmt_duration, and
# $DATE_SHORT_FORMAT all come from those).

# A cycle break is never a table row: it delimits periods, it isn't work, and
# its ~50-char label overflows the %-22s project column and smears the row's
# remaining columns [#46]. With `show_cycles` it renders as the boundary line
# it is — "here starts the new count" — carrying the id that every cycle
# subcommand addresses it by, plus its note when the note is the period's own
# rather than the canned instruction.
render_session_rows() {
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

render_session_header() {
    printf "%-4s %-22s %-19s %-19s %-8s\n" "ID" "Project" "Start" "End" "Duration"
    echo "─────────────────────────────────────────────────────────────────────────────"
}
