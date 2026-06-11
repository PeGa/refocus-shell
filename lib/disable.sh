#!/usr/bin/env bash
set -euo pipefail
source "$REFOCUS_ROOT/config.sh"
source "$REFOCUS_ROOT/services/database.sh"
source "$REFOCUS_ROOT/services/cron.sh"
db_ensure
db_set_focus_disabled
cron_remove 2>/dev/null || true
echo "🚫 Refocus disabled."
