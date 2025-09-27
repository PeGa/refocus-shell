#!/usr/bin/env bash
# Refocus Shell - Pause Subcommand
# Copyright (c) 2025 PeGa
# Licensed under the GNU General Public License v3

# Source bootstrap module
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/focus-bootstrap.sh"

function focus_pause() {
    # Check if refocus shell is disabled
    if is_focus_disabled; then
        echo "❌ Refocus shell is disabled. Run 'focus enable' first."
        return 1
    fi
    
    # Check if there's an active focus session
    if ! is_focus_active; then
        echo "❌ No active focus session to pause."
        echo "   Start a session first with 'focus on <project>'"
        return 1
    fi
    
    # Get current session info
    local current_state
    current_state=$(get_focus_state)
    if [[ -z "$current_state" ]]; then
        echo "❌ Could not retrieve current session information."
        return 1
    fi
    
    IFS='|' read -r active project start_time paused pause_notes pause_start_time previous_elapsed <<< "$current_state"
    
    if [[ "$active" -eq 0 ]] || [[ -z "$project" ]]; then
        echo "❌ No active focus session found."
        return 1
    fi
    
    # Calculate elapsed time
    local now=$(date --iso-8601=seconds)
    local start_ts=$(date --date="$start_time" +%s 2>/dev/null)
    local current_ts=$(date --date="$now" +%s 2>/dev/null)
    local elapsed_seconds=0
    
    if [[ -n "$start_ts" ]] && [[ -n "$current_ts" ]]; then
        elapsed_seconds=$((current_ts - start_ts))
    fi
    
    local elapsed_minutes=$((elapsed_seconds / 60))
    
    # Prompt for pause notes
    echo "⏸️  Pausing focus session on: $project"
    echo "   Session duration so far: ${elapsed_minutes}m"
    echo ""
    echo -n "Focus paused. Please add notes for future recalling, or hit Enter to skip: "
    read -r pause_notes
    
    # Pause the session
    local pause_result
    pause_result=$(pause_focus_session "$pause_notes" "$now")
    
    if [[ $? -eq 0 ]]; then
        IFS='|' read -r paused_project elapsed_so_far <<< "$pause_result"
        
        echo ""
        if [[ -n "$pause_notes" ]]; then
            echo "✅ Paused focus on: $paused_project (${elapsed_minutes}m elapsed)"
            echo "   Current session notes: $pause_notes"
        else
            echo "✅ Paused focus on: $paused_project (${elapsed_minutes}m elapsed)"
            echo "   No session notes provided"
        fi
        echo ""
        echo "💡 Use 'focus continue' to resume this session"
        echo "   Use 'focus off' to end the session permanently"
        
        # Remove cron job for nudging during pause
        if remove_focus_cron_job; then
            verbose_echo "Real-time nudging paused"
        else
            echo "Warning: Failed to remove nudging cron job" >&2
        fi
    else
        echo "❌ Failed to pause focus session."
        return 1
    fi
}


# Main execution
refocus_script_main focus_pause "$@"
