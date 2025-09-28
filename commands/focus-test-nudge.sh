#!/usr/bin/env bash
# Refocus Shell - Test Nudge Subcommand
# Copyright (c) 2025 PeGa
# Licensed under the GNU General Public License v3

# Source bootstrap module
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/focus-bootstrap.sh"


function focus_test_nudge() {
    echo "🧪 Testing refocus shell notifications..."
    
    # Test basic notification
    send_notification "Refocus Shell Test" "This is a test notification from the refocus shell."
    
    if [[ $? -eq 0 ]]; then
        echo "✅ Notification test successful"
    else
        echo "❌ Notification test failed - notify-send may not be available"
    fi
    
    # Test focus prompt
    echo "Testing focus prompt functionality..."
    local test_project="test-project"
    local focus_prompt
    focus_prompt=$(create_focus_prompt "$test_project")
    echo "Focus prompt: $focus_prompt"
    
    # Test default prompt
    local default_prompt
    default_prompt=$(create_default_prompt)
    echo "Default prompt: $default_prompt"
    
    echo "✅ All tests completed"
}


# Main execution
refocus_script_main focus_test_nudge "$@"
