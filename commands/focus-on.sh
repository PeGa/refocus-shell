#!/usr/bin/env bash
# Refocus Shell - On Subcommand
# Copyright (c) 2025 PeGa
# Licensed under the GNU General Public License v3

# Source bootstrap module
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/focus-bootstrap.sh"

# Source centralized validation functions
source "$SCRIPT_DIR/../lib/focus-validation-centralized.sh"

function focus_on() {
    local project="$1"
    local start_time
    start_time=$(date -Iseconds)
    
    # Validate project name if provided
    if [[ -n "$project" ]]; then
        project=$(validate_project_name_standardized "$project" "Project")
        if [[ $? -ne 0 ]]; then
            exit 2  # Invalid arguments
        fi
    else
        handle_argument_error "missing_project" \
            "focus on <project>" \
            "focus on coding
  focus on 'my-project'
  focus on meeting" \
            "Project name is required to start a focus session"
    fi

    # Check if refocus shell is disabled
    if is_focus_disabled; then
        handle_state_error "disabled"
    fi

    # Check if already active
    local state
    state=$(get_focus_state)
    if [[ -n "$state" ]]; then
        IFS='|' read -r active current_project existing_start_time paused pause_notes pause_start_time previous_elapsed <<< "$state"
        if [[ "$active" -eq 1 ]]; then
            handle_state_error "already_active"
        fi
        
        # Check if there's a paused session
        if [[ "$paused" -eq 1 ]]; then
            handle_state_error "session_paused" "$current_project"
        fi
    fi

    # Store idle session from last focus_off to now (if any)
    local last_focus_off_time
    last_focus_off_time=$(get_last_focus_off_time)
    
    if [[ -n "$last_focus_off_time" ]] && [[ "$last_focus_off_time" != "NULL" ]]; then
        local idle_start_ts
        idle_start_ts=$(date --date="$last_focus_off_time" +%s)
        local idle_end_ts
        idle_end_ts=$(date +%s)
        local idle_duration
        idle_duration=$((idle_end_ts - idle_start_ts))
        
        # Only store idle session if duration is significant (> 1 minute)
        if [[ $idle_duration -gt 60 ]]; then
            insert_session "[idle]" "$last_focus_off_time" "$start_time" "$idle_duration"
            verbose_echo "Stored idle session: ${idle_duration}s"
        fi
    fi

    # If no project specified, try to use last project
    if [[ -z "$project" ]]; then
        local last_project
        last_project=$(get_last_project)
        
        if [[ -n "$last_project" ]]; then
            # Calculate total time for the last project to show in prompt
            local total_project_time
            total_project_time=$(get_total_project_time "$last_project")
            local total_minutes
            total_minutes=$((total_project_time / 60))
            
            if [[ $total_minutes -gt 0 ]]; then
                echo "Last project was: $last_project (Total: ${total_minutes}m)"
            else
                echo "Last project was: $last_project"
            fi
            echo "Continue? (Y/n)"
            read -r response
            
            if [[ "$response" =~ ^[Nn]$ ]]; then
                            echo "Focus session aborted — no project specified."
            echo "Run 'focus on \"project\"' to start a focus session."
                exit 2  # Invalid arguments - no project specified
            fi
            
            project="$last_project"
        else
            echo "No previous project found."
            echo "Run 'focus on \"project\"' to start a focus session."
            exit 2  # Invalid arguments - no project specified
        fi
    fi

    # Calculate total time for this project (including previous sessions)
    local total_project_time
    total_project_time=$(get_total_project_time "$project")
    local total_minutes
    total_minutes=$((total_project_time / 60))
    
    # Update focus state
    update_focus_state 1 "$project" "$start_time" "$last_focus_off_time"
    
    # Install cron job for real-time nudging
    if install_focus_cron_job "$project" "$start_time"; then
        verbose_echo "Real-time nudging enabled"
    else
        echo "Warning: Failed to install nudging cron job" >&2
    fi
    
    if [[ $total_minutes -gt 0 ]]; then
            echo "Started focus on: $project (Total: ${total_minutes}m)"
        else
            echo "Started focus on: $project"
        fi

    # Set focus prompt
    set_focus_prompt "$project"

    send_notification "Started focus on: $project"
}


# Main execution
refocus_script_main focus_on "$@"
