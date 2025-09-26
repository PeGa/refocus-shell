#!/usr/bin/env bash
# Refocus Shell - Configuration Management Subcommand
# Copyright (c) 2025 PeGa
# Licensed under the GNU General Public License v3

# Source libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$HOME/.local/refocus/lib/focus-db.sh" ]]; then
    source "$HOME/.local/refocus/lib/focus-db.sh"
    source "$HOME/.local/refocus/lib/focus-utils.sh"
else
    source "$SCRIPT_DIR/../lib/focus-db.sh"
    source "$SCRIPT_DIR/../lib/focus-utils.sh"
fi

# Source configuration
if [[ -f "$SCRIPT_DIR/../config.sh" ]]; then
    source "$SCRIPT_DIR/../config.sh"
elif [[ -f "$HOME/.local/refocus/config.sh" ]]; then
    source "$HOME/.local/refocus/config.sh"
else
    echo "❌ Configuration file not found"
    exit 1
fi

# Set table names
STATE_TABLE="${STATE_TABLE:-state}"
SESSIONS_TABLE="${SESSIONS_TABLE:-sessions}"
PROJECTS_TABLE="${PROJECTS_TABLE:-projects}"

# Ensure database is migrated to include projects table
migrate_database

function focus_config_show() {
    show_config
}

function focus_config_validate() {
    echo "Validating Refocus Shell Configuration..."
    echo "======================================"
    echo
    
    local errors=0
    
    # Validate database path
    if [[ -z "$REFOCUS_DB_PATH" ]]; then
        echo "❌ REFOCUS_DB_PATH is not set"
        ((errors++))
    else
        echo "✅ REFOCUS_DB_PATH: $REFOCUS_DB_PATH"
    fi
    
    # Validate installation directory
    if [[ -z "$REFOCUS_INSTALL_DIR" ]]; then
        echo "❌ REFOCUS_INSTALL_DIR is not set"
        ((errors++))
    else
        echo "✅ REFOCUS_INSTALL_DIR: $REFOCUS_INSTALL_DIR"
    fi
    
    # Validate numeric values
    if ! [[ "$REFOCUS_IDLE_THRESHOLD" =~ ^[0-9]+$ ]]; then
        echo "❌ REFOCUS_IDLE_THRESHOLD must be a positive integer (current: $REFOCUS_IDLE_THRESHOLD)"
        ((errors++))
    else
        echo "✅ REFOCUS_IDLE_THRESHOLD: ${REFOCUS_IDLE_THRESHOLD}s"
    fi
    
    if ! [[ "$REFOCUS_MAX_PROJECT_LENGTH" =~ ^[0-9]+$ ]]; then
        echo "❌ REFOCUS_MAX_PROJECT_LENGTH must be a positive integer (current: $REFOCUS_MAX_PROJECT_LENGTH)"
        ((errors++))
    else
        echo "✅ REFOCUS_MAX_PROJECT_LENGTH: ${REFOCUS_MAX_PROJECT_LENGTH} chars"
    fi
    
    if ! [[ "$REFOCUS_NUDGE_INTERVAL" =~ ^[0-9]+$ ]]; then
        echo "❌ REFOCUS_NUDGE_INTERVAL must be a positive integer (current: $REFOCUS_NUDGE_INTERVAL)"
        ((errors++))
    else
        echo "✅ REFOCUS_NUDGE_INTERVAL: ${REFOCUS_NUDGE_INTERVAL} minutes"
    fi
    
    if ! [[ "$REFOCUS_REPORT_LIMIT" =~ ^[0-9]+$ ]]; then
        echo "❌ REFOCUS_REPORT_LIMIT must be a positive integer (current: $REFOCUS_REPORT_LIMIT)"
        ((errors++))
    else
        echo "✅ REFOCUS_REPORT_LIMIT: $REFOCUS_REPORT_LIMIT"
    fi
    
    # Check if database exists
    if [[ -f "$REFOCUS_DB_PATH" ]]; then
        echo "✅ Database exists: $REFOCUS_DB_PATH"
    else
        echo "⚠️  Database does not exist: $REFOCUS_DB_PATH"
    fi
    
    # Check if installation directory exists
    if [[ -d "$REFOCUS_INSTALL_DIR" ]]; then
        echo "✅ Installation directory exists: $REFOCUS_INSTALL_DIR"
    else
        echo "⚠️  Installation directory does not exist: $REFOCUS_INSTALL_DIR"
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
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    focus_config "$@"
fi 