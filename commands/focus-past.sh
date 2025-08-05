#!/usr/bin/env bash
# Refocus Shell - Manage Past Sessions Subcommand
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

function focus_past_add() {
    local project="$1"
    local start_time="$2"
    local end_time="$3"
    
    if [[ -z "$project" ]]; then
        echo "❌ Project name is required."
        echo "Usage: focus past add <project> <start_time> <end_time>"
        echo ""
        echo "Time formats supported:"
        echo "  - YYYY/MM/DD-HH:MM (recommended: 2025/07/30-14:30)"
        echo "  - HH:MM (today's date)"
        echo "  - 'YYYY-MM-DD HH:MM' (quoted datetime)"
        echo "  - 'YYYY-MM-DDTHH:MM' (ISO format)"
        echo "  - Full ISO format (YYYY-MM-DDTHH:MM:SS±HH:MM)"
        echo "  - Relative dates ('yesterday 14:30', '2 hours ago', etc.)"
        echo ""
        echo "Examples:"
        echo "  focus past add meeting 2025/07/30-14:15 2025/07/30-15:30  # Specific date"
        echo "  focus past add meeting 14:15 15:30                          # Today's date"
        echo "  focus past add coding 'yesterday 09:00' 'yesterday 17:00'   # Relative dates"
        echo ""
        echo "💡 Tip: Use YYYY/MM/DD-HH:MM format for easy, quote-free dates!"
        exit 1
    fi
    
    if [[ -z "$start_time" ]]; then
        echo "❌ Start time is required."
        echo "Usage: focus past add <project> <start_time> <end_time>"
        echo ""
        echo "💡 Tip: Use YYYY/MM/DD-HH:MM format for easy dates!"
        echo "   Example: focus past add meeting 2025/07/30-14:15 2025/07/30-15:30"
        exit 1
    fi
    
    if [[ -z "$end_time" ]]; then
        echo "❌ End time is required."
        echo "Usage: focus past add <project> <start_time> <end_time>"
        echo ""
        echo "💡 Tip: Use YYYY/MM/DD-HH:MM format for easy dates!"
        echo "   Example: focus past add meeting 2025/07/30-14:15 2025/07/30-15:30"
        exit 1
    fi
    
    # Sanitize and validate project name
    project=$(sanitize_project_name "$project")
    if ! validate_project_name "$project"; then
        exit 1
    fi
    
    # Convert timestamps to ISO format
    local converted_start_time
    converted_start_time=$(validate_timestamp "$start_time" "Start time")
    if [[ $? -ne 0 ]]; then
        echo "$converted_start_time"
        exit 1
    fi
    
    local converted_end_time
    converted_end_time=$(validate_timestamp "$end_time" "End time")
    if [[ $? -ne 0 ]]; then
        echo "$converted_end_time"
        exit 1
    fi
    
    # Validate time range
    if ! validate_time_range "$converted_start_time" "$converted_end_time"; then
        exit 1
    fi
    
    # Calculate duration
    local duration
    duration=$(calculate_duration "$converted_start_time" "$converted_end_time")
    
    # Insert session
    insert_session "$project" "$converted_start_time" "$converted_end_time" "$duration"
    
    echo "✅ Added past session: $project"
    echo "   Start: $start_time → $converted_start_time"
    echo "   End: $end_time → $converted_end_time"
    echo "   Duration: $((duration / 60)) minutes"
}

function focus_past_modify() {
    local session_id="$1"
    local project="$2"
    local start_time="$3"
    local end_time="$4"
    
    if [[ -z "$session_id" ]]; then
        echo "❌ Session ID is required."
        echo "Usage: focus past modify <session_id> [project] [start_time] [end_time]"
        echo "Use 'focus past list' to see session IDs"
        echo ""
        echo "Examples:"
        echo "  focus past modify 1 'new-project'"
        echo "  focus past modify 1 'new-project' '2025/07/30-14:00' '2025/07/30-16:00'"
        echo "  focus past modify 1 '' '14:30' '15:30'  # Change only times"
        exit 1
    fi
    
    # Get current session data
    local current_data
    current_data=$(sqlite3 "$DB" "SELECT project, start_time, end_time, duration_seconds FROM $SESSIONS_TABLE WHERE rowid = $session_id;" 2>/dev/null)
    
    if [[ -z "$current_data" ]]; then
        echo "❌ Session not found with ID: $session_id"
        exit 1
    fi
    
    IFS='|' read -r current_project current_start current_end current_duration <<< "$current_data"
    
    # Use current values if not provided
    project="${project:-$current_project}"
    start_time="${start_time:-$current_start}"
    end_time="${end_time:-$current_end}"
    
    # Sanitize and validate project name if provided
    if [[ "$project" != "$current_project" ]]; then
        project=$(sanitize_project_name "$project")
        if ! validate_project_name "$project"; then
            exit 1
        fi
    fi
    
    # Convert timestamps to ISO format if provided
    if [[ "$start_time" != "$current_start" ]]; then
        local converted_start_time
        converted_start_time=$(validate_timestamp "$start_time" "Start time")
        if [[ $? -ne 0 ]]; then
            echo "$converted_start_time"
            exit 1
        fi
        start_time="$converted_start_time"
    fi
    
    if [[ "$end_time" != "$current_end" ]]; then
        local converted_end_time
        converted_end_time=$(validate_timestamp "$end_time" "End time")
        if [[ $? -ne 0 ]]; then
            echo "$converted_end_time"
            exit 1
        fi
        end_time="$converted_end_time"
    fi
    
    # Validate time range if times were changed
    if [[ "$start_time" != "$current_start" ]] || [[ "$end_time" != "$current_end" ]]; then
        if ! validate_time_range "$start_time" "$end_time"; then
            exit 1
        fi
    fi
    
    # Calculate new duration
    local duration
    duration=$(calculate_duration "$start_time" "$end_time")
    
    # Update session
    sqlite3 "$DB" "UPDATE $SESSIONS_TABLE SET project = '$(sql_escape "$project")', start_time = '$start_time', end_time = '$end_time', duration_seconds = $duration WHERE rowid = $session_id;"
    
    echo "✅ Modified session $session_id: $project"
    echo "   Start: $start_time"
    echo "   End: $end_time"
    echo "   Duration: $((duration / 60)) minutes"
}

function focus_past_delete() {
    local session_id="$1"
    
    if [[ -z "$session_id" ]]; then
        echo "❌ Session ID is required."
        echo "Usage: focus past delete <session_id>"
        echo "Use 'focus past list' to see session IDs"
        exit 1
    fi
    
    # Validate session ID exists
    if ! validate_session_id "$session_id"; then
        exit 1
    fi
    
    # Get session info for confirmation
    local session_info
    session_info=$(sqlite3 "$DB" "SELECT project, start_time, end_time, duration_seconds FROM $SESSIONS_TABLE WHERE rowid = $session_id;" 2>/dev/null)
    
    if [[ -z "$session_info" ]]; then
        echo "❌ Session not found with ID: $session_id"
        exit 1
    fi
    
    IFS='|' read -r project start_time end_time duration <<< "$session_info"
    
    echo "🗑️  Delete session $session_id: $project"
    echo "   Start: $start_time"
    echo "   End: $end_time"
    echo "   Duration: $((duration / 60)) minutes"
    echo "Are you sure? (y/N)"
    read -r response
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        sqlite3 "$DB" "DELETE FROM $SESSIONS_TABLE WHERE rowid = $session_id;"
        echo "✅ Session deleted"
    else
        echo "Deletion cancelled."
    fi
}

function focus_past_list() {
    local limit="${1:-20}"
    
    if ! validate_numeric_input "$limit" "Limit"; then
        exit 1
    fi
    
    echo "📋 Recent focus sessions (last $limit):"
    echo
    
    local sessions
    sessions=$(sqlite3 "$DB" "SELECT rowid, project, start_time, end_time, duration_seconds FROM $SESSIONS_TABLE WHERE project != '[idle]' ORDER BY end_time DESC LIMIT $limit;" 2>/dev/null)
    
    if [[ -z "$sessions" ]]; then
        echo "No focus sessions found."
        return 0
    fi
    
    printf "%-4s %-20s %-19s %-19s %-8s\n" "ID" "Project" "Start" "End" "Duration"
    printf "%-4s %-20s %-19s %-19s %-8s\n" "----" "--------------------" "-------------------" "-------------------" "--------"
    
    while IFS='|' read -r id project start_time end_time duration; do
        local start_date
        start_date=$(date --date="$start_time" +"%Y-%m-%d %H:%M")
        local end_date
        end_date=$(date --date="$end_time" +"%Y-%m-%d %H:%M")
        local duration_min
        duration_min=$((duration / 60))
        
        printf "%-4s %-20s %-19s %-19s %-8s\n" "$id" "$(truncate_project_name "$project" 18)" "$start_date" "$end_date" "${duration_min}m"
    done <<< "$sessions"
}

function focus_past() {
    local action="$1"
    shift
    
    case "$action" in
        "add")
            focus_past_add "$@"
            ;;
        "modify"|"edit")
            focus_past_modify "$@"
            ;;
        "delete"|"del"|"rm")
            focus_past_delete "$@"
            ;;
        "list"|"ls")
            focus_past_list "$@"
            ;;
        *)
            echo "❌ Unknown action: $action"
            echo "Available actions:"
            echo "  add     - Add a past focus session"
            echo "  modify  - Modify an existing session"
            echo "  delete  - Delete a session"
            echo "  list    - List recent sessions"
            echo
            echo "Examples:"
            echo "  focus past add 'meeting' '2025-01-15T10:00:00' '2025-01-15T11:30:00'"
            echo "  focus past modify 1 'new-project'"
            echo "  focus past delete 1"
            echo "  focus past list 10"
            exit 1
            ;;
    esac
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    focus_past "$@"
fi 