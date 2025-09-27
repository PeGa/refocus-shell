#!/usr/bin/env bash
# Refocus Shell - Off Subcommand
# Copyright (c) 2025 PeGa
# Licensed under the GNU General Public License v3

# Source bootstrap module
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/focus-bootstrap.sh"

# Source centralized validation functions
# Note: Using direct validation instead of centralized functions

function focus_off() {
    local now
    now=$(get_current_timestamp)

    local state
    state=$(get_focus_state)
    IFS='|' read -r active current_project start_time paused pause_notes pause_start_time previous_elapsed <<< "$state"

    if [[ "$active" -ne 1 ]] && [[ "$paused" -ne 1 ]]; then
        handle_state_error "no_active_session"
    fi

    local duration
    local total_duration
    
    if [[ "$paused" -eq 1 ]]; then
        # Session is paused, calculate total duration including previous elapsed time
        local pause_ts=$(date --date="$pause_start_time" +%s 2>/dev/null)
        local current_ts=$(date --date="$now" +%s 2>/dev/null)
        local pause_duration=0
        
        if [[ -n "$pause_ts" ]] && [[ -n "$current_ts" ]]; then
            pause_duration=$((current_ts - pause_ts))
        fi
        
        total_duration=$((previous_elapsed + pause_duration))
        duration=$total_duration
        
        echo "⏸️  Stopping paused focus session on: $current_project"
        echo ""
        echo "   Previous session time: $((previous_elapsed / 60))m"
        echo "   Pause duration: $((pause_duration / 60))m"
        echo "   Total session time: $((total_duration / 60))m"
        echo ""
        
        if [[ -n "$pause_notes" ]]; then
            echo "📝 Session notes so far: $pause_notes"
        else
            echo "📝 Session notes so far: None"
        fi
        echo ""
    else
        # Session is active, calculate current duration
        duration=$(calculate_duration "$start_time" "$now")
        total_duration=$duration
    fi

    # Prompt for session notes
    if [[ "$paused" -eq 1 ]]; then
        echo -n "Please enter current session notes (Enter to skip): "
    else
        echo -n "📝 What did you accomplish during this focus session? (Press Enter to skip, or type a brief description): "
    fi
    read -r session_notes
    
    # Combine pause notes with final session notes if this was a paused session
    local final_notes="$session_notes"
    if [[ "$paused" -eq 1 ]] && [[ -n "$pause_notes" ]]; then
        if [[ -n "$session_notes" ]]; then
            final_notes="$pause_notes

$session_notes"
        else
            final_notes="$pause_notes"
        fi
    fi
    
    # Insert session record with combined notes
    insert_session "$current_project" "$start_time" "$now" "$total_duration" "$final_notes"

    # Update focus state - clear all pause-related fields
    update_focus_state 0 "" "" "$now" 0 "" "" 0
    
    # Remove cron job for nudging
    if remove_focus_cron_job; then
        verbose_echo "Real-time nudging disabled"
    else
        echo "Warning: Failed to remove nudging cron job" >&2
    fi
    
    if [[ -n "$final_notes" ]]; then
        echo "Stopped focus on $current_project ($((total_duration / 60)) min) with the following session notes:"
        echo ""
        
        # Display notes in chronological order with bullet formatting
        if [[ "$paused" -eq 1 ]] && [[ -n "$pause_notes" ]]; then
            # Show pause notes first (chronologically earlier)
            echo "- $pause_notes"
            if [[ -n "$session_notes" ]]; then
                # Show final session notes second (chronologically later)
                echo "- $session_notes"
            fi
        else
            # Regular session (no pause notes)
            echo "- $session_notes"
        fi
    else
        echo "Stopped focus on $current_project ($((total_duration / 60)) min) without session notes"
    fi

    # Restore original prompt
    restore_original_prompt

    send_notification "Stopped focus on: $current_project"
}


# Main execution
refocus_script_main focus_off "$@"
