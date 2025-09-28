#!/usr/bin/env bash
# Refocus Shell - Config Subcommand
# Copyright (c) 2025 PeGa
# Licensed under the GNU General Public License v3

PROJECTS_TABLE="${PROJECTS_TABLE:-projects}"

# Source bootstrap module
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/focus-bootstrap.sh"

# Source centralized validation functions
# Note: Using direct validation instead of centralized functions

function focus_config_show() {
    echo "Refocus Shell Configuration"
    echo "=========================="
    echo
    echo "Database: $DB"
    echo "Data Directory: $(get_cfg DATA_DIR "$HOME/.local/refocus")"
    echo "Log Directory: $(get_cfg DATA_DIR "$HOME/.local/refocus")"
    echo "Error Log: $(get_cfg DATA_DIR "$HOME/.local/refocus")/error.log"
    echo
    echo "Table Names:"
    echo "  State: ${REFOCUS_STATE_TABLE:-state}"
    echo "  Sessions: ${REFOCUS_SESSIONS_TABLE:-sessions}"
    echo "  Projects: ${REFOCUS_PROJECTS_TABLE:-projects}"
    echo
    echo "Environment Variables:"
    echo "  REFOCUS_DATA_PATH: ${REFOCUS_DATA_PATH:-not set}"
    echo "  REFOCUS_LOG_DIR: ${REFOCUS_LOG_DIR:-not set}"
    echo "  REFOCUS_ERROR_LOG: ${REFOCUS_ERROR_LOG:-not set}"
}

function focus_config_validate() {
    echo "Validating Refocus Shell Configuration..."
    echo "======================================"
    echo
    
    local errors=0
    
    # Validate database path
    if [[ -z "$(get_cfg DB_PATH "$HOME/.local/refocus/refocus.db")" ]]; then
        format_error_message "REFOCUS_DB_PATH is not set"
        ((errors++))
    else
        format_success_message "REFOCUS_DB_PATH: $REFOCUS_DB_PATH"
    fi
    
    # Validate installation directory
    if [[ -z "$REFOCUS_INSTALL_DIR" ]]; then
        format_error_message "REFOCUS_INSTALL_DIR is not set"
        ((errors++))
    else
        format_success_message "REFOCUS_INSTALL_DIR: $REFOCUS_INSTALL_DIR"
    fi
    
    # Validate numeric values using centralized function
    if ! validate_numeric_input_standardized "$REFOCUS_IDLE_THRESHOLD" "REFOCUS_IDLE_THRESHOLD" 1 3600; then
        format_error_message "REFOCUS_IDLE_THRESHOLD validation failed" "Current value: $REFOCUS_IDLE_THRESHOLD"
        ((errors++))
    else
        format_success_message "REFOCUS_IDLE_THRESHOLD: ${REFOCUS_IDLE_THRESHOLD}s"
    fi
    
    if ! validate_numeric_input_standardized "$REFOCUS_MAX_PROJECT_LENGTH" "REFOCUS_MAX_PROJECT_LENGTH" 1 1000; then
        format_error_message "REFOCUS_MAX_PROJECT_LENGTH validation failed" "Current value: $REFOCUS_MAX_PROJECT_LENGTH"
        ((errors++))
    else
        format_success_message "REFOCUS_MAX_PROJECT_LENGTH: ${REFOCUS_MAX_PROJECT_LENGTH} chars"
    fi
    
    if ! validate_numeric_input_standardized "$REFOCUS_NUDGE_INTERVAL" "REFOCUS_NUDGE_INTERVAL" 1 1440; then
        format_error_message "REFOCUS_NUDGE_INTERVAL validation failed" "Current value: $REFOCUS_NUDGE_INTERVAL"
        ((errors++))
    else
        format_success_message "REFOCUS_NUDGE_INTERVAL: ${REFOCUS_NUDGE_INTERVAL} minutes"
    fi
    
    if ! validate_numeric_input_standardized "$REFOCUS_REPORT_LIMIT" "REFOCUS_REPORT_LIMIT" 1 10000; then
        format_error_message "REFOCUS_REPORT_LIMIT validation failed" "Current value: $REFOCUS_REPORT_LIMIT"
        ((errors++))
    else
        format_success_message "REFOCUS_REPORT_LIMIT: $REFOCUS_REPORT_LIMIT"
    fi
    
    # Check if database exists
    if [[ -f "$REFOCUS_DB_PATH" ]]; then
        format_success_message "Database exists: $REFOCUS_DB_PATH"
    else
        format_warning_message "Database does not exist: $REFOCUS_DB_PATH"
    fi
    
    # Check if installation directory exists
    if [[ -d "$REFOCUS_INSTALL_DIR" ]]; then
        format_success_message "Installation directory exists: $REFOCUS_INSTALL_DIR"
    else
        format_warning_message "Installation directory does not exist: $REFOCUS_INSTALL_DIR"
    fi
    
    echo
    if [[ $errors -eq 0 ]]; then
        format_success_message "Configuration is valid!"
    else
        format_error_message "Configuration has $errors error(s)."
        exit 1
    fi
}

function focus_config_set() {
    local key="$1"
    local value="$2"
    
    if [[ -z "$key" ]]; then
        echo "❌ Configuration key is required."
        echo "Usage: focus config set <key> <value>"
        echo "Example: focus config set VERBOSE true"
        exit 1
    fi
    
    if [[ -z "$value" ]]; then
        echo "❌ Configuration value is required."
        echo "Usage: focus config set <key> <value>"
        exit 1
    fi
    
    # Set the configuration value directly
    export "REFOCUS_${key^^}=$value"
    
    echo "✅ Set $key = $value"
    echo "Note: This change is temporary. Use 'focus config save' to make it permanent."
}

function focus_config_get() {
    local key="$1"
    
    if [[ -z "$key" ]]; then
        echo "❌ Configuration key is required."
        echo "Usage: focus config get <key>"
        echo "Example: focus config get VERBOSE"
        exit 1
    fi
    
    # Get the configuration value directly from environment variable
    local env_var="REFOCUS_${key^^}"
    if [[ -n "${!env_var}" ]]; then
        echo "${!env_var}"
    else
        echo "Configuration key '$key' not found."
        exit 1
    fi
}

function focus_config_save() {
    local config_file="$HOME/.config/refocus-shell/config.sh"
    
    echo "Saving configuration to: $config_file"
    
    # Save the configuration
    save_config "$config_file"
    
    echo "✅ Configuration saved successfully!"
    echo "The configuration will be loaded automatically on next startup."
}

function focus_config_reset() {
    local config_file="$HOME/.config/refocus-shell/config.sh"
    
    echo "This will reset all custom configuration to defaults."
    echo "Are you sure you want to continue? (y/N)"
    read -r response
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        if [[ -f "$config_file" ]]; then
            rm -f "$config_file"
            echo "✅ Configuration reset to defaults"
        else
            echo "✅ No custom configuration found (already using defaults)"
        fi
    else
        echo "Configuration reset cancelled."
    fi
}

function focus_config() {
    local action="$1"
    shift
    
    case "$action" in
        "show"|"list")
            focus_config_show
            ;;
        "validate"|"check")
            focus_config_validate
            ;;
        "set")
            focus_config_set "$@"
            ;;
        "get")
            focus_config_get "$@"
            ;;
        "save")
            focus_config_save
            ;;
        "reset")
            focus_config_reset
            ;;
        *)
            echo "❌ Unknown action: $action"
            echo "Available actions:"
            echo "  show     - Show current configuration"
            echo "  validate - Validate configuration"
            echo "  set      - Set a configuration value"
            echo "  get      - Get a configuration value"
            echo "  save     - Save configuration to file"
            echo "  reset    - Reset to defaults"
            echo
            echo "Examples:"
            echo "  focus config show"
            echo "  focus config set VERBOSE true"
            echo "  focus config get VERBOSE"
            echo "  focus config save"
            exit 1
            ;;
    esac
}


# Main execution
refocus_script_main focus_config "$@"
