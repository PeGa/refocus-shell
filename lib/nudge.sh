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
        ;;
    *)
        echo "Usage: focus nudge <enable|disable|status>" >&2; exit 2
        ;;
esac
