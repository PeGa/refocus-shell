#!/usr/bin/env bash
# Refocus Shell - On Subcommand
# Copyright (c) 2025 PeGa
# Licensed under the GNU General Public License v3

# Source required modules
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/focus-bootstrap.sh"
source "$SCRIPT_DIR/../lib/focus-utils.sh"
source "$SCRIPT_DIR/../lib/focus-db.sh"
source "$SCRIPT_DIR/../lib/focus-output.sh"

function focus_on() {
    local project="$1"
    
    # Guard clauses
    if [[ -z "$project" ]]; then
        usage "Project name is required. Usage: focus on <project>"
    fi
    
    if [[ "$project" =~ [[:cntrl:]] ]] || [[ ${#project} -gt 100 ]]; then
        usage "Invalid project name"
    fi
    
    if is_focus_disabled; then
        die "Refocus shell is disabled. Run 'focus enable' to enable it."
    fi
    
    if is_focus_active; then
        conflict "Already focusing on a project. Run 'focus off' first."
    fi
    
    # Sanitize project name
    project=$(echo "$project" | tr -d '\r\n\t' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    
    local start_time
    start_time=$(date -Iseconds)

    # Store idle session from last focus_off to now (if any)
    local state
    state=$(db_get_active)
    if [[ -n "$state" ]]; then
        IFS='|' read -r active current_project existing_start_time paused pause_notes pause_start_time previous_elapsed <<< "$state"
        if [[ "$active" -eq 0 ]] && [[ -n "$current_project" ]]; then
            # There's a last focus off time stored, create idle session
            local idle_duration
            idle_duration=$(calculate_duration "$current_project" "$start_time")
            if [[ $idle_duration -gt 60 ]]; then
                db_start_session "[idle]" "" "$current_project"
                db_end_session "$start_time" ""
                verbose_echo "Stored idle session: ${idle_duration}s"
            fi
        fi
    fi

    # Start new focus session
    if db_start_session "$project" "" "$start_time"; then
        # Update prompt
        set_focus_prompt "$project"
        
        # Install cron job for nudging
        _install_focus_cron_job_public "$SCRIPT_DIR/../focus-nudge" "$(get_cfg NUDGE_INTERVAL "10")"
        
        log_info "Started focus on: $project"
    else
        die "Failed to start focus session"
    fi
}


# Main execution
refocus_script_main focus_on "$@"
