#!/usr/bin/env bash
# Refocus Shell - Output Formatting Module
# Copyright (c) 2025 PeGa
# Licensed under the GNU General Public License v3

# This module provides common output formatting functions for refocus commands
# to ensure consistent, clean, and user-friendly display.

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

# Function to print status message
# Usage: print_status <message>
print_status() {
    echo -e "\033[0;34m[INFO]\033[0m $1"
}

# Function: print_past_row
# Description: Prints a formatted row for past session display (human-readable format)
# Usage: print_past_row <id> <start_ts> <end_ts> <project> <desc> <note>
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

# Function: print_report_table_header
# Description: Print header for report table (human format)
# Usage: print_report_table_header
print_report_table_header() {
    echo "project,start_time,end_time,duration_seconds,notes,duration_only,session_date"
}

# Function: print_report_table_row
# Description: Print human-readable row for report sessions
# Usage: print_report_table_row <session_num> <project> <start> <end> <duration> <notes> <duration_only> <session_date>
print_report_table_row() {
    local session_num="$1"
    local project="$2"
    local start="$3"
    local end="$4"
    local duration="$5"
    local notes="$6"
    local duration_only="$7"
    local session_date="$8"
    
    if [[ "$project" == "[idle]" ]]; then
        return 0
    fi
    
    local duration_min=$((duration / 60))
    local duration_hours=$((duration / 3600))
    local duration_remaining_min=$(((duration % 3600) / 60))
    
    local duration_display
    if [[ $duration_hours -gt 0 ]]; then
        duration_display="${duration_hours}h ${duration_remaining_min}m"
    else
        duration_display="${duration_min}m"
    fi
    
    if [[ "$duration_only" == "1" ]]; then
        # Duration-only session
        local session_date_display
        local session_epoch
        session_epoch=$(date -d "$session_date" +%s)
        session_date_display=$(format_ts "$session_epoch" "%Y-%m-%d")
        echo "$session_num. **$project** (Manual entry: $session_date_display, $duration_display)"
    else
        # Regular session
        local start_date end_date
        local start_epoch end_epoch
        start_epoch=$(date -d "$start" +%s)
        end_epoch=$(date -d "$end" +%s)
        start_date=$(format_ts "$start_epoch" "%Y-%m-%d %H:%M")
        end_date=$(format_ts "$end_epoch" "%H:%M")
        echo "$session_num. **$project** ($start_date - $end_date, $duration_display)"
    fi
    
    # Show notes with proper line breaks
    if [[ -n "$notes" ]]; then
        echo "   - $notes"
    else
        # If no session notes, try to show project description
        local project_desc
        project_desc=$(get_project_description "$project")
        if [[ -n "$project_desc" ]]; then
            echo "   - $project_desc"
        fi
    fi
    echo ""
}

# Function: print_report_table_footer
# Description: Print footer for report table (human format)
# Usage: print_report_table_footer
print_report_table_footer() {
    # Empty footer for now, can be extended if needed
    :
}

# Function to write current focus state to prompt cache files
# Usage: write_prompt_cache <status> <project> <minutes>
write_prompt_cache() {
    local dir
    if [[ -n "${REFOCUS_STATE_DIR:-}" ]]; then
        dir="$REFOCUS_STATE_DIR"
    elif [[ -n "${XDG_STATE_HOME:-}" ]]; then
        dir="$XDG_STATE_HOME/refocus"
    else
        dir="$HOME/.local/refocus"
    fi
    mkdir -p "$dir" 2>/dev/null || true
    printf "%s|%s|%s\n" "${1:-idle}" "${2:--}" "${3:--}" >"$dir/prompt.cache"
    date +%s >"$dir/prompt.ver"
}

# Export functions for use in other scripts
export -f format_duration
export -f format_ts
# Function: print_past_table_header
# Description: Print header for past sessions table (human format)
# Usage: print_past_table_header
print_past_table_header() {
    printf "%-4s %-20s %-19s %-19s %-8s %-6s\n" "ID" "Project" "Start" "End" "Duration" "Type"
    echo "---- -------------------- ------------------- ------------------- -------- ------"
}

# Function: print_past_table_footer
# Description: Print footer for past sessions table (human format)
# Usage: print_past_table_footer
print_past_table_footer() {
    # Empty footer for now, can be extended if needed
    :
}

# Function: print_past_table_row_raw
# Description: Print raw CSV row for past sessions
# Usage: print_past_table_row_raw <id> <start_ts> <end_ts> <project> <desc> <note>
print_past_table_row_raw() {
    local id="$1"
    local start_ts="$2"
    local end_ts="$3"
    local project="$4"
    local desc="$5"
    local note="$6"
    
    echo "$id,$start_ts,$end_ts,$project,$desc,$note"
}

export -f print_session_row
export -f print_status
export -f print_past_row
export -f print_past_row_raw
export -f print_report_header
export -f print_report_summary
export -f print_report_project_row
export -f print_report_footer
export -f print_report_row_raw
export -f write_prompt_cache
export -f print_past_table_header
export -f print_past_table_footer
export -f print_past_table_row_raw
export -f print_report_table_header
export -f print_report_table_row
export -f print_report_table_footer