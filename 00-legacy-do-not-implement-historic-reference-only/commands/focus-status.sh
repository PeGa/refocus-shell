#!/usr/bin/env bash
# Refocus Shell - Focus Status Subcommand
# Copyright (c) 2025 PeGa
# Licensed under the GNU General Public License v3

# Source bootstrap module
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/focus-bootstrap.sh"


function focus_status() {
    local state
    state=$(get_focus_state)
    IFS='|' read -r active current_project start_time paused pause_notes pause_start_time previous_elapsed <<< "$state"

    if [[ "$active" -eq 1 ]]; then
        local now
        now=$(get_current_timestamp)
        local elapsed
        elapsed=$(calculate_duration "$start_time" "$now")
        
        # Calculate total time for this project (including previous sessions)
        local total_project_time
        total_project_time=$(get_total_project_time "$current_project")
        local total_minutes
        total_minutes=$((total_project_time / 60))
        local current_minutes
        current_minutes=$((elapsed / 60))
        
        # Get project description if available
        local project_description
        project_description=$(get_project_description "$current_project")
        
        if [[ $total_minutes -gt 0 ]]; then
            echo "⏳ Focusing on: $current_project — ${current_minutes}m elapsed (Total: ${total_minutes}m)"
        else
            echo "⏳ Focusing on: $current_project — ${current_minutes}m elapsed"
        fi
        
        # Show project description if available
        if [[ -n "$project_description" ]]; then
            echo "📋 $project_description"
        fi
    elif [[ "$paused" -eq 1 ]]; then
        # Show paused session information
        local now
        now=$(get_current_timestamp)
        local pause_ts=$(date --date="$pause_start_time" +%s 2>/dev/null)
        local current_ts=$(date --date="$now" +%s 2>/dev/null)
        local pause_duration=0
        
        if [[ -n "$pause_ts" ]] && [[ -n "$current_ts" ]]; then
            pause_duration=$((current_ts - pause_ts))
        fi
        
        local pause_minutes=$((pause_duration / 60))
        local previous_minutes=$((previous_elapsed / 60))
        
        echo "⏸️  Session paused: $current_project"
        echo "   Previous session time: ${previous_minutes}m"
        echo "   Pause duration: ${pause_minutes}m"
        if [[ -n "$pause_notes" ]]; then
            echo "   Current session notes: $pause_notes"
        fi
        echo ""
        echo "💡 Use 'focus continue' to resume this session"
        echo "   Use 'focus off' to end the session permanently"
    else
        echo "✅ Not currently tracking focus."
        
        # Show last focus session information (excluding idle sessions)
        local last_session
        last_session=$(get_last_session)
        
        if [[ -n "$last_session" ]]; then
            IFS='|' read -r last_project last_end_time last_duration <<< "$last_session"
            
            if [[ -n "$last_project" && -n "$last_end_time" ]]; then
                local now_ts
                now_ts=$(date +%s)
                local end_ts
                end_ts=$(date --date="$last_end_time" +%s)
                local time_since
                time_since=$((now_ts - end_ts))
                
                local duration_min
                duration_min=$((last_duration / 60))
                local time_since_min
                time_since_min=$((time_since / 60))
                
                echo "📊 Last session: $last_project (${duration_min}m)"
                echo "⏰ Time since last focus: ${time_since_min}m"
            fi
        fi
    fi
}

# Main execution
refocus_script_main focus_status "$@" 