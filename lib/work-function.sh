#!/usr/bin/env bash
# Refocus Shell - Shell Function
# Copyright (c) 2025 PeGa
# Licensed under the GNU General Public License v3

# This function can be sourced directly into the shell environment
# Usage: source ~/.local/work/lib/work-function.sh

# Store original PS1 if not already stored
if [[ -z "$WORK_ORIGINAL_PS1" ]]; then
    export WORK_ORIGINAL_PS1="$PS1"
fi

# Work function - main entry point
work() {
    local subcommand="$1"
    shift
    
    # Get the work script path
    local work_script
    if [[ -f "$HOME/.local/bin/work" ]]; then
        work_script="$HOME/.local/bin/work"
    elif [[ -f "$HOME/.local/work/work" ]]; then
        work_script="$HOME/.local/work/work"
    elif [[ -f "$HOME/dev/personal/refocus-shell/work" ]]; then
    work_script="$HOME/dev/personal/refocus-shell/work"
    else
        echo "❌ Refocus shell not found. Please install it first."
        return 1
    fi
    
    # Execute the work command
    "$work_script" "$subcommand" "$@"
    
    # Update prompt immediately after command execution
    if [[ "$subcommand" == "on" ]] || [[ "$subcommand" == "off" ]]; then
        work-update-prompt
    fi
}

# Function to update prompt from database
work-update-prompt() {
    local work_db="$HOME/.local/work/timelog.db"
    
    if [[ -f "$work_db" ]]; then
        # Get current prompt from database
        local prompt_content
        prompt_content=$(sqlite3 "$work_db" "SELECT prompt_content FROM state WHERE id = 1;" 2>/dev/null)
        
        if [[ -n "$prompt_content" ]]; then
            export PS1="$prompt_content"
            return 0
        fi
    fi
    
    # Fallback to original prompt
    if [[ -n "$WORK_ORIGINAL_PS1" ]]; then
        export PS1="$WORK_ORIGINAL_PS1"
    else
        # Default prompt if no original stored
        export PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01:34m\]\w\[\033[00m\]\$ '
    fi
}

# Function to restore original prompt
work-restore-prompt() {
    if [[ -n "$WORK_ORIGINAL_PS1" ]]; then
        export PS1="$WORK_ORIGINAL_PS1"
    else
        # Default prompt if no original stored
        export PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01:34m\]\w\[\033[00m\]\$ '
    fi
}

# Auto-update prompt on function load if work is active
if [[ -f "$HOME/.local/work/timelog.db" ]]; then
    # Check if work is currently active
    ACTIVE_STATE=$(sqlite3 "$HOME/.local/work/timelog.db" "SELECT active FROM state WHERE id = 1;" 2>/dev/null)
    if [[ "$ACTIVE_STATE" == "1" ]]; then
        work-update-prompt
    fi
fi

# Export the function for use
export -f work
export -f work-update-prompt
export -f work-restore-prompt 