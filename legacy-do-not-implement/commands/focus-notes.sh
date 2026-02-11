#!/usr/bin/env bash
# Refocus Shell - Manage Session Notes Subcommand
# Copyright (c) 2025 PeGa
# Licensed under the GNU General Public License v3

# Source bootstrap module
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/focus-bootstrap.sh"


function focus_notes_add() {
    local project="$1"
    
    if [[ -z "$project" ]]; then
        echo "❌ Project name is required."
        echo "Usage: focus notes add <project>"
        echo ""
        echo "Examples:"
        echo "  focus notes add 'meeting'"
        echo "  focus notes add coding"
        exit 1
    fi
    
    # Sanitize and validate project name
    project=$(sanitize_project_name "$project")
    if ! validate_project_name "$project"; then
        exit 1
    fi
    
    # Get the most recent session for this project
    local session_info
    session_info=$(execute_sqlite "SELECT rowid, start_time, end_time, duration_seconds, notes FROM ${REFOCUS_SESSIONS_TABLE:-sessions} WHERE project = '$(sql_escape "$project")' ORDER BY end_time DESC LIMIT 1;" "focus_notes_add")
    
    if [[ -z "$session_info" ]]; then
        echo "❌ No sessions found for project: $project"
        exit 1
    fi
    
    IFS='|' read -r session_id start_time end_time duration existing_notes <<< "$session_info"
    
    echo "📝 Adding notes to recent session for: $project"
    echo "   Start: $start_time"
    echo "   End: $end_time"
    echo "   Duration: $((duration / 60)) minutes"
    if [[ -n "$existing_notes" ]]; then
        echo "   Current notes: $existing_notes"
    fi
    
    echo ""
    echo -n "What did you accomplish during this focus session? (Press Enter to skip, or type a brief description): "
    read -r session_notes
    
    if [[ -n "$session_notes" ]]; then
        # Update the session with new notes
        local escaped_notes
        escaped_notes=$(sql_escape "$session_notes")
        # Validate session_id is numeric to prevent injection
    if ! [[ "$session_id" =~ ^[0-9]+$ ]]; then
        echo "❌ Invalid session ID: $session_id"
        show_error_info
        exit 1
    fi
    execute_sqlite "UPDATE ${REFOCUS_SESSIONS_TABLE:-sessions} SET notes = '$escaped_notes' WHERE rowid = $session_id;" "focus_notes_add" >/dev/null
        echo "✅ Notes added to session $session_id"
    else
        echo "No notes added."
    fi
}

function focus_notes() {
    local action="$1"
    shift
    
    case "$action" in
        "add")
            focus_notes_add "$@"
            ;;
        *)
            echo "❌ Unknown action: $action"
            echo "Available actions:"
            echo "  add     - Add notes to the most recent session for a project"
            echo
            echo "Examples:"
            echo "  focus notes add 'meeting'"
            echo "  focus notes add coding"
            exit 1
            ;;
    esac
}

# Main execution
refocus_script_main focus_notes "$@"
