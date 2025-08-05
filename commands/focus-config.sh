#!/usr/bin/env bash
# Refocus Shell - Configuration Management Subcommand
# Copyright (c) 2025 PeGa
# Licensed under the GNU General Public License v3

# Source libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$HOME/.local/focus/lib/focus-db.sh" ]]; then
    source "$HOME/.local/focus/lib/focus-db.sh"
    source "$HOME/.local/focus/lib/focus-utils.sh"
else
    source "$SCRIPT_DIR/../lib/focus-db.sh"
    source "$SCRIPT_DIR/../lib/focus-utils.sh"
fi

# Source configuration
if [[ -f "$SCRIPT_DIR/../config.sh" ]]; then
    source "$SCRIPT_DIR/../config.sh"
elif [[ -f "$HOME/.local/focus/config.sh" ]]; then
    source "$HOME/.local/focus/config.sh"
elif [[ -f "$HOME/dev/personal/refocus-shell/config.sh" ]]; then
    source "$HOME/dev/personal/refocus-shell/config.sh"
else
    echo "❌ Configuration file not found"
    exit 1
fi

function focus_config_show() {
    show_config
}

function focus_config_validate() {
    echo "Validating Refocus Shell Configuration..."
    echo "======================================"
    echo
    
    local errors=0
    
    # Validate database path
    if [[ -z "$FOCUS_DB_PATH" ]]; then
        echo "❌ FOCUS_DB_PATH is not set"
        ((errors++))
    else
        echo "✅ FOCUS_DB_PATH: $FOCUS_DB_PATH"
    fi
    
    # Validate installation directory
    if [[ -z "$FOCUS_INSTALL_DIR" ]]; then
        echo "❌ FOCUS_INSTALL_DIR is not set"
        ((errors++))
    else
        echo "✅ FOCUS_INSTALL_DIR: $FOCUS_INSTALL_DIR"
    fi
    
    # Validate numeric values
    if ! [[ "$FOCUS_IDLE_THRESHOLD" =~ ^[0-9]+$ ]]; then
        echo "❌ FOCUS_IDLE_THRESHOLD must be a positive integer (current: $FOCUS_IDLE_THRESHOLD)"
        ((errors++))
    else
        echo "✅ FOCUS_IDLE_THRESHOLD: ${FOCUS_IDLE_THRESHOLD}s"
    fi
    
    if ! [[ "$FOCUS_MAX_PROJECT_LENGTH" =~ ^[0-9]+$ ]]; then
        echo "❌ FOCUS_MAX_PROJECT_LENGTH must be a positive integer (current: $FOCUS_MAX_PROJECT_LENGTH)"
        ((errors++))
    else
        echo "✅ FOCUS_MAX_PROJECT_LENGTH: ${FOCUS_MAX_PROJECT_LENGTH} chars"
    fi
    
    if ! [[ "$FOCUS_NUDGE_INTERVAL" =~ ^[0-9]+$ ]]; then
        echo "❌ FOCUS_NUDGE_INTERVAL must be a positive integer (current: $FOCUS_NUDGE_INTERVAL)"
        ((errors++))
    else
        echo "✅ FOCUS_NUDGE_INTERVAL: ${FOCUS_NUDGE_INTERVAL} minutes"
    fi
    
    if ! [[ "$FOCUS_REPORT_LIMIT" =~ ^[0-9]+$ ]]; then
        echo "❌ FOCUS_REPORT_LIMIT must be a positive integer (current: $FOCUS_REPORT_LIMIT)"
        ((errors++))
    else
        echo "✅ FOCUS_REPORT_LIMIT: $FOCUS_REPORT_LIMIT"
    fi
    
    # Check if database exists
    if [[ -f "$FOCUS_DB_PATH" ]]; then
        echo "✅ Database exists: $FOCUS_DB_PATH"
    else
        echo "⚠️  Database does not exist: $FOCUS_DB_PATH"
    fi
    
    # Check if installation directory exists
    if [[ -d "$FOCUS_INSTALL_DIR" ]]; then
        echo "✅ Installation directory exists: $FOCUS_INSTALL_DIR"
    else
        echo "⚠️  Installation directory does not exist: $FOCUS_INSTALL_DIR"
    fi
    
    echo
    if [[ $errors -eq 0 ]]; then
        echo "✅ Configuration is valid!"
    else
        echo "❌ Configuration has $errors error(s)."
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
    export "FOCUS_${key^^}=$value"
    
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
    local env_var="WORK_${key^^}"
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
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    focus_config "$@"
fi 