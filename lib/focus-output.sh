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
# Usage: format_timestamp <timestamp> [format]
format_timestamp() {
    local timestamp="$1"
    local format="${2:-%Y-%m-%d %H:%M}"
    
    if [[ -z "$timestamp" ]] || [[ "$timestamp" == "N/A" ]]; then
        echo "N/A"
        return
    fi
    
    date --date="$timestamp" "+$format" 2>/dev/null || echo "N/A"
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

# Function to format session summary
# Usage: format_session_summary <project> <start> <end> <duration> <type> [notes]
format_session_summary() {
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
    formatted_start=$(format_timestamp "$start")
    formatted_end=$(format_timestamp "$end")
    
    printf "%-20s %-19s %-19s %-8s %-6s\n" \
        "$project" "$formatted_start" "$formatted_end" "$formatted_duration" "$type"
    
    if [[ -n "$notes" ]]; then
        echo "     📝 $notes"
    fi
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
    local dir="${REFOCUS_STATE_DIR:-$HOME/.local/refocus}"
    mkdir -p "$dir"
    printf "%s|%s|%s\n" "${1:-idle}" "${2:--}" "${3:--}" >"$dir/prompt.cache"
    date +%s >"$dir/prompt.ver"
}

# Export functions for use in other scripts
export -f format_duration
export -f format_timestamp
export -f format_project_with_description
export -f format_session_summary
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
