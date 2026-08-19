#!/usr/bin/env bash
set -euo pipefail
source "$REFOCUS_ROOT/env.sh"
source "$REFOCUS_ROOT/services/database.sh"
source "$REFOCUS_ROOT/services/help.sh"

wants_help "$@" && show_help checkin

db_ensure

sub="${1:-status}"; shift || true

case "$sub" in
    status)
        if is_focus_disabled; then
            echo "🚫 Refocus is disabled (check-in inactive)."
        elif [[ "$CHECKIN_INTERVAL" == "0" ]]; then
            echo "🚫 Check-in is disabled (CHECKIN_INTERVAL=0)."
        else
            echo "✅ Refocus is enabled — checking in every ${CHECKIN_INTERVAL}m, when idle."
        fi
        echo ""
        echo "Crontab:"
        crontab -l 2>/dev/null | grep "focus-checkin" || echo "  (no cron entry — run 'focus enable')"
        echo ""
        # Same order focus-checkin itself checks in.
        if command -v kdialog >/dev/null 2>&1; then
            echo "Popup tool: kdialog"
        elif command -v zenity >/dev/null 2>&1; then
            echo "Popup tool: zenity"
        else
            for term in x-terminal-emulator xterm; do
                if command -v "$term" >/dev/null 2>&1; then
                    if command -v dialog >/dev/null 2>&1; then
                        echo "Popup tool: dialog, in a spawned $term"
                    else
                        echo "Popup tool: plain prompt in a spawned $term (no dialog installed)"
                    fi
                    term_found=1
                    break
                fi
            done
            [[ -z "${term_found:-}" ]] && echo "Popup tool: none found — check-in will silently do nothing"
        fi
        ;;
    test)
        echo "Running focus-checkin directly — same guards as a real cron fire apply:"
        echo "it stays silent if you're disabled, active, or paused. Go idle first"
        echo "if you want to actually see the popup."
        bash "$REFOCUS_ROOT/focus-checkin" \
            && echo "✅ focus-checkin: OK (ran to completion — check above for a popup)" \
            || echo "❌ focus-checkin: failed"
        echo ""
        echo "Crontab:"
        crontab -l 2>/dev/null | grep "focus-checkin" || echo "  (no cron entry)"
        ;;
    *)
        usage_error checkin
        ;;
esac
