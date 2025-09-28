#!/usr/bin/env bash
# Refocus Shell - Off Subcommand
# Copyright (c) 2025 PeGa
# Licensed under the GNU General Public License v3

# Source required modules
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/focus-bootstrap.sh"
source "$SCRIPT_DIR/../lib/focus-utils.sh"
source "$SCRIPT_DIR/../lib/focus-db.sh"

function focus_off() {
    # Guard clauses
    local state
    state=$(db_get_active)
    IFS='|' read -r active current_project start_time paused pause_notes pause_start_time previous_elapsed <<< "$state"

    if [[ "$active" -ne 1 ]] && [[ "$paused" -ne 1 ]]; then
        not_found "No active focus session to stop"
    fi
    
    local now
    now=$(get_current_timestamp)

    # Prompt for session notes
    echo -n "📝 What did you accomplish during this focus session? (Press Enter to skip, or type a brief description): "
    read -r session_notes
    
    # End the session using the façade
    if db_end_session "$now" "$session_notes"; then
        log_info "Stopped focus on: $current_project"
        
        # Restore original prompt
        restore_original_prompt
        
        # Remove cron job
        remove_focus_cron_job
        
        send_notification "Stopped focus on: $current_project"
    else
        die "Failed to stop focus session"
    fi
}


# Main execution
refocus_script_main focus_off "$@"
