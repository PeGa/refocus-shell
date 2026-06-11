#!/usr/bin/env bash
set -euo pipefail
source "$REFOCUS_ROOT/config.sh"
source "$REFOCUS_ROOT/services/database.sh"

db_ensure

IFS='|' read -r active project start_time paused pause_notes pause_start_time previous_elapsed _ <<< "$(db_get_state)"
now_ts=$(date +%s)

if [[ "$active" == "1" ]]; then
    start_ts=$(date --date="$start_time" +%s)
    elapsed=$(( now_ts - start_ts ))
    elapsed_min=$(( elapsed / 60 ))

    total=$(db_get_total_time "$project")
    total_min=$(( total / 60 ))

    echo -n "⏳ Focusing on: $project — ${elapsed_min}m"
    [[ $total_min -gt 0 ]] && echo " (Total: ${total_min}m)" || echo ""

    desc=$(db_get_description "$project")
    [[ -n "$desc" ]] && echo "   $desc" || true

elif [[ "$paused" == "1" ]]; then
    pause_ts=$(date --date="$pause_start_time" +%s)
    paused_for=$(( (now_ts - pause_ts) / 60 ))

    echo "⏸  Paused: $project"
    echo "   Session so far: $(( previous_elapsed / 60 ))m | Paused for: ${paused_for}m"
    [[ -n "$pause_notes" ]] && echo "   Notes: $pause_notes" || true
    echo ""
    echo "   focus continue  — resume"
    echo "   focus off       — end session"

else
    echo "✅ Not focusing."

    last=$(db_get_last_session)
    if [[ -n "$last" ]]; then
        IFS='|' read -r last_project last_end last_dur <<< "$last"
        last_ts=$(date --date="$last_end" +%s 2>/dev/null || echo 0)
        since=$(( (now_ts - last_ts) / 60 ))
        echo "   Last: $last_project ($(( last_dur / 60 ))m, ${since}m ago)"
    fi
fi
