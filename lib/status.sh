#!/usr/bin/env bash
set -euo pipefail
source "$REFOCUS_ROOT/env.sh"
source "$REFOCUS_ROOT/services/database.sh"
source "$REFOCUS_ROOT/core/time.sh"
source "$REFOCUS_ROOT/services/help.sh"

wants_help "$@" && show_help status

db_ensure

now_ts=$(now_epoch)

_show_last() {
    local last; last=$(get_last_session)
    [[ -z "$last" ]] && return
    IFS='|' read -r last_project last_end last_dur <<< "$last"
    local last_ts; last_ts=$(iso_to_epoch "$last_end" 2>/dev/null || echo 0)
    local since=$(( (now_ts - last_ts) / 60 ))
    echo "   Last: $last_project ($(( last_dur / 60 ))m, ${since}m ago)"
}

if is_focus_disabled; then
    echo "🚫 Refocus disabled — run 'focus enable' to start tracking."
    _show_last
    exit 0
fi

IFS='|' read -r active project start_time paused pause_start_time previous_elapsed _ _ <<< "$(get_state)"

if [[ "$active" == "1" ]]; then
    local_start_ts=$(iso_to_epoch "$start_time")
    elapsed=$(( now_ts - local_start_ts ))
    elapsed_min=$(( elapsed / 60 ))
    total=$(get_total_time "$project")
    total_min=$(( total / 60 ))
    echo -n "⏳ Focusing on: $project — ${elapsed_min}m"
    [[ $total_min -gt 0 ]] && echo " (Total: ${total_min}m)" || echo ""

elif [[ "$paused" == "1" ]]; then
    pause_ts=$(iso_to_epoch "$pause_start_time")
    paused_for=$(( (now_ts - pause_ts) / 60 ))
    echo "⏸  Paused: $project"
    echo "   Session so far: $(( previous_elapsed / 60 ))m | Paused for: ${paused_for}m"
    echo ""
    echo "   focus continue  — resume"
    echo "   focus off       — end session"

else
    echo "✅ Not focusing."
    _show_last
fi
