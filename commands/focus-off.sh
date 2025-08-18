#!/usr/bin/env bash
# Refocus Shell - Stop Focus Session Subcommand
# Copyright (c) 2025 PeGa
# Licensed under the GNU General Public License v3

# Source libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$HOME/.local/refocus/lib/focus-db.sh" ]]; then
    source "$HOME/.local/refocus/lib/focus-db.sh"
    source "$HOME/.local/refocus/lib/focus-utils.sh"
else
    source "$SCRIPT_DIR/../lib/focus-db.sh"
    source "$SCRIPT_DIR/../lib/focus-utils.sh"
fi

# Set table names
STATE_TABLE="${STATE_TABLE:-state}"
SESSIONS_TABLE="${SESSIONS_TABLE:-sessions}"

function focus_off() {
    local now
    now=$(get_current_timestamp)

    local state
    state=$(get_focus_state)
    IFS='|' read -r active current_project start_time <<< "$state"

    if [[ "$active" -ne 1 ]]; then
        echo "No active focus session."
        exit 1
    fi

    local duration
    duration=$(calculate_duration "$start_time" "$now")

    # Prompt for session notes
    echo ""
    echo "📝 What did you accomplish during this focus session?"
    echo "   (Press Enter to skip, or type a brief description)"
    echo -n "   Notes: "
    read -r session_notes

    # Insert session record with notes
    insert_session "$current_project" "$start_time" "$now" "$duration" "$session_notes"

    # Update focus state
    update_focus_state 0 "" "" "$now"
    echo ""
    echo "✅ Stopped focus on: $current_project (Duration: $((duration / 60)) min)"
    
    if [[ -n "$session_notes" ]]; then
        echo "📝 Session notes: $session_notes"
    fi

    # Restore original prompt
    restore_original_prompt

    send_notification "Stopped focus on: $current_project"
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    focus_off "$@"
fi 