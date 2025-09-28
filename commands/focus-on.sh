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
        install_focus_cron_job "$SCRIPT_DIR/../focus-nudge" "$(get_cfg NUDGE_INTERVAL "10")"
        
        echo "Started focus on: $project"
    else
        echo "❌ Failed to start focus session" >&2
        exit 1
    fi
}


# Main execution
refocus_script_main focus_on "$@"
