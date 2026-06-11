#!/usr/bin/env bash
set -euo pipefail
source "$REFOCUS_ROOT/config.sh"
source "$REFOCUS_ROOT/services/database.sh"
source "$REFOCUS_ROOT/services/cron.sh"

db_ensure

if db_is_disabled; then
    echo "❌ Refocus is disabled. Run 'focus enable' first." >&2; exit 1
fi
if db_is_active; then
    IFS='|' read -r _ project _ <<< "$(db_get_state)"
    echo "❌ Already focusing on: $project. Run 'focus off' first." >&2; exit 1
fi
if db_is_paused; then
    IFS='|' read -r _ project _ <<< "$(db_get_state)"
    echo "❌ Session paused: $project. Run 'focus continue' or 'focus off'." >&2; exit 1
fi

project="${1:-}"

if [[ -z "$project" ]]; then
    last=$(db_get_last_project)
    if [[ -n "$last" ]]; then
        echo -n "▶ Continue '$last'? (Y/n): "
        read -r ans
        [[ "${ans:-Y}" =~ ^[Nn]$ ]] && { echo "Aborted."; exit 0; }
        project="$last"
    else
        echo "Usage: focus on <project>" >&2; exit 2
    fi
fi

if [[ ${#project} -gt $MAX_PROJECT_LENGTH ]]; then
    echo "❌ Project name too long (max $MAX_PROJECT_LENGTH chars)." >&2; exit 2
fi

start_time=$(date -Iseconds)
db_start_session "$project" "$start_time"
cron_install "$project" "$start_time" 2>/dev/null || true

total=$(db_get_total_time "$project")
total_min=$(( total / 60 ))

if [[ $total_min -gt 0 ]]; then
    echo "🎯 Started focus on: $project (Total so far: ${total_min}m)"
else
    echo "🎯 Started focus on: $project"
fi

notify-send "Refocus" "Started: $project" 2>/dev/null || true
