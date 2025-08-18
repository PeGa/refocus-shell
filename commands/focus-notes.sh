#!/usr/bin/env bash
# Refocus Shell - Session Notes Management Subcommand
# Copyright (c) 2025 PeGa
# Licensed under the GNU General Public License v3

# Source libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$HOME/.local/refocus/lib/focus-db.sh" ]]; then
    source "$HOME/.local/refocus/lib/focus-db.sh"
    source "$HOME/.local/refocus/lib/focus-utils.sh"
else
    source "$SCRIPT_DIR/../lib/focus-db.sh"
    source "$SCRIPT_DIR/../lib/focus-utils.sh"
fi

function focus_notes_add() {
    local project="$1"
    local notes="$2"
    
    if [[ -z "$project" ]]; then
        echo "❌ Project name is required."
        echo "Usage: focus notes add <project> <notes>"
        echo ""
        echo "Examples:"
        echo "  focus notes add coding \"Fixed the login bug and updated docs\""
        echo "  focus notes add meeting \"Team standup and sprint planning\""
        exit 1
    fi
    
    if [[ -z "$notes" ]]; then
        echo "❌ Notes are required."
        echo "Usage: focus notes add <project> <notes>"
        exit 1
    fi
    
    # Sanitize project name
    project=$(sanitize_project_name "$project")
    if ! validate_project_name "$project"; then
        exit 1
    fi
    
    # Get the most recent session for this project
    local session_data
    session_data=$(sqlite3 "$DB" "SELECT rowid, project, start_time, end_time, duration_seconds, notes FROM $SESSIONS_TABLE WHERE project = '$(sql_escape "$project")' ORDER BY end_time DESC LIMIT 1;" 2>/dev/null)
    
    if [[ -z "$session_data" ]]; then
        echo "❌ No sessions found for project: $project"
        echo "Use 'focus past add' to create a session first."
        exit 1
    fi
    
    IFS='|' read -r session_id session_project session_start session_end session_duration session_notes <<< "$session_data"
    
    # Update the session notes
    local escaped_notes
    escaped_notes=$(sql_escape "$notes")
    
    sqlite3 "$DB" "UPDATE $SESSIONS_TABLE SET notes = '$escaped_notes' WHERE rowid = $session_id;"
    
    echo "✅ Added notes for project: $project"
    echo "   Notes: $notes"
    echo "   Session: $session_start to $session_end"
}

function focus_notes_show() {
    local project="$1"
    
    if [[ -z "$project" ]]; then
        echo "❌ Project name is required."
        echo "Usage: focus notes show <project>"
        exit 1
    fi
    
    # Sanitize project name
    project=$(sanitize_project_name "$project")
    if ! validate_project_name "$project"; then
        exit 1
    fi
    
    # Get recent sessions with notes for this project
    local sessions
    sessions=$(sqlite3 "$DB" "SELECT start_time, end_time, duration_seconds, notes FROM $SESSIONS_TABLE WHERE project = '$(sql_escape "$project")' AND notes IS NOT NULL AND notes != '' ORDER BY end_time DESC LIMIT 5;" 2>/dev/null)
    
    if [[ -z "$sessions" ]]; then
        echo "ℹ️  No notes found for project: $project"
        echo "Use 'focus notes add' to add notes to a session."
    else
        echo "📝 Notes for project: $project"
        echo "======================"
        echo ""
        
        while IFS='|' read -r start_time end_time duration notes; do
            local start_date
            start_date=$(date --date="$start_time" +"%Y-%m-%d %H:%M")
            local end_date
            end_date=$(date --date="$end_time" +"%H:%M")
            local duration_min
            duration_min=$((duration / 60))
            
            echo "📅 $start_date - $end_date ($duration_min minutes)"
            echo "   $notes"
            echo ""
        done <<< "$sessions"
    fi
}

function focus_notes() {
    local action="$1"
    
    case "$action" in
        "add")
            shift
            focus_notes_add "$@"
            ;;
        "show")
            shift
            focus_notes_show "$@"
            ;;
        *)
            echo "❌ Unknown action: $action"
            echo ""
            echo "Usage: focus notes <action> [options]"
            echo ""
            echo "Actions:"
            echo "  add <project> <notes>    - Add notes to the most recent session"
            echo "  show <project>           - Show notes for a project"
            echo ""
            echo "Examples:"
            echo "  focus notes add coding \"Fixed the login bug\""
            echo "  focus notes show coding"
            echo ""
            echo "💡 Tip: Notes are automatically added when you use 'focus off'"
            exit 1
            ;;
    esac
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    focus_notes "$@"
fi
