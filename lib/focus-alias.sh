#!/usr/bin/env bash
# Refocus Shell - Safe Alias Implementation
# Copyright (c) 2025 PeGa
# Licensed under the GNU General Public License v3

# This provides a safe alias-based approach that avoids the -e exit issue
# Usage: source ~/.local/refocus/lib/focus-alias.sh

# Source configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../config.sh"

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
    elif [[ -f "/usr/local/bin/focus" ]]; then
        focus_script="/usr/local/bin/focus"
    elif [[ -f "/usr/bin/focus" ]]; then
        focus_script="/usr/bin/focus"
    elif [[ -f "$HOME/.local/refocus/focus" ]]; then
        focus_script="$HOME/.local/refocus/focus"
    else
        echo "❌ Refocus shell not found. Please install it first."
        # Restore original exit behavior
        eval "$original_e"
        return 1
    fi
    
    # Execute the focus command and capture its exit code
    "$focus_script" "$@"
    local exit_code=$?
    
    # Note: Prompt updates are handled by focus-function.sh
    
    # Restore original exit behavior
    eval "$original_e"
    
    return $exit_code
}

# Note: Prompt-related functions have been moved to focus-function.sh
# This file now only provides the safe focus execution wrapper

# Export the functions for use
export -f focus-safe

# Create alias (optional - can be commented out if you prefer the function)
# alias focus='focus-safe' 