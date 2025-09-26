#!/usr/bin/env bash
# Refocus Shell - Past Subcommand
# Copyright (c) 2025 PeGa
# Licensed under the GNU General Public License v3

# Source bootstrap module
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/focus-bootstrap.sh"

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
        echo "❌ Project name is required."
        echo "Usage: focus past add <project> <start_time> <end_time>"
        echo "   OR: focus past add <project> --duration <time> --date <date> [--notes <notes>]"
        echo ""
        echo "Time formats supported:"
        echo "  - YYYY/MM/DD-HH:MM (recommended: 2025/07/30-14:30)"
        echo "  - HH:MM (today's date)"
        echo "  - 'YYYY-MM-DD HH:MM' (quoted datetime)"
        echo "  - 'YYYY-MM-DDTHH:MM' (ISO format)"
        echo "  - Full ISO format (YYYY-MM-DDTHH:MM:SS±HH:MM)"
        echo "  - Relative dates ('yesterday 14:30', '2 hours ago', etc.)"
        echo ""
        echo "Duration formats supported:"
        echo "  - 1h30m, 2h, 45m, 90m"
        echo "  - 1.5h, 0.5h"
        echo ""
        echo "⚠️  Note: Times should be absolute timestamps, not durations."
        echo "   Use '7 hours ago' not '7h' to specify relative times."
        echo ""
        echo "Examples:"
        echo "  focus past add meeting 2025/07/30-14:15 2025/07/30-15:30  # Specific date"
        echo "  focus past add meeting 14:15 15:30                          # Today's date"
        echo "  focus past add coding 'yesterday 09:00' 'yesterday 17:00'   # Relative dates"
        echo "  focus past add coding '7 hours ago' 'now'                   # Relative times"
        echo "  focus past add coding --duration 2h30m --date 2025/07/30    # Duration-only"
        echo "  focus past add coding --duration 90m --date yesterday --notes 'retrospective'"
        echo ""
        echo "💡 Tip: Use YYYY/MM/DD-HH:MM format for easy, quote-free dates!"
        exit 1
    fi
    
    # Sanitize and validate project name
    project=$(sanitize_project_name "$project")
    if ! validate_project_name "$project"; then
        exit 1
    fi
    
    if [[ "$duration_mode" == "true" ]]; then
        # Duration-only mode
        if [[ -z "$duration" ]]; then
            echo "❌ Duration is required when using --duration flag."
            echo "Usage: focus past add <project> --duration <time> --date <date> [--notes <notes>]"
            echo ""
            echo "Duration formats: 1h30m, 2h, 45m, 90m, 1.5h, 0.5h"
            exit 1
        fi
        
        if [[ -z "$session_date" ]]; then
            echo "❌ Date is required when using --duration flag."
            echo "Usage: focus past add <project> --duration <time> --date <date> [--notes <notes>]"
            echo ""
            echo "Date formats: 2025/07/30, yesterday, 2 days ago, etc."
            exit 1
        fi
        
        # Parse duration (e.g., "1h30m" -> 5400 seconds)
        local duration_seconds
        duration_seconds=$(parse_duration "$duration")
        if [[ $? -ne 0 ]]; then
            echo "❌ Invalid duration format: $duration"
            echo "Supported formats: 1h30m, 2h, 45m, 90m, 1.5h, 0.5h"
            exit 1
        fi
        
        # Validate and convert session date
        local converted_date
        converted_date=$(validate_timestamp "$session_date" "Session date")
        if [[ $? -ne 0 ]]; then
            echo "$converted_date"
            exit 1
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
        
        echo "✅ Added duration-only session: $project"
        echo "   Date: $session_date → $date_only"
        echo "   Duration: $duration → $((duration_seconds / 60)) minutes"
        if [[ -n "$notes" ]]; then
            echo "   Notes: $notes"
        fi
        
    else
        # Traditional mode (start_time and end_time)
        if [[ -z "$start_time" ]]; then
            echo "❌ Start time is required."
            echo "Usage: focus past add <project> <start_time> <end_time>"
            echo ""
            echo "💡 Tip: Use YYYY/MM/DD-HH:MM format for easy dates!"
            echo "   Example: focus past add meeting 2025/07/30-14:15 2025/07/30-15:30"
            echo ""
            echo "⚠️  Note: Times should be absolute timestamps, not durations."
            echo "   Use '7 hours ago' not '7h' to specify relative times."
            echo "   Example: focus past add meeting '7 hours ago' 'now'"
            exit 1
        fi
        
        if [[ -z "$end_time" ]]; then
            echo "❌ End time is required."
            echo "Usage: focus past add <project> <start_time> <end_time>"
            echo ""
            echo "💡 Tip: Use YYYY/MM/DD-HH:MM format for easy dates!"
            echo "   Example: focus past add meeting 2025/07/30-14:15 2025/07/30-15:30"
            echo ""
            echo "⚠️  Note: Times should be absolute timestamps, not durations."
            echo "   Use '7 hours ago' not '7h' to specify relative times."
            echo "   Example: focus past add meeting '7 hours ago' 'now'"
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
        
        # Prompt for session notes if not provided via --notes
        if [[ -z "$notes" ]]; then
            echo -n "📝 What did you accomplish during this focus session? (Press Enter to skip, or type a brief description): "
            read -r session_notes
            notes="$session_notes"
        fi
        
        # Insert session with notes
        insert_session "$project" "$converted_start_time" "$converted_end_time" "$duration" "$notes"
        
        echo "✅ Added past session: $project"
        echo "   Start: $start_time → $converted_start_time"
        echo "   End: $end_time → $converted_end_time"
        echo "   Duration: $((duration / 60)) minutes"
        if [[ -n "$notes" ]]; then
            echo "   Notes: $notes"
        fi
    fi
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
    # Validate session_id is numeric to prevent injection
    if ! [[ "$session_id" =~ ^[0-9]+$ ]]; then
        echo "❌ Invalid session ID: $session_id"
        show_error_info
        exit 1
    fi
    current_data=$(execute_sqlite "SELECT project, start_time, end_time, duration_seconds, duration_only FROM $SESSIONS_TABLE WHERE rowid = $session_id;" "focus_past_modify")
    
    if [[ -z "$current_data" ]]; then
        echo "❌ Session not found with ID: $session_id"
        show_error_info
        exit 1
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
            exit 1
        fi
        if [[ -n "$end_time" ]] && [[ "$end_time" != "$current_end" ]]; then
            echo "❌ Cannot modify end time for duration-only sessions."
            echo "Duration-only sessions only support project name changes."
            exit 1
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
        exit 1
    fi
    
    # Validate session ID exists
    if ! validate_session_id "$session_id"; then
        exit 1
    fi
    
    # Get session info for confirmation
    local session_info
    # Validate session_id is numeric to prevent injection
    if ! [[ "$session_id" =~ ^[0-9]+$ ]]; then
        echo "❌ Invalid session ID: $session_id"
        show_error_info
        exit 1
    fi
    session_info=$(execute_sqlite "SELECT project, start_time, end_time, duration_seconds FROM $SESSIONS_TABLE WHERE rowid = $session_id;" "focus_past_delete")
    
    if [[ -z "$session_info" ]]; then
        echo "❌ Session not found with ID: $session_id"
        show_error_info
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
        # Validate session_id is numeric to prevent injection
    if ! [[ "$session_id" =~ ^[0-9]+$ ]]; then
        echo "❌ Invalid session ID: $session_id"
        show_error_info
        exit 1
    fi
    execute_sqlite "DELETE FROM $SESSIONS_TABLE WHERE rowid = $session_id;" "focus_past_delete" >/dev/null
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
    # Validate limit is numeric to prevent injection
    if ! [[ "$limit" =~ ^[0-9]+$ ]]; then
        echo "❌ Invalid limit: $limit"
        show_error_info
        exit 1
    fi
    sessions=$(execute_sqlite "SELECT rowid, project, start_time, end_time, duration_seconds, notes, duration_only, session_date FROM $SESSIONS_TABLE WHERE project != '[idle]' ORDER BY rowid DESC LIMIT $limit;" "focus_past_list")
    
    if [[ -z "$sessions" ]]; then
        echo "No focus sessions found."
        return 0
    fi
    
    printf "%-4s %-20s %-19s %-19s %-8s %-6s\n" "ID" "Project" "Start" "End" "Duration" "Type"
    printf "%-4s %-20s %-19s %-19s %-8s %-6s\n" "----" "--------------------" "-------------------" "-------------------" "--------" "------"
    
    while IFS='|' read -r id project start_time end_time duration notes duration_only session_date; do
        local duration_min
        duration_min=$((duration / 60))
        
        if [[ "$duration_only" == "1" ]]; then
            # Duration-only session
            printf "%-4s %-20s %-19s %-19s %-8s %-6s\n" "$id" "$project" "N/A" "N/A" "${duration_min}m" "Manual"
            
            # Show notes if available
            if [[ -n "$notes" ]]; then
                printf "     📝 %s\n" "$notes"
            fi
        else
            # Regular session
            local start_date
            start_date=$(date --date="$start_time" +"%Y-%m-%d %H:%M")
            local end_date
            end_date=$(date --date="$end_time" +"%Y-%m-%d %H:%M")
            
            printf "%-4s %-20s %-19s %-19s %-8s %-6s\n" "$id" "$project" "$start_date" "$end_date" "${duration_min}m" "Live"
            
            # Show notes if available
            if [[ -n "$notes" ]]; then
                printf "     📝 %s\n" "$notes"
            fi
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
            echo "  focus past list 10"
            exit 1
            ;;
    esac
}


# Main execution
refocus_script_main focus_past "$@"
