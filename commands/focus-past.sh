#!/usr/bin/env bash
# Refocus Shell - Past Subcommand
# Copyright (c) 2025 PeGa
# Licensed under the GNU General Public License v3

# Source bootstrap module
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/focus-bootstrap.sh"

# Note: Using direct SQL queries and validation instead of centralized functions
# to maintain compatibility with installed versions

function focus_past_add() {
    local project=""
    local start_time=""
    local end_time=""
    local duration=""
    local session_date=""
    local notes=""
    local duration_mode=false
    
    # Parse all arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --duration)
                duration="$2"
                duration_mode=true
                shift 2
                ;;
            --date)
                session_date="$2"
                shift 2
                ;;
            --notes)
                notes="$2"
                shift 2
                ;;
            *)
                if [[ -z "$project" ]]; then
                    project="$1"
                elif [[ -z "$start_time" ]] && [[ "$duration_mode" == "false" ]]; then
                    start_time="$1"
                elif [[ -z "$end_time" ]] && [[ "$duration_mode" == "false" ]]; then
                    end_time="$1"
                fi
                shift
                ;;
        esac
    done
    
    if [[ -z "$project" ]]; then
        handle_argument_error "missing_project" \
            "focus past add <project> <start_time> <end_time>" \
            "focus past add meeting 2025/07/30-14:15 2025/07/30-15:30  # Specific date
  focus past add meeting 14:15 15:30                          # Today's date
  focus past add coding 'yesterday 09:00' 'yesterday 17:00'   # Relative dates
  focus past add coding '7 hours ago' 'now'                   # Relative times
  focus past add coding --duration 2h30m --date 2025/07/30    # Duration-only
  focus past add coding --duration 90m --date yesterday --notes 'retrospective'" \
            "Time formats: YYYY/MM/DD-HH:MM, HH:MM, 'YYYY-MM-DD HH:MM', etc.
Duration formats: 1h30m, 2h, 45m, 90m, 1.5h, 0.5h
Note: Times should be absolute timestamps, not durations."
    fi
    
    # Validate project name using centralized function
    project=$(validate_project_name_standardized "$project" "Project")
    if [[ $? -ne 0 ]]; then
        exit 2  # Invalid arguments
    fi
    
    if [[ "$duration_mode" == "true" ]]; then
        # Duration-only mode
        if [[ -z "$duration" ]]; then
            handle_argument_error "missing_duration" \
                "focus past add <project> --duration <time> --date <date> [--notes <notes>]" \
                "focus past add coding --duration 2h30m --date 2025/07/30
  focus past add coding --duration 90m --date yesterday --notes 'retrospective'" \
                "Duration formats: 1h30m, 2h, 45m, 90m, 1.5h, 0.5h"
        fi
        
        if [[ -z "$session_date" ]]; then
            handle_argument_error "missing_date" \
                "focus past add <project> --duration <time> --date <date> [--notes <notes>]" \
                "focus past add coding --duration 2h30m --date 2025/07/30
  focus past add coding --duration 90m --date yesterday --notes 'retrospective'" \
                "Date formats: 2025/07/30, yesterday, 2 days ago, etc."
        fi
        
        # Parse duration using centralized function
        local duration_seconds
        duration_seconds=$(validate_duration_standardized "$duration" "Duration")
        if [[ $? -ne 0 ]]; then
            exit 2  # Invalid arguments
        fi
        
        # Validate and convert session date using centralized function
        local converted_date
        converted_date=$(validate_timestamp_standardized "$session_date" "Session date")
        if [[ $? -ne 0 ]]; then
            echo "$converted_date"
            exit 2  # Invalid arguments
        fi
        
        # Extract just the date part (YYYY-MM-DD)
        local date_only
        date_only=$(date --date="$converted_date" +"%Y-%m-%d" 2>/dev/null)
        
        # Prompt for session notes if not provided via --notes
        if [[ -z "$notes" ]]; then
            echo -n "📝 What did you accomplish during this focus session? (Press Enter to skip, or type a brief description): "
            read -r session_notes
            notes="$session_notes"
        fi
        
        # Insert duration-only session
        insert_duration_only_session "$project" "$duration_seconds" "$date_only" "$notes"
        
        format_success_message "Added duration-only session: $project" \
            "Date: $session_date → $date_only
Duration: $duration → $(format_duration "$duration_seconds")
Notes: ${notes:-'none'}"
        
    else
        # Traditional mode (start_time and end_time)
        if [[ -z "$start_time" ]]; then
            handle_argument_error "missing_start_time" \
                "focus past add <project> <start_time> <end_time>" \
                "focus past add meeting 2025/07/30-14:15 2025/07/30-15:30  # Specific date
  focus past add meeting 14:15 15:30                          # Today's date
  focus past add coding 'yesterday 09:00' 'yesterday 17:00'   # Relative dates
  focus past add coding '7 hours ago' 'now'                   # Relative times" \
                "Tip: Use YYYY/MM/DD-HH:MM format for easy dates!
Note: Times should be absolute timestamps, not durations."
        fi
        
        if [[ -z "$end_time" ]]; then
            handle_argument_error "missing_end_time" \
                "focus past add <project> <start_time> <end_time>" \
                "focus past add meeting 2025/07/30-14:15 2025/07/30-15:30  # Specific date
  focus past add meeting 14:15 15:30                          # Today's date
  focus past add coding 'yesterday 09:00' 'yesterday 17:00'   # Relative dates
  focus past add coding '7 hours ago' 'now'                   # Relative times" \
                "Tip: Use YYYY/MM/DD-HH:MM format for easy dates!
Note: Times should be absolute timestamps, not durations."
        fi
        
        # Convert timestamps to ISO format using centralized functions
        local converted_start_time
        converted_start_time=$(validate_timestamp_standardized "$start_time" "Start time")
        if [[ $? -ne 0 ]]; then
            echo "$converted_start_time"
            exit 2  # Invalid arguments
        fi
        
        local converted_end_time
        converted_end_time=$(validate_timestamp_standardized "$end_time" "End time")
        if [[ $? -ne 0 ]]; then
            echo "$converted_end_time"
            exit 2  # Invalid arguments
        fi
        
        # Validate time range
        if ! validate_time_range "$converted_start_time" "$converted_end_time"; then
            exit 2  # Invalid arguments
        fi
        
        # Calculate duration
        local duration
        duration=$(calculate_duration "$converted_start_time" "$converted_end_time")
        
        # Prompt for session notes if not provided via --notes
        if [[ -z "$notes" ]]; then
            echo -n "📝 What did you accomplish during this focus session? (Press Enter to skip, or type a brief description): "
            read -r session_notes
            notes="$session_notes"
        fi
        
        # Insert session with notes
        insert_session "$project" "$converted_start_time" "$converted_end_time" "$duration" "$notes"
        
        local duration_seconds
        duration_seconds=$(calculate_duration "$converted_start_time" "$converted_end_time")
        
        format_success_message "Added past session: $project" \
            "Start: $start_time → $(format_timestamp "$converted_start_time")
End: $end_time → $(format_timestamp "$converted_end_time")
Duration: $(format_duration "$duration_seconds")
Notes: ${notes:-'none'}"
    fi
}

function focus_past_modify() {
    local session_id="$1"
    local project="$2"
    local start_time="$3"
    local end_time="$4"
    
    if [[ -z "$session_id" ]]; then
        handle_argument_error "missing_session_id" \
            "focus past modify <session_id> [project] [start_time] [end_time]" \
            "focus past modify 1 'new-project'
  focus past modify 1 'new-project' '2025/07/30-14:00' '2025/07/30-16:00'
  focus past modify 1 '' '14:30' '15:30'  # Change only times" \
            "Use 'focus past list' to see session IDs"
    fi
    
    # Validate session ID using centralized function
    if ! validate_numeric_input_standardized "$session_id" "Session ID"; then
        exit 2  # Invalid arguments
    fi
    
    # Get current session data using centralized function
    local current_data
    current_data=$(get_session_by_id "$session_id")
    if [[ $? -ne 0 ]]; then
        handle_database_error "session_not_found"
        return 1
    fi
    
    IFS='|' read -r current_project current_start current_end current_duration current_duration_only <<< "$current_data"
    
    # Check if any changes are actually being made
    local project_changed=false
    local start_time_changed=false
    local end_time_changed=false
    
    if [[ -n "$project" ]] && [[ "$project" != "$current_project" ]]; then
        project_changed=true
    fi
    
    if [[ -n "$start_time" ]] && [[ "$start_time" != "$current_start" ]]; then
        start_time_changed=true
    fi
    
    if [[ -n "$end_time" ]] && [[ "$end_time" != "$current_end" ]]; then
        end_time_changed=true
    fi
    
    # If no changes are being made, show current session info and exit
    if [[ "$project_changed" == false ]] && [[ "$start_time_changed" == false ]] && [[ "$end_time_changed" == false ]]; then
        echo "📋 Session $session_id details:"
        echo "   Project: $current_project"
        if [[ "$current_duration_only" == "1" ]]; then
            echo "   Type: Duration-only session"
            echo "   Duration: $((current_duration / 60)) minutes"
        else
            echo "   Start: $current_start"
            echo "   End: $current_end"
            echo "   Duration: $((current_duration / 60)) minutes"
        fi
        echo ""
        echo "💡 No changes specified. Use 'focus past modify <id> <new_project>' to modify."
        exit 0
    fi
    
    # Use current values if not provided or empty
    project="${project:-$current_project}"
    if [[ -z "$start_time" ]]; then
        start_time="$current_start"
    fi
    if [[ -z "$end_time" ]]; then
        end_time="$current_end"
    fi
    
    # For duration-only sessions, only allow project name changes
    if [[ "$current_duration_only" == "1" ]]; then
        if [[ -n "$start_time" ]] && [[ "$start_time" != "$current_start" ]]; then
            echo "❌ Cannot modify start time for duration-only sessions."
            echo "Duration-only sessions only support project name changes."
            exit 2  # Invalid arguments
        fi
        if [[ -n "$end_time" ]] && [[ "$end_time" != "$current_end" ]]; then
            echo "❌ Cannot modify end time for duration-only sessions."
            echo "Duration-only sessions only support project name changes."
            exit 2  # Invalid arguments
        fi
        
        # For duration-only sessions, preserve the original duration
        local duration="$current_duration"
        
        # Update only the project name for duration-only sessions
        execute_sqlite "UPDATE $SESSIONS_TABLE SET project = '$(sql_escape "$project")' WHERE rowid = $session_id;" "focus_past_modify" >/dev/null
        
        echo "✅ Modified session $session_id: $project"
        echo "   Type: Duration-only session"
        echo "   Duration: $((duration / 60)) minutes"
        return 0
    fi
    
    # Sanitize and validate project name if provided
    if [[ "$project" != "$current_project" ]]; then
        project=$(sanitize_project_name "$project")
        if ! validate_project_name "$project"; then
            exit 2  # Invalid arguments
        fi
    fi
    
    # Convert timestamps to ISO format if provided
    if [[ "$start_time" != "$current_start" ]]; then
        local converted_start_time
        converted_start_time=$(validate_timestamp "$start_time" "Start time")
        if [[ $? -ne 0 ]]; then
            echo "$converted_start_time"
            exit 2  # Invalid arguments
        fi
        start_time="$converted_start_time"
    fi
    
    if [[ "$end_time" != "$current_end" ]]; then
        local converted_end_time
        converted_end_time=$(validate_timestamp "$end_time" "End time")
        if [[ $? -ne 0 ]]; then
            echo "$converted_end_time"
            exit 2  # Invalid arguments
        fi
        end_time="$converted_end_time"
    fi
    
    # Validate time range if times were changed
    if [[ "$start_time" != "$current_start" ]] || [[ "$end_time" != "$current_end" ]]; then
        if ! validate_time_range "$start_time" "$end_time"; then
            exit 2  # Invalid arguments
        fi
    fi
    
    # Calculate new duration only if times were actually changed
    local duration="$current_duration"
    if [[ "$start_time" != "$current_start" ]] || [[ "$end_time" != "$current_end" ]]; then
        # Only recalculate duration if we have valid timestamps
        if [[ -n "$start_time" ]] && [[ -n "$end_time" ]]; then
            duration=$(calculate_duration "$start_time" "$end_time")
        fi
    fi
    
    # Update session (preserve existing notes)
        # Escape timestamps for SQL
        local escaped_start_time
        local escaped_end_time
        escaped_start_time=$(sql_escape "$start_time")
        escaped_end_time=$(sql_escape "$end_time")
        
        execute_sqlite "UPDATE $SESSIONS_TABLE SET project = '$(sql_escape "$project")', start_time = '$escaped_start_time', end_time = '$escaped_end_time', duration_seconds = $duration WHERE rowid = $session_id;" "focus_past_modify" >/dev/null
    
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
        exit 2  # Invalid arguments
    fi
    
    # Validate session ID exists
    if ! validate_session_id "$session_id"; then
        exit 2  # Invalid arguments
    fi
    
    # Get session info for confirmation
    local session_info
    # Validate session_id is numeric to prevent injection
    if ! [[ "$session_id" =~ ^[0-9]+$ ]]; then
        echo "❌ Invalid session ID: $session_id"
        show_error_info
        exit 2  # Invalid arguments
    fi
    session_info=$(execute_sqlite "SELECT project, start_time, end_time, duration_seconds FROM $SESSIONS_TABLE WHERE rowid = $session_id;" "focus_past_delete")
    
    if [[ -z "$session_info" ]]; then
        echo "❌ Session not found with ID: $session_id"
        show_error_info
        exit 1  # General error - session not found
    fi
    
    IFS='|' read -r project start_time end_time duration <<< "$session_info"
    
    echo "🗑️  Delete session $session_id: $project"
    echo "   Start: $start_time"
    echo "   End: $end_time"
    echo "   Duration: $((duration / 60)) minutes"
    echo "Are you sure? (y/N)"
    read -r response
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        # Validate session_id is numeric to prevent injection
    if ! [[ "$session_id" =~ ^[0-9]+$ ]]; then
        echo "❌ Invalid session ID: $session_id"
        show_error_info
        exit 2  # Invalid arguments
    fi
    execute_sqlite "DELETE FROM $SESSIONS_TABLE WHERE rowid = $session_id;" "focus_past_delete" >/dev/null
        echo "✅ Session deleted"
    else
        echo "Deletion cancelled."
    fi
}

function focus_past_list() {
    local limit=20
    
    # Parse arguments to support both -n flag and positional argument
    while [[ $# -gt 0 ]]; do
        case $1 in
            -n|--number)
                if [[ $# -lt 2 ]]; then
                    echo "❌ Missing value for option: $1"
                    echo "Usage: focus past list [-n|--number <number>] [<number>]"
                    exit 2  # Invalid arguments
                fi
                limit="$2"
                shift 2
                ;;
            -*)
                echo "❌ Unknown option: $1"
                echo "Usage: focus past list [-n|--number <number>] [<number>]"
                echo "Examples:"
                echo "  focus past list"
                echo "  focus past list 30"
                echo "  focus past list -n 30"
                echo "  focus past list --number 30"
                exit 2  # Invalid arguments
                ;;
            *)
                # If it's a number, use it as the limit
                if [[ "$1" =~ ^[0-9]+$ ]]; then
                    limit="$1"
                else
                    echo "❌ Invalid argument: $1"
                    echo "Usage: focus past list [-n|--number <number>] [<number>]"
                    echo "The number argument must be a positive integer."
                    exit 2  # Invalid arguments
                fi
                shift
                ;;
        esac
    done
    
    if ! [[ "$limit" =~ ^[0-9]+$ ]]; then
        echo "❌ Invalid limit: $limit"
        exit 2  # Invalid arguments
    fi
    
    echo "📋 Recent focus sessions (last $limit):"
    echo
    
    # Get recent sessions using direct SQL query
    local sessions
    sessions=$(execute_sqlite "SELECT rowid, project, start_time, end_time, duration_seconds, notes FROM $SESSIONS_TABLE WHERE project != '[idle]' ORDER BY rowid DESC LIMIT $limit;" "focus_past_list")
    
    if [[ -z "$sessions" ]]; then
        echo "No focus sessions found."
        return 0
    fi
    
    # Format table header using centralized function
    format_table_header "ID" "Project" "Start" "End" "Duration" "Type"
    
    # Process sessions and add blank lines between entries
    local session_count=0
    local total_sessions
    total_sessions=$(echo "$sessions" | wc -l)
    
    while IFS='|' read -r id project start_time end_time duration notes; do
        session_count=$((session_count + 1))
        
        # Format timestamps and duration using centralized functions
        local start_date
        start_date=$(format_timestamp "$start_time")
        local end_date
        end_date=$(format_timestamp "$end_time")
        local duration_formatted
        duration_formatted=$(format_duration "$duration" "minutes_only")
        
        printf "%-4s %-20s %-19s %-19s %-8s %-6s\n" "$id" "$project" "$start_date" "$end_date" "$duration_formatted" "Live"
        
        # Show notes if available
        if [[ -n "$notes" ]]; then
            printf "     📝 %s\n" "$notes"
        fi
        
        # Add blank line after each entry except the last one
        if [[ $session_count -lt $total_sessions ]]; then
            printf "\n"
        fi
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
            echo "  focus past list"
            echo "  focus past list 30"
            echo "  focus past list -n 30"
            exit 2  # Invalid arguments
            ;;
    esac
}


# Main execution
refocus_script_main focus_past "$@"
