#!/usr/bin/env bash
set -euo pipefail
source "$REFOCUS_ROOT/config.sh"
source "$REFOCUS_ROOT/services/database.sh"
source "$REFOCUS_ROOT/services/cron.sh"
db_ensure
set_focus_enabled
cron_install || echo "⚠  Could not install cron nudge — check 'focus nudge test'" >&2
echo "✅ Refocus enabled."
