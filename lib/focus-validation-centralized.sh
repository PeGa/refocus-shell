#!/usr/bin/env bash
# Refocus Shell - Centralized Validation Functions
# Copyright (c) 2025 PeGa
# Licensed under the GNU General Public License v3

# Source bootstrap module
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/focus-bootstrap.sh"

# Table name variables
STATE_TABLE="${STATE_TABLE:-state}"
SESSIONS_TABLE="${SESSIONS_TABLE:-sessions}"
PROJECTS_TABLE="${PROJECTS_TABLE:-projects}"

# =============================================================================
# CENTRALIZED VALIDATION FUNCTIONS
# =============================================================================

# Function to validate required arguments with standardized error messages
validate_required_args() {
    local args=("$@")
    local command_name="${args[0]}"
    local usage="${args[1]}"
    local examples="${args[2]:-}"
    
    shift 3
    local missing_args=()
    
    for arg in "$@"; do
        if [[ -z "$arg" ]]; then
            missing_args+=("$arg")
        fi
    done
    
    if [[ ${#missing_args[@]} -gt 0 ]]; then
        echo "❌ Missing required arguments."
        echo "Usage: $usage"
        if [[ -n "$examples" ]]; then
            echo ""
            echo "Examples:"
            echo "$examples"
        fi
        return 1
    fi
    
    return 0
}

# Function to validate project name with standardized error handling
validate_project_name_standardized() {
    local project="$1"
    local context="${2:-project}"
    
    if [[ -z "$project" ]]; then
        echo "❌ $context name is required."
        return 1
    fi
    
    # Sanitize project name
    project=$(sanitize_project_name "$project")
    
    # Validate project name
    if ! validate_project_name "$project"; then
        return 1
    fi
    
    echo "$project"
    return 0
}

# Function to validate numeric input with standardized error messages
validate_numeric_input_standardized() {
    local value="$1"
    local field_name="${2:-Value}"
    local min_value="${3:-0}"
    local max_value="${4:-999999}"
    
    if [[ -z "$value" ]]; then
        echo "❌ $field_name is required."
        return 1
    fi
    
    if ! [[ "$value" =~ ^[0-9]+$ ]]; then
        echo "❌ $field_name must be a positive integer."
        return 1
    fi
    
    if [[ "$value" -lt "$min_value" ]]; then
        echo "❌ $field_name must be at least $min_value."
        return 1
    fi
    
    if [[ "$value" -gt "$max_value" ]]; then
        echo "❌ $field_name must be no more than $max_value."
        return 1
    fi
    
    return 0
}

# Function to validate timestamp with standardized error handling
validate_timestamp_standardized() {
    local timestamp="$1"
    local field_name="${2:-Timestamp}"
    
    if [[ -z "$timestamp" ]]; then
        echo "❌ $field_name is required."
        return 1
    fi
    
    local converted_timestamp
    converted_timestamp=$(validate_timestamp "$timestamp" "$field_name")
    if [[ $? -ne 0 ]]; then
        echo "$converted_timestamp"
        return 1
    fi
    
    echo "$converted_timestamp"
    return 0
}

# Function to validate duration with standardized error handling
validate_duration_standardized() {
    local duration="$1"
    local field_name="${2:-Duration}"
    
    if [[ -z "$duration" ]]; then
        echo "❌ $field_name is required."
        return 1
    fi
    
    local duration_seconds
    duration_seconds=$(parse_duration "$duration")
    if [[ $? -ne 0 ]]; then
        return 1
    fi
    
    echo "$duration_seconds"
    return 0
}

# Function to validate file existence with standardized error messages
validate_file_exists() {
    local file_path="$1"
    local file_type="${2:-File}"
    
    if [[ -z "$file_path" ]]; then
        echo "❌ $file_type path is required."
        return 1
    fi
    
    if [[ ! -f "$file_path" ]]; then
        echo "❌ $file_type does not exist: $file_path"
        return 1
    fi
    
    return 0
}

# Function to validate directory existence with standardized error messages
validate_directory_exists() {
    local dir_path="$1"
    local dir_type="${2:-Directory}"
    
    if [[ -z "$dir_path" ]]; then
        echo "❌ $dir_type path is required."
        return 1
    fi
    
    if [[ ! -d "$dir_path" ]]; then
        echo "❌ $dir_type does not exist: $dir_path"
        return 1
    fi
    
    return 0
}

# =============================================================================
# CENTRALIZED ERROR HANDLING FUNCTIONS
# =============================================================================

# Function to handle state errors with standardized messages
handle_state_error() {
    local error_type="$1"
    local context="${2:-}"
    
    case "$error_type" in
        "disabled")
            echo "❌ Refocus shell is disabled. Run 'focus enable' first."
            exit 7  # State error - disabled
            ;;
        "already_active")
            echo "Focus already active. Run 'focus off' before switching."
            exit 7  # State error - already active
            ;;
        "session_paused")
            echo "❌ Cannot start new focus session while one is paused."
            if [[ -n "$context" ]]; then
                echo "   Paused session: $context"
            fi
            echo ""
            echo "💡 Use 'focus continue' to resume the paused session"
            echo "   Use 'focus off' to end the paused session permanently"
            exit 7  # State error - session paused
            ;;
        "no_active_session")
            echo "No active or paused focus session."
            exit 7  # State error - no active session
            ;;
        *)
            echo "❌ Invalid application state: $error_type"
            exit 7  # State error
            ;;
    esac
}

# Function to handle argument errors with standardized messages
handle_argument_error() {
    local error_type="$1"
    local usage="${2:-}"
    local examples="${3:-}"
    
    case "$error_type" in
        "missing_project")
            echo "❌ Project name is required."
            ;;
        "missing_duration")
            echo "❌ Duration is required when using --duration flag."
            ;;
        "missing_date")
            echo "❌ Date is required when using --duration flag."
            ;;
        "missing_start_time")
            echo "❌ Start time is required."
            ;;
        "missing_end_time")
            echo "❌ End time is required."
            ;;
        "invalid_option")
            echo "❌ Unknown option: $usage"
            ;;
        *)
            echo "❌ Invalid arguments: $error_type"
            ;;
    esac
    
    if [[ -n "$usage" ]]; then
        echo "Usage: $usage"
    fi
    
    if [[ -n "$examples" ]]; then
        echo ""
        echo "Examples:"
        echo "$examples"
    fi
    
    exit 2  # Invalid arguments
}

# Function to handle database errors with standardized messages
handle_database_error() {
    local error_type="$1"
    local context="${2:-database operation}"
    
    case "$error_type" in
        "session_not_found")
            echo "❌ Session not found."
            ;;
        "project_not_found")
            echo "❌ Project not found."
            ;;
        "database_error")
            echo "❌ Database error during $context."
            ;;
        *)
            echo "❌ Database error: $error_type"
            ;;
    esac
    
    echo "More information can be found at: $REFOCUS_ERROR_LOG"
    exit 1  # General error
}

# =============================================================================
# CENTRALIZED OUTPUT FORMATTING FUNCTIONS
# =============================================================================

# Function to format success messages consistently
format_success_message() {
    local message="$1"
    local details="${2:-}"
    
    echo "✅ $message"
    if [[ -n "$details" ]]; then
        echo "   $details"
    fi
}

# Function to format error messages consistently
format_error_message() {
    local message="$1"
    local details="${2:-}"
    
    echo "❌ $message"
    if [[ -n "$details" ]]; then
        echo "   $details"
    fi
}

# Function to format warning messages consistently
format_warning_message() {
    local message="$1"
    local details="${2:-}"
    
    echo "⚠️  $message"
    if [[ -n "$details" ]]; then
        echo "   $details"
    fi
}

# Function to format info messages consistently
format_info_message() {
    local message="$1"
    local details="${2:-}"
    
    echo "ℹ️  $message"
    if [[ -n "$details" ]]; then
        echo "   $details"
    fi
}

# Function to format duration consistently
format_duration() {
    local duration_seconds="$1"
    local format="${2:-short}"  # short, long, minutes_only
    
    local hours=$((duration_seconds / 3600))
    local minutes=$(((duration_seconds % 3600) / 60))
    
    case "$format" in
        "short")
            if [[ $hours -gt 0 ]]; then
                echo "${hours}h ${minutes}m"
            else
                echo "${minutes}m"
            fi
            ;;
        "long")
            if [[ $hours -gt 0 ]]; then
                echo "${hours} hours ${minutes} minutes"
            else
                echo "${minutes} minutes"
            fi
            ;;
        "minutes_only")
            echo "${minutes}m"
            ;;
        *)
            echo "${minutes}m"
            ;;
    esac
}

# Function to format timestamp consistently
format_timestamp() {
    local timestamp="$1"
    local format="${2:-default}"  # default, date_only, time_only, iso
    
    case "$format" in
        "default")
            date --date="$timestamp" +"%Y-%m-%d %H:%M"
            ;;
        "date_only")
            date --date="$timestamp" +"%Y-%m-%d"
            ;;
        "time_only")
            date --date="$timestamp" +"%H:%M"
            ;;
        "iso")
            date --date="$timestamp" +"%Y-%m-%dT%H:%M:%S"
            ;;
        *)
            date --date="$timestamp" +"%Y-%m-%d %H:%M"
            ;;
    esac
}

# Function to format table headers consistently
format_table_header() {
    local headers=("$@")
    local widths=()
    
    # Calculate column widths
    for header in "${headers[@]}"; do
        widths+=(${#header})
    done
    
    # Print header row
    printf "%-${widths[0]}s" "${headers[0]}"
    for i in $(seq 1 $((${#headers[@]} - 1))); do
        printf " %-${widths[$i]}s" "${headers[$i]}"
    done
    printf "\n"
    
    # Print separator row
    printf "%-${widths[0]}s" "$(printf "%*s" ${widths[0]} | tr ' ' '-')"
    for i in $(seq 1 $((${#headers[@]} - 1))); do
        printf " %-${widths[$i]}s" "$(printf "%*s" ${widths[$i]} | tr ' ' '-')"
    done
    printf "\n"
}

# =============================================================================
# CENTRALIZED DATABASE OPERATION FUNCTIONS
# =============================================================================

# Function to get session by ID with standardized error handling
get_session_by_id() {
    local session_id="$1"
    
    if ! validate_numeric_input_standardized "$session_id" "Session ID"; then
        return 1
    fi
    
    local session_data
    session_data=$(execute_sqlite "SELECT rowid, project, start_time, end_time, duration_seconds, notes FROM $SESSIONS_TABLE WHERE rowid = $session_id;" "get_session_by_id")
    
    if [[ -z "$session_data" ]]; then
        handle_database_error "session_not_found"
        return 1
    fi
    
    echo "$session_data"
    return 0
}

# Function to get project sessions with standardized error handling
get_project_sessions() {
    local project="$1"
    local limit="${2:-20}"
    
    if ! validate_numeric_input_standardized "$limit" "Limit" 1 1000; then
        return 1
    fi
    
    local escaped_project
    escaped_project=$(sql_escape "$project")
    
    local sessions
    sessions=$(execute_sqlite "SELECT rowid, project, start_time, end_time, duration_seconds, notes FROM $SESSIONS_TABLE WHERE project = '$escaped_project' ORDER BY rowid DESC LIMIT $limit;" "get_project_sessions")
    
    echo "$sessions"
    return 0
}

# Function to get recent sessions with standardized error handling
get_recent_sessions() {
    local limit="${1:-20}"
    
    if ! validate_numeric_input_standardized "$limit" "Limit" 1 1000; then
        return 1
    fi
    
    local sessions
    sessions=$(execute_sqlite "SELECT rowid, project, start_time, end_time, duration_seconds, notes FROM $SESSIONS_TABLE WHERE project != '[idle]' ORDER BY rowid DESC LIMIT $limit;" "get_recent_sessions")
    
    echo "$sessions"
    return 0
}

# Function to get session count with standardized error handling
get_session_count() {
    local project="${1:-}"
    
    local query
    if [[ -n "$project" ]]; then
        local escaped_project
        escaped_project=$(sql_escape "$project")
        query="SELECT COUNT(*) FROM $SESSIONS_TABLE WHERE project = '$escaped_project';"
    else
        query="SELECT COUNT(*) FROM $SESSIONS_TABLE WHERE project != '[idle]';"
    fi
    
    local count
    count=$(execute_sqlite "$query" "get_session_count")
    
    echo "${count:-0}"
    return 0
}

# Function to get total project time with standardized error handling
get_total_project_time() {
    local project="$1"
    
    if [[ -z "$project" ]]; then
        echo "0"
        return 0
    fi
    
    local escaped_project
    escaped_project=$(sql_escape "$project")
    
    local total_time
    total_time=$(execute_sqlite "SELECT COALESCE(SUM(duration_seconds), 0) FROM $SESSIONS_TABLE WHERE project = '$escaped_project' AND project != '[idle]';" "get_total_project_time")
    
    echo "${total_time:-0}"
    return 0
}

# =============================================================================
# CENTRALIZED USAGE AND HELP FUNCTIONS
# =============================================================================

# Function to generate standardized usage messages
generate_usage_message() {
    local command="$1"
    local usage="$2"
    local examples="${3:-}"
    local notes="${4:-}"
    
    echo "Usage: $usage"
    
    if [[ -n "$examples" ]]; then
        echo ""
        echo "Examples:"
        echo "$examples"
    fi
    
    if [[ -n "$notes" ]]; then
        echo ""
        echo "Notes:"
        echo "$notes"
    fi
}

# Function to generate standardized help sections
generate_help_section() {
    local title="$1"
    local commands="$2"
    
    echo "$title:"
    echo "$commands"
    echo ""
}

# Export all functions for use in other modules
export -f validate_required_args
export -f validate_project_name_standardized
export -f validate_numeric_input_standardized
export -f validate_timestamp_standardized
export -f validate_duration_standardized
export -f validate_file_exists
export -f validate_directory_exists
export -f handle_state_error
export -f handle_argument_error
export -f handle_database_error
export -f format_success_message
export -f format_error_message
export -f format_warning_message
export -f format_info_message
export -f format_duration
export -f format_timestamp
export -f format_table_header
export -f get_session_by_id
export -f get_project_sessions
export -f get_recent_sessions
export -f get_session_count
export -f get_total_project_time
export -f generate_usage_message
export -f generate_help_section
