#!/usr/bin/env bash
# Refocus Shell - Shell Function
# Copyright (c) 2025 PeGa
# Licensed under the GNU General Public License v3

# This function can be sourced directly into the shell environment
# Usage: source ~/.local/refocus/lib/focus-function.sh

# Store original PS1 if not already stored
if [[ -z "${REFOCUS_ORIGINAL_PS1:-}" ]]; then
    export REFOCUS_ORIGINAL_PS1="${PS1:-}"
fi

# Focus function - main entry point
focus() {
    local subcommand="${1:-help}"
    if [[ $# -gt 0 ]]; then
        shift
    fi
    
    # Get the command directory
    local command_dir
    if [[ -d "$HOME/.local/refocus/commands" ]]; then
        command_dir="$HOME/.local/refocus/commands"
    else
        echo "❌ Refocus shell not found. Please install it first."
        return 1
    fi
    
    # Execute the subcommand directly
    local command_file="$command_dir/focus-$subcommand.sh"
    if [[ -f "$command_file" ]]; then
        "$command_file" "$@"
    else
        echo "❌ Unknown subcommand: $subcommand"
        echo "Run 'focus help' for available commands"
        return 1
    fi
    
    # Update prompt immediately after command execution
    if [[ "$subcommand" == "on" ]] || [[ "$subcommand" == "off" ]]; then
        focus-update-prompt
    fi
}

# Function to update prompt from database
focus-update-prompt() {
    # Source config.sh to get table names
    source "$HOME/.local/refocus/config.sh"
    
    # Source focus-output.sh to get write_prompt_cache function
    source "$HOME/.local/refocus/lib/focus-output.sh" 2>/dev/null || true
    
    local focus_db="$HOME/.local/refocus/refocus.db"
    
    if [[ -f "$focus_db" ]]; then
        # Get current state from database
        local active=$(sqlite3 "$focus_db" "SELECT active FROM ${REFOCUS_STATE_TABLE:-state} WHERE id = 1;" 2>/dev/null)
        local project=$(sqlite3 "$focus_db" "SELECT project FROM ${REFOCUS_STATE_TABLE:-state} WHERE id = 1;" 2>/dev/null)
        
        if [[ "$active" == "1" && -n "$project" ]]; then
            write_prompt_cache "on" "$project" "0"
        else
            write_prompt_cache "off" "-" "-"
        fi
        return 0
    fi
    
    # Fallback - write to cache instead of direct PS1 mutation
    write_prompt_cache "off" "-" "-"
}

# Function to restore original prompt
focus-restore-prompt() {
    # Source focus-output.sh to get write_prompt_cache function
    source "$HOME/.local/refocus/lib/focus-output.sh" 2>/dev/null || true
    
    # Use write_prompt_cache instead of direct PS1 mutation
    write_prompt_cache "off" "-" "-"
}
# Export the function for use
export -f focus
export -f focus-update-prompt
export -f focus-restore-prompt 