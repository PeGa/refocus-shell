#!/usr/bin/env bash
# Refocus Shell - Continue Subcommand
# Copyright (c) 2025 PeGa
# Licensed under the GNU General Public License v3

# Source bootstrap module
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/focus-bootstrap.sh"


function focus_continue() {
    # Check if refocus shell is disabled
    if is_focus_disabled; then
        echo "❌ Refocus shell is disabled. Run 'focus enable' first."
        return 1
    fi
    
    # Check if there's a paused session
    if ! is_session_paused; then
        echo "❌ No paused session to continue."
        echo "   Pause a session first with 'focus pause'"
        return 1
    fi
    
    # Get paused session info
    local paused_info
    paused_info=$(get_paused_session_info)
    if [[ -z "$paused_info" ]]; then
        echo "❌ Could not retrieve paused session information."
        return 1
    fi
    
    IFS='|' read -r project pause_notes pause_start_time previous_elapsed <<< "$paused_info"
    
    if [[ -z "$project" ]]; then
        echo "❌ No paused session found."
        return 1
    fi
    
    # Calculate pause duration
    local now=$(date --iso-8601=seconds)
    local pause_ts=$(date --date="$pause_start_time" +%s 2>/dev/null)
    local current_ts=$(date --date="$now" +%s 2>/dev/null)
    local pause_duration_seconds=0
    
    if [[ -n "$pause_ts" ]] && [[ -n "$current_ts" ]]; then
        pause_duration_seconds=$((current_ts - pause_ts))
    fi
    
    local pause_duration_minutes=$((pause_duration_seconds / 60))
    local previous_elapsed_minutes=$((previous_elapsed / 60))
    
    # Display session information
    echo "▶️  Resuming paused focus session on: $project"
    echo "   Previous session time: ${previous_elapsed_minutes}m"
    echo "   Pause duration: ${pause_duration_minutes}m"
    if [[ -n "$pause_notes" ]]; then
        echo "   Current session notes: $pause_notes"
    fi
    echo ""
    
    # Ask whether to include previous elapsed time
    echo -n "⏱️  Include previous ${previous_elapsed_minutes}m in resumed session? (y/N): "
    read -r include_previous
    
    local include_previous_elapsed=0
    if [[ "$include_previous" =~ ^[Yy]$ ]]; then
        include_previous_elapsed=1
        echo "✅ Will continue counting from ${previous_elapsed_minutes}m elapsed"
    else
        echo "🔄 Will start fresh from 0m (previous time discarded)"
    fi
    
    echo ""
    
    # Resume the session
    local resume_result
    resume_result=$(resume_focus_session "$include_previous_elapsed" "$now")
    
    if [[ $? -eq 0 ]]; then
        IFS='|' read -r resumed_project new_start_time include_prev <<< "$resume_result"
        
        echo "✅ Resumed focus on: $resumed_project"
        if [[ "$include_prev" -eq 1 ]]; then
            echo "   Continuing from: ${previous_elapsed_minutes}m elapsed"
        else
            echo "   Starting fresh from: 0m"
        fi
        
        # Install cron job for real-time nudging
        if install_focus_cron_job "$resumed_project" "$new_start_time"; then
            verbose_echo "Real-time nudging resumed"
        else
            echo "Warning: Failed to install nudging cron job" >&2
        fi
    else
        echo "❌ Failed to resume focus session."
        return 1
    fi
}


# Main execution
refocus_script_main focus_continue "$@"
