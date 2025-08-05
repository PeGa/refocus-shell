#!/usr/bin/env bash
# Refocus Shell - Safe Alias Implementation
# Copyright (c) 2025 PeGa
# Licensed under the GNU General Public License v3

# This provides a safe alias-based approach that avoids the -e exit issue
# Usage: source ~/.local/refocus/lib/focus-alias.sh

# Store original PS1 if not already stored
if [[ -z "$FOCUS_ORIGINAL_PS1" ]]; then
    export FOCUS_ORIGINAL_PS1="$PS1"
fi

# Safe focus function that sources the focus script
focus-safe() {
    # Temporarily disable exit on error
    local original_e
    original_e=$(set +o | grep errexit)
    
    # Disable exit on error for this function
    set +e
    
    # Get the focus script path
    local focus_script
    if [[ -f "$HOME/.local/bin/focus" ]]; then
        focus_script="$HOME/.local/bin/focus"
    elif [[ -f "$HOME/dev/personal/refocus-shell/focus" ]]; then
    focus_script="$HOME/dev/personal/refocus-shell/focus"
    else
        echo "❌ Refocus shell not found. Please install it first."
        # Restore original exit behavior
        eval "$original_e"
        return 1
    fi
    
    # Execute the focus command and capture its exit code
    "$focus_script" "$@"
    local exit_code=$?
    
    # Update prompt if focus on/off was executed
    if [[ $# -gt 0 ]] && [[ "$1" == "on" || "$1" == "off" ]]; then
        focus-update-prompt-safe
    fi
    
    # Restore original exit behavior
    eval "$original_e"
    
    return $exit_code
}

# Function to update prompt from database (safe version)
focus-update-prompt-safe() {
    local focus_db="$HOME/.local/refocus/timelog.db"
    
    if [[ -f "$focus_db" ]]; then
        # Get current prompt from database
        local prompt_content
        prompt_content=$(sqlite3 "$focus_db" "SELECT prompt_content FROM state WHERE id = 1;" 2>/dev/null)
        
        if [[ -n "$prompt_content" ]]; then
            export PS1="$prompt_content"
            return 0
        fi
    fi
    
    # Fallback to original prompt
    if [[ -n "$FOCUS_ORIGINAL_PS1" ]]; then
        export PS1="$FOCUS_ORIGINAL_PS1"
    else
        # Default prompt if no original stored
        export PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01:34m\]\w\[\033[00m\]\$ '
    fi
}

# Function to restore original prompt (safe version)
focus-restore-prompt-safe() {
    if [[ -n "$FOCUS_ORIGINAL_PS1" ]]; then
        export PS1="$FOCUS_ORIGINAL_PS1"
    else
        # Default prompt if no original stored
        export PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01:34m\]\w\[\033[00m\]\$ '
    fi
}

# Auto-update prompt on function load if focus is active
if [[ -f "$HOME/.local/refocus/timelog.db" ]]; then
    # Check if focus is currently active
    ACTIVE_STATE=$(sqlite3 "$HOME/.local/refocus/timelog.db" "SELECT active FROM state WHERE id = 1;" 2>/dev/null)
    if [[ "$ACTIVE_STATE" == "1" ]]; then
        focus-update-prompt-safe
    fi
fi

# Export the functions for use
export -f focus-safe
export -f focus-update-prompt-safe
export -f focus-restore-prompt-safe

# Create alias (optional - can be commented out if you prefer the function)
# alias focus='focus-safe' 