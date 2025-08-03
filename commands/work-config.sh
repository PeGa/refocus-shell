#!/usr/bin/env bash
# Refocus Shell - Configuration Management Subcommand
# Copyright (c) 2025 PeGa
# Licensed under the GNU General Public License v3

# Source libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$HOME/.local/work/lib/work-db.sh" ]]; then
    source "$HOME/.local/work/lib/work-db.sh"
    source "$HOME/.local/work/lib/work-utils.sh"
else
    source "$SCRIPT_DIR/../lib/work-db.sh"
    source "$SCRIPT_DIR/../lib/work-utils.sh"
fi

# Source configuration
if [[ -f "$SCRIPT_DIR/../config.sh" ]]; then
    source "$SCRIPT_DIR/../config.sh"
elif [[ -f "$HOME/.local/work/config.sh" ]]; then
    source "$HOME/.local/work/config.sh"
elif [[ -f "$HOME/dev/personal/refocus-shell/config.sh" ]]; then
    source "$HOME/dev/personal/refocus-shell/config.sh"
else
    echo "❌ Configuration file not found"
    exit 1
fi

function work_config_show() {
    show_config
}

function work_config_validate() {
    echo "Validating Refocus Shell Configuration..."
    echo "======================================"
    echo
    
    local errors=0
    
    # Validate database path
    if [[ -z "$WORK_DB_PATH" ]]; then
        echo "❌ WORK_DB_PATH is not set"
        ((errors++))
    else
        echo "✅ WORK_DB_PATH: $WORK_DB_PATH"
    fi
    
    # Validate installation directory
    if [[ -z "$WORK_INSTALL_DIR" ]]; then
        echo "❌ WORK_INSTALL_DIR is not set"
        ((errors++))
    else
        echo "✅ WORK_INSTALL_DIR: $WORK_INSTALL_DIR"
    fi
    
    # Validate numeric values
    if ! [[ "$WORK_IDLE_THRESHOLD" =~ ^[0-9]+$ ]]; then
        echo "❌ WORK_IDLE_THRESHOLD must be a positive integer (current: $WORK_IDLE_THRESHOLD)"
        ((errors++))
    else
        echo "✅ WORK_IDLE_THRESHOLD: ${WORK_IDLE_THRESHOLD}s"
    fi
    
    if ! [[ "$WORK_MAX_PROJECT_LENGTH" =~ ^[0-9]+$ ]]; then
        echo "❌ WORK_MAX_PROJECT_LENGTH must be a positive integer (current: $WORK_MAX_PROJECT_LENGTH)"
        ((errors++))
    else
        echo "✅ WORK_MAX_PROJECT_LENGTH: ${WORK_MAX_PROJECT_LENGTH} chars"
    fi
    
    if ! [[ "$WORK_NUDGE_INTERVAL" =~ ^[0-9]+$ ]]; then
        echo "❌ WORK_NUDGE_INTERVAL must be a positive integer (current: $WORK_NUDGE_INTERVAL)"
        ((errors++))
    else
        echo "✅ WORK_NUDGE_INTERVAL: ${WORK_NUDGE_INTERVAL} minutes"
    fi
    
    if ! [[ "$WORK_REPORT_LIMIT" =~ ^[0-9]+$ ]]; then
        echo "❌ WORK_REPORT_LIMIT must be a positive integer (current: $WORK_REPORT_LIMIT)"
        ((errors++))
    else
        echo "✅ WORK_REPORT_LIMIT: $WORK_REPORT_LIMIT"
    fi
    
    # Check if database exists
    if [[ -f "$WORK_DB_PATH" ]]; then
        echo "✅ Database exists: $WORK_DB_PATH"
    else
        echo "⚠️  Database does not exist: $WORK_DB_PATH"
    fi
    
    # Check if installation directory exists
    if [[ -d "$WORK_INSTALL_DIR" ]]; then
        echo "✅ Installation directory exists: $WORK_INSTALL_DIR"
    else
        echo "⚠️  Installation directory does not exist: $WORK_INSTALL_DIR"
    fi
    
    echo
    if [[ $errors -eq 0 ]]; then
        echo "✅ Configuration is valid!"
    else
        echo "❌ Configuration has $errors error(s)."
        exit 1
    fi
}

function work_config_set() {
    local key="$1"
    local value="$2"
    
    if [[ -z "$key" ]]; then
        echo "❌ Configuration key is required."
        echo "Usage: work config set <key> <value>"
        echo "Example: work config set VERBOSE true"
        exit 1
    fi
    
    if [[ -z "$value" ]]; then
        echo "❌ Configuration value is required."
        echo "Usage: work config set <key> <value>"
        exit 1
    fi
    
    # Set the configuration value directly
    export "WORK_${key^^}=$value"
    
    echo "✅ Set $key = $value"
    echo "Note: This change is temporary. Use 'work config save' to make it permanent."
}

function work_config_get() {
    local key="$1"
    
    if [[ -z "$key" ]]; then
        echo "❌ Configuration key is required."
        echo "Usage: work config get <key>"
        echo "Example: work config get VERBOSE"
        exit 1
    fi
    
    # Get the configuration value directly from environment variable
    local env_var="WORK_${key^^}"
    if [[ -n "${!env_var}" ]]; then
        echo "${!env_var}"
    else
        echo "Configuration key '$key' not found."
        exit 1
    fi
}

function work_config_save() {
    local config_file="$HOME/.config/refocus-shell/config.sh"
    
    echo "Saving configuration to: $config_file"
    
    # Save the configuration
    save_config "$config_file"
    
    echo "✅ Configuration saved successfully!"
    echo "The configuration will be loaded automatically on next startup."
}

function work_config_reset() {
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

function work_config() {
    local action="$1"
    shift
    
    case "$action" in
        "show"|"list")
            work_config_show
            ;;
        "validate"|"check")
            work_config_validate
            ;;
        "set")
            work_config_set "$@"
            ;;
        "get")
            work_config_get "$@"
            ;;
        "save")
            work_config_save
            ;;
        "reset")
            work_config_reset
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
            echo "  work config show"
            echo "  work config set VERBOSE true"
            echo "  work config get VERBOSE"
            echo "  work config save"
            exit 1
            ;;
    esac
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    work_config "$@"
fi 