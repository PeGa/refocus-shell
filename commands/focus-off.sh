#!/usr/bin/env bash
# Refocus Shell - Off Subcommand
# Copyright (c) 2025 PeGa
# Licensed under the GNU General Public License v3

# Source bootstrap module
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/focus-bootstrap.sh"

function focus_off() {
    # Guard clauses
    local state
    state=$(db_get_active)
    IFS='|' read -r active current_project start_time paused pause_notes pause_start_time previous_elapsed <<< "$state"

    if [[ "$active" -ne 1 ]] && [[ "$paused" -ne 1 ]]; then
        echo "❌ No active focus session to stop" >&2
        exit 4
    fi
    
    local now
    now=$(get_current_timestamp)

    # Prompt for session notes
    echo -n "📝 What did you accomplish during this focus session? (Press Enter to skip, or type a brief description): "
    read -r session_notes
    
    # End the session using the façade
    if db_end_session "$now" "$session_notes"; then
        echo "Stopped focus on: $current_project"
        
        # Restore original prompt
        restore_original_prompt
        
        # Remove cron job
        remove_focus_cron_job
        
        send_notification "Stopped focus on: $current_project"
    else
        echo "❌ Failed to stop focus session" >&2
        exit 1
    fi
}


# Main execution
refocus_script_main focus_off "$@"
