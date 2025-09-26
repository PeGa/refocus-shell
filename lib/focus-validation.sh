#!/usr/bin/env bash
# Refocus Shell - Validation Module
# Copyright (c) 2025 PeGa
# Licensed under the GNU General Public License v3

# This module provides common validation functions for refocus commands
# to ensure consistent input validation and error handling.

# Function to validate project name
# Usage: validate_project_name <project_name>
validate_project_name() {
    local project="$1"
    
    if [[ -z "$project" ]]; then
        echo "❌ Project name is required"
        return 1
    fi
    
    # Check for reasonable length
    if [[ ${#project} -gt 100 ]]; then
        echo "❌ Project name too long (max 100 characters)"
        return 1
    fi
    
    # Check for invalid characters
    if [[ "$project" =~ [[:cntrl:]] ]]; then
        echo "❌ Project name contains invalid characters"
        return 1
    fi
    
    return 0
}

# Function to validate session ID
# Usage: validate_session_id <session_id>
validate_session_id() {
    local session_id="$1"
    
    if [[ -z "$session_id" ]]; then
        echo "❌ Session ID is required"
        return 1
    fi
    
    if ! [[ "$session_id" =~ ^[0-9]+$ ]]; then
        echo "❌ Invalid session ID: $session_id (must be numeric)"
        return 1
    fi
    
    return 0
}

# Function to validate duration format
# Usage: validate_duration <duration_string>
validate_duration() {
    local duration="$1"
    
    if [[ -z "$duration" ]]; then
        echo "❌ Duration is required"
        return 1
    fi
    
    # Check for valid duration format (e.g., "1h30m", "45m", "2h")
    if ! [[ "$duration" =~ ^[0-9]+[hm]?([0-9]+[hm])?$ ]]; then
        echo "❌ Invalid duration format: $duration"
        echo "   Use format like: 1h30m, 45m, 2h"
        return 1
    fi
    
    return 0
}

# Function to validate date format
# Usage: validate_date_format <date_string>
validate_date_format() {
    local date_string="$1"
    
    if [[ -z "$date_string" ]]; then
        echo "❌ Date is required"
        return 1
    fi
    
    # Check for various date formats
    if ! [[ "$date_string" =~ ^[0-9]{4}/[0-9]{2}/[0-9]{2}(-[0-9]{2}:[0-9]{2})?$ ]] && \
       ! [[ "$date_string" =~ ^[0-9]{2}:[0-9]{2}$ ]] && \
       ! [[ "$date_string" =~ ^(today|yesterday|tomorrow)$ ]]; then
        echo "❌ Invalid date format: $date_string"
        echo "   Use format like: YYYY/MM/DD-HH:MM, HH:MM, or 'today'"
        return 1
    fi
    
    return 0
}

# Function to validate file path
# Usage: validate_file_path <file_path> <description>
validate_file_path() {
    local file_path="$1"
    local description="${2:-File}"
    
    if [[ -z "$file_path" ]]; then
        echo "❌ $description path is required"
        return 1
    fi
    
    # Check for path traversal attempts
    if [[ "$file_path" == *".."* ]]; then
        echo "❌ $description path contains invalid characters"
        return 1
    fi
    
    # Check for valid path format (allow plain filenames in current directory)
    if [[ "$file_path" == *"/"* ]] && [[ "$file_path" != /* ]] && [[ "$file_path" != ./* ]] && [[ "$file_path" != ~* ]]; then
        echo "❌ $description path contains invalid characters"
        return 1
    fi
    
    return 0
}

# Function to validate configuration key
# Usage: validate_config_key <key>
validate_config_key() {
    local key="$1"
    
    if [[ -z "$key" ]]; then
        echo "❌ Configuration key is required"
        return 1
    fi
    
    # Check for valid configuration keys
    local valid_keys=(
        "VERBOSE" "IDLE_THRESHOLD" "MAX_PROJECT_LENGTH"
        "NOTIFICATION_TIMEOUT" "NUDGING_ENABLED" "NUDGING_INTERVAL"
        "REPORT_LIMIT" "DATE_FORMAT" "TIME_FORMAT"
        "MAX_SESSION_HOURS" "MIN_SESSION_SECONDS" "DEBUG_MODE"
    )
    
    local is_valid=false
    for valid_key in "${valid_keys[@]}"; do
        if [[ "$key" == "$valid_key" ]]; then
            is_valid=true
            break
        fi
    done
    
    if [[ "$is_valid" == false ]]; then
        echo "❌ Invalid configuration key: $key"
        echo "   Valid keys: ${valid_keys[*]}"
        return 1
    fi
    
    return 0
}

# Function to validate configuration value
# Usage: validate_config_value <key> <value>
validate_config_value() {
    local key="$1"
    local value="$2"
    
    case "$key" in
        "VERBOSE"|"NUDGING_ENABLED"|"DEBUG_MODE")
            if ! [[ "$value" =~ ^(true|false)$ ]]; then
                echo "❌ Invalid value for $key: $value (must be true or false)"
                return 1
            fi
            ;;
        "IDLE_THRESHOLD"|"MAX_PROJECT_LENGTH"|"NOTIFICATION_TIMEOUT"|"NUDGING_INTERVAL"|"REPORT_LIMIT"|"MAX_SESSION_HOURS"|"MIN_SESSION_SECONDS")
            if ! [[ "$value" =~ ^[0-9]+$ ]]; then
                echo "❌ Invalid value for $key: $value (must be numeric)"
                return 1
            fi
            ;;
        "DATE_FORMAT"|"TIME_FORMAT")
            # Basic validation for format strings
            if [[ -z "$value" ]]; then
                echo "❌ Invalid value for $key: $value (cannot be empty)"
                return 1
            fi
            ;;
    esac
    
    return 0
}

# Function to validate session notes
# Usage: validate_session_notes <notes>
validate_session_notes() {
    local notes="$1"
    
    # Notes are optional, but if provided, check length
    if [[ -n "$notes" ]] && [[ ${#notes} -gt 1000 ]]; then
        echo "❌ Session notes too long (max 1000 characters)"
        return 1
    fi
    
    return 0
}

# Function to validate time range
# Usage: validate_time_range <start_time> <end_time>
validate_time_range() {
    local start_time="$1"
    local end_time="$2"
    
    if [[ -z "$start_time" ]] || [[ -z "$end_time" ]]; then
        echo "❌ Both start and end times are required"
        return 1
    fi
    
    # Convert to timestamps for comparison
    local start_ts
    local end_ts
    
    start_ts=$(date --date="$start_time" +%s 2>/dev/null)
    end_ts=$(date --date="$end_time" +%s 2>/dev/null)
    
    if [[ -z "$start_ts" ]] || [[ -z "$end_ts" ]]; then
        echo "❌ Invalid time format"
        return 1
    fi
    
    if [[ $start_ts -ge $end_ts ]]; then
        echo "❌ Start time must be before end time"
        return 1
    fi
    
    # Check for reasonable session duration (max 24 hours)
    local duration=$((end_ts - start_ts))
    if [[ $duration -gt 86400 ]]; then
        echo "❌ Session duration too long (max 24 hours)"
        return 1
    fi
    
    return 0
}

# Function to validate export format
# Usage: validate_export_format <format>
validate_export_format() {
    local format="$1"
    
    if [[ -z "$format" ]]; then
        echo "❌ Export format is required"
        return 1
    fi
    
    case "$format" in
        "sql"|"json"|"both")
            return 0
            ;;
        *)
            echo "❌ Invalid export format: $format"
            echo "   Valid formats: sql, json, both"
            return 1
            ;;
    esac
}

# Export functions for use in other scripts
export -f validate_project_name
export -f validate_session_id
export -f validate_duration
export -f validate_date_format
export -f validate_file_path
export -f validate_config_key
export -f validate_config_value
export -f validate_session_notes
export -f validate_time_range
export -f validate_export_format
