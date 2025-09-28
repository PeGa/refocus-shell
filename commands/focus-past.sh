#!/usr/bin/env bash
# Refocus Shell - Past Subcommand
# Copyright (c) 2025 PeGa
# Licensed under the GNU General Public License v3

# Source required modules
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/focus-bootstrap.sh"
source "$SCRIPT_DIR/../lib/focus-utils.sh"

# Note: Using direct SQL queries and validation instead of centralized functions
# to maintain compatibility with installed versions

# Note: parse_duration_to_seconds and parse_date_to_timestamp functions
# have been moved to lib/focus-utils.sh as parse_duration and parse_time_spec

function focus_past_add() {
    # Guard clauses
    if [[ $# -lt 3 ]]; then
        usage "Usage: focus past add <project> <start> <end>"
    fi
    
    local project="$1"
    local start_time="$2"
    local end_time="$3"
    
    if [[ -z "$project" ]] || [[ "$project" =~ [[:cntrl:]] ]] || [[ ${#project} -gt 100 ]]; then
        usage "Invalid project name"
    fi
    
    if [[ -z "$start_time" ]] || [[ -z "$end_time" ]]; then
        usage "Start and end times are required"
    fi
    
    # Parse and validate timestamps
    local converted_start_time
    converted_start_time=$(parse_date_to_timestamp "$start_time")
    if [[ $? -ne 0 ]]; then
        usage "Invalid start time format"
    fi
    
    local converted_end_time
    converted_end_time=$(parse_date_to_timestamp "$end_time")
    if [[ $? -ne 0 ]]; then
        usage "Invalid end time format"
    fi
    
    # Check if start time is before end time
    local start_ts
    start_ts=$(date -d "$converted_start_time" +%s 2>/dev/null)
    local end_ts
    end_ts=$(date -d "$converted_end_time" +%s 2>/dev/null)
    
    if [[ -n "$start_ts" ]] && [[ -n "$end_ts" ]] && [[ "$start_ts" -ge "$end_ts" ]]; then
        usage "Start time must be before end time"
    fi
    
    # Sanitize project name
    project=$(echo "$project" | tr -d '\r\n\t' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    
    local duration=""
    local session_date=""
    local notes=""
    local duration_mode=false
    
    if [[ -z "$project" ]]; then
        echo "❌ Project name is required" >&2
        echo "Usage: focus past add <project> <start_time> <end_time>" >&2
        echo "Examples:" >&2
        echo "  focus past add meeting 2025/07/30-14:15 2025/07/30-15:30  # Specific date" >&2
        echo "  focus past add meeting 14:15 15:30                          # Today's date" >&2
        echo "  focus past add coding 'yesterday 09:00' 'yesterday 17:00'   # Relative dates" >&2
        echo "  focus past add coding '7 hours ago' 'now'                   # Relative times" >&2
        echo "  focus past add coding --duration 2h30m --date 2025/07/30    # Duration-only" >&2
        echo "  focus past add coding --duration 90m --date yesterday --notes 'retrospective'" >&2
        echo "Time formats: YYYY/MM/DD-HH:MM, HH:MM, 'YYYY-MM-DD HH:MM', etc." >&2
        echo "Duration formats: 1h30m, 2h, 45m, 90m, 1.5h, 0.5h" >&2
        echo "Note: Times should be absolute timestamps, not durations." >&2
        exit 2  # Invalid arguments
    fi
    
    # Validate project name using centralized function
    # Basic project name validation
    if [[ -z "$project" ]] || [[ "$project" =~ [[:cntrl:]] ]]; then
        echo "❌ Invalid project name: $project" >&2
        exit 2  # Invalid arguments
    fi
    # Sanitize project name
    project=$(echo "$project" | tr -d '\r\n\t' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    
    if [[ "$duration_mode" == "true" ]]; then
        # Duration-only mode
        if [[ -z "$duration" ]]; then
            echo "❌ Duration is required for duration-only mode" >&2
            echo "Usage: focus past add <project> --duration <time> --date <date> [--notes <notes>]" >&2
            echo "Examples:" >&2
            echo "  focus past add coding --duration 2h30m --date 2025/07/30" >&2
            echo "  focus past add coding --duration 90m --date yesterday --notes 'retrospective'" >&2
            echo "Duration formats: 1h30m, 2h, 45m, 90m, 1.5h, 0.5h" >&2
            exit 2  # Invalid arguments
        fi
        
        if [[ -z "$session_date" ]]; then
            echo "❌ Date is required for duration-only mode" >&2
            echo "Usage: focus past add <project> --duration <time> --date <date> [--notes <notes>]" >&2
            echo "Examples:" >&2
            echo "  focus past add coding --duration 2h30m --date 2025/07/30" >&2
            echo "  focus past add coding --duration 90m --date yesterday --notes 'retrospective'" >&2
            echo "Date formats: 2025/07/30, yesterday, 2 days ago, etc." >&2
            exit 2  # Invalid arguments
        fi
        
        # Parse duration - convert to seconds
        local duration_seconds
        duration_seconds=$(parse_duration "$duration")
        if [[ $? -ne 0 ]] || [[ -z "$duration_seconds" ]]; then
            echo "❌ Invalid duration format: $duration" >&2
            echo "Valid formats: 1h30m, 2h, 45m, 90m, 1.5h, 0.5h" >&2
            exit 2  # Invalid arguments
        fi
        
        # Validate and convert session date
        local converted_date
        converted_date=$(get_timestamp_for_time "$session_date")
        if [[ $? -ne 0 ]] || [[ -z "$converted_date" ]]; then
            echo "❌ Invalid date format: $session_date" >&2
            echo "Valid formats: 2025/07/30, yesterday, 2 days ago, etc." >&2
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
        
        echo "✅ Added duration-only session: $project" >&2
        echo "Date: $session_date → $date_only" >&2
        echo "Duration: $duration → $(refocus_format_duration "$duration_seconds")" >&2
        echo "Notes: ${notes:-'none'}" >&2
        
    else
        # Traditional mode (start_time and end_time)
        if [[ -z "$start_time" ]]; then
            echo "❌ Start time is required" >&2
            echo "Usage: focus past add <project> <start_time> <end_time>" >&2
            echo "Examples:" >&2
            echo "  focus past add meeting 2025/07/30-14:15 2025/07/30-15:30  # Specific date" >&2
            echo "  focus past add meeting 14:15 15:30                          # Today's date" >&2
            echo "  focus past add coding 'yesterday 09:00' 'yesterday 17:00'   # Relative dates" >&2
            echo "  focus past add coding '7 hours ago' 'now'                   # Relative times" >&2
            echo "Tip: Use YYYY/MM/DD-HH:MM format for easy dates!" >&2
            echo "Note: Times should be absolute timestamps, not durations." >&2
            exit 2  # Invalid arguments
        fi
        
        if [[ -z "$end_time" ]]; then
            echo "❌ End time is required" >&2
            echo "Usage: focus past add <project> <start_time> <end_time>" >&2
            echo "Examples:" >&2
            echo "  focus past add meeting 2025/07/30-14:15 2025/07/30-15:30  # Specific date" >&2
            echo "  focus past add meeting 14:15 15:30                          # Today's date" >&2
            echo "  focus past add coding 'yesterday 09:00' 'yesterday 17:00'   # Relative dates" >&2
            echo "  focus past add coding '7 hours ago' 'now'                   # Relative times" >&2
            echo "Tip: Use YYYY/MM/DD-HH:MM format for easy dates!" >&2
            echo "Note: Times should be absolute timestamps, not durations." >&2
            exit 2  # Invalid arguments
        fi
        
        # Convert timestamps to ISO format
        local converted_start_time
        converted_start_time=$(get_timestamp_for_time "$start_time")
        if [[ $? -ne 0 ]] || [[ -z "$converted_start_time" ]]; then
            echo "❌ Invalid start time format: $start_time" >&2
            echo "Valid formats: YYYY/MM/DD-HH:MM, HH:MM, 'YYYY-MM-DD HH:MM', etc." >&2
            exit 2  # Invalid arguments
        fi
        
        local converted_end_time
        converted_end_time=$(get_timestamp_for_time "$end_time")
        if [[ $? -ne 0 ]] || [[ -z "$converted_end_time" ]]; then
            echo "❌ Invalid end time format: $end_time" >&2
            echo "Valid formats: YYYY/MM/DD-HH:MM, HH:MM, 'YYYY-MM-DD HH:MM', etc." >&2
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
        
        echo "✅ Added past session: $project" >&2
        echo "Start: $start_time → $(date -d "$converted_start_time" +"%Y-%m-%d %H:%M" 2>/dev/null)" >&2
        echo "End: $end_time → $(date -d "$converted_end_time" +"%Y-%m-%d %H:%M" 2>/dev/null)" >&2
        echo "Duration: $(refocus_format_duration "$duration_seconds")" >&2
    fi
}

function focus_past_modify() {
    local session_id="$1"
    local project="$2"
    local start_time="$3"
    local end_time="$4"
    
    if [[ -z "$session_id" ]]; then
        echo "❌ Session ID is required" >&2
        echo "Usage: focus past modify <session_id> [project] [start_time] [end_time]" >&2
        echo "Examples:" >&2
        echo "  focus past modify 1 'new-project'" >&2
        echo "  focus past modify 1 'new-project' '2025/07/30-14:00' '2025/07/30-16:00'" >&2
        echo "  focus past modify 1 '' '14:30' '15:30'  # Change only times" >&2
        echo "Use 'focus past list' to see session IDs" >&2
        exit 2  # Invalid arguments
    fi
    
    # Validate session ID
    if ! [[ "$session_id" =~ ^[0-9]+$ ]]; then
        echo "❌ Invalid session ID: $session_id" >&2
        echo "Session ID must be a number. Use 'focus past list' to see available IDs." >&2
        exit 2  # Invalid arguments
    fi
    
    # Get current session data using direct SQL query
    local current_data
    current_data=$(execute_sqlite "SELECT project, start_time, end_time, duration_seconds, notes FROM ${REFOCUS_SESSIONS_TABLE:-sessions} WHERE rowid = $session_id;" "focus_past_modify")
    if [[ -z "$current_data" ]]; then
        echo "❌ Session ID $session_id not found" >&2
        echo "Use 'focus past list' to see available session IDs." >&2
        exit 2  # Invalid arguments
    fi
    
    IFS='|' read -r current_project current_start current_end current_duration current_notes <<< "$current_data"
    
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
        if [[ -z "$current_start" ]] || [[ -z "$current_end" ]]; then
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
    if [[ -z "$current_start" ]] || [[ -z "$current_end" ]]; then
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
        execute_sqlite "UPDATE ${REFOCUS_SESSIONS_TABLE:-sessions} SET project = '$(_sql_escape_public "$project")' WHERE rowid = $session_id;" "focus_past_modify" >/dev/null
        
        echo "✅ Modified session $session_id: $project"
        echo "   Type: Duration-only session"
        echo "   Duration: $((duration / 60)) minutes"
        return 0
    fi
    
    # Sanitize and validate project name if provided
    if [[ "$project" != "$current_project" ]]; then
        project=$(sanitize_project_name "$project")
        # Basic project name validation
        if [[ -z "$project" ]] || [[ "$project" =~ [[:cntrl:]] ]]; then
            echo "❌ Invalid project name: $project" >&2
            exit 2  # Invalid arguments
        fi
        # Sanitize project name
        project=$(echo "$project" | tr -d '\r\n\t' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    fi
    
    # Convert timestamps to ISO format if provided
    if [[ "$start_time" != "$current_start" ]]; then
        local converted_start_time
        converted_start_time=$(get_timestamp_for_time "$start_time")
        if [[ $? -ne 0 ]] || [[ -z "$converted_start_time" ]]; then
            echo "❌ Invalid start time format: $start_time" >&2
            exit 2  # Invalid arguments
        fi
        start_time="$converted_start_time"
    fi
    
    if [[ "$end_time" != "$current_end" ]]; then
        local converted_end_time
        converted_end_time=$(get_timestamp_for_time "$end_time")
        if [[ $? -ne 0 ]] || [[ -z "$converted_end_time" ]]; then
            echo "❌ Invalid end time format: $end_time" >&2
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
    
    # Use current values if not changed
    local final_start_time="$current_start"
    local final_end_time="$current_end"
    
    if [[ "$start_time_changed" == true ]]; then
        final_start_time="$start_time"
    fi
    
    if [[ "$end_time_changed" == true ]]; then
        final_end_time="$end_time"
    fi
    
    # Calculate new duration only if times were actually changed
    local duration_seconds="$current_duration"
    if [[ "$start_time_changed" == true ]] || [[ "$end_time_changed" == true ]]; then
        # Only recalculate duration if we have valid timestamps
        if [[ -n "$final_start_time" ]] && [[ -n "$final_end_time" ]]; then
            duration_seconds=$(calculate_duration "$final_start_time" "$final_end_time")
        fi
    fi
    
    # Update session (preserve existing notes)
        
        # Escape timestamps for SQL
        local escaped_start_time
        local escaped_end_time
        escaped_start_time=$(_sql_escape_public "$final_start_time")
        escaped_end_time=$(_sql_escape_public "$final_end_time")
        
        execute_sqlite "UPDATE ${REFOCUS_SESSIONS_TABLE:-sessions} SET project = '$(_sql_escape_public "$project")', start_time = '$escaped_start_time', end_time = '$escaped_end_time', duration_seconds = $duration_seconds WHERE rowid = $session_id;" "focus_past_modify" >/dev/null
    
    echo "✅ Modified session $session_id: $project"
    echo "   Start: $final_start_time"
    echo "   End: $final_end_time"
    echo "   Duration: $((duration_seconds / 60)) minutes"
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
    # Validate session ID
    if ! [[ "$session_id" =~ ^[0-9]+$ ]]; then
        echo "❌ Invalid session ID: $session_id" >&2
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
    session_info=$(execute_sqlite "SELECT project, start_time, end_time, duration_seconds FROM ${REFOCUS_SESSIONS_TABLE:-sessions} WHERE rowid = $session_id;" "focus_past_delete")
    
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
    execute_sqlite "DELETE FROM ${REFOCUS_SESSIONS_TABLE:-sessions} WHERE rowid = $session_id;" "focus_past_delete" >/dev/null
        echo "✅ Session deleted"
    else
        echo "Deletion cancelled."
    fi
}

function focus_past_list() {
    # Parse flags using centralized function
    parse_past_flags "$@"
    
    if ! [[ "$PAST_LIMIT" =~ ^[0-9]+$ ]]; then
        echo "❌ Invalid limit: $PAST_LIMIT"
        exit 2  # Invalid arguments
    fi
    
    echo "📋 Recent focus sessions (last $PAST_LIMIT):"
    echo
    
    # Get sessions from database
    local sessions
    sessions=$(execute_sqlite "SELECT rowid, project, start_time, end_time, duration_seconds, notes FROM ${REFOCUS_SESSIONS_TABLE:-sessions} WHERE project != '[idle]' ORDER BY rowid DESC LIMIT $PAST_LIMIT;" "focus_past_list")
    
    if [[ -z "$sessions" ]]; then
        echo "No focus sessions found."
        return 0
    fi
    
    # Print table using centralized functions
    if [[ "$PAST_RAW_MODE" == true ]]; then
        # Raw CSV output
        while IFS='|' read -r id project start_time end_time duration notes; do
            print_past_table_row_raw "$id" "$start_time" "$end_time" "$project" "" "$notes"
        done <<< "$sessions"
    else
        # Human-readable table
        print_past_table_header
        
        # Process sessions and add blank lines between entries
        local session_count=0
        local total_sessions
        total_sessions=$(echo "$sessions" | wc -l)
        
        while IFS='|' read -r id project start_time end_time duration notes; do
            session_count=$((session_count + 1))
            
            # Use the printer function for consistent formatting
            print_past_row "$id" "$start_time" "$end_time" "$project" "" "$notes"
            
            # Add blank line after each entry except the last one
            if [[ $session_count -lt $total_sessions ]]; then
                printf "\n"
            fi
        done <<< "$sessions"
        
        print_past_table_footer
    fi
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
