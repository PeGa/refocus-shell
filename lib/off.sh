#!/usr/bin/env bash
set -euo pipefail
source "$REFOCUS_ROOT/env.sh"
source "$REFOCUS_ROOT/services/database.sh"
source "$REFOCUS_ROOT/services/editor.sh"
source "$REFOCUS_ROOT/core/time.sh"
source "$REFOCUS_ROOT/core/text.sh"
source "$REFOCUS_ROOT/services/help.sh"

wants_help "$@" && show_help off

db_ensure

IFS='|' read -r active project start_time paused _ previous_elapsed _ _ <<< "$(get_state)"

if [[ "$active" != "1" && "$paused" != "1" ]]; then
    echo "❌ No active session." >&2; exit 1
fi

now=$(now_iso)
now_ts=$(now_epoch)

if [[ "$paused" == "1" ]]; then
    duration=$previous_elapsed
    echo "⏸  Stopping paused session: $project"
    echo "   Session time: $(( duration / 60 ))m"
else
    start_ts=$(iso_to_epoch "$start_time")
    duration=$(( now_ts - start_ts ))
    echo "⏹  Stopping: $project ($(( duration / 60 ))m)"
fi

echo ""
echo "📝 What did you accomplish? (empty to skip)"
notes=$(capture_notes "")

record_session "$project" "$start_time" "$now" "$duration" "$notes"
end_session "$now"

if [[ -n "$notes" ]]; then
    echo "✅ Stopped. Notes:"
    notes_block "   " "   " "$notes"
else
    echo "✅ Stopped. No notes recorded."
fi

notify-send "Refocus" "Stopped: $project ($(( duration / 60 ))m)" 2>/dev/null || true
