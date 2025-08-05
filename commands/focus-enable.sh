#!/usr/bin/env bash
# Refocus Shell - Enable Refocus Shell Subcommand
# Copyright (c) 2025 PeGa
# Licensed under the GNU General Public License v3

# Source libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$HOME/.local/focus/lib/focus-db.sh" ]]; then
    source "$HOME/.local/focus/lib/focus-db.sh"
    source "$HOME/.local/focus/lib/focus-utils.sh"
else
    source "$SCRIPT_DIR/../lib/focus-db.sh"
    source "$SCRIPT_DIR/../lib/focus-utils.sh"
fi

# Set table names
STATE_TABLE="${STATE_TABLE:-state}"
SESSIONS_TABLE="${SESSIONS_TABLE:-sessions}"

function focus_enable() {
    # Check if refocus shell is disabled
    if is_focus_disabled; then
        update_focus_disabled 0
        echo "✅ Refocus shell enabled"
        
        send_notification "Refocus Shell Enabled" "Work tracking and nudging are now active."
    else
        echo "✅ Refocus shell is already enabled"
    fi
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    focus_enable "$@"
fi 