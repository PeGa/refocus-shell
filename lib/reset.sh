#!/usr/bin/env bash
set -euo pipefail
source "$REFOCUS_ROOT/config.sh"
source "$REFOCUS_ROOT/services/database.sh"
source "$REFOCUS_ROOT/services/cron.sh"

echo -n "⚠  This deletes ALL focus data. Are you sure? (yes/N): "
read -r ans
[[ "$ans" == "yes" ]] || { echo "Cancelled."; exit 0; }

cron_remove 2>/dev/null || true
rm -f "$DB_PATH"
db_init
set_focus_disabled
echo "✅ Reset complete. Run 'focus enable' to start tracking."
