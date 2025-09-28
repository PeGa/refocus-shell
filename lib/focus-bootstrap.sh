#!/usr/bin/env bash
# Refocus Shell - Bootstrap Module
# Copyright (c) 2025 PeGa
# Licensed under the GNU General Public License v3

# This module provides common initialization patterns for all refocus commands
# to eliminate code duplication and ensure consistent behavior.

# Source configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../config.sh"

# Function to initialize refocus environment
# Usage: refocus_bootstrap [command_name]
refocus_bootstrap() {
    local command_name="${1:-unknown}"
    
    # Set script directory
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    # Source libraries with fallback paths
    if [[ -f "$HOME/.local/refocus/lib/focus-db.sh" ]]; then
        source "$HOME/.local/refocus/lib/focus-db.sh"
        source "$HOME/.local/refocus/lib/focus-utils.sh"
        source "$HOME/.local/refocus/lib/focus-output.sh"
    else
        source "$script_dir/focus-db.sh"
        source "$script_dir/focus-utils.sh"
        source "$script_dir/focus-output.sh"
    fi
    
    # Run database migration if needed
    if [[ -f "$DB" ]]; then
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

# Function to format duration in human-readable format
# Usage: refocus_format_duration <seconds>
refocus_format_duration() {
    local seconds="$1"
    local hours=$((seconds / 3600))
    local minutes=$(((seconds % 3600) / 60))
    local remaining_seconds=$((seconds % 60))
    
    if [[ $hours -gt 0 ]]; then
        if [[ $minutes -gt 0 ]]; then
            echo "${hours}h ${minutes}m"
        else
            echo "${hours}h"
        fi
    elif [[ $minutes -gt 0 ]]; then
        echo "${minutes}m"
    else
        echo "${remaining_seconds}s"
    fi
}

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
export -f refocus_bootstrap
export -f refocus_command_main
export -f refocus_script_main
export -f refocus_validate_dependencies
export -f refocus_confirm
export -f refocus_format_duration
export -f refocus_backup_database
export -f refocus_timestamp
export -f refocus_log_command
