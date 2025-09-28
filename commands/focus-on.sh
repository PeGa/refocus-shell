#!/usr/bin/env bash
# Refocus Shell - On Subcommand
# Copyright (c) 2025 PeGa
# Licensed under the GNU General Public License v3

# Source bootstrap module
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/focus-bootstrap.sh"

function focus_on() {
    local project="$1"
    
    # Guard clauses
    if [[ -z "$project" ]]; then
        echo "❌ Project name is required" >&2
        echo "Usage: focus on <project>" >&2
        exit 2
    fi
    
    if [[ "$project" =~ [[:cntrl:]] ]] || [[ ${#project} -gt 100 ]]; then
        echo "❌ Invalid project name" >&2
        exit 2
    fi
    
    if is_focus_disabled; then
        echo "❌ Refocus shell is disabled. Run 'focus enable' to enable it." >&2
        exit 1
    fi
    
    if is_focus_active; then
        echo "❌ Already focusing on a project. Run 'focus off' first." >&2
        exit 4
    fi
    
    # Sanitize project name
    project=$(echo "$project" | tr -d '\r\n\t' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    
    local start_time
    start_time=$(date -Iseconds)

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
    
    # Write start timestamp and prompt cache
    local dir="${REFOCUS_STATE_DIR:-$HOME/.local/refocus}"
    mkdir -p "$dir"
    date +%s >"$dir/start.ts"
    write_prompt_cache "on" "$project" "0"
    
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
