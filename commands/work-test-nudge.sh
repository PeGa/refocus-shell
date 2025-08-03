#!/usr/bin/env bash
# Refocus Shell - Test Nudge Subcommand
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

function work_test_nudge() {
    echo "🧪 Testing refocus shell notifications..."
    
    # Test basic notification
    send_notification "Refocus Shell Test" "This is a test notification from the refocus shell."
    
    if [[ $? -eq 0 ]]; then
        echo "✅ Notification test successful"
    else
        echo "❌ Notification test failed - notify-send may not be available"
    fi
    
    # Test work prompt
    echo "Testing work prompt functionality..."
    local test_project="test-project"
    local work_prompt
    work_prompt=$(create_work_prompt "$test_project")
    echo "Work prompt: $work_prompt"
    
    # Test default prompt
    local default_prompt
    default_prompt=$(create_default_prompt)
    echo "Default prompt: $default_prompt"
    
    echo "✅ All tests completed"
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    work_test_nudge "$@"
fi 