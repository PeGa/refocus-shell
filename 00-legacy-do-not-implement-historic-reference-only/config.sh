#!/usr/bin/env bash
# Refocus Shell Configuration
# Copyright (c) 2025 PeGa
# Licensed under the GNU General Public License v3

# =============================================================================
# DATABASE CONFIGURATION
# =============================================================================

# Default database path
REFOCUS_DB_DEFAULT="$HOME/.local/refocus/refocus.db"

# Database path (can be overridden by environment variable)
REFOCUS_DB_PATH="${REFOCUS_DB_PATH:-$REFOCUS_DB_DEFAULT}"

# Database table names (namespaced to avoid shell pollution)
REFOCUS_STATE_TABLE="${REFOCUS_STATE_TABLE:-state}"
REFOCUS_SESSIONS_TABLE="${REFOCUS_SESSIONS_TABLE:-sessions}"
REFOCUS_PROJECTS_TABLE="${REFOCUS_PROJECTS_TABLE:-projects}"

# =============================================================================
# INSTALLATION PATHS
# =============================================================================

# Default installation directory
REFOCUS_INSTALL_DIR_DEFAULT="$HOME/.local/bin"

# Installation directory (can be overridden by environment variable)
REFOCUS_INSTALL_DIR="${REFOCUS_INSTALL_DIR:-$REFOCUS_INSTALL_DIR_DEFAULT}"

# Refocus data directory
REFOCUS_DATA_DIR="$HOME/.local/refocus"

# Library directory
REFOCUS_LIB_DIR="$REFOCUS_DATA_DIR/lib"

# Commands directory
REFOCUS_COMMANDS_DIR="$REFOCUS_DATA_DIR/commands"

# =============================================================================
# BEHAVIOR CONFIGURATION
# =============================================================================

# Verbose mode (can be overridden by environment variable)
REFOCUS_VERBOSE="${REFOCUS_VERBOSE:-false}"

# Default idle session threshold (in seconds)
REFOCUS_IDLE_THRESHOLD="${REFOCUS_IDLE_THRESHOLD:-60}"

# Maximum project name length
REFOCUS_MAX_PROJECT_LENGTH="${REFOCUS_MAX_PROJECT_LENGTH:-100}"

# Default prompt format
REFOCUS_DEFAULT_PROMPT='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

# Focus prompt format (with project placeholder)
REFOCUS_PROMPT_FORMAT='⏳ [%s] ${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

# =============================================================================
# NOTIFICATION CONFIGURATION
# =============================================================================

# Enable notifications (can be overridden by environment variable)
REFOCUS_NOTIFICATIONS="${REFOCUS_NOTIFICATIONS:-true}"

# Notification timeout (in milliseconds)
REFOCUS_NOTIFICATION_TIMEOUT="${REFOCUS_NOTIFICATION_TIMEOUT:-5000}"

# =============================================================================
# NUDGING CONFIGURATION
# =============================================================================

# Enable nudging (can be overridden by environment variable)
REFOCUS_NUDGING="${REFOCUS_NUDGING:-true}"

# Nudging interval (in minutes)
REFOCUS_NUDGE_INTERVAL="${REFOCUS_NUDGE_INTERVAL:-10}"

# Nudge message format
REFOCUS_NUDGE_MESSAGE="⏰ Time to check your focus status! Run 'focus status' to see current progress."

# =============================================================================
# REPORTING CONFIGURATION
# =============================================================================

# Default report limit (number of sessions to show)
REFOCUS_REPORT_LIMIT="${REFOCUS_REPORT_LIMIT:-20}"

# Date format for reports
REFOCUS_DATE_FORMAT="${REFOCUS_DATE_FORMAT:-%Y-%m-%d %H:%M}"

# Time format for reports
REFOCUS_TIME_FORMAT="${REFOCUS_TIME_FORMAT:-%H:%M}"

# =============================================================================
# EXPORT/IMPORT CONFIGURATION
# =============================================================================

# Default export filename format
REFOCUS_EXPORT_FORMAT="refocus-export-%Y%m%d_%H%M%S.sql"

# Export directory (optional, defaults to current directory)
REFOCUS_EXPORT_DIR="${REFOCUS_EXPORT_DIR:-}"

# =============================================================================
# VALIDATION CONFIGURATION
# =============================================================================

# Maximum session duration (in hours) - for validation
REFOCUS_MAX_SESSION_HOURS="${REFOCUS_MAX_SESSION_HOURS:-24}"

# Minimum session duration (in seconds) - for validation
REFOCUS_MIN_SESSION_SECONDS="${REFOCUS_MIN_SESSION_SECONDS:-1}"

# =============================================================================
# DEBUG CONFIGURATION
# =============================================================================

# Debug mode (can be overridden by environment variable)
REFOCUS_DEBUG="${REFOCUS_DEBUG:-false}"

# Log file path (optional)
REFOCUS_LOG_FILE="${REFOCUS_LOG_FILE:-}"

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

# Function to get configuration value
get_config() {
    local key="$1"
    local default="$2"
    
    # Check if environment variable exists
    local env_var="REFOCUS_${key^^}"
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
    export "REFOCUS_${key^^}=$value"
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
REFOCUS_DB_PATH="$REFOCUS_DB_PATH"

# Installation Paths
REFOCUS_INSTALL_DIR="$REFOCUS_INSTALL_DIR"
REFOCUS_DATA_DIR="$REFOCUS_DATA_DIR"

# Behavior Configuration
REFOCUS_VERBOSE="$REFOCUS_VERBOSE"
REFOCUS_IDLE_THRESHOLD="$REFOCUS_IDLE_THRESHOLD"
REFOCUS_MAX_PROJECT_LENGTH="$REFOCUS_MAX_PROJECT_LENGTH"

# Notification Configuration
REFOCUS_NOTIFICATIONS="$REFOCUS_NOTIFICATIONS"
REFOCUS_NOTIFICATION_TIMEOUT="$REFOCUS_NOTIFICATION_TIMEOUT"

# Nudging Configuration
REFOCUS_NUDGING="$REFOCUS_NUDGING"
REFOCUS_NUDGE_INTERVAL="$REFOCUS_NUDGE_INTERVAL"

# Reporting Configuration
REFOCUS_REPORT_LIMIT="$REFOCUS_REPORT_LIMIT"
REFOCUS_DATE_FORMAT="$REFOCUS_DATE_FORMAT"
REFOCUS_TIME_FORMAT="$REFOCUS_TIME_FORMAT"

# Export/Import Configuration
REFOCUS_EXPORT_FORMAT="$REFOCUS_EXPORT_FORMAT"
REFOCUS_EXPORT_DIR="$REFOCUS_EXPORT_DIR"

# Validation Configuration
REFOCUS_MAX_SESSION_HOURS="$REFOCUS_MAX_SESSION_HOURS"
REFOCUS_MIN_SESSION_SECONDS="$REFOCUS_MIN_SESSION_SECONDS"

# Debug Configuration
REFOCUS_DEBUG="$REFOCUS_DEBUG"
REFOCUS_LOG_FILE="$REFOCUS_LOG_FILE"
EOF
}

# Function to validate configuration
validate_config() {
    local errors=0
    
    # Validate database path
    if [[ -z "$REFOCUS_DB_PATH" ]]; then
        echo "❌ REFOCUS_DB_PATH is not set"
        ((errors++))
    fi
    
    # Validate installation directory
    if [[ -z "$REFOCUS_INSTALL_DIR" ]]; then
        echo "❌ REFOCUS_INSTALL_DIR is not set"
        ((errors++))
    fi
    
    # Validate numeric values
    if ! [[ "$REFOCUS_IDLE_THRESHOLD" =~ ^[0-9]+$ ]]; then
        echo "❌ REFOCUS_IDLE_THRESHOLD must be a positive integer"
        ((errors++))
    fi
    
    if ! [[ "$REFOCUS_MAX_PROJECT_LENGTH" =~ ^[0-9]+$ ]]; then
        echo "❌ REFOCUS_MAX_PROJECT_LENGTH must be a positive integer"
        ((errors++))
    fi
    
    if ! [[ "$REFOCUS_NUDGE_INTERVAL" =~ ^[0-9]+$ ]]; then
        echo "❌ REFOCUS_NUDGE_INTERVAL must be a positive integer"
        ((errors++))
    fi
    
    if ! [[ "$REFOCUS_REPORT_LIMIT" =~ ^[0-9]+$ ]]; then
        echo "❌ REFOCUS_REPORT_LIMIT must be a positive integer"
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
    echo "  DB Path: $REFOCUS_DB_PATH"
    echo "  State Table: ${REFOCUS_STATE_TABLE:-state}"
    echo "  Sessions Table: $REFOCUS_SESSIONS_TABLE"
    echo
    echo "Installation:"
    echo "  Install Dir: $REFOCUS_INSTALL_DIR"
    echo "  Data Dir: $REFOCUS_DATA_DIR"
    echo "  Lib Dir: $REFOCUS_LIB_DIR"
    echo "  Commands Dir: $REFOCUS_COMMANDS_DIR"
    echo
    echo "Behavior:"
    echo "  Verbose: $REFOCUS_VERBOSE"
    echo "  Idle Threshold: ${REFOCUS_IDLE_THRESHOLD}s"
    echo "  Max Project Length: ${REFOCUS_MAX_PROJECT_LENGTH} chars"
    echo
    echo "Notifications:"
    echo "  Enabled: $REFOCUS_NOTIFICATIONS"
    echo "  Timeout: ${REFOCUS_NOTIFICATION_TIMEOUT}ms"
    echo
    echo "Nudging:"
    echo "  Enabled: $REFOCUS_NUDGING"
    echo "  Interval: ${REFOCUS_NUDGE_INTERVAL} minutes"
    echo
    echo "Reporting:"
    echo "  Report Limit: $REFOCUS_REPORT_LIMIT"
    echo "  Date Format: $REFOCUS_DATE_FORMAT"
    echo "  Time Format: $REFOCUS_TIME_FORMAT"
    echo
    echo "Validation:"
    echo "  Max Session Hours: $REFOCUS_MAX_SESSION_HOURS"
    echo "  Min Session Seconds: $REFOCUS_MIN_SESSION_SECONDS"
    echo
    echo "Debug:"
    echo "  Debug Mode: $REFOCUS_DEBUG"
    echo "  Log File: ${REFOCUS_LOG_FILE:-none}"
}

# Load user configuration if it exists
USER_CONFIG="$HOME/.config/refocus-shell/config.sh"
if [[ -f "$USER_CONFIG" ]]; then
    load_config "$USER_CONFIG"
fi

# Validate configuration on load
if [[ "${REFOCUS_VALIDATE_CONFIG:-true}" == "true" ]]; then
    if ! validate_config >/dev/null 2>&1; then
        echo "Warning: Some configuration values are invalid. Run 'focus config validate' to see details."
    fi
fi 
