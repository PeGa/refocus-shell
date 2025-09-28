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
    export REFOCUS_DB_PATH="$(get_cfg DB_PATH "$HOME/.local/refocus/refocus.db")"
    export REFOCUS_STATE_TABLE="$(get_cfg STATE_TABLE "state")"
    export REFOCUS_SESSIONS_TABLE="$(get_cfg SESSIONS_TABLE "sessions")"
    export REFOCUS_PROJECTS_TABLE="$(get_cfg PROJECTS_TABLE "projects")"
    
    export REFOCUS_INSTALL_DIR="$(get_cfg INSTALL_DIR "$HOME/.local/bin")"
    export REFOCUS_DATA_DIR="$(get_cfg DATA_DIR "$HOME/.local/refocus")"
    export REFOCUS_LIB_DIR="$(get_cfg LIB_DIR "$REFOCUS_DATA_DIR/lib")"
    export REFOCUS_COMMANDS_DIR="$(get_cfg COMMANDS_DIR "$REFOCUS_DATA_DIR/commands")"
    
    export REFOCUS_VERBOSE="$(get_cfg VERBOSE "false")"
    export REFOCUS_IDLE_THRESHOLD="$(get_cfg IDLE_THRESHOLD "60")"
    export REFOCUS_MAX_PROJECT_LENGTH="$(get_cfg MAX_PROJECT_LENGTH "100")"
    
    export REFOCUS_NOTIFICATIONS="$(get_cfg NOTIFICATIONS "true")"
    export REFOCUS_NOTIFICATION_TIMEOUT="$(get_cfg NOTIFICATION_TIMEOUT "5000")"
    
    export REFOCUS_NUDGING="$(get_cfg NUDGING "true")"
    export REFOCUS_NUDGE_INTERVAL="$(get_cfg NUDGE_INTERVAL "10")"
    
    export REFOCUS_REPORT_LIMIT="$(get_cfg REPORT_LIMIT "20")"
    export REFOCUS_DATE_FORMAT="$(get_cfg DATE_FORMAT "%Y-%m-%d %H:%M")"
    export REFOCUS_TIME_FORMAT="$(get_cfg TIME_FORMAT "%H:%M")"
    
    export REFOCUS_EXPORT_FORMAT="$(get_cfg EXPORT_FORMAT "refocus-export-%Y%m%d_%H%M%S.sql")"
    export REFOCUS_EXPORT_DIR="$(get_cfg EXPORT_DIR "")"
    
    export REFOCUS_MAX_SESSION_HOURS="$(get_cfg MAX_SESSION_HOURS "24")"
    export REFOCUS_MIN_SESSION_SECONDS="$(get_cfg MIN_SESSION_SECONDS "1")"
    
    export REFOCUS_DEBUG="$(get_cfg DEBUG "false")"
    export REFOCUS_LOG_FILE="$(get_cfg LOG_FILE "")"
}

# Load configuration on bootstrap
load_configuration

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
        migrate_database
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

# Function to validate required dependencies
# Usage: refocus_validate_dependencies [dependency1] [dependency2] ...
refocus_validate_dependencies() {
    local missing_deps=()
    
    for dep in "$@"; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            missing_deps+=("$dep")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        echo "❌ Missing required dependencies: ${missing_deps[*]}"
        echo "Please install them and try again."
        return 1
    fi
    
    return 0
}

# Function to handle user confirmation prompts
# Usage: refocus_confirm <message> [default_response]
# Returns: 0 for yes, 1 for no
refocus_confirm() {
    local message="$1"
    local default="${2:-N}"
    local response
    
    echo "$message"
    read -r response
    
    # Handle empty response with default
    if [[ -z "$response" ]]; then
        response="$default"
    fi
    
    [[ "$response" =~ ^[Yy]$ ]]
}

# Source the centralized output formatting functions
if [[ -f "${REFOCUS_LIB_DIR:-$HOME/.local/refocus/lib}/focus-output.sh" ]]; then
    source "${REFOCUS_LIB_DIR:-$HOME/.local/refocus/lib}/focus-output.sh"
fi

# Note: Validation functions have been removed - each command now has its own guard clauses

# Function to create backup of database
# Usage: refocus_backup_database [backup_suffix]
refocus_backup_database() {
    local suffix="${1:-backup}"
    
    if [[ -f "$DB" ]]; then
        local backup_file
        backup_file="${DB}.${suffix}.$(date +%Y%m%d_%H%M%S)"
        cp "$DB" "$backup_file"
        echo "📋 Created backup: $backup_file"
        return 0
    fi
    
    return 1
}

# Function to get current timestamp
# Usage: refocus_timestamp [format]
refocus_timestamp() {
    local format="${1:-%Y-%m-%d %H:%M:%S}"
    date "+$format"
}

# Function to log command execution
# Usage: refocus_log_command <command> <args...>
refocus_log_command() {
    local command="$1"
    shift
    local args="$*"
    
    if [[ "$VERBOSE" == "true" ]]; then
        echo "🔧 Executing: $command $args"
    fi
}

# Export functions for use in other scripts
export -f get_cfg
export -f load_configuration
export -f refocus_bootstrap
export -f refocus_command_main
export -f refocus_script_main
export -f refocus_validate_dependencies
export -f refocus_confirm
export -f refocus_backup_database
export -f refocus_timestamp
export -f refocus_log_command
