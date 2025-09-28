#!/usr/bin/env bash
# Refocus Shell - Output Formatting Module
# Copyright (c) 2025 PeGa
# Licensed under the GNU General Public License v3

# This module provides common output formatting functions for refocus commands
# to ensure consistent, clean, and user-friendly display.

# Function to format duration in minutes only
# Usage: format_duration_minutes <seconds>
format_duration_minutes() {
    local duration_seconds="$1"
    echo $((duration_seconds / 60))
}

# Function to format duration in hours and minutes
# Usage: format_duration_hours_minutes <seconds>
format_duration_hours_minutes() {
    local duration_seconds="$1"
    local hours=$((duration_seconds / 3600))
    local minutes=$(((duration_seconds % 3600) / 60))
    echo "${hours}h ${minutes}m"
}

# Function to format duration in human-readable format
# Usage: format_duration <seconds> [compact]
format_duration() {
    local seconds="$1"
    local compact="${2:-false}"
    local hours=$((seconds / 3600))
    local minutes=$(((seconds % 3600) / 60))
    local remaining_seconds=$((seconds % 60))
    
    if [[ "$compact" == "true" ]]; then
        if [[ $hours -gt 0 ]]; then
            echo "${hours}h${minutes}m"
        elif [[ $minutes -gt 0 ]]; then
            echo "${minutes}m"
        else
            echo "${remaining_seconds}s"
        fi
    else
        if [[ $hours -gt 0 ]]; then
            if [[ $minutes -gt 0 ]]; then
                echo "${hours}h ${minutes}m"
            else
                echo "${hours}h"
            fi
        elif [[ $minutes -gt 0 ]]; then
            echo "${minutes}m"
        else
            echo "${remaining_seconds}s"
        fi
    fi
}

# Legacy function for backward compatibility
refocus_format_duration() {
    format_duration "$@"
}

# Function to format timestamp for display
# Usage: format_ts <epoch> [format]
format_ts() {
    local epoch="$1"
    local format="${2:-${TIME_FMT:-%Y-%m-%d %H:%M}}"
    
    if [[ -z "$epoch" ]] || [[ "$epoch" == "N/A" ]]; then
        echo "N/A"
        return
    fi
    
    date --date="@$epoch" "+$format" 2>/dev/null || echo "N/A"
}

# Legacy function for backward compatibility
format_timestamp() {
    format_ts "$@"
}

# Function to format project name with description
# Usage: format_project_with_description <project> <description>
format_project_with_description() {
    local project="$1"
    local description="$2"
    
    if [[ -n "$description" ]]; then
        echo "$project - $description"
    else
        echo "$project"
    fi
}

# Function to print session row
# Usage: print_session_row <project> <start> <end> <duration> <type> [notes]
print_session_row() {
    local project="$1"
    local start="$2"
    local end="$3"
    local duration="$4"
    local type="$5"
    local notes="$6"
    
    local formatted_duration
    formatted_duration=$(format_duration "$duration" "true")
    
    local formatted_start
    local formatted_end
    formatted_start=$(format_ts "$start")
    formatted_end=$(format_ts "$end")
    
    printf "%-20s %-19s %-19s %-8s %-6s\n" \
        "$project" "$formatted_start" "$formatted_end" "$formatted_duration" "$type"
    
    if [[ -n "$notes" ]]; then
        echo "     📝 $notes"
    fi
}

# Legacy function for backward compatibility
format_session_summary() {
    print_session_row "$@"
}

# Function to print status message
# Usage: print_status <message>
print_status() {
    echo -e "\033[0;34m[INFO]\033[0m $1"
}

# Function to format focus status
# Usage: format_focus_status <active> <project> <elapsed> [total_time] [description]
format_focus_status() {
    local active="$1"
    local project="$2"
    local elapsed="$3"
    local total_time="$4"
    local description="$5"
    
    local elapsed_minutes=$((elapsed / 60))
    
    if [[ "$active" -eq 1 ]]; then
        if [[ -n "$total_time" ]] && [[ $total_time -gt 0 ]]; then
            local total_minutes=$((total_time / 60))
            echo "⏳ Focusing on: $project — ${elapsed_minutes}m elapsed (Total: ${total_minutes}m)"
        else
            echo "⏳ Focusing on: $project — ${elapsed_minutes}m elapsed"
        fi
        
        if [[ -n "$description" ]]; then
            echo "📋 $description"
        fi
    else
        echo "✅ Not currently tracking focus."
    fi
}


# Function to format paused session status
# Usage: format_paused_status <project> <previous_elapsed> <pause_duration> [notes]
format_paused_status() {
    local project="$1"
    local previous_elapsed="$2"
    local pause_duration="$3"
    local notes="$4"
    
    local previous_minutes=$((previous_elapsed / 60))
    local pause_minutes=$((pause_duration / 60))
    
    echo "⏸️  Session paused: $project"
    echo "   Previous session time: ${previous_minutes}m"
    echo "   Pause duration: ${pause_minutes}m"
    
    if [[ -n "$notes" ]]; then
        echo "   Current session notes: $notes"
    fi
    
    echo ""
    echo "💡 Use 'focus continue' to resume this session"
    echo "   Use 'focus off' to end the session permanently"
}

# Function to format last session info
# Usage: format_last_session <project> <duration> <time_since>
format_last_session() {
    local project="$1"
    local duration="$2"
    local time_since="$3"
    
    local duration_minutes=$((duration / 60))
    local time_since_minutes=$((time_since / 60))
    
    echo "📊 Last session: $project (${duration_minutes}m)"
    echo "⏰ Time since last focus: ${time_since_minutes}m"
}

# Function to format error message
# Usage: format_error <message> [details]
format_error() {
    local message="$1"
    local details="$2"
    
    echo "❌ $message"
    if [[ -n "$details" ]]; then
        echo "   $details"
    fi
}

# Function to format success message
# Usage: format_success <message> [details]
format_success() {
    local message="$1"
    local details="$2"
    
    echo "✅ $message"
    if [[ -n "$details" ]]; then
        echo "   $details"
    fi
}

# Function to format warning message
# Usage: format_warning <message> [details]
format_warning() {
    local message="$1"
    local details="$2"
    
    echo "⚠️  $message"
    if [[ -n "$details" ]]; then
        echo "   $details"
    fi
}

# Function to format info message
# Usage: format_info <message> [details]
format_info() {
    local message="$1"
    local details="$2"
    
    echo "ℹ️  $message"
    if [[ -n "$details" ]]; then
        echo "   $details"
    fi
}

# Function to format table header
# Usage: format_table_header <header1> <header2> [header3] [header4] [header5]
format_table_header() {
    local header1="$1"
    local header2="$2"
    local header3="$3"
    local header4="$4"
    local header5="$5"
    
    printf "%-4s %-20s %-19s %-19s %-8s %-6s\n" \
        "$header1" "$header2" "$header3" "$header4" "$header5" "Type"
    echo "---- -------------------- ------------------- ------------------- -------- ------"
}

# Function to format configuration display
# Usage: format_config_display <key> <value> [description]
format_config_display() {
    local key="$1"
    local value="$2"
    local description="$3"
    
    printf "  %-20s: %s" "$key" "$value"
    if [[ -n "$description" ]]; then
        echo " ($description)"
    else
        echo
    fi
}

# Function to format usage help
# Usage: format_usage <command> <description> [examples]
format_usage() {
    local command="$1"
    local description="$2"
    local examples="$3"
    
    echo "Usage: $command"
    echo "       $description"
    
    if [[ -n "$examples" ]]; then
        echo ""
        echo "Examples:"
        echo "$examples"
    fi
}

# Function to format section header
# Usage: format_section_header <title> [subtitle]
format_section_header() {
    local title="$1"
    local subtitle="$2"
    
    echo "$title"
    echo "$(printf '=%.0s' $(seq 1 ${#title}))"
    
    if [[ -n "$subtitle" ]]; then
        echo "$subtitle"
    fi
    
    echo
}

# Function to write current focus state to prompt cache files
# Usage: write_prompt_cache <status> <project> <minutes>
write_prompt_cache() {
    local dir="$(get_cfg DATA_DIR "$HOME/.local/refocus")"
    mkdir -p "$dir"
    printf "%s|%s|%s\n" "${1:-idle}" "${2:--}" "${3:--}" >"$dir/prompt.cache"
    date +%s >"$dir/prompt.ver"
}

# Function: print_past_row
# Description: Prints a formatted row for past session display (human-readable format)
# Usage: print_past_row <id> <start_ts> <end_ts> <project> <desc> <note>
# Parameters:
#   $1 - id: Session ID
#   $2 - start_ts: Start timestamp (epoch or ISO format)
#   $3 - end_ts: End timestamp (epoch or ISO format)
#   $4 - project: Project name
#   $5 - desc: Description (optional)
#   $6 - note: Session notes (optional)
# Returns:
#   0 - Success: Prints formatted row to stdout
# Side Effects:
#   - Prints formatted session information to stdout
# Dependencies:
#   - date command with --date support
#   - format_duration function
# Examples:
#   print_past_row "1" "1642248000" "1642251600" "meeting" "team sync" "productive discussion"
# Notes:
#   - Formats timestamps as YYYY-MM-DD HH:MM
#   - Shows duration in human-readable format
#   - Displays notes if provided
print_past_row() {
    local id="$1"
    local start_ts="$2"
    local end_ts="$3"
    local project="$4"
    local desc="$5"
    local note="$6"
    
    # Format timestamps
    local start_date
    local end_date
    if [[ "$start_ts" =~ ^[0-9]+$ ]]; then
        # Epoch timestamp
        start_date=$(date --date="@$start_ts" +"%Y-%m-%d %H:%M" 2>/dev/null || echo "$start_ts")
        end_date=$(date --date="@$end_ts" +"%Y-%m-%d %H:%M" 2>/dev/null || echo "$end_ts")
    else
        # ISO timestamp
        start_date=$(date --date="$start_ts" +"%Y-%m-%d %H:%M" 2>/dev/null || echo "$start_ts")
        end_date=$(date --date="$end_ts" +"%Y-%m-%d %H:%M" 2>/dev/null || echo "$end_ts")
    fi
    
    # Calculate duration
    local duration_seconds
    if [[ "$start_ts" =~ ^[0-9]+$ ]] && [[ "$end_ts" =~ ^[0-9]+$ ]]; then
        duration_seconds=$((end_ts - start_ts))
    else
        duration_seconds=$(calculate_duration "$start_ts" "$end_ts")
    fi
    
    local duration_formatted
    duration_formatted=$(format_duration "$duration_seconds" "true")
    
    # Format project with description
    local project_display="$project"
    if [[ -n "$desc" ]]; then
        project_display="$project - $desc"
    fi
    
    # Print formatted row
    printf "%-4s %-20s %-19s %-19s %-8s %-6s\n" \
        "$id" "$project_display" "$start_date" "$end_date" "$duration_formatted" "Live"
    
    # Show notes if available
    if [[ -n "$note" ]]; then
        printf "     📝 %s\n" "$note"
    fi
}

# Function: print_past_row_raw
# Description: Prints a raw row for past session display (CSV/epoch format for --raw flag)
# Usage: print_past_row_raw <start_ts> <end_ts> <project> <desc> <note>
# Parameters:
#   $1 - start_ts: Start timestamp (epoch or ISO format)
#   $2 - end_ts: End timestamp (epoch or ISO format)
#   $3 - project: Project name
#   $4 - desc: Description (optional)
#   $5 - note: Session notes (optional)
# Returns:
#   0 - Success: Prints raw CSV row to stdout
# Side Effects:
#   - Prints raw session information to stdout
# Dependencies:
#   - date command with --date support
# Examples:
#   print_past_row_raw "1642248000" "1642251600" "meeting" "team sync" "productive discussion"
# Notes:
#   - Outputs CSV format: start_epoch,end_epoch,project,description,notes
#   - Converts ISO timestamps to epoch if needed
#   - Suitable for --raw flag output
print_past_row_raw() {
    local start_ts="$1"
    local end_ts="$2"
    local project="$3"
    local desc="$4"
    local note="$5"
    
    # Convert to epoch timestamps if needed
    local start_epoch
    local end_epoch
    if [[ "$start_ts" =~ ^[0-9]+$ ]]; then
        start_epoch="$start_ts"
    else
        start_epoch=$(date --date="$start_ts" +%s 2>/dev/null || echo "$start_ts")
    fi
    
    if [[ "$end_ts" =~ ^[0-9]+$ ]]; then
        end_epoch="$end_ts"
    else
        end_epoch=$(date --date="$end_ts" +%s 2>/dev/null || echo "$end_ts")
    fi
    
    # Escape CSV fields
    local project_escaped
    local desc_escaped
    local note_escaped
    project_escaped=$(echo "$project" | sed 's/"/""/g')
    desc_escaped=$(echo "${desc:-}" | sed 's/"/""/g')
    note_escaped=$(echo "${note:-}" | sed 's/"/""/g')
    
    # Print CSV row
    echo "\"$start_epoch\",\"$end_epoch\",\"$project_escaped\",\"$desc_escaped\",\"$note_escaped\""
}

# Function: print_report_header
# Description: Prints a formatted header for focus reports
# Usage: print_report_header <title> <start_date> <end_date>
# Parameters:
#   $1 - title: Report title
#   $2 - start_date: Start date for the report period
#   $3 - end_date: End date for the report period
# Returns:
#   0 - Success: Prints formatted header to stdout
# Side Effects:
#   - Prints formatted report header to stdout
# Examples:
#   print_report_header "Today's Focus Report" "2025-01-15" "2025-01-15"
# Notes:
#   - Formats dates consistently
#   - Handles single-day reports (start_date == end_date)
print_report_header() {
    local title="$1"
    local start_date="$2"
    local end_date="$3"
    
    echo "📊 $title"
    echo "$(printf '=%.0s' $(seq 1 ${#title}))"
    
    if [[ "$start_date" == "$end_date" ]]; then
        echo "Period: $start_date"
    else
        echo "Period: $start_date to $end_date"
    fi
    echo
}

# Function: print_report_summary
# Description: Prints a formatted summary section for focus reports
# Usage: print_report_summary <total_sessions> <total_duration> <projects_count>
# Parameters:
#   $1 - total_sessions: Total number of sessions
#   $2 - total_duration: Total duration in seconds
#   $3 - projects_count: Number of active projects
# Returns:
#   0 - Success: Prints formatted summary to stdout
# Side Effects:
#   - Prints formatted summary to stdout
# Examples:
#   print_report_summary "5" "7200" "3"
# Notes:
#   - Converts duration to hours and minutes
#   - Formats numbers consistently
print_report_summary() {
    local total_sessions="$1"
    local total_duration="$2"
    local projects_count="$3"
    
    local total_hours=$((total_duration / 3600))
    local total_minutes=$(((total_duration % 3600) / 60))
    
    echo "📈 Summary:"
    echo "   Total focus time: ${total_hours}h ${total_minutes}m"
    echo "   Total sessions: $total_sessions"
    echo "   Active projects: $projects_count"
    echo
}

# Function: print_report_project_row
# Description: Prints a formatted project row for focus reports
# Usage: print_report_project_row <project> <sessions> <duration> <earliest_start> <latest_end>
# Parameters:
#   $1 - project: Project name
#   $2 - sessions: Number of sessions for this project
#   $3 - duration: Total duration in seconds
#   $4 - earliest_start: Earliest session start time
#   $5 - latest_end: Latest session end time
# Returns:
#   0 - Success: Prints formatted project row to stdout
# Side Effects:
#   - Prints formatted project information to stdout
# Examples:
#   print_report_project_row "coding" "3" "5400" "2025-01-15T09:00:00" "2025-01-15T17:00:00"
# Notes:
#   - Formats duration as hours and minutes
#   - Formats date range consistently
print_report_project_row() {
    local project="$1"
    local sessions="$2"
    local duration="$3"
    local earliest_start="$4"
    local latest_end="$5"
    
    local proj_hours=$((duration / 3600))
    local proj_minutes=$(((duration % 3600) / 60))
    
    # Format date range
    local start_date end_date
    start_date=$(date --date="$earliest_start" +"%Y-%m-%d" 2>/dev/null || echo "$earliest_start")
    end_date=$(date --date="$latest_end" +"%Y-%m-%d" 2>/dev/null || echo "$latest_end")
    
    local date_display
    if [[ "$start_date" == "$end_date" ]]; then
        date_display="$start_date"
    else
        date_display="$start_date to $end_date"
    fi
    
    printf "%-20s %-8s %-12s %-20s\n" \
        "$project" "$sessions" "${proj_hours}h ${proj_minutes}m" "$date_display"
}

# Function: print_report_footer
# Description: Prints a formatted footer for focus reports
# Usage: print_report_footer <report_filename> [raw_mode]
# Parameters:
#   $1 - report_filename: Name of the generated report file
#   $2 - raw_mode: Whether in raw mode (optional, default: false)
# Returns:
#   0 - Success: Prints formatted footer to stdout
# Side Effects:
#   - Prints formatted footer to stdout
# Examples:
#   print_report_footer "focus-report-2025-01-15.md"
# Notes:
#   - Only shows file message in non-raw mode
print_report_footer() {
    local report_filename="$1"
    local raw_mode="${2:-false}"
    
    if [[ "$raw_mode" != "true" ]]; then
        echo "📄 Detailed report saved to: $report_filename"
    fi
}

# Function: print_report_row_raw
# Description: Prints a raw CSV row for focus reports (for --raw flag)
# Usage: print_report_row_raw <project> <start_time> <end_time> <duration> <notes> <duration_only> <session_date>
# Parameters:
#   $1 - project: Project name
#   $2 - start_time: Session start time
#   $3 - end_time: Session end time
#   $4 - duration: Session duration in seconds
#   $5 - notes: Session notes
#   $6 - duration_only: Whether this is a duration-only session (1 or 0)
#   $7 - session_date: Session date for duration-only sessions
# Returns:
#   0 - Success: Prints raw CSV row to stdout
# Side Effects:
#   - Prints raw session information to stdout
# Examples:
#   print_report_row_raw "coding" "2025-01-15T09:00:00" "2025-01-15T11:00:00" "7200" "productive session" "0" ""
# Notes:
#   - Outputs CSV format suitable for --raw flag
#   - Escapes CSV fields properly
print_report_row_raw() {
    local project="$1"
    local start_time="$2"
    local end_time="$3"
    local duration="$4"
    local notes="$5"
    local duration_only="$6"
    local session_date="$7"
    
    # Escape CSV fields
    local project_escaped
    local notes_escaped
    project_escaped=$(echo "$project" | sed 's/"/""/g')
    notes_escaped=$(echo "${notes:-}" | sed 's/"/""/g')
    
    echo "$project_escaped,$start_time,$end_time,$duration,$notes_escaped,$duration_only,$session_date"
}

# Export functions for use in other scripts
export -f format_duration
export -f format_duration_minutes
export -f format_duration_hours_minutes
export -f refocus_format_duration
export -f format_ts
export -f format_timestamp
export -f format_project_with_description
export -f print_session_row
export -f format_session_summary
export -f print_status
export -f format_focus_status
export -f format_paused_status
export -f format_last_session
export -f format_error
export -f format_success
export -f format_warning
export -f format_info
export -f format_table_header
export -f format_config_display
export -f format_usage
export -f format_section_header
export -f write_prompt_cache
export -f print_past_row
export -f print_past_row_raw
export -f print_report_header
export -f print_report_summary
export -f print_report_project_row
export -f print_report_footer
export -f print_report_row_raw
