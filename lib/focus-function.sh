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

# Store original RPROMPT if not already stored (for zsh)
if [[ -n "${ZSH_VERSION:-}" ]] && [[ -z "${REFOCUS_ORIGINAL_RPROMPT:-}" ]]; then
    export REFOCUS_ORIGINAL_RPROMPT="${RPROMPT:-}"
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
    local rc=0
    if [[ -f "$command_file" ]]; then
        "$command_file" "$@" || rc=$?
        # Prompt hook will handle updates automatically
        return "$rc"
    else
        echo "❌ Unknown subcommand: $subcommand"
        echo "Run 'focus help' for available commands"
        return 1
    fi
}

# Function to update prompt from database
focus-update-prompt() {
    # Source config.sh to get table names
    source "$HOME/.local/refocus/config.sh"
    
    local focus_db="$HOME/.local/refocus/refocus.db"
    
    if [[ -f "$focus_db" ]]; then
        # Get current state from database
        local state_row
        state_row=$(sqlite3 "$focus_db" "SELECT active, project, start_time, paused FROM ${REFOCUS_STATE_TABLE:-state} WHERE id = 1;" 2>/dev/null)
        
        if [[ -n "$state_row" ]]; then
            # Parse the row into shell variables
            IFS='|' read -r active project start_time paused <<< "$state_row"
            
            # Compute minutes if active and not paused
            local mins=0
            if [[ "$active" == "1" && "$paused" == "0" && -n "$start_time" ]]; then
                local start_ts
                start_ts=$(date -d "$start_time" +%s 2>/dev/null || echo "")
                if [[ -n "$start_ts" ]]; then
                    local now_ts
                    now_ts=$(date +%s)
                    mins=$(( (now_ts - start_ts) / 60 ))
                    [[ "$mins" -lt 0 ]] && mins=0
                fi
            fi
            
            # Build segment based on state
            local segment=""
            if [[ "$active" == "1" ]]; then
                if [[ "$paused" == "1" ]]; then
                    segment=" ⏸ ${project:-"(no project)"}"
                else
                    segment=" ⏳ ${project:-"(no project)"} (${mins}m)"
                fi
            elif [[ "$paused" == "1" ]]; then
                # Show pause state even when active=0
                segment=" ⏸ ${project:-"(no project)"}"
            fi
            
            # Write to prompt cache instead of directly modifying PS1/RPROMPT
            # The prompt hook will read from cache and update the prompt
            source "$HOME/.local/refocus/lib/focus-output.sh" 2>/dev/null || true
            if [[ -n "$segment" ]]; then
                write_prompt_cache "on" "$project" "$mins"
            else
                write_prompt_cache "off" "-" "-"
            fi
            
            return 0
        fi
    fi
    
    # Fallback: write "off" to prompt cache
    source "$HOME/.local/refocus/lib/focus-output.sh" 2>/dev/null || true
    write_prompt_cache "off" "-" "-"
}

# Function to restore original prompt
focus-restore-prompt() {
    # Write "off" to prompt cache instead of directly modifying PS1/RPROMPT
    source "$HOME/.local/refocus/lib/focus-output.sh" 2>/dev/null || true
    write_prompt_cache "off" "-" "-"
}
# Export the function for use
export -f focus
export -f focus-update-prompt
export -f focus-restore-prompt 