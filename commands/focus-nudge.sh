#!/usr/bin/env bash
# Refocus Shell - Nudge Subcommand
# Copyright (c) 2025 PeGa
# Licensed under the GNU General Public License v3

# Source bootstrap module
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/focus-bootstrap.sh"

function focus_nudge_enable() {
    # Check if refocus shell is disabled
    if is_focus_disabled; then
        echo "❌ Refocus shell is disabled. Run 'focus enable' first."
        return 1
    fi
    
    # Enable nudging
    update_nudging_enabled 1
    echo "✅ Nudging enabled"
    echo "You will receive focus reminders every 10 minutes during active sessions"
    
    send_notification "Nudging Enabled" "Focus reminders are now active."
}

function focus_nudge_disable() {
    # Disable nudging
    update_nudging_enabled 0
    echo "🚫 Nudging disabled"
    echo "You will no longer receive focus reminders"
    
    send_notification "Nudging Disabled" "Focus reminders are now inactive."
}

function focus_nudge_status() {
    # Check if refocus shell is disabled
    if is_focus_disabled; then
        echo "❌ Refocus shell is disabled"
        return 1
    fi
    
    # Get nudging status
    local nudging_enabled
    nudging_enabled=$(get_nudging_enabled)
    
    if [[ "$nudging_enabled" -eq 1 ]]; then
        echo "✅ Nudging is enabled"
        echo "Focus reminders: Active (every 10 minutes)"
        
        # Check if there's an active session
        if is_focus_active; then
            local state
            state=$(get_focus_state)
            IFS='|' read -r active project start_time <<< "$state"
            
            if [[ "$active" -eq 1 ]] && [[ -n "$project" ]]; then
                local now=$(date +%s)
                local start_ts=$(date --date="$start_time" +%s 2>/dev/null)
                if [[ -n "$start_ts" ]]; then
                    local elapsed=$((now - start_ts))
                    local minutes=$((elapsed / 60))
                    echo "Current session: $project (${minutes}m elapsed)"
                    echo "Next nudge: In $((10 - (minutes % 10))) minutes"
                fi
            fi
        else
            echo "Current session: None"
            echo "Next nudge: When you start a focus session"
        fi
    else
        echo "🚫 Nudging is disabled"
        echo "Focus reminders: Inactive"
    fi
}

function focus_nudge_test() {
    # Check if refocus shell is disabled
    if is_focus_disabled; then
        echo "❌ Refocus shell is disabled. Run 'focus enable' first."
        return 1
    fi
    
    # Check if nudging is enabled
    local nudging_enabled
    nudging_enabled=$(get_nudging_enabled)
    
    if [[ "$nudging_enabled" -eq 0 ]]; then
        echo "❌ Nudging is disabled. Run 'focus nudge enable' first."
        return 1
    fi
    
    echo "🧪 Testing nudge notification..."
    
    # Test the nudge script
    if [[ -f "$HOME/.local/refocus/focus-nudge" ]]; then
        if "$HOME/.local/refocus/focus-nudge"; then
            echo "✅ Nudge test completed successfully"
            echo "Check your notifications or system logs for the test message"
        else
            echo "❌ Nudge test failed"
            echo "Check system logs for error details"
        fi
    else
        echo "❌ Nudge script not found at $HOME/.local/refocus/focus-nudge"
        return 1
    fi
}

function focus_nudge_help() {
    echo "Focus Nudge Control"
    echo "==================="
    echo
    echo "Commands:"
    echo "  enable    Enable nudging (focus reminders every 10 minutes)"
    echo "  disable   Disable nudging (stop focus reminders)"
    echo "  status    Show current nudging status and next reminder time"
    echo "  test      Test the nudge notification system"
    echo "  help      Show this help message"
    echo
    echo "Examples:"
    echo "  focus nudge enable   # Enable focus reminders"
    echo "  focus nudge status   # Check nudging status"
    echo "  focus nudge test     # Test notification system"
    echo "  focus nudge disable  # Stop focus reminders"
    echo
    echo "Note: Nudging requires refocus shell to be enabled."
    echo "      Notifications appear every 10 minutes during active focus sessions."
}

# Main dispatcher
function focus_nudge() {
    local action="$1"
    
    case "$action" in
        enable)
            focus_nudge_enable
            ;;
        disable)
            focus_nudge_disable
            ;;
        status)
            focus_nudge_status
            ;;
        test)
            focus_nudge_test
            ;;
        help|--help|-h)
            focus_nudge_help
            ;;
        "")
            focus_nudge_status
            ;;
        *)
            echo "❌ Unknown action: $action"
            echo "Run 'focus nudge help' for available commands"
            return 1
            ;;
    esac
}


# Main execution
refocus_script_main focus_nudge_enable "$@"
