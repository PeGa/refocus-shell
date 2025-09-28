#!/usr/bin/env bash
# Refocus Shell - Bootstrap Module
# Copyright (c) 2025 PeGa
# Licensed under the GNU General Public License v3

# This module provides common initialization patterns for all refocus commands
# to eliminate code duplication and ensure consistent behavior.

# =============================================================================
# CONFIGURATION MANAGEMENT
# =============================================================================
#
# Supported Configuration Keys (precedence: defaults < config file < env vars):
#
# Database Configuration:
#   DB_PATH              - Database file path (default: $HOME/.local/refocus/refocus.db)
#   STATE_TABLE          - State table name (default: state)
#   SESSIONS_TABLE       - Sessions table name (default: sessions)
#   PROJECTS_TABLE       - Projects table name (default: projects)
#
# Installation Paths:
#   INSTALL_DIR          - Installation directory (default: $HOME/.local/bin)
#   DATA_DIR             - Data directory (default: $HOME/.local/refocus)
#   LIB_DIR              - Library directory (default: $DATA_DIR/lib)
#   COMMANDS_DIR         - Commands directory (default: $DATA_DIR/commands)
#
# Behavior Configuration:
#   VERBOSE              - Enable verbose mode (default: false)
#   IDLE_THRESHOLD       - Idle session threshold in seconds (default: 60)
#   MAX_PROJECT_LENGTH   - Maximum project name length (default: 100)
#
# Notification Configuration:
#   NOTIFICATIONS        - Enable notifications (default: true)
#   NOTIFICATION_TIMEOUT - Notification timeout in milliseconds (default: 5000)
#
# Nudging Configuration:
#   NUDGING              - Enable nudging (default: true)
#   NUDGE_INTERVAL       - Nudging interval in minutes (default: 10)
#
# Reporting Configuration:
#   REPORT_LIMIT         - Default report limit (default: 20)
#   DATE_FORMAT          - Date format for reports (default: %Y-%m-%d %H:%M)
#   TIME_FORMAT          - Time format for reports (default: %H:%M)
#
# Export/Import Configuration:
#   EXPORT_FORMAT        - Export filename format (default: refocus-export-%Y%m%d_%H%M%S.sql)
#   EXPORT_DIR           - Export directory (default: current directory)
#
# Validation Configuration:
#   MAX_SESSION_HOURS    - Maximum session duration in hours (default: 24)
#   MIN_SESSION_SECONDS  - Minimum session duration in seconds (default: 1)
#
# Debug Configuration:
#   DEBUG                - Enable debug mode (default: false)
#   LOG_FILE             - Log file path (default: none)
#
# =============================================================================

# Function to get configuration value with proper precedence
# Usage: get_cfg <key> <default>
# Precedence: defaults < $XDG_CONFIG_HOME/refocus/refocus.conf < env overrides
get_cfg() {
    local key="$1"
    local default="$2"
    local config_file="${XDG_CONFIG_HOME:-$HOME/.config}/refocus/refocus.conf"
    
    # Check environment variable first (highest priority)
    local env_var="REFOCUS_${key^^}"
    if [[ -n "${!env_var:-}" ]]; then
        echo "${!env_var}"
        return 0
    fi
    
    # Check config file (medium priority)
    if [[ -f "$config_file" ]]; then
        local config_value
        config_value=$(grep "^${key}=" "$config_file" 2>/dev/null | cut -d'=' -f2- | sed 's/^"//;s/"$//')
        if [[ -n "$config_value" ]]; then
            echo "$config_value"
            return 0
        fi
    fi
    
    # Return default value (lowest priority)
    echo "$default"
}

# Function to load configuration with precedence handling
load_configuration() {
    local config_file="${XDG_CONFIG_HOME:-$HOME/.config}/refocus/refocus.conf"
    
    # Set default values
    local db_path
    db_path=$(get_cfg DB_PATH "$HOME/.local/refocus/refocus.db")
    export REFOCUS_DB_PATH="$db_path"
    
    local state_table
    state_table=$(get_cfg STATE_TABLE "state")
    export REFOCUS_STATE_TABLE="$state_table"
    
    local sessions_table
    sessions_table=$(get_cfg SESSIONS_TABLE "sessions")
    export REFOCUS_SESSIONS_TABLE="$sessions_table"
    
    local projects_table
    projects_table=$(get_cfg PROJECTS_TABLE "projects")
    export REFOCUS_PROJECTS_TABLE="$projects_table"
    
    local install_dir
    install_dir=$(get_cfg INSTALL_DIR "$HOME/.local/bin")
    export REFOCUS_INSTALL_DIR="$install_dir"
    
    local data_dir
    data_dir=$(get_cfg DATA_DIR "$HOME/.local/refocus")
    export REFOCUS_DATA_DIR="$data_dir"
    
    local lib_dir
    lib_dir=$(get_cfg LIB_DIR "$REFOCUS_DATA_DIR/lib")
    export REFOCUS_LIB_DIR="$lib_dir"
    
    local commands_dir
    commands_dir=$(get_cfg COMMANDS_DIR "$REFOCUS_DATA_DIR/commands")
    export REFOCUS_COMMANDS_DIR="$commands_dir"
    
    local verbose
    verbose=$(get_cfg VERBOSE "false")
    export REFOCUS_VERBOSE="$verbose"
    
    local idle_threshold
    idle_threshold=$(get_cfg IDLE_THRESHOLD "60")
    export REFOCUS_IDLE_THRESHOLD="$idle_threshold"
    
    local max_project_length
    max_project_length=$(get_cfg MAX_PROJECT_LENGTH "100")
    export REFOCUS_MAX_PROJECT_LENGTH="$max_project_length"
    
    local notifications
    notifications=$(get_cfg NOTIFICATIONS "true")
    export REFOCUS_NOTIFICATIONS="$notifications"
    
    local notification_timeout
    notification_timeout=$(get_cfg NOTIFICATION_TIMEOUT "5000")
    export REFOCUS_NOTIFICATION_TIMEOUT="$notification_timeout"
    
    local nudging
    nudging=$(get_cfg NUDGING "true")
    export REFOCUS_NUDGING="$nudging"
    
    local nudge_interval
    nudge_interval=$(get_cfg NUDGE_INTERVAL "10")
    export REFOCUS_NUDGE_INTERVAL="$nudge_interval"
    
    local report_limit
    report_limit=$(get_cfg REPORT_LIMIT "20")
    export REFOCUS_REPORT_LIMIT="$report_limit"
    
    local date_format
    date_format=$(get_cfg DATE_FORMAT "%Y-%m-%d %H:%M")
    export REFOCUS_DATE_FORMAT="$date_format"
    
    local time_format
    time_format=$(get_cfg TIME_FORMAT "%H:%M")
    export REFOCUS_TIME_FORMAT="$time_format"
    
    local export_format
    export_format=$(get_cfg EXPORT_FORMAT "refocus-export-%Y%m%d_%H%M%S.sql")
    export REFOCUS_EXPORT_FORMAT="$export_format"
    
    local export_dir
    export_dir=$(get_cfg EXPORT_DIR "")
    export REFOCUS_EXPORT_DIR="$export_dir"
    
    local max_session_hours
    max_session_hours=$(get_cfg MAX_SESSION_HOURS "24")
    export REFOCUS_MAX_SESSION_HOURS="$max_session_hours"
    
    local min_session_seconds
    min_session_seconds=$(get_cfg MIN_SESSION_SECONDS "1")
    export REFOCUS_MIN_SESSION_SECONDS="$min_session_seconds"
    
    local debug
    debug=$(get_cfg DEBUG "false")
    export REFOCUS_DEBUG="$debug"
    
    local log_file
    log_file=$(get_cfg LOG_FILE "")
    export REFOCUS_LOG_FILE="$log_file"
}

# Load configuration on bootstrap
load_configuration

# Function to ensure data directories exist
# Usage: ensure_data_dirs
ensure_data_dirs() {
    local data_dir="${REFOCUS_DATA_DIR:-$HOME/.local/refocus}"
    local lib_dir="${REFOCUS_LIB_DIR:-$data_dir/lib}"
    local commands_dir="${REFOCUS_COMMANDS_DIR:-$data_dir/commands}"
    
    mkdir -p "$data_dir" "$lib_dir" "$commands_dir"
}

# Function to parse global flags
# Usage: parse_global_flags "$@"
# Sets REFOCUS_QUIET=true if -q/--quiet is found
parse_global_flags() {
    local args=()
    local quiet_mode=false
    
    # Parse global flags
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -q|--quiet)
                quiet_mode=true
                shift
                ;;
            -*)
                # Unknown global flag, pass through to subcommand
                args+=("$1")
                shift
                ;;
            *)
                # Non-flag argument, add to args
                args+=("$1")
                shift
                ;;
        esac
    done
    
    # Set quiet mode globally
    if [[ "$quiet_mode" == "true" ]]; then
        export REFOCUS_QUIET=true
    fi
    
    # Return remaining arguments
    echo "${args[@]}"
}

# Function to initialize refocus environment
# Usage: refocus_bootstrap [command_name]
refocus_bootstrap() {
    local command_name="${1:-unknown}"
    
    # Set script directory
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    # Source libraries with fallback paths
    if [[ -f "$REFOCUS_LIB_DIR/focus-db.sh" ]]; then
        source "$REFOCUS_LIB_DIR/focus-db.sh"
        source "$REFOCUS_LIB_DIR/focus-utils.sh"
        source "$REFOCUS_LIB_DIR/focus-output.sh"
    else
        source "$script_dir/focus-db.sh"
        source "$script_dir/focus-utils.sh"
        source "$script_dir/focus-output.sh"
    fi
    
    # Run database migration if needed
    if [[ -f "$REFOCUS_DB_PATH" ]]; then
        _migrate_database
    fi
    
    # Set up error context
    export REFOCUS_COMMAND_CONTEXT="$command_name"
}

# Function to handle command execution pattern
# Usage: refocus_command_main <command_function> "$@"
refocus_command_main() {
    local command_function="$1"
    shift
    
    # Initialize environment
    refocus_bootstrap "$command_function"
    
    # Execute the command
    "$command_function" "$@"
}

# Function to check if script is being executed directly
# Usage: refocus_script_main <command_function> "$@"
refocus_script_main() {
    local command_function="$1"
    shift
    
    # Always execute the command, whether called directly or via function
    refocus_command_main "$command_function" "$@"
}

# Export functions for use in other scripts
export -f get_cfg
export -f load_configuration
export -f ensure_data_dirs
export -f parse_global_flags
export -f refocus_bootstrap
export -f refocus_command_main
export -f refocus_script_main