#!/usr/bin/env bash
set -euo pipefail
source "$REFOCUS_ROOT/config.sh"
source "$REFOCUS_ROOT/services/database.sh"
source "$REFOCUS_ROOT/services/cron.sh"

db_ensure

if ! db_is_paused; then
    echo "❌ No paused session." >&2; exit 1
fi

IFS='|' read -r _ project _ _ _ _ previous_elapsed _ <<< "$(db_get_state)"
prev_min=$(( previous_elapsed / 60 ))

echo -n "▶ Resume '$project' (${prev_min}m logged). Count previous time? (Y/n): "
read -r ans

now=$(date -Iseconds)
now_ts=$(date +%s)

if [[ "${ans:-Y}" =~ ^[Nn]$ ]]; then
    # Fresh start: new start_time = now
    db_resume_session "$now"
    echo "▶  Resumed '$project' (timer reset)."
else
    # Keep accumulated time: back-date start_time by previous_elapsed seconds
    adjusted_ts=$(( now_ts - previous_elapsed ))
    adjusted=$(date --date="@$adjusted_ts" -Iseconds)
    db_resume_session "$adjusted"
    echo "▶  Resumed '$project' (continuing from ${prev_min}m)."
fi

cron_install "$project" "$now" 2>/dev/null || true
notify-send "Refocus" "Resumed: $project" 2>/dev/null || true
