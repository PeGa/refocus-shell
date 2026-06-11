#!/usr/bin/env bash
set -euo pipefail
source "$REFOCUS_ROOT/config.sh"
source "$REFOCUS_ROOT/services/database.sh"

db_ensure

sub="${1:-status}"; shift || true

case "$sub" in
    enable)
        db_flip_flag nudging_enabled 1
        echo "✅ Nudging enabled (every ${NUDGE_INTERVAL}m during active sessions)."
        ;;
    disable)
        db_flip_flag nudging_enabled 0
        echo "🚫 Nudging disabled."
        ;;
    status)
        if db_nudging_on; then
            echo "✅ Nudging is ON (every ${NUDGE_INTERVAL}m)."
        else
            echo "🚫 Nudging is OFF."
        fi
        echo ""
        echo "Crontab:"
        crontab -l 2>/dev/null | grep "focus-nudge" || echo "  (no cron entry found)"
        ;;
    test)
        echo "Testing notification..."
        notify-send "Refocus test" "If you see this, notify-send works." \
            && echo "✅ notify-send: OK" \
            || echo "❌ notify-send: failed — check DISPLAY/WAYLAND_DISPLAY"
        echo ""
        echo "Testing nudge script directly..."
        bash "$HOME/.local/refocus/focus-nudge" \
            && echo "✅ focus-nudge: OK" \
            || echo "❌ focus-nudge: failed"
        echo ""
        echo "Crontab:"
        crontab -l 2>/dev/null | grep "focus-nudge" || echo "  (no cron entry — run 'focus on' to install it)"
        ;;
    *)
        echo "Usage: focus nudge <enable|disable|status|test>" >&2; exit 2
        ;;
esac
