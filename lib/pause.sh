#!/usr/bin/env bash
set -euo pipefail
source "$REFOCUS_ROOT/env.sh"
source "$REFOCUS_ROOT/services/database.sh"
source "$REFOCUS_ROOT/core/time.sh"

db_ensure

if ! is_session_active; then
    echo "❌ No active session to pause." >&2; exit 1
fi

IFS='|' read -r _ project start_time _ <<< "$(get_state)"
now=$(now_iso)
now_ts=$(now_epoch)
start_ts=$(iso_to_epoch "$start_time")
elapsed=$(( now_ts - start_ts ))

pause_session "$elapsed" "$now"

echo "⏸  Paused: $project ($(( elapsed / 60 ))m). Use 'focus continue' to resume."
notify-send "Refocus" "Paused: $project" 2>/dev/null || true
