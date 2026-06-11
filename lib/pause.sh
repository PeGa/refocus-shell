#!/usr/bin/env bash
set -euo pipefail
source "$REFOCUS_ROOT/config.sh"
source "$REFOCUS_ROOT/services/database.sh"

db_ensure

if ! is_session_active; then
    echo "❌ No active session to pause." >&2; exit 1
fi

IFS='|' read -r _ project start_time _ <<< "$(db_get_state)"
now=$(date -Iseconds)
now_ts=$(date +%s)
start_ts=$(date --date="$start_time" +%s)
elapsed=$(( now_ts - start_ts ))

db_pause_session "$elapsed" "$now"

echo "⏸  Paused: $project ($(( elapsed / 60 ))m). Use 'focus continue' to resume."
notify-send "Refocus" "Paused: $project" 2>/dev/null || true
