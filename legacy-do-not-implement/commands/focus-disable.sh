#!/usr/bin/env bash
# Refocus Shell - Disable Subcommand
# Copyright (c) 2025 PeGa
# Licensed under the GNU General Public License v3

# Source bootstrap module
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/focus-bootstrap.sh"


function focus_disable() {
    # Stop any active session first
    if is_focus_active; then
        echo "Stopping active session..."
        # Call focus-off command directly
        local focus_script
        if [[ -f "$HOME/.local/bin/focus" ]]; then
            focus_script="$HOME/.local/bin/focus"
        elif [[ -f "/usr/local/bin/focus" ]]; then
            focus_script="/usr/local/bin/focus"
        elif [[ -f "/usr/bin/focus" ]]; then
            focus_script="/usr/bin/focus"
        elif [[ -f "$HOME/.local/refocus/focus" ]]; then
            focus_script="$HOME/.local/refocus/focus"
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
refocus_script_main focus_disable "$@"
