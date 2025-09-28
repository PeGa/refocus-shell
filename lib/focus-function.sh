#!/usr/bin/env bash
# Refocus Shell - Shell Function
# Copyright (c) 2025 PeGa
# Licensed under the GNU General Public License v3

# This function can be sourced directly into the shell environment
# Usage: source ~/.local/refocus/lib/focus-function.sh

# Focus function - main entry point
focus() {
    # Handle global flags first
    local args=()
    local quiet_mode=false
    
    # Parse global flags
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -q|--quiet)
                quiet_mode=true
                shift
                ;;
            -*)
                # Unknown global flag, pass through to subcommand
                args+=("$1")
                shift
                ;;
            *)
                # Non-flag argument, add to args
                args+=("$1")
                shift
                ;;
        esac
    done
    
    # Set quiet mode globally
    if [[ "$quiet_mode" == "true" ]]; then
        export REFOCUS_QUIET=true
    fi
    
    # Get subcommand (first argument)
    local subcommand="${args[0]:-help}"
    if [[ ${#args[@]} -gt 0 ]]; then
        args=("${args[@]:1}")  # Remove first argument (subcommand)
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
        "$command_file" "${args[@]}" || rc=$?
        # Always refresh prompt after any subcommand
        focus-update-prompt
        return "$rc"
    else
        echo "❌ Unknown subcommand: $subcommand"
        echo "Run 'focus help' for available commands"
        return 1
    fi
}

# Function to update prompt from database
focus-update-prompt() {
    local focus_db="$(get_cfg DB_PATH "$HOME/.local/refocus/refocus.db")"
    local state_dir="$(get_cfg DATA_DIR "$HOME/.local/refocus")"
    
    if [[ -f "$focus_db" ]]; then
        # Get current state from database
        local state_row
        state_row=$(sqlite3 "$focus_db" "SELECT active, project, start_time, paused FROM ${REFOCUS_STATE_TABLE:-state} WHERE id = 1;" 2>/dev/null)
        
        if [[ -n "$state_row" ]]; then
            # Parse the row into shell variables
            IFS='|' read -r active project start_time paused <<< "$state_row"
            
            # Write start.ts for live minutes computation
            if [[ "$active" == "1" && "$paused" == "0" && -n "$start_time" ]]; then
                local start_ts
                start_ts=$(date -d "$start_time" +%s 2>/dev/null || echo "")
                if [[ -n "$start_ts" ]]; then
                    echo "$start_ts" > "$state_dir/start.ts"
                fi
            else
                # Remove start.ts when not active or paused
                rm -f "$state_dir/start.ts"
            fi
            
            # Write to prompt cache - the prompt hook will handle live minutes computation
            source "$HOME/.local/refocus/lib/focus-output.sh" 2>/dev/null || true
            if [[ "$active" == "1" ]]; then
                write_prompt_cache "on" "$project" "0"  # Minutes computed live by prompt hook
            else
                write_prompt_cache "off" "-" "-"
            fi
            
            return 0
        fi
    fi
    
    # Fallback: write "off" to prompt cache and remove start.ts
    rm -f "$state_dir/start.ts"
    source "$HOME/.local/refocus/lib/focus-output.sh" 2>/dev/null || true
    write_prompt_cache "off" "-" "-"
}

# Function to restore original prompt
focus-restore-prompt() {
    # Write "off" to prompt cache instead of directly modifying PS1/RPROMPT
    source "$HOME/.local/refocus/lib/focus-output.sh" 2>/dev/null || true
    write_prompt_cache "off" "-" "-"
}

# Safe versions of prompt functions (for compatibility with focus-alias.sh)
focus-update-prompt-safe() {
    focus-update-prompt
}

focus-restore-prompt-safe() {
    focus-restore-prompt
}

# Additional prompt-related functions moved from focus-utils.sh
# Function to check if update-prompt function is available
is_update_prompt_available() {
    type update-prompt >/dev/null 2>&1
}

# Function to get the current prompt or fallback to default
get_current_prompt() {
    # Always use the standard Ubuntu prompt as fallback since current PS1 is broken
    echo '${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
}

# Function to create focus prompt string
create_focus_prompt() {
    local project="$1"
    echo '⏳ ['$project'] ${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
}

# Function to create default prompt string
create_default_prompt() {
    echo '${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
}

# Function to set focus prompt
set_focus_prompt() {
    local project="$1"
    
    # Create focus prompt
    local focus_prompt
    focus_prompt=$(create_focus_prompt "$project")
    
    # Update database with focus prompt
    update_prompt_content "$focus_prompt" "focus"
    
    # Try multiple methods to update the prompt
    local prompt_updated=false
    
    # Method 1: Try to call update-prompt function if available
    if type update-prompt >/dev/null 2>&1; then
        update-prompt
        prompt_updated=true
        verbose_echo "Focus prompt set via update-prompt function"
    fi
    
    # Method 2: Try to source the shell integration directly
    if [[ "$prompt_updated" == "false" ]] && [[ -f "$HOME/.local/refocus/shell-integration.sh" ]]; then
        source "$HOME/.local/refocus/shell-integration.sh" 2>/dev/null
        if type update-prompt >/dev/null 2>&1; then
            update-prompt
            prompt_updated=true
            verbose_echo "Focus prompt set via sourced shell integration"
        fi
    fi
    
    # Method 3: Write to prompt cache as fallback
    if [[ "$prompt_updated" == "false" ]]; then
        write_prompt_cache "on" "$project" "0"
        prompt_updated=true
        verbose_echo "Focus prompt set via prompt cache"
    fi
    
    verbose_echo "Focus prompt set for project: $project"
    
    # Show appropriate message based on method used
    if [[ "$prompt_updated" == "true" ]]; then
        verbose_echo "Tip: Run 'update-prompt' to update the current terminal prompt"
        verbose_echo "Note: New terminals will automatically show the focus prompt"
    else
        echo "Warning: Could not update prompt automatically"
        echo "Run 'update-prompt' to update the current terminal prompt"
    fi
}

# Function to restore original prompt
restore_original_prompt() {
    # Get original prompt from database
    local original_prompt
    original_prompt=$(get_prompt_content_by_type "original")
    
    # If no original prompt found, use default
    if [[ -z "$original_prompt" ]]; then
        original_prompt=$(create_default_prompt)
    fi
    
    # Update database with default prompt
    update_prompt_content "$original_prompt" "default"
    
    # Try multiple methods to update the prompt
    local prompt_updated=false
    
    # Method 1: Try to call update-prompt function if available
    if type update-prompt >/dev/null 2>&1; then
        update-prompt
        prompt_updated=true
        verbose_echo "Original prompt restored via update-prompt function"
    fi
    
    # Method 2: Try to source the shell integration directly
    if [[ "$prompt_updated" == "false" ]] && [[ -f "$HOME/.local/refocus/shell-integration.sh" ]]; then
        source "$HOME/.local/refocus/shell-integration.sh" 2>/dev/null
        if type update-prompt >/dev/null 2>&1; then
            update-prompt
            prompt_updated=true
            verbose_echo "Original prompt restored via sourced shell integration"
        fi
    fi
    
    # Method 3: Write to prompt cache as fallback
    if [[ "$prompt_updated" == "false" ]]; then
        write_prompt_cache "off" "-" "-"
        prompt_updated=true
        verbose_echo "Original prompt restored via prompt cache"
    fi
    
    verbose_echo "Original prompt restored"
    
    # Show appropriate message based on method used
    if [[ "$prompt_updated" == "true" ]]; then
        verbose_echo "Tip: Run 'update-prompt' to update the current terminal prompt"
        verbose_echo "Note: New terminals will automatically show the normal prompt"
    else
        echo "Warning: Could not restore prompt automatically"
        echo "Run 'update-prompt' to update the current terminal prompt"
    fi
}
# Export the function for use
export -f focus
export -f focus-update-prompt
export -f focus-restore-prompt
export -f focus-update-prompt-safe
export -f focus-restore-prompt-safe
export -f is_update_prompt_available
export -f get_current_prompt
export -f create_focus_prompt
export -f create_default_prompt
export -f set_focus_prompt
export -f restore_original_prompt 