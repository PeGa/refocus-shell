#!/usr/bin/env bash
set -euo pipefail
source "$REFOCUS_ROOT/config.sh"
source "$REFOCUS_ROOT/services/database.sh"
source "$REFOCUS_ROOT/services/cron.sh"

db_ensure

if is_session_active; then
    IFS='|' read -r _ project _ <<< "$(get_state)"
    echo "⚠  Active session '$project' will be discarded."
elif is_session_paused; then
    IFS='|' read -r _ project _ <<< "$(get_state)"
    echo "⚠  Paused session '$project' will be discarded."
fi

echo -n "⚠  This deletes ALL focus data. Are you sure? (yes/N): "
read -r ans
[[ "$ans" == "yes" ]] || { echo "Cancelled."; exit 0; }

cron_remove 2>/dev/null || true
rm -f "$DB_PATH"
db_init
set_focus_disabled
echo "✅ Reset complete. Run 'focus enable' to start tracking."
