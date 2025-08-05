#!/usr/bin/env bash
# Refocus Shell - Work Status Subcommand
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

function focus_status() {
    local state
    state=$(get_focus_state)
    IFS='|' read -r active current_project start_time <<< "$state"

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
        
        if [[ $total_minutes -gt 0 ]]; then
            echo "⏳ Focusing on: $current_project — ${current_minutes}m elapsed (Total: ${total_minutes}m)"
        else
            echo "⏳ Focusing on: $current_project — ${current_minutes}m elapsed"
        fi
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
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    focus_status "$@"
fi 