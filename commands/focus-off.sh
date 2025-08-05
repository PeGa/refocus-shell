#!/usr/bin/env bash
# Refocus Shell - Stop Focus Session Subcommand
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

    # Insert session record
    insert_session "$current_project" "$start_time" "$now" "$duration"

    # Update focus state
    update_focus_state 0 "" "" "$now"
    echo "Stopped focus on: $current_project (Duration: $((duration / 60)) min)"

    # Restore original prompt
    restore_original_prompt

    send_notification "Stopped focus on: $current_project"
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    focus_off "$@"
fi 