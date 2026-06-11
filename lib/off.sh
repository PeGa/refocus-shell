#!/usr/bin/env bash
set -euo pipefail
source "$REFOCUS_ROOT/config.sh"
source "$REFOCUS_ROOT/services/database.sh"
source "$REFOCUS_ROOT/services/cron.sh"

db_ensure

IFS='|' read -r active project start_time paused pause_notes pause_start_time previous_elapsed _ <<< "$(db_get_state)"

if [[ "$active" != "1" && "$paused" != "1" ]]; then
    echo "❌ No active session." >&2; exit 1
fi

now=$(date -Iseconds)
now_ts=$(date +%s)

if [[ "$paused" == "1" ]]; then
    # Was paused: total = previous_elapsed + time spent paused (we don't count pause time)
    duration=$previous_elapsed
    echo "⏸  Stopping paused session: $project"
    echo "   Session time: $(( duration / 60 ))m"
    [[ -n "$pause_notes" ]] && echo "   Pause notes: $pause_notes" || true
else
    start_ts=$(date --date="$start_time" +%s)
    duration=$(( now_ts - start_ts ))
    echo "⏹  Stopping focus on: $project ($(( duration / 60 ))m)"
fi

echo ""
echo -n "📝 What did you accomplish? (Enter to skip): "
read -r notes

# Combine pause notes + session notes if both exist
if [[ -n "$pause_notes" && -n "$notes" ]]; then
    final_notes="$pause_notes | $notes"
elif [[ -n "$pause_notes" ]]; then
    final_notes="$pause_notes"
else
    final_notes="$notes"
fi

db_insert_session "$project" "$start_time" "$now" "$duration" "$final_notes"
db_end_session "$now"
cron_remove || echo "⚠  Could not remove cron nudge" >&2

if [[ -n "$final_notes" ]]; then
    echo "✅ Stopped. Notes: $final_notes"
else
    echo "✅ Stopped. No notes recorded."
fi

notify-send "Refocus" "Stopped: $project ($(( duration / 60 ))m)" 2>/dev/null || true
