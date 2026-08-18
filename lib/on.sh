#!/usr/bin/env bash
set -euo pipefail
source "$REFOCUS_ROOT/env.sh"
source "$REFOCUS_ROOT/services/database.sh"
source "$REFOCUS_ROOT/core/time.sh"

db_ensure

if is_focus_disabled; then
    echo "❌ Refocus is disabled. Run 'focus enable' first." >&2; exit 1
fi
if is_session_active; then
    IFS='|' read -r _ project _ <<< "$(get_state)"
    echo "❌ Already focusing on: $project. Run 'focus off' first." >&2; exit 1
fi
if is_session_paused; then
    IFS='|' read -r _ project _ <<< "$(get_state)"
    echo "❌ Session paused: $project. Run 'focus continue' or 'focus off'." >&2; exit 1
fi

project="${1:-}"

if [[ -z "$project" ]]; then
    last=$(get_last_project)
    if [[ -n "$last" ]]; then
        total=$(get_total_time "$last")
        total_min=$(( total / 60 ))
        suffix=""
        [[ $total_min -gt 0 ]] && suffix=" (${total_min}m logged)"
        echo -n "▶ Continue '$last'${suffix}? (Y/n): "
        read -r ans
        if [[ "${ans:-Y}" =~ ^[Nn]$ ]]; then
            echo "Run 'focus on <project>' to focus on something else."
            exit 0
        fi
        project="$last"
    else
        echo "Usage: focus on <project>" >&2; exit 2
    fi
else
    if [[ ${#project} -gt $MAX_PROJECT_LENGTH ]]; then
        echo "❌ Project name too long (max $MAX_PROJECT_LENGTH chars)." >&2; exit 2
    fi
    total=$(get_total_time "$project")
    total_min=$(( total / 60 ))
    if [[ $total_min -gt 0 ]]; then
        echo -n "▶ '$project' has ${total_min}m logged. Continue? (Y/n): "
        read -r ans
        if [[ "${ans:-Y}" =~ ^[Nn]$ ]]; then
            echo "Run 'focus on <project>' with the correct project name."
            exit 0
        fi
    fi
fi

start_time=$(now_iso)
start_session "$project" "$start_time"

if [[ ${total_min:-0} -gt 0 ]]; then
    echo "🎯 Started: $project (Total so far: ${total_min}m)"
else
    echo "🎯 Started: $project"
fi

notify-send "Refocus" "Started: $project" 2>/dev/null || true
