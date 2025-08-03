#!/usr/bin/env bash
# Refocus Shell Configuration
# Copyright (c) 2025 PeGa
# Licensed under the GNU General Public License v3

# =============================================================================
# DATABASE CONFIGURATION
# =============================================================================

# Default database path
WORK_DB_DEFAULT="$HOME/.local/work/timelog.db"

# Database path (can be overridden by environment variable)
WORK_DB_PATH="${WORK_DB_PATH:-$WORK_DB_DEFAULT}"

# Database table names
WORK_STATE_TABLE="${WORK_STATE_TABLE:-state}"
WORK_SESSIONS_TABLE="${WORK_SESSIONS_TABLE:-sessions}"

# =============================================================================
# INSTALLATION PATHS
# =============================================================================

# Default installation directory
WORK_INSTALL_DIR_DEFAULT="$HOME/.local/bin"

# Installation directory (can be overridden by environment variable)
WORK_INSTALL_DIR="${WORK_INSTALL_DIR:-$WORK_INSTALL_DIR_DEFAULT}"

# Work data directory
WORK_DATA_DIR="$HOME/.local/work"

# Library directory
WORK_LIB_DIR="$WORK_DATA_DIR/lib"

# Commands directory
WORK_COMMANDS_DIR="$WORK_DATA_DIR/commands"

# =============================================================================
# BEHAVIOR CONFIGURATION
# =============================================================================

# Verbose mode (can be overridden by environment variable)
WORK_VERBOSE="${WORK_VERBOSE:-false}"

# Default idle session threshold (in seconds)
WORK_IDLE_THRESHOLD="${WORK_IDLE_THRESHOLD:-60}"

# Maximum project name length
WORK_MAX_PROJECT_LENGTH="${WORK_MAX_PROJECT_LENGTH:-100}"

# Default prompt format
WORK_DEFAULT_PROMPT='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

# Work prompt format (with project placeholder)
WORK_PROMPT_FORMAT='⏳ [%s] ${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

# =============================================================================
# NOTIFICATION CONFIGURATION
# =============================================================================

# Enable notifications (can be overridden by environment variable)
WORK_NOTIFICATIONS="${WORK_NOTIFICATIONS:-true}"

# Notification timeout (in milliseconds)
WORK_NOTIFICATION_TIMEOUT="${WORK_NOTIFICATION_TIMEOUT:-5000}"

# =============================================================================
# NUDGING CONFIGURATION
# =============================================================================

# Enable nudging (can be overridden by environment variable)
WORK_NUDGING="${WORK_NUDGING:-true}"

# Nudging interval (in minutes)
WORK_NUDGE_INTERVAL="${WORK_NUDGE_INTERVAL:-10}"

# Nudge message format
WORK_NUDGE_MESSAGE="⏰ Time to check your work status! Run 'work status' to see current progress."

# =============================================================================
# REPORTING CONFIGURATION
# =============================================================================

# Default report limit (number of sessions to show)
WORK_REPORT_LIMIT="${WORK_REPORT_LIMIT:-20}"

# Date format for reports
WORK_DATE_FORMAT="${WORK_DATE_FORMAT:-%Y-%m-%d %H:%M}"

# Time format for reports
WORK_TIME_FORMAT="${WORK_TIME_FORMAT:-%H:%M}"

# =============================================================================
# EXPORT/IMPORT CONFIGURATION
# =============================================================================

# Default export filename format
WORK_EXPORT_FORMAT="work-export-%Y%m%d_%H%M%S.sql"

# Export directory (optional, defaults to current directory)
WORK_EXPORT_DIR="${WORK_EXPORT_DIR:-}"

# =============================================================================
# VALIDATION CONFIGURATION
# =============================================================================

# Maximum session duration (in hours) - for validation
WORK_MAX_SESSION_HOURS="${WORK_MAX_SESSION_HOURS:-24}"

# Minimum session duration (in seconds) - for validation
WORK_MIN_SESSION_SECONDS="${WORK_MIN_SESSION_SECONDS:-1}"

# =============================================================================
# DEBUG CONFIGURATION
# =============================================================================

# Debug mode (can be overridden by environment variable)
WORK_DEBUG="${WORK_DEBUG:-false}"

# Log file path (optional)
WORK_LOG_FILE="${WORK_LOG_FILE:-}"

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

# Function to get configuration value
get_config() {
    local key="$1"
    local default="$2"
    
    # Check if environment variable exists
    local env_var="WORK_${key^^}"
    if [[ -n "${!env_var}" ]]; then
        echo "${!env_var}"
        return 0
    fi
    
    # Return default value
    echo "$default"
}

# Function to set configuration value
set_config() {
    local key="$1"
    local value="$2"
    
    # Export the environment variable
    export "WORK_${key^^}=$value"
}

# Function to load configuration from file
load_config() {
    local config_file="$1"
    
    if [[ -f "$config_file" ]]; then
        # Source the config file
        source "$config_file"
    fi
}

# Function to save configuration to file
save_config() {
    local config_file="$1"
    
    # Create directory if it doesn't exist
    local config_dir
    config_dir=$(dirname "$config_file")
    mkdir -p "$config_dir"
    
    # Generate configuration file content
    cat > "$config_file" << EOF
# Refocus Shell Configuration
# Generated on $(date)

# Database Configuration
WORK_DB_PATH="$WORK_DB_PATH"
WORK_STATE_TABLE="$WORK_STATE_TABLE"
WORK_SESSIONS_TABLE="$WORK_SESSIONS_TABLE"

# Installation Paths
WORK_INSTALL_DIR="$WORK_INSTALL_DIR"
WORK_DATA_DIR="$WORK_DATA_DIR"

# Behavior Configuration
WORK_VERBOSE="$WORK_VERBOSE"
WORK_IDLE_THRESHOLD="$WORK_IDLE_THRESHOLD"
WORK_MAX_PROJECT_LENGTH="$WORK_MAX_PROJECT_LENGTH"

# Notification Configuration
WORK_NOTIFICATIONS="$WORK_NOTIFICATIONS"
WORK_NOTIFICATION_TIMEOUT="$WORK_NOTIFICATION_TIMEOUT"

# Nudging Configuration
WORK_NUDGING="$WORK_NUDGING"
WORK_NUDGE_INTERVAL="$WORK_NUDGE_INTERVAL"

# Reporting Configuration
WORK_REPORT_LIMIT="$WORK_REPORT_LIMIT"
WORK_DATE_FORMAT="$WORK_DATE_FORMAT"
WORK_TIME_FORMAT="$WORK_TIME_FORMAT"

# Export/Import Configuration
WORK_EXPORT_FORMAT="$WORK_EXPORT_FORMAT"
WORK_EXPORT_DIR="$WORK_EXPORT_DIR"

# Validation Configuration
WORK_MAX_SESSION_HOURS="$WORK_MAX_SESSION_HOURS"
WORK_MIN_SESSION_SECONDS="$WORK_MIN_SESSION_SECONDS"

# Debug Configuration
WORK_DEBUG="$WORK_DEBUG"
WORK_LOG_FILE="$WORK_LOG_FILE"
EOF
}

# Function to validate configuration
validate_config() {
    local errors=0
    
    # Validate database path
    if [[ -z "$WORK_DB_PATH" ]]; then
        echo "❌ WORK_DB_PATH is not set"
        ((errors++))
    fi
    
    # Validate installation directory
    if [[ -z "$WORK_INSTALL_DIR" ]]; then
        echo "❌ WORK_INSTALL_DIR is not set"
        ((errors++))
    fi
    
    # Validate numeric values
    if ! [[ "$WORK_IDLE_THRESHOLD" =~ ^[0-9]+$ ]]; then
        echo "❌ WORK_IDLE_THRESHOLD must be a positive integer"
        ((errors++))
    fi
    
    if ! [[ "$WORK_MAX_PROJECT_LENGTH" =~ ^[0-9]+$ ]]; then
        echo "❌ WORK_MAX_PROJECT_LENGTH must be a positive integer"
        ((errors++))
    fi
    
    if ! [[ "$WORK_NUDGE_INTERVAL" =~ ^[0-9]+$ ]]; then
        echo "❌ WORK_NUDGE_INTERVAL must be a positive integer"
        ((errors++))
    fi
    
    if ! [[ "$WORK_REPORT_LIMIT" =~ ^[0-9]+$ ]]; then
        echo "❌ WORK_REPORT_LIMIT must be a positive integer"
        ((errors++))
    fi
    
    # Return number of errors
    return $errors
}

# Function to show current configuration
show_config() {
    echo "Refocus Shell Configuration"
    echo "========================="
    echo
    echo "Database:"
    echo "  DB Path: $WORK_DB_PATH"
    echo "  State Table: $WORK_STATE_TABLE"
    echo "  Sessions Table: $WORK_SESSIONS_TABLE"
    echo
    echo "Installation:"
    echo "  Install Dir: $WORK_INSTALL_DIR"
    echo "  Data Dir: $WORK_DATA_DIR"
    echo "  Lib Dir: $WORK_LIB_DIR"
    echo "  Commands Dir: $WORK_COMMANDS_DIR"
    echo
    echo "Behavior:"
    echo "  Verbose: $WORK_VERBOSE"
    echo "  Idle Threshold: ${WORK_IDLE_THRESHOLD}s"
    echo "  Max Project Length: ${WORK_MAX_PROJECT_LENGTH} chars"
    echo
    echo "Notifications:"
    echo "  Enabled: $WORK_NOTIFICATIONS"
    echo "  Timeout: ${WORK_NOTIFICATION_TIMEOUT}ms"
    echo
    echo "Nudging:"
    echo "  Enabled: $WORK_NUDGING"
    echo "  Interval: ${WORK_NUDGE_INTERVAL} minutes"
    echo
    echo "Reporting:"
    echo "  Report Limit: $WORK_REPORT_LIMIT"
    echo "  Date Format: $WORK_DATE_FORMAT"
    echo "  Time Format: $WORK_TIME_FORMAT"
    echo
    echo "Validation:"
    echo "  Max Session Hours: $WORK_MAX_SESSION_HOURS"
    echo "  Min Session Seconds: $WORK_MIN_SESSION_SECONDS"
    echo
    echo "Debug:"
    echo "  Debug Mode: $WORK_DEBUG"
    echo "  Log File: ${WORK_LOG_FILE:-none}"
}

# Load user configuration if it exists
USER_CONFIG="$HOME/.config/refocus-shell/config.sh"
if [[ -f "$USER_CONFIG" ]]; then
    load_config "$USER_CONFIG"
fi

# Validate configuration on load
if [[ "${WORK_VALIDATE_CONFIG:-true}" == "true" ]]; then
    if ! validate_config >/dev/null 2>&1; then
        echo "Warning: Some configuration values are invalid. Run 'work config validate' to see details."
    fi
fi 