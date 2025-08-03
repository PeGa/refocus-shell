#!/usr/bin/env bash
# Refocus Shell - Safe Alias Implementation
# Copyright (c) 2025 PeGa
# Licensed under the GNU General Public License v3

# This provides a safe alias-based approach that avoids the -e exit issue
# Usage: source ~/.local/work/lib/work-alias.sh

# Store original PS1 if not already stored
if [[ -z "$WORK_ORIGINAL_PS1" ]]; then
    export WORK_ORIGINAL_PS1="$PS1"
fi

# Safe work function that sources the work script
work-safe() {
    # Temporarily disable exit on error
    local original_e
    original_e=$(set +o | grep errexit)
    
    # Disable exit on error for this function
    set +e
    
    # Get the work script path
    local work_script
    if [[ -f "$HOME/.local/bin/work" ]]; then
        work_script="$HOME/.local/bin/work"
    elif [[ -f "$HOME/dev/personal/refocus-shell/work" ]]; then
    work_script="$HOME/dev/personal/refocus-shell/work"
    else
        echo "❌ Refocus shell not found. Please install it first."
        # Restore original exit behavior
        eval "$original_e"
        return 1
    fi
    
    # Execute the work command and capture its exit code
    "$work_script" "$@"
    local exit_code=$?
    
    # Update prompt if work on/off was executed
    if [[ $# -gt 0 ]] && [[ "$1" == "on" || "$1" == "off" ]]; then
        work-update-prompt-safe
    fi
    
    # Restore original exit behavior
    eval "$original_e"
    
    return $exit_code
}

# Function to update prompt from database (safe version)
work-update-prompt-safe() {
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

# Function to restore original prompt (safe version)
work-restore-prompt-safe() {
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
        work-update-prompt-safe
    fi
fi

# Export the functions for use
export -f work-safe
export -f work-update-prompt-safe
export -f work-restore-prompt-safe

# Create alias (optional - can be commented out if you prefer the function)
# alias work='work-safe' 