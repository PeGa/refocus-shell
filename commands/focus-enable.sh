#!/usr/bin/env bash
# Refocus Shell - Enable Subcommand
# Copyright (c) 2025 PeGa
# Licensed under the GNU General Public License v3

# Source required modules
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/focus-bootstrap.sh"


function focus_enable() {
    # Check if refocus shell is disabled
    if is_focus_disabled; then
        echo "✅ Re-enabling refocus shell..."
        update_focus_disabled 0
        echo "✅ Refocus shell enabled"
        echo "Focus sessions and nudging are now available"
        
        # Enable nudging by default
        update_nudging_enabled 1
        echo "✅ Nudging enabled by default"
        
        send_notification "Refocus Shell Enabled" "Focus tracking and nudging are now active."
    else
        echo "✅ Refocus shell is already enabled"
    fi
}


# Main execution
refocus_script_main focus_enable "$@"
