#!/usr/bin/env bash
set -euo pipefail
source "$REFOCUS_ROOT/env.sh"
source "$REFOCUS_ROOT/services/database.sh"
source "$REFOCUS_ROOT/services/help.sh"

wants_help "$@" && show_help nudge

db_ensure

sub="${1:-status}"; shift || true

case "$sub" in
    status)
        if is_focus_disabled; then
            echo "🚫 Refocus is disabled (nudging inactive)."
        else
            echo "✅ Refocus is enabled — nudging active every ${NUDGE_INTERVAL}m."
        fi
        echo ""
        echo "Crontab:"
        crontab -l 2>/dev/null | grep "focus-nudge" || echo "  (no cron entry — run 'focus enable')"
        ;;
    test)
        echo "Testing notification..."
        notify-send "Refocus test" "If you see this, notify-send works." \
            && echo "✅ notify-send: OK" \
            || echo "❌ notify-send: failed — check DISPLAY/WAYLAND_DISPLAY"
        echo ""
        echo "Testing nudge script directly..."
        bash "$REFOCUS_ROOT/focus-nudge" \
            && echo "✅ focus-nudge: OK" \
            || echo "❌ focus-nudge: failed"
        echo ""
        echo "Crontab:"
        crontab -l 2>/dev/null | grep "focus-nudge" || echo "  (no cron entry)"
        ;;
    *)
        usage_error nudge
        ;;
esac
