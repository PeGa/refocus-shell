#!/usr/bin/env bash
# Refocus Shell - Shell Function
# Copyright (c) 2025 PeGa
# Licensed under the GNU General Public License v3

# This function can be sourced directly into the shell environment
# Usage: source ~/.local/refocus/lib/focus-function.sh

# Table name variables
STATE_TABLE="${STATE_TABLE:-state}"
SESSIONS_TABLE="${SESSIONS_TABLE:-sessions}"

# Store original PS1 if not already stored
if [[ -z "$REFOCUS_ORIGINAL_PS1" ]]; then
    export REFOCUS_ORIGINAL_PS1="$PS1"
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
    local focus_db="$HOME/.local/refocus/refocus.db"
    
    if [[ -f "$focus_db" ]]; then
        # Get current prompt from database
        local prompt_content
        prompt_content=$(sqlite3 "$focus_db" "SELECT prompt_content FROM $STATE_TABLE WHERE id = 1;" 2>/dev/null)
        
        if [[ -n "$prompt_content" ]]; then
            export PS1="$prompt_content"
            return 0
        fi
    fi
    
    # Fallback to original prompt
    if [[ -n "$REFOCUS_ORIGINAL_PS1" ]]; then
        export PS1="$REFOCUS_ORIGINAL_PS1"
    else
        # Default prompt if no original stored
        export PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01:34m\]\w\[\033[00m\]\$ '
    fi
}

# Function to restore original prompt
focus-restore-prompt() {
    if [[ -n "$REFOCUS_ORIGINAL_PS1" ]]; then
        export PS1="$REFOCUS_ORIGINAL_PS1"
    else
        # Default prompt if no original stored
        export PS1='${debian_chroot:+($debian_chroot)}\[\033[01:32m\]\u@\h\[\033[00m\]:\[\033[01:34m\]\w\[\033[00m\]\$ '
    fi
}

# Auto-update prompt on function load if focus is active
if [[ -f "$HOME/.local/refocus/refocus.db" ]]; then
    # Check if focus is currently active
    ACTIVE_STATE=$(sqlite3 "$HOME/.local/refocus/refocus.db" "SELECT active FROM $STATE_TABLE WHERE id = 1;" 2>/dev/null)
    if [[ "$ACTIVE_STATE" == "1" ]]; then
        focus-update-prompt
    fi
fi

# Export the function for use
export -f focus
export -f focus-update-prompt
export -f focus-restore-prompt 