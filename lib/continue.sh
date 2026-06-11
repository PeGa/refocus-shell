#!/usr/bin/env bash
set -euo pipefail
source "$REFOCUS_ROOT/config.sh"
source "$REFOCUS_ROOT/services/database.sh"

db_ensure

if ! is_session_paused; then
    echo "❌ No paused session." >&2; exit 1
fi

IFS='|' read -r _ project _ _ _ previous_elapsed _ _ <<< "$(db_get_state)"
prev_min=$(( previous_elapsed / 60 ))

echo -n "▶ Continue '$project' (${prev_min}m before pause)? (Y/n): "
read -r ans
if [[ "${ans:-Y}" =~ ^[Nn]$ ]]; then
    echo "Session remains paused. Use 'focus off' to end it."
    exit 0
fi

now=$(date -Iseconds)
now_ts=$(date +%s)
adjusted_ts=$(( now_ts - previous_elapsed ))
adjusted=$(date --date="@$adjusted_ts" -Iseconds)
db_resume_session "$adjusted"

echo "▶  Resumed: $project (continuing from ${prev_min}m)."
notify-send "Refocus" "Resumed: $project" 2>/dev/null || true
