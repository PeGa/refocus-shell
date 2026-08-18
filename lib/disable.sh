#!/usr/bin/env bash
set -euo pipefail
source "$REFOCUS_ROOT/env.sh"
source "$REFOCUS_ROOT/services/database.sh"
source "$REFOCUS_ROOT/services/cron.sh"
source "$REFOCUS_ROOT/services/help.sh"

wants_help "$@" && show_help disable
db_ensure

if is_session_active || is_session_paused; then
    IFS='|' read -r _ project _ <<< "$(get_state)"
    echo "❌ Session running: $project — run 'focus off' first." >&2
    exit 1
fi

set_focus_disabled
cron_remove 2>/dev/null || true
echo "🚫 Refocus disabled."
