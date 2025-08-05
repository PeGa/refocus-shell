#!/usr/bin/env bash
# Refocus Shell - Test Nudge Subcommand
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
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    focus_test_nudge "$@"
fi 