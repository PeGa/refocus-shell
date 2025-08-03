#!/usr/bin/env bash
# Refocus Shell - Disable Refocus Shell Subcommand
# Copyright (c) 2025 PeGa
# Licensed under the GNU General Public License v3

# Source libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$HOME/.local/work/lib/work-db.sh" ]]; then
    source "$HOME/.local/work/lib/work-db.sh"
    source "$HOME/.local/work/lib/work-utils.sh"
else
    source "$SCRIPT_DIR/../lib/work-db.sh"
    source "$SCRIPT_DIR/../lib/work-utils.sh"
fi

# Set table names
STATE_TABLE="${STATE_TABLE:-state}"
SESSIONS_TABLE="${SESSIONS_TABLE:-sessions}"

function work_disable() {
    # Stop any active session first
    if is_work_active; then
        echo "Stopping active session..."
        # Call work-off command directly
        local work_script
        if [[ -f "$HOME/.local/bin/work" ]]; then
            work_script="$HOME/.local/bin/work"
        elif [[ -f "$HOME/dev/personal/refocus-shell/work" ]]; then
    work_script="$HOME/dev/personal/refocus-shell/work"
        else
            echo "❌ Work script not found"
            exit 1
        fi
        
        "$work_script" off
    fi
    
    # Disable refocus shell
    update_work_disabled 1
    echo "🚫 Refocus shell disabled"
    echo "No work sessions or nudging will be available until you run 'work enable'"
    
    send_notification "Refocus Shell Disabled" "Work tracking and nudging are now inactive."
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    work_disable "$@"
fi 