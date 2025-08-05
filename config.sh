#!/usr/bin/env bash
# Refocus Shell Configuration
# Copyright (c) 2025 PeGa
# Licensed under the GNU General Public License v3

# =============================================================================
# DATABASE CONFIGURATION
# =============================================================================

# Default database path
FOCUS_DB_DEFAULT="$HOME/.local/focus/timelog.db"

# Database path (can be overridden by environment variable)
FOCUS_DB_PATH="${FOCUS_DB_PATH:-$FOCUS_DB_DEFAULT}"

# Database table names
FOCUS_STATE_TABLE="${FOCUS_STATE_TABLE:-state}"
FOCUS_SESSIONS_TABLE="${FOCUS_SESSIONS_TABLE:-sessions}"

# =============================================================================
# INSTALLATION PATHS
# =============================================================================

# Default installation directory
FOCUS_INSTALL_DIR_DEFAULT="$HOME/.local/bin"

# Installation directory (can be overridden by environment variable)
FOCUS_INSTALL_DIR="${FOCUS_INSTALL_DIR:-$FOCUS_INSTALL_DIR_DEFAULT}"

# Focus data directory
FOCUS_DATA_DIR="$HOME/.local/focus"

# Library directory
FOCUS_LIB_DIR="$FOCUS_DATA_DIR/lib"

# Commands directory
FOCUS_COMMANDS_DIR="$FOCUS_DATA_DIR/commands"

# =============================================================================
# BEHAVIOR CONFIGURATION
# =============================================================================

# Verbose mode (can be overridden by environment variable)
FOCUS_VERBOSE="${FOCUS_VERBOSE:-false}"

# Default idle session threshold (in seconds)
FOCUS_IDLE_THRESHOLD="${FOCUS_IDLE_THRESHOLD:-60}"

# Maximum project name length
FOCUS_MAX_PROJECT_LENGTH="${FOCUS_MAX_PROJECT_LENGTH:-100}"

# Default prompt format
FOCUS_DEFAULT_PROMPT='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

# Focus prompt format (with project placeholder)
FOCUS_PROMPT_FORMAT='⏳ [%s] ${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

# =============================================================================
# NOTIFICATION CONFIGURATION
# =============================================================================

# Enable notifications (can be overridden by environment variable)
FOCUS_NOTIFICATIONS="${FOCUS_NOTIFICATIONS:-true}"

# Notification timeout (in milliseconds)
FOCUS_NOTIFICATION_TIMEOUT="${FOCUS_NOTIFICATION_TIMEOUT:-5000}"

# =============================================================================
# NUDGING CONFIGURATION
# =============================================================================

# Enable nudging (can be overridden by environment variable)
FOCUS_NUDGING="${FOCUS_NUDGING:-true}"

# Nudging interval (in minutes)
FOCUS_NUDGE_INTERVAL="${FOCUS_NUDGE_INTERVAL:-10}"

# Nudge message format
FOCUS_NUDGE_MESSAGE="⏰ Time to check your focus status! Run 'focus status' to see current progress."

# =============================================================================
# REPORTING CONFIGURATION
# =============================================================================

# Default report limit (number of sessions to show)
FOCUS_REPORT_LIMIT="${FOCUS_REPORT_LIMIT:-20}"

# Date format for reports
FOCUS_DATE_FORMAT="${FOCUS_DATE_FORMAT:-%Y-%m-%d %H:%M}"

# Time format for reports
FOCUS_TIME_FORMAT="${FOCUS_TIME_FORMAT:-%H:%M}"

# =============================================================================
# EXPORT/IMPORT CONFIGURATION
# =============================================================================

# Default export filename format
FOCUS_EXPORT_FORMAT="focus-export-%Y%m%d_%H%M%S.sql"

# Export directory (optional, defaults to current directory)
FOCUS_EXPORT_DIR="${FOCUS_EXPORT_DIR:-}"

# =============================================================================
# VALIDATION CONFIGURATION
# =============================================================================

# Maximum session duration (in hours) - for validation
FOCUS_MAX_SESSION_HOURS="${FOCUS_MAX_SESSION_HOURS:-24}"

# Minimum session duration (in seconds) - for validation
FOCUS_MIN_SESSION_SECONDS="${FOCUS_MIN_SESSION_SECONDS:-1}"

# =============================================================================
# DEBUG CONFIGURATION
# =============================================================================

# Debug mode (can be overridden by environment variable)
FOCUS_DEBUG="${FOCUS_DEBUG:-false}"

# Log file path (optional)
FOCUS_LOG_FILE="${FOCUS_LOG_FILE:-}"

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

# Function to get configuration value
get_config() {
    local key="$1"
    local default="$2"
    
    # Check if environment variable exists
    local env_var="FOCUS_${key^^}"
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
    export "FOCUS_${key^^}=$value"
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
FOCUS_DB_PATH="$FOCUS_DB_PATH"
FOCUS_STATE_TABLE="$FOCUS_STATE_TABLE"
FOCUS_SESSIONS_TABLE="$FOCUS_SESSIONS_TABLE"

# Installation Paths
FOCUS_INSTALL_DIR="$FOCUS_INSTALL_DIR"
FOCUS_DATA_DIR="$FOCUS_DATA_DIR"

# Behavior Configuration
FOCUS_VERBOSE="$FOCUS_VERBOSE"
FOCUS_IDLE_THRESHOLD="$FOCUS_IDLE_THRESHOLD"
FOCUS_MAX_PROJECT_LENGTH="$FOCUS_MAX_PROJECT_LENGTH"

# Notification Configuration
FOCUS_NOTIFICATIONS="$FOCUS_NOTIFICATIONS"
FOCUS_NOTIFICATION_TIMEOUT="$FOCUS_NOTIFICATION_TIMEOUT"

# Nudging Configuration
FOCUS_NUDGING="$FOCUS_NUDGING"
FOCUS_NUDGE_INTERVAL="$FOCUS_NUDGE_INTERVAL"

# Reporting Configuration
FOCUS_REPORT_LIMIT="$FOCUS_REPORT_LIMIT"
FOCUS_DATE_FORMAT="$FOCUS_DATE_FORMAT"
FOCUS_TIME_FORMAT="$FOCUS_TIME_FORMAT"

# Export/Import Configuration
FOCUS_EXPORT_FORMAT="$FOCUS_EXPORT_FORMAT"
FOCUS_EXPORT_DIR="$FOCUS_EXPORT_DIR"

# Validation Configuration
FOCUS_MAX_SESSION_HOURS="$FOCUS_MAX_SESSION_HOURS"
FOCUS_MIN_SESSION_SECONDS="$FOCUS_MIN_SESSION_SECONDS"

# Debug Configuration
FOCUS_DEBUG="$FOCUS_DEBUG"
FOCUS_LOG_FILE="$FOCUS_LOG_FILE"
EOF
}

# Function to validate configuration
validate_config() {
    local errors=0
    
    # Validate database path
    if [[ -z "$FOCUS_DB_PATH" ]]; then
        echo "❌ FOCUS_DB_PATH is not set"
        ((errors++))
    fi
    
    # Validate installation directory
    if [[ -z "$FOCUS_INSTALL_DIR" ]]; then
        echo "❌ FOCUS_INSTALL_DIR is not set"
        ((errors++))
    fi
    
    # Validate numeric values
    if ! [[ "$FOCUS_IDLE_THRESHOLD" =~ ^[0-9]+$ ]]; then
        echo "❌ FOCUS_IDLE_THRESHOLD must be a positive integer"
        ((errors++))
    fi
    
    if ! [[ "$FOCUS_MAX_PROJECT_LENGTH" =~ ^[0-9]+$ ]]; then
        echo "❌ FOCUS_MAX_PROJECT_LENGTH must be a positive integer"
        ((errors++))
    fi
    
    if ! [[ "$FOCUS_NUDGE_INTERVAL" =~ ^[0-9]+$ ]]; then
        echo "❌ FOCUS_NUDGE_INTERVAL must be a positive integer"
        ((errors++))
    fi
    
    if ! [[ "$FOCUS_REPORT_LIMIT" =~ ^[0-9]+$ ]]; then
        echo "❌ FOCUS_REPORT_LIMIT must be a positive integer"
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
    echo "  DB Path: $FOCUS_DB_PATH"
    echo "  State Table: $FOCUS_STATE_TABLE"
    echo "  Sessions Table: $FOCUS_SESSIONS_TABLE"
    echo
    echo "Installation:"
    echo "  Install Dir: $FOCUS_INSTALL_DIR"
    echo "  Data Dir: $FOCUS_DATA_DIR"
    echo "  Lib Dir: $FOCUS_LIB_DIR"
    echo "  Commands Dir: $FOCUS_COMMANDS_DIR"
    echo
    echo "Behavior:"
    echo "  Verbose: $FOCUS_VERBOSE"
    echo "  Idle Threshold: ${FOCUS_IDLE_THRESHOLD}s"
    echo "  Max Project Length: ${FOCUS_MAX_PROJECT_LENGTH} chars"
    echo
    echo "Notifications:"
    echo "  Enabled: $FOCUS_NOTIFICATIONS"
    echo "  Timeout: ${FOCUS_NOTIFICATION_TIMEOUT}ms"
    echo
    echo "Nudging:"
    echo "  Enabled: $FOCUS_NUDGING"
    echo "  Interval: ${FOCUS_NUDGE_INTERVAL} minutes"
    echo
    echo "Reporting:"
    echo "  Report Limit: $FOCUS_REPORT_LIMIT"
    echo "  Date Format: $FOCUS_DATE_FORMAT"
    echo "  Time Format: $FOCUS_TIME_FORMAT"
    echo
    echo "Validation:"
    echo "  Max Session Hours: $FOCUS_MAX_SESSION_HOURS"
    echo "  Min Session Seconds: $FOCUS_MIN_SESSION_SECONDS"
    echo
    echo "Debug:"
    echo "  Debug Mode: $FOCUS_DEBUG"
    echo "  Log File: ${FOCUS_LOG_FILE:-none}"
}

# Load user configuration if it exists
USER_CONFIG="$HOME/.config/refocus-shell/config.sh"
if [[ -f "$USER_CONFIG" ]]; then
    load_config "$USER_CONFIG"
fi

# Validate configuration on load
if [[ "${FOCUS_VALIDATE_CONFIG:-true}" == "true" ]]; then
    if ! validate_config >/dev/null 2>&1; then
        echo "Warning: Some configuration values are invalid. Run 'focus config validate' to see details."
    fi
fi 