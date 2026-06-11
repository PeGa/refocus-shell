#!/usr/bin/env bash
set -euo pipefail
source "$REFOCUS_ROOT/config.sh"
source "$REFOCUS_ROOT/services/database.sh"
source "$REFOCUS_ROOT/services/cron.sh"

db_ensure

if ! db_is_active; then
    echo "❌ No active session to pause." >&2; exit 1
fi

IFS='|' read -r _ project start_time _ <<< "$(db_get_state)"
now=$(date -Iseconds)
now_ts=$(date +%s)
start_ts=$(date --date="$start_time" +%s)
elapsed=$(( now_ts - start_ts ))

echo -n "⏸  Pausing '$project' ($(( elapsed / 60 ))m elapsed). Notes: "
read -r notes

db_pause_session "$elapsed" "$notes" "$now"
cron_remove 2>/dev/null || true

echo "✅ Paused. Use 'focus continue' to resume."
notify-send "Refocus" "Paused: $project" 2>/dev/null || true
