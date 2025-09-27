#!/usr/bin/env bash
# Refocus Shell Utilities Library
# Copyright (C) 2025 Pablo Gonzalez
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

# Verbose mode flag
VERBOSE="${VERBOSE:-false}"

# Error logging configuration
REFOCUS_LOG_DIR="${REFOCUS_LOG_DIR:-$HOME/.local/refocus}"
REFOCUS_ERROR_LOG="${REFOCUS_ERROR_LOG:-$REFOCUS_LOG_DIR/error.log}"

# Function to log errors to file
log_error() {
    local error_message="$1"
    local context="${2:-unknown}"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Ensure log directory exists
    mkdir -p "$REFOCUS_LOG_DIR"
    
    # Log to file
    echo "[$timestamp] [$context] $error_message" >> "$REFOCUS_ERROR_LOG"
}

# Function to execute SQLite command with proper error handling and edge case checks
execute_sqlite() {
    local sql_command="$1"
    local context="${2:-sqlite}"
    local output
    local exit_code
    
    # Perform pre-operation checks for write operations
    if [[ "$sql_command" =~ ^(INSERT|UPDATE|DELETE|CREATE|DROP|ALTER) ]]; then
        if ! pre_database_operation_check "$context"; then
            echo "❌ Pre-operation checks failed for: $context" >&2
            return 1
        fi
    fi
    
    # Execute SQLite command and capture both output and exit code
    output=$(sqlite3 "$DB" "$sql_command" 2>&1)
    exit_code=$?
    
    # Handle specific error cases
    if [[ $exit_code -ne 0 ]]; then
        # Check for disk space errors
        if [[ "$output" =~ "disk I/O error" ]] || [[ "$output" =~ "database or disk is full" ]]; then
            echo "❌ Disk space error detected" >&2
            echo "   Available space: $(df -h "$(dirname "$DB")" | awk 'NR==2 {print $4}')" >&2
            log_error "Disk space error: $output" "$context"
            return 5  # File system error
        fi
        
        # Check for permission errors
        if [[ "$output" =~ "permission denied" ]] || [[ "$output" =~ "readonly database" ]]; then
            echo "❌ Permission error detected" >&2
            echo "   Database file: $DB" >&2
            echo "   File permissions: $(ls -la "$DB" 2>/dev/null || echo 'File not accessible')" >&2
            log_error "Permission error: $output" "$context"
            return 4  # Permission error
        fi
        
        # Check for database corruption
        if [[ "$output" =~ "database disk image is malformed" ]] || [[ "$output" =~ "corrupt" ]]; then
            echo "❌ Database corruption detected" >&2
            echo "   Attempting recovery..." >&2
            log_error "Database corruption: $output" "$context"
            
            # Attempt recovery
            if attempt_database_recovery; then
                echo "✅ Database recovered, retrying operation..." >&2
                # Retry the operation
                output=$(sqlite3 "$DB" "$sql_command" 2>&1)
                exit_code=$?
                if [[ $exit_code -eq 0 ]]; then
                    echo "$output"
                    return 0
                fi
            fi
            
            return 3  # Database error
        fi
        
        # Log other errors
        log_error "SQLite error (exit code: $exit_code): $output" "$context"
        log_error "SQL command: $sql_command" "$context"
        return $exit_code
    fi
    
    # Return the output
    echo "$output"
    return 0
}


# Function to show user-friendly error message
show_error_info() {
    echo "More information can be found at: $REFOCUS_ERROR_LOG"
}

# Function to print verbose messages
verbose_echo() {
    if [[ "$VERBOSE" == "true" ]]; then
        echo "$1"
    fi
}

# Function to get current timestamp in ISO format
get_current_timestamp() {
    date -Iseconds
}

# Function to get timestamp for a specific time
get_timestamp_for_time() {
    local time_spec="$1"
    date -Iseconds -d "$time_spec"
}

# Function to calculate duration between two timestamps
calculate_duration() {
    local start_time="$1"
    local end_time="$2"
    
    local start_ts
    start_ts=$(date --date="$start_time" +%s)
    local end_ts
    end_ts=$(date --date="$end_time" +%s)
    
    echo $((end_ts - start_ts))
}

# Function to parse duration string (e.g., "1h30m", "2h", "45m") to seconds
parse_duration() {
    local duration_str="$1"
    local total_seconds=0
    
    # Validate input
    if [[ -z "$duration_str" ]]; then
        echo "❌ Duration is required" >&2
        return 1
    fi
    
    # Remove any whitespace
    duration_str=$(echo "$duration_str" | tr -d ' ')
    
    # Check if it's a decimal hour format (e.g., "1.5h", "0.5h")
    if [[ "$duration_str" =~ ^([0-9]+\.?[0-9]*)h$ ]]; then
        local hours="${BASH_REMATCH[1]}"
        local hours_int=$(echo "$hours * 3600" | bc -l)
        total_seconds=$(echo "$hours_int" | cut -d'.' -f1)
    # Check for hour+minute format (e.g., "1h30m", "2h45m")
    elif [[ "$duration_str" =~ ^([0-9]+)h([0-9]+)m$ ]]; then
        local hours="${BASH_REMATCH[1]}"
        local minutes="${BASH_REMATCH[2]}"
        total_seconds=$((hours * 3600 + minutes * 60))
    # Check for hours only (e.g., "2h", "1h")
    elif [[ "$duration_str" =~ ^([0-9]+)h$ ]]; then
        local hours="${BASH_REMATCH[1]}"
        total_seconds=$((hours * 3600))
    # Check for minutes only (e.g., "45m", "90m")
    elif [[ "$duration_str" =~ ^([0-9]+)m$ ]]; then
        local minutes="${BASH_REMATCH[1]}"
        total_seconds=$((minutes * 60))
    else
        echo "❌ Invalid duration format: $duration_str" >&2
        echo "   Supported formats: 1h30m, 2h, 45m, 1.5h, 0.5h" >&2
        return 1
    fi
    
    echo "$total_seconds"
}

# Function to format duration in minutes
format_duration_minutes() {
    local duration_seconds="$1"
    echo $((duration_seconds / 60))
}

# Function to format duration in hours and minutes
format_duration_hours_minutes() {
    local duration_seconds="$1"
    local hours=$((duration_seconds / 3600))
    local minutes=$(((duration_seconds % 3600) / 60))
    echo "${hours}h ${minutes}m"
}

# Function to validate numeric input
validate_numeric_input() {
    local input="$1"
    local description="$2"
    
    if ! [[ "$input" =~ ^[0-9]+$ ]]; then
        echo "❌ $description must be a positive integer."
        return 1
    fi
    return 0
}

# Function to validate project name
validate_project_name() {
    local project="$1"
    
    if [[ -z "$project" ]]; then
        echo "❌ Project name cannot be empty."
        return 1
    fi
    
    # Check for maximum length (reasonable limit)
    if [[ ${#project} -gt 100 ]]; then
        echo "❌ Project name is too long (max 100 characters)."
        return 1
    fi
    
    # Check for dangerous characters that could cause SQL issues
    if [[ "$project" =~ [\"\\] ]]; then
        echo "❌ Project name contains invalid characters (quotes or backslashes)."
        return 1
    fi
    
    # Check for control characters
    if [[ "$project" =~ [[:cntrl:]] ]]; then
        echo "❌ Project name contains control characters."
        return 1
    fi
    
    return 0
}

# Function to validate and convert timestamp format
validate_timestamp() {
    local timestamp="$1"
    local description="${2:-timestamp}"
    
    if [[ -z "$timestamp" ]]; then
        echo "❌ $description cannot be empty."
        return 1
    fi
    
    # Check if it's already in ISO format
    if [[ "$timestamp" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}([+-][0-9]{2}:[0-9]{2}|Z)?$ ]]; then
        # Already in ISO format, just validate it
        if ! date --date="$timestamp" >/dev/null 2>&1; then
            echo "❌ $description is not a valid date/time."
            return 1
        fi
        return 0
    fi
    
    # Check for new YYYY/MM/DD-HH:MM format
    if [[ "$timestamp" =~ ^[0-9]{4}/[0-9]{2}/[0-9]{2}-[0-9]{2}:[0-9]{2}$ ]]; then
        # Convert YYYY/MM/DD-HH:MM to ISO format
        local year month day hour minute
        
        # Parse YYYY/MM/DD-HH:MM format
        year=$(echo "$timestamp" | cut -d'/' -f1)
        month=$(echo "$timestamp" | cut -d'/' -f2)
        day=$(echo "$timestamp" | cut -d'/' -f3 | cut -d'-' -f1)
        hour=$(echo "$timestamp" | cut -d'-' -f2 | cut -d':' -f1)
        minute=$(echo "$timestamp" | cut -d'-' -f2 | cut -d':' -f2)
        
        # Validate the components (force decimal interpretation to avoid octal issues)
        if [[ $((10#$year)) -lt 1900 ]] || [[ $((10#$year)) -gt 2100 ]]; then
            echo "❌ $description has invalid year: $year"
            return 1
        fi
        
        if [[ $((10#$month)) -lt 1 ]] || [[ $((10#$month)) -gt 12 ]]; then
            echo "❌ $description has invalid month: $month"
            return 1
        fi
        
        if [[ $((10#$day)) -lt 1 ]] || [[ $((10#$day)) -gt 31 ]]; then
            echo "❌ $description has invalid day: $day"
            return 1
        fi
        
        if [[ $((10#$hour)) -lt 0 ]] || [[ $((10#$hour)) -gt 23 ]]; then
            echo "❌ $description has invalid hour: $hour"
            return 1
        fi
        
        if [[ $((10#$minute)) -lt 0 ]] || [[ $((10#$minute)) -gt 59 ]]; then
            echo "❌ $description has invalid minute: $minute"
            return 1
        fi
        
        # Convert to ISO format
        local iso_timestamp
        iso_timestamp=$(date --date="$year-$month-$day $hour:$minute" -Iseconds 2>/dev/null)
        
        if [[ $? -ne 0 ]]; then
            echo "❌ $description is not a valid date/time."
            return 1
        fi
        
        echo "$iso_timestamp"
        return 0
    fi
    
    # Check for hour-based relative formats only
    if [[ "$timestamp" =~ ^[0-9]+[hm]$ ]]; then
        local number unit converted_timestamp
        number=$(echo "$timestamp" | sed 's/[hm]$//')
        unit=$(echo "$timestamp" | sed 's/^[0-9]*//')
        
        # Validate number is reasonable (max 24 for hours, max 59 for minutes)
        if [[ "$unit" == "h" ]]; then
            if [[ "$number" -lt 1 ]] || [[ "$number" -gt 24 ]]; then
                echo "❌ $description: Hours must be between 1 and 24 (got: ${number}h)"
                return 1
            fi
        elif [[ "$unit" == "m" ]]; then
            if [[ "$number" -lt 1 ]] || [[ "$number" -gt 59 ]]; then
                echo "❌ $description: Minutes must be between 1 and 59 (got: ${number}m)"
                return 1
            fi
        fi
        
        # Convert to relative time format that date can understand
        if [[ "$unit" == "h" ]]; then
            converted_timestamp=$(date --date="$number hours ago" -Iseconds 2>/dev/null)
        else
            converted_timestamp=$(date --date="$number minutes ago" -Iseconds 2>/dev/null)
        fi
        
        if [[ $? -ne 0 ]]; then
            echo "❌ $description: Failed to convert time format"
            return 1
        fi
        
        echo "$converted_timestamp"
        return 0
    fi
    
    # Check for invalid relative time formats (days, weeks, months, years)
    if [[ "$timestamp" =~ ^[0-9]+[dwmy]$ ]]; then
        echo "❌ $description: Invalid time format '$timestamp'"
        echo "Only hour-based formats are supported (e.g., 7h, 30m)"
        echo "Days, weeks, months, and years are not allowed for focus sessions"
        return 1
    fi
    
    # Try to parse and convert to ISO format (for backward compatibility)
    local converted_timestamp
    converted_timestamp=$(date --date="$timestamp" -Iseconds 2>/dev/null)
    
    if [[ $? -ne 0 ]]; then
        echo "❌ $description format not recognized."
        echo "Supported formats:"
        echo "  - YYYY/MM/DD-HH:MM (recommended: 2025/07/30-14:30)"
        echo "  - HH:MM (today's date)"
        echo "  - 'YYYY-MM-DD HH:MM' (quoted datetime)"
        echo "  - 'YYYY-MM-DDTHH:MM' (ISO format)"
        echo "  - Full ISO format (YYYY-MM-DDTHH:MM:SS±HH:MM)"
        echo "  - Hour-based relative times (7h, 30m, etc.)"
        echo "  - 'now' for current time"
        echo ""
        echo "Examples:"
        echo "  focus past add meeting 2025/07/30-14:15 2025/07/30-15:30"
        echo "  focus past add meeting 14:15 15:30  # Today's date"
        echo "  focus past add meeting 7h now        # 7 hours ago until now"
        echo "  focus past add meeting 30m now       # 30 minutes ago until now"
        return 1
    fi
    
    # Return the converted timestamp
    echo "$converted_timestamp"
    return 0
}

# Function to validate time range
validate_time_range() {
    local start_time="$1"
    local end_time="$2"
    
    if ! validate_timestamp "$start_time" "Start time"; then
        return 1
    fi
    
    if ! validate_timestamp "$end_time" "End time"; then
        return 1
    fi
    
    # Check that end time is after start time
    local start_ts
    start_ts=$(date --date="$start_time" +%s)
    local end_ts
    end_ts=$(date --date="$end_time" +%s)
    
    if [[ $end_ts -le $start_ts ]]; then
        echo "❌ End time must be after start time."
        return 1
    fi
    
    return 0
}

# Function to validate file path
validate_file_path() {
    local file_path="$1"
    local description="${2:-file}"
    
    if [[ -z "$file_path" ]]; then
        echo "❌ $description path cannot be empty."
        return 1
    fi
    
    # Check for dangerous characters
    if [[ "$file_path" =~ [\"\\] ]]; then
        echo "❌ $description path contains invalid characters."
        return 1
    fi
    
    # Check for control characters
    if [[ "$file_path" =~ [[:cntrl:]] ]]; then
        echo "❌ $description path contains control characters."
        return 1
    fi
    
    return 0
}

# Function to sanitize project name
sanitize_project_name() {
    local project="$1"
    
    # Remove leading/trailing whitespace
    project=$(echo "$project" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    
    # Replace multiple spaces with single space
    project=$(echo "$project" | sed 's/[[:space:]]\+/ /g')
    
    # Truncate if too long
    if [[ ${#project} -gt 100 ]]; then
        project="${project:0:97}..."
    fi
    
    echo "$project"
}

# Function to validate session ID
validate_session_id() {
    local session_id="$1"
    
    if ! validate_numeric_input "$session_id" "Session ID"; then
        return 1
    fi
    
    # Check if session exists in database
    if [[ -f "$(dirname "$0")/focus-db.sh" ]]; then
        source "$(dirname "$0")/focus-db.sh"
    fi
    
    local session_exists
    session_exists=$(sqlite3 "$DB" "SELECT COUNT(*) FROM $SESSIONS_TABLE WHERE rowid = $session_id;" 2>/dev/null)
    
    if [[ "$session_exists" -eq 0 ]]; then
        echo "❌ Session ID $session_id does not exist."
        return 1
    fi
    
    return 0
}

# Function to check if focus is active
is_focus_active() {
    # Source the database library to use its functions
    if [[ -f "$(dirname "$0")/focus-db.sh" ]]; then
        source "$(dirname "$0")/focus-db.sh"
    fi
    
    local state
    local old_ifs
    local active
    local current_project
    local start_time
    state=$(get_focus_state)
    if [[ -n "$state" ]]; then
        old_ifs="$IFS"
        IFS='|' read -r active current_project start_time <<< "$state"
        IFS="$old_ifs"
        if [[ "$active" -eq 1 ]]; then
            return 0  # Active
        fi
    fi
    return 1  # Not active
}

# Function to check if refocus shell is disabled
is_focus_disabled() {
    # Source the database library to use its functions
    if [[ -f "$(dirname "$0")/focus-db.sh" ]]; then
        source "$(dirname "$0")/focus-db.sh"
    fi
    
    local focus_disabled
    focus_disabled=$(get_focus_disabled)
    if [[ "$focus_disabled" -eq 1 ]]; then
        return 0  # Disabled
    fi
    
    return 1  # Enabled
}

# Function to send notification if available
send_notification() {
    local title="$1"
    local message="$2"
    
    if command -v notify-send >/dev/null 2>&1; then
        notify-send "$title" "$message"
    fi
}

# Function to check if update-prompt function is available
is_update_prompt_available() {
    type update-prompt >/dev/null 2>&1
}

# Function to get the current prompt or fallback to default
get_current_prompt() {
    # Always use the standard Ubuntu prompt as fallback since current PS1 is broken
    echo '${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
}

# Function to create focus prompt string
create_focus_prompt() {
    local project="$1"
    echo '⏳ ['$project'] ${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
}

# Function to create default prompt string
create_default_prompt() {
    echo '${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
}

# Function to set focus prompt
set_focus_prompt() {
    local project="$1"
    
    # Create focus prompt
    local focus_prompt
    focus_prompt=$(create_focus_prompt "$project")
    
    # Update database with focus prompt
    update_prompt_content "$focus_prompt" "focus"
    
    # Try multiple methods to update the prompt
    local prompt_updated=false
    
    # Method 1: Try to call update-prompt function if available
    if type update-prompt >/dev/null 2>&1; then
        update-prompt
        prompt_updated=true
        verbose_echo "Focus prompt set via update-prompt function"
    fi
    
    # Method 2: Try to source the shell integration directly
    if [[ "$prompt_updated" == "false" ]] && [[ -f "$HOME/.local/refocus/shell-integration.sh" ]]; then
        source "$HOME/.local/refocus/shell-integration.sh" 2>/dev/null
        if type update-prompt >/dev/null 2>&1; then
            update-prompt
            prompt_updated=true
            verbose_echo "Focus prompt set via sourced shell integration"
        fi
    fi
    
    # Method 3: Direct PS1 export as fallback
    if [[ "$prompt_updated" == "false" ]]; then
        export PS1="$focus_prompt"
        prompt_updated=true
        verbose_echo "Focus prompt set via direct PS1 export"
    fi
    
    verbose_echo "Focus prompt set for project: $project"
    
    # Show appropriate message based on method used
    if [[ "$prompt_updated" == "true" ]]; then
        verbose_echo "Tip: Run 'update-prompt' to update the current terminal prompt"
        verbose_echo "Note: New terminals will automatically show the focus prompt"
    else
        echo "Warning: Could not update prompt automatically"
        echo "Run 'update-prompt' to update the current terminal prompt"
    fi
}

# Function to restore original prompt
restore_original_prompt() {
    # Get original prompt from database
    local original_prompt
    original_prompt=$(get_prompt_content_by_type "original")
    
    # If no original prompt found, use default
    if [[ -z "$original_prompt" ]]; then
        original_prompt=$(create_default_prompt)
    fi
    
    # Update database with default prompt
    update_prompt_content "$original_prompt" "default"
    
    # Try multiple methods to update the prompt
    local prompt_updated=false
    
    # Method 1: Try to call update-prompt function if available
    if type update-prompt >/dev/null 2>&1; then
        update-prompt
        prompt_updated=true
        verbose_echo "Original prompt restored via update-prompt function"
    fi
    
    # Method 2: Try to source the shell integration directly
    if [[ "$prompt_updated" == "false" ]] && [[ -f "$HOME/.local/refocus/shell-integration.sh" ]]; then
        source "$HOME/.local/refocus/shell-integration.sh" 2>/dev/null
        if type update-prompt >/dev/null 2>&1; then
            update-prompt
            prompt_updated=true
            verbose_echo "Original prompt restored via sourced shell integration"
        fi
    fi
    
    # Method 3: Direct PS1 export as fallback
    if [[ "$prompt_updated" == "false" ]]; then
        export PS1="$original_prompt"
        prompt_updated=true
        verbose_echo "Original prompt restored via direct PS1 export"
    fi
    
    verbose_echo "Original prompt restored"
    
    # Show appropriate message based on method used
    if [[ "$prompt_updated" == "true" ]]; then
        verbose_echo "Tip: Run 'update-prompt' to update the current terminal prompt"
        verbose_echo "Note: New terminals will automatically show the normal prompt"
    else
        echo "Warning: Could not restore prompt automatically"
        echo "Run 'update-prompt' to update the current terminal prompt"
    fi
}

# Function to truncate long project names for display
truncate_project_name() {
    local project="$1"
    local max_length="${2:-33}"
    
    if [[ ${#project} -gt $max_length ]]; then
        echo "${project:0:$((max_length-3))}..."
    else
        echo "$project"
    fi
}

# Function to get time period start/end for reports
get_today_period() {
    local start_time
    start_time=$(get_timestamp_for_time "today 00:00")
    local end_time
    end_time=$(get_current_timestamp)
    echo "$start_time|$end_time"
}

get_week_period() {
    local start_time
    # Use last 7 days instead of calendar week alignment
    start_time=$(get_timestamp_for_time "7 days ago 00:00")
    local end_time
    end_time=$(get_current_timestamp)
    echo "$start_time|$end_time"
}

get_month_period() {
    local start_time
    start_time=$(get_timestamp_for_time "$(date +%Y-%m-01) 00:00")
    local end_time
    end_time=$(get_current_timestamp)
    echo "$start_time|$end_time"
}

get_custom_period() {
    local days_back="$1"
    local start_time
    start_time=$(get_timestamp_for_time "$days_back days ago 00:00")
    local end_time
    end_time=$(get_current_timestamp)
    echo "$start_time|$end_time"
} 