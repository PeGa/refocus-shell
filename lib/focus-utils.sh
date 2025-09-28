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

# Global quiet mode flag (set by -q/--quiet)
REFOCUS_QUIET="${REFOCUS_QUIET:-false}"

# =============================================================================
# LOGGING SYSTEM
# =============================================================================

log_debug() {
    local message="$1"
    if [[ "${REFOCUS_DEBUG:-false}" == "true" ]]; then
        echo "🔍 DEBUG: $message" >&2
    fi
}

log_info() {
    local message="$1"
    if [[ "${REFOCUS_QUIET:-false}" != "true" ]]; then
        echo "ℹ️  INFO: $message" >&2
    fi
}

log_warn() {
    local message="$1"
    echo "⚠️  WARN: $message" >&2
}

log_err() {
    local message="$1"
    echo "❌ ERROR: $message" >&2
}

# =============================================================================
# ERROR HANDLING HELPERS
# =============================================================================

die() {
    local message="$1"
    echo "❌ $message" >&2
    exit 1
}

usage() {
    local message="$1"
    echo "❌ $message" >&2
    exit 2
}

not_found() {
    local message="$1"
    echo "❌ $message" >&2
    exit 3
}

conflict() {
    local message="$1"
    echo "❌ $message" >&2
    exit 4
}

# =============================================================================
# TIME UTILITIES (PRIVATE)
# =============================================================================

now_epoch() {
    date +%s
}

start_of_today() {
    date --date="today 00:00" +%s
}

start_of_yesterday() {
    date --date="yesterday 00:00" +%s
}

start_of_week() {
    date --date="7 days ago 00:00" +%s
}

get_current_timestamp() {
    date -Iseconds
}

get_timestamp_for_time() {
    local time_spec="$1"
    date -Iseconds -d "$time_spec"
}

calculate_duration() {
    local start_time="$1"
    local end_time="$2"
    local start_ts
    start_ts=$(date --date="$start_time" +%s)
    local end_ts
    end_ts=$(date --date="$end_time" +%s)
    echo $((end_ts - start_ts))
}

parse_duration() {
    local duration_str="$1"
    local total_seconds=0
    
    if [[ -z "$duration_str" ]]; then
        echo "❌ Duration is required" >&2
        return 1
    fi
    
    duration_str=$(echo "$duration_str" | tr -d ' ')
    
    if [[ "$duration_str" =~ ^([0-9]+\.?[0-9]*)h$ ]]; then
        local hours="${BASH_REMATCH[1]}"
        local hours_int=$(echo "$hours * 3600" | bc -l)
        total_seconds=$(echo "$hours_int" | cut -d'.' -f1)
    elif [[ "$duration_str" =~ ^([0-9]+)h([0-9]+)m$ ]]; then
        local hours="${BASH_REMATCH[1]}"
        local minutes="${BASH_REMATCH[2]}"
        total_seconds=$((hours * 3600 + minutes * 60))
    elif [[ "$duration_str" =~ ^([0-9]+)h$ ]]; then
        local hours="${BASH_REMATCH[1]}"
        total_seconds=$((hours * 3600))
    elif [[ "$duration_str" =~ ^([0-9]+)m$ ]]; then
        local minutes="${BASH_REMATCH[1]}"
        total_seconds=$((minutes * 60))
    else
        echo "❌ Invalid duration format: $duration_str" >&2
        return 1
    fi
    
    echo "$total_seconds"
}


# =============================================================================
# DATABASE UTILITIES (PRIVATE)
# =============================================================================

execute_sqlite() {
    local sql_command="$1"
    local context="${2:-sqlite}"
    local output
    local exit_code
    
    output=$(sqlite3 "$DB" "$sql_command" 2>&1)
    exit_code=$?
    
    if [[ $exit_code -ne 0 ]]; then
        if [[ "$output" =~ "disk I/O error" ]] || [[ "$output" =~ "database or disk is full" ]]; then
            echo "❌ Disk space error detected" >&2
            return 5
        fi
        if [[ "$output" =~ "permission denied" ]] || [[ "$output" =~ "readonly database" ]]; then
            echo "❌ Permission error detected" >&2
            return 4
        fi
        if [[ "$output" =~ "database disk image is malformed" ]] || [[ "$output" =~ "corrupt" ]]; then
            echo "❌ Database corruption detected" >&2
            return 3
        fi
        return $exit_code
    fi
    
    echo "$output"
    return 0
}

# =============================================================================
# VALIDATION FUNCTIONS (EXPORTED)
# =============================================================================

validate_timestamp() {
    local timestamp="$1"
    local description="${2:-timestamp}"
    
    if [[ -z "$timestamp" ]]; then
        echo "❌ $description cannot be empty."
        return 1
    fi
    
    if [[ "$timestamp" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}([+-][0-9]{2}:[0-9]{2}|Z)?$ ]]; then
        if ! date --date="$timestamp" >/dev/null 2>&1; then
            echo "❌ $description is not a valid date/time."
            return 1
        fi
        return 0
    fi
    
    if [[ "$timestamp" =~ ^[0-9]{4}/[0-9]{2}/[0-9]{2}-[0-9]{2}:[0-9]{2}$ ]]; then
        local year month day hour minute
        year=$(echo "$timestamp" | cut -d'/' -f1)
        month=$(echo "$timestamp" | cut -d'/' -f2)
        day=$(echo "$timestamp" | cut -d'/' -f3 | cut -d'-' -f1)
        hour=$(echo "$timestamp" | cut -d'-' -f2 | cut -d':' -f1)
        minute=$(echo "$timestamp" | cut -d'-' -f2 | cut -d':' -f2)
        
        if [[ $((10#$year)) -lt 1900 ]] || [[ $((10#$year)) -gt 2100 ]] || [[ $((10#$month)) -lt 1 ]] || [[ $((10#$month)) -gt 12 ]] || [[ $((10#$day)) -lt 1 ]] || [[ $((10#$day)) -gt 31 ]] || [[ $((10#$hour)) -lt 0 ]] || [[ $((10#$hour)) -gt 23 ]] || [[ $((10#$minute)) -lt 0 ]] || [[ $((10#$minute)) -gt 59 ]]; then
            echo "❌ $description has invalid components"
            return 1
        fi
        
        local iso_timestamp
        iso_timestamp=$(date --date="$year-$month-$day $hour:$minute" -Iseconds 2>/dev/null)
        if [[ $? -ne 0 ]]; then
            echo "❌ $description is not a valid date/time."
            return 1
        fi
        echo "$iso_timestamp"
        return 0
    fi
    
    if [[ "$timestamp" =~ ^[0-9]+[hm]$ ]]; then
        local number unit converted_timestamp
        number=$(echo "$timestamp" | sed 's/[hm]$//')
        unit=$(echo "$timestamp" | sed 's/^[0-9]*//')
        
        if [[ "$unit" == "h" && ("$number" -lt 1 || "$number" -gt 24) ]]; then
            echo "❌ $description: Hours must be between 1 and 24 (got: ${number}h)"
            return 1
        elif [[ "$unit" == "m" && ("$number" -lt 1 || "$number" -gt 59) ]]; then
            echo "❌ $description: Minutes must be between 1 and 59 (got: ${number}m)"
            return 1
        fi
        
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
    
    if [[ "$timestamp" =~ ^[0-9]+[dwmy]$ ]]; then
        echo "❌ $description: Invalid time format '$timestamp'"
        echo "Only hour-based formats are supported (e.g., 7h, 30m)"
        return 1
    fi
    
    local converted_timestamp
    converted_timestamp=$(date --date="$timestamp" -Iseconds 2>/dev/null)
    if [[ $? -ne 0 ]]; then
        echo "❌ $description format not recognized."
        return 1
    fi
    echo "$converted_timestamp"
    return 0
}

validate_time_range() {
    local start_time="$1"
    local end_time="$2"
    
    if ! validate_timestamp "$start_time" "Start time"; then
        return 1
    fi
    
    if ! validate_timestamp "$end_time" "End time"; then
        return 1
    fi
    
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

validate_file_path() {
    local file_path="$1"
    local description="${2:-file}"
    
    if [[ -z "$file_path" ]]; then
        echo "❌ $description path cannot be empty."
        return 1
    fi
    
    if [[ "$file_path" =~ [\"\\] ]]; then
        echo "❌ $description path contains invalid characters."
        return 1
    fi
    
    if [[ "$file_path" =~ [[:cntrl:]] ]]; then
        echo "❌ $description path contains control characters."
        return 1
    fi
    
    return 0
}

validate_session_id() {
    local session_id="$1"
    if ! validate_numeric_input "$session_id" "Session ID"; then
        return 1
    fi
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

# =============================================================================
# TIME SPECIFICATION PARSER (EXPORTED)
# =============================================================================

parse_time_spec() {
    local args=("$@")
    local start_spec=""
    local end_spec=""
    local start_epoch=""
    local end_epoch=""
    
    if [[ ${#args[@]} -eq 0 ]]; then
        echo "❌ Time specification required" >&2
        return 2
    fi
    
    if [[ "${args[0]}" == "range" ]]; then
        if [[ ${#args[@]} -ne 3 ]]; then
            echo "❌ Range format requires exactly 3 arguments: range <start> <end>" >&2
            return 2
        fi
        start_spec="${args[1]}"
        end_spec="${args[2]}"
    elif [[ ${#args[@]} -eq 1 ]]; then
        case "${args[0]}" in
            "today")
                start_spec="today 00:00"
                end_spec="today 23:59"
                ;;
            "yesterday")
                start_spec="yesterday 00:00"
                end_spec="yesterday 23:59"
                ;;
            "week")
                start_spec="7 days ago 00:00"
                end_spec="now"
                ;;
            *)
                echo "❌ Unknown period: ${args[0]}" >&2
                return 2
                ;;
        esac
    elif [[ ${#args[@]} -eq 2 ]]; then
        start_spec="${args[0]}"
        end_spec="${args[1]}"
    else
        echo "❌ Too many arguments" >&2
        return 2
    fi
    
    if [[ -n "$start_spec" ]]; then
        start_epoch=$(date --date="$start_spec" +%s 2>/dev/null)
        if [[ $? -ne 0 ]] || [[ -z "$start_epoch" ]]; then
            echo "❌ Invalid start time: $start_spec" >&2
            return 2
        fi
    fi
    
    if [[ -n "$end_spec" ]]; then
        end_epoch=$(date --date="$end_spec" +%s 2>/dev/null)
        if [[ $? -ne 0 ]] || [[ -z "$end_epoch" ]]; then
            echo "❌ Invalid end time: $end_spec" >&2
            return 2
        fi
    fi
    
    if [[ -n "$start_epoch" ]] && [[ -n "$end_epoch" ]] && [[ "$start_epoch" -ge "$end_epoch" ]]; then
        echo "❌ Start time must be before end time" >&2
        return 2
    fi
    
    echo "$start_epoch $end_epoch"
    return 0
}

# =============================================================================
# UTILITY HELPERS (PRIVATE)
# =============================================================================


# Export only essential functions
export -f validate_timestamp
export -f validate_time_range
export -f validate_file_path
export -f validate_session_id
export -f parse_time_spec
export -f log_debug
export -f log_info
export -f log_warn
export -f log_err
export -f die
export -f usage
export -f not_found
export -f conflict