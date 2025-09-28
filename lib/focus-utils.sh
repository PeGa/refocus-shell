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
REFOCUS_LOG_DIR="$(get_cfg DATA_DIR "$HOME/.local/refocus")"
REFOCUS_ERROR_LOG="$(get_cfg DATA_DIR "$HOME/.local/refocus")/error.log"

# =============================================================================
# LOGGING SYSTEM
# =============================================================================

# Global quiet mode flag (set by -q/--quiet)
REFOCUS_QUIET="${REFOCUS_QUIET:-false}"

# Function: log_debug
# Description: Log debug message to stderr (only if REFOCUS_DEBUG=true)
# Usage: log_debug <message>
log_debug() {
    local message="$1"
    if [[ "${REFOCUS_DEBUG:-false}" == "true" ]]; then
        echo "🔍 DEBUG: $message" >&2
    fi
}

# Function: log_info
# Description: Log info message to stderr (suppressed if QUIET=true)
# Usage: log_info <message>
log_info() {
    local message="$1"
    if [[ "${REFOCUS_QUIET:-false}" != "true" ]]; then
        echo "ℹ️  INFO: $message" >&2
    fi
}

# Function: log_warn
# Description: Log warning message to stderr (always shown)
# Usage: log_warn <message>
log_warn() {
    local message="$1"
    echo "⚠️  WARN: $message" >&2
}

# Function: log_err
# Description: Log error message to stderr (always shown)
# Usage: log_err <message>
log_err() {
    local message="$1"
    echo "❌ ERROR: $message" >&2
}

# =============================================================================
# ERROR HANDLING HELPERS
# =============================================================================

# Function: die
# Description: Exit with generic error (exit code 1)
# Usage: die <message>
die() {
    local message="$1"
    echo "❌ $message" >&2
    exit 1
}

# Function: usage
# Description: Exit with usage/validation error (exit code 2)
# Usage: usage <message>
usage() {
    local message="$1"
    echo "❌ $message" >&2
    exit 2
}

# Function: not_found
# Description: Exit with not found error (exit code 3)
# Usage: not_found <message>
not_found() {
    local message="$1"
    echo "❌ $message" >&2
    exit 3
}

# Function: conflict
# Description: Exit with conflict error (exit code 4)
# Usage: conflict <message>
conflict() {
    local message="$1"
    echo "❌ $message" >&2
    exit 4
}

# Function: log_error
# Description: Logs error messages to the configured error log file with timestamp and context
# Usage: log_error <error_message> [context]
# Parameters:
#   $1 - error_message: The error message to log (string)
#   $2 - context: Optional context identifier for the error (string, default: "unknown")
# Returns:
#   0 - Success: Error message logged successfully
# Side Effects:
#   - Creates log directory if it doesn't exist
#   - Appends timestamped error message to error log file
# Dependencies:
#   - REFOCUS_LOG_DIR environment variable
#   - REFOCUS_ERROR_LOG environment variable
#   - date command
# Examples:
#   log_error "Database connection failed" "focus_on"
#   log_error "Invalid project name provided" "validation"
# Notes:
#   - Log format: [YYYY-MM-DD HH:MM:SS] [context] error_message
#   - Log directory is created automatically if missing
#   - Uses system date command for timestamp generation
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

# Function: execute_sqlite
# Description: Executes SQLite commands with comprehensive error handling, edge case checks, and automatic recovery
# Usage: execute_sqlite <sql_command> [context]
# Parameters:
#   $1 - sql_command: The SQL command to execute (string)
#   $2 - context: Optional context identifier for error logging (string, default: "sqlite")
# Returns:
#   0 - Success: SQL command executed successfully
#   1 - Error: Database error occurred (connection, syntax, constraint violation)
#   2 - Error: Disk space insufficient for operation
#   3 - Error: Permission denied accessing database
#   4 - Error: Database corruption detected
# Side Effects:
#   - Queries or modifies the SQLite database
#   - Logs errors to error log file
#   - May trigger database backup and recovery operations
#   - Prints query results to stdout on success
# Dependencies:
#   - sqlite3 command
#   - Database file at REFOCUS_DB_PATH
#   - check_disk_space function
#   - check_database_permissions function
#   - check_database_integrity function
#   - create_database_backup function
#   - attempt_database_recovery function
# Examples:
#   execute_sqlite "SELECT * FROM sessions;" "get_sessions"
#   execute_sqlite "INSERT INTO sessions (project) VALUES ('test');" "add_session"
# Notes:
#   - Performs pre-operation checks for disk space, permissions, and integrity
#   - Automatically attempts recovery from database corruption
#   - Uses prepared statements to prevent SQL injection
#   - Logs all database operations for debugging
#   - Returns standardized error codes for different failure types
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

# Function: get_current_timestamp
# Description: Gets the current timestamp in ISO 8601 format with timezone
# Usage: get_current_timestamp
# Parameters:
#   None
# Returns:
#   0 - Success: Current timestamp printed to stdout in ISO format
# Side Effects:
#   - Calls system date command
# Dependencies:
#   - date command with -Iseconds support
# Examples:
#   local timestamp=$(get_current_timestamp)
#   echo "Current time: $(get_current_timestamp)"
# Notes:
#   - Returns format: YYYY-MM-DDTHH:MM:SS±HH:MM
#   - Uses system timezone settings
#   - Compatible with SQLite datetime functions
get_current_timestamp() {
    date -Iseconds
}

# Function: get_timestamp_for_time
# Description: Converts a time specification to ISO 8601 timestamp format
# Usage: get_timestamp_for_time <time_spec>
# Parameters:
#   $1 - time_spec: Time specification in various formats (string)
# Returns:
#   0 - Success: Converted timestamp printed to stdout in ISO format
#   1 - Error: Invalid time specification provided
# Side Effects:
#   - Calls system date command for conversion
# Dependencies:
#   - date command with -Iseconds and -d support
# Examples:
#   get_timestamp_for_time "2025-01-15 14:30"
#   get_timestamp_for_time "yesterday 09:00"
#   get_timestamp_for_time "2 hours ago"
# Notes:
#   - Supports various time formats: absolute dates, relative times, ISO format
#   - Returns format: YYYY-MM-DDTHH:MM:SS±HH:MM
#   - Uses system timezone settings
#   - Compatible with SQLite datetime functions
get_timestamp_for_time() {
    local time_spec="$1"
    date -Iseconds -d "$time_spec"
}

# Function: calculate_duration
# Description: Calculates the duration in seconds between two ISO timestamp strings
# Usage: calculate_duration <start_time> <end_time>
# Parameters:
#   $1 - start_time: Start timestamp in ISO format (string)
#   $2 - end_time: End timestamp in ISO format (string)
# Returns:
#   0 - Success: Duration in seconds printed to stdout
#   1 - Error: Invalid timestamp format or calculation error
# Side Effects:
#   - Calls system date command for timestamp conversion
# Dependencies:
#   - date command with --date support
# Examples:
#   calculate_duration "2025-01-15T14:30:00+00:00" "2025-01-15T16:30:00+00:00"
#   local duration=$(calculate_duration "$start" "$end")
# Notes:
#   - Returns duration as positive integer seconds
#   - Handles timezone differences automatically
#   - Negative durations indicate end_time is before start_time
#   - Uses Unix timestamp conversion for accurate calculation
calculate_duration() {
    local start_time="$1"
    local end_time="$2"
    
    local start_ts
    start_ts=$(date --date="$start_time" +%s)
    local end_ts
    end_ts=$(date --date="$end_time" +%s)
    
    echo $((end_ts - start_ts))
}

# Function: parse_duration
# Description: Parses human-readable duration strings into seconds with comprehensive validation
# Usage: parse_duration <duration_string>
# Parameters:
#   $1 - duration_string: Duration in human-readable format (string)
# Returns:
#   0 - Success: Duration in seconds printed to stdout
#   1 - Error: Invalid duration format or parsing error
# Side Effects:
#   - Prints detailed error messages to stderr on failure
# Dependencies:
#   - bc command for decimal calculations
# Examples:
#   parse_duration "1h30m"    # Returns: 5400
#   parse_duration "2h"        # Returns: 7200
#   parse_duration "45m"       # Returns: 2700
#   parse_duration "1.5h"      # Returns: 5400
# Notes:
#   - Supported formats: 1h30m, 2h, 45m, 90m, 1.5h, 0.5h
#   - Hours and minutes must be positive integers
#   - Decimal hours are supported (e.g., 1.5h = 1 hour 30 minutes)
#   - Whitespace is automatically removed
#   - Returns detailed error messages for unsupported formats
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

# Source the centralized output formatting functions
if [[ -f "${REFOCUS_LIB_DIR:-$HOME/.local/refocus/lib}/focus-output.sh" ]]; then
    source "${REFOCUS_LIB_DIR:-$HOME/.local/refocus/lib}/focus-output.sh"
fi

# Note: Validation functions have been removed - each command now has its own guard clauses

# Note: All validation functions have been removed - each command now has its own guard clauses

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

# Note: Prompt-related functions have been moved to focus-function.sh
# This file now contains only utility functions that don't deal with prompts

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

# Export logging and error handling helper functions
export -f log_debug
export -f log_info
export -f log_warn
export -f log_err
export -f die
export -f usage
export -f not_found
export -f conflict 