#!/usr/bin/env bash
# Refocus Shell - Stop Work Session Subcommand
# Copyright (c) 2025 PeGa
# Licensed under the GNU General Public License v3

# Source libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$HOME/.local/work/lib/work-db.sh" ]]; then
    source "$HOME/.local/work/lib/work-db.sh"
    source "$HOME/.local/work/lib/work-utils.sh"
else
    source "$SCRIPT_DIR/../lib/work-db.sh"
    source "$SCRIPT_DIR/../lib/work-utils.sh"
fi

# Set table names
STATE_TABLE="${STATE_TABLE:-state}"
SESSIONS_TABLE="${SESSIONS_TABLE:-sessions}"

function work_off() {
    local now
    now=$(get_current_timestamp)

    local state
    state=$(get_work_state)
    IFS='|' read -r active current_project start_time <<< "$state"

    if [[ "$active" -ne 1 ]]; then
        echo "No active work session."
        exit 1
    fi

    local duration
    duration=$(calculate_duration "$start_time" "$now")

    # Insert session record
    insert_session "$current_project" "$start_time" "$now" "$duration"

    # Update work state
    update_work_state 0 "" "" "$now"
    echo "Stopped work on: $current_project (Duration: $((duration / 60)) min)"

    # Restore original prompt
    restore_original_prompt

    send_notification "Stopped work on: $current_project"
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    work_off "$@"
fi 