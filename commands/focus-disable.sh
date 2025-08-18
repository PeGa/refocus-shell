#!/usr/bin/env bash
# Refocus Shell - Disable Refocus Shell Subcommand
# Copyright (c) 2025 PeGa
# Licensed under the GNU General Public License v3

# Source libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$HOME/.local/refocus/lib/focus-db.sh" ]]; then
    source "$HOME/.local/refocus/lib/focus-db.sh"
    source "$HOME/.local/refocus/lib/focus-utils.sh"
else
    source "$SCRIPT_DIR/../lib/focus-db.sh"
    source "$SCRIPT_DIR/../lib/focus-utils.sh"
fi

# Set table names
STATE_TABLE="${STATE_TABLE:-state}"
SESSIONS_TABLE="${SESSIONS_TABLE:-sessions}"

# Ensure database is migrated to include projects table
migrate_database

function focus_disable() {
    # Stop any active session first
    if is_focus_active; then
        echo "Stopping active session..."
        # Call focus-off command directly
        local focus_script
        if [[ -f "$HOME/.local/bin/focus" ]]; then
            focus_script="$HOME/.local/bin/focus"
        elif [[ -f "$HOME/dev/personal/refocus-shell/focus" ]]; then
            focus_script="$HOME/dev/personal/refocus-shell/focus"
        else
            echo "❌ Focus script not found"
            exit 1
        fi
        
        "$focus_script" off
    fi
    
    # Disable refocus shell
    update_focus_disabled 1
    echo "🚫 Refocus shell disabled"
    echo "No focus sessions or nudging will be available until you run 'focus enable'"
    
    send_notification "Refocus Shell Disabled" "Focus tracking and nudging are now inactive."
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    focus_disable "$@"
fi 