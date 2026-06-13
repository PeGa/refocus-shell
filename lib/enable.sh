#!/usr/bin/env bash
set -euo pipefail
source "$REFOCUS_ROOT/env.sh"
source "$REFOCUS_ROOT/services/database.sh"
source "$REFOCUS_ROOT/services/cron.sh"
db_ensure
if ! is_focus_disabled; then
    echo "✅ Refocus is already enabled." >&2
    exit 0
fi
set_focus_enabled
cron_install || echo "⚠  Could not install cron nudge — check 'focus nudge test'" >&2
echo "✅ Refocus enabled."
