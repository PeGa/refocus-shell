#!/usr/bin/env bash
# Refocus Shell - Focus Status Subcommand
# Copyright (c) 2025 PeGa
# Licensed under the GNU General Public License v3

# Source bootstrap module
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/focus-bootstrap.sh"


function focus_status() {
    local state
    state=$(db_get_active)
    IFS='|' read -r active current_project start_time paused pause_notes pause_start_time previous_elapsed <<< "$state"

    if [[ "$active" -eq 1 ]]; then
        local now
        now=$(get_current_timestamp)
        local elapsed
        elapsed=$(calculate_duration "$start_time" "$now")
        
        # Calculate total time for this project using db_list
        local sessions
        sessions=$(db_list "all")
        local total_project_time=0
        
        while IFS='|' read -r id project start_time end_time duration_seconds notes; do
            if [[ "$project" == "$current_project" ]]; then
                ((total_project_time += duration_seconds))
            fi
        done <<< "$sessions"
        
        local total_minutes
        total_minutes=$((total_project_time / 60))
        local current_minutes
        current_minutes=$((elapsed / 60))
        
        if [[ $total_minutes -gt 0 ]]; then
            log_info "⏳ Focusing on: $current_project — ${current_minutes}m elapsed (Total: ${total_minutes}m)"
        else
            log_info "⏳ Focusing on: $current_project — ${current_minutes}m elapsed"
        fi
        
        # Refresh prompt cache with current state
        write_prompt_cache "on" "$current_project" "$current_minutes"
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
        
        log_info "⏸️  Session paused: $current_project"
        log_info "   Previous session time: ${previous_minutes}m"
        log_info "   Pause duration: ${pause_minutes}m"
        if [[ -n "$pause_notes" ]]; then
            log_info "   Current session notes: $pause_notes"
        fi
        log_info ""
        log_info "💡 Use 'focus continue' to resume this session"
        log_info "   Use 'focus off' to end the session permanently"
        
        # Refresh prompt cache with paused state
        write_prompt_cache "off" "-" "-"
    else
        log_info "✅ Not currently tracking focus."
        
        # Show last focus session information using db_list
        local sessions
        sessions=$(db_list "today")
        local last_project last_end_time last_duration
        
        while IFS='|' read -r id project start_time end_time duration_seconds notes; do
            if [[ -n "$project" ]] && [[ "$project" != "[idle]" ]]; then
                last_project="$project"
                last_end_time="$end_time"
                last_duration="$duration_seconds"
                break
            fi
        done <<< "$sessions"
        
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
            
            log_info "📊 Last session: $last_project (${duration_min}m)"
            log_info "⏰ Time since last focus: ${time_since_min}m"
        fi
        
        # Refresh prompt cache with inactive state
        write_prompt_cache "off" "-" "-"
    fi
}

# Main execution
refocus_script_main focus_status "$@" 