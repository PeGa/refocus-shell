#!/usr/bin/env bash
# Refocus Shell - Project Description Management Subcommand
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

# Set table names
PROJECTS_TABLE="${PROJECTS_TABLE:-projects}"

# Ensure database is migrated to include projects table
migrate_database

function focus_description_show() {
    local project="$1"
    
    if [[ -z "$project" ]]; then
        echo "❌ Project name is required."
        echo "Usage: focus description show <project_name>"
        echo "Example: focus description show my-project"
        exit 1
    fi
    
    # Sanitize project name
    project=$(sanitize_project_name "$project")
    if ! validate_project_name "$project"; then
        exit 1
    fi
    
    # Get project description
    local description
    description=$(get_project_description "$project")
    
    if [[ -n "$description" ]]; then
        echo "📋 Project: $project"
        echo "Description: $description"
    else
        echo "📋 Project: $project"
        echo "Description: No description set"
        echo ""
        echo "To add a description, use: focus description add $project <description>"
    fi
}

function focus_description_add() {
    local project="$1"
    local description="$2"
    
    if [[ -z "$project" ]]; then
        echo "❌ Project name is required."
        echo "Usage: focus description add <project_name> <description>"
        echo "Example: focus description add my-project 'This is my awesome project'"
        exit 1
    fi
    
    if [[ -z "$description" ]]; then
        echo "❌ Description is required."
        echo "Usage: focus description add <project_name> <description>"
        echo "Example: focus description add my-project 'This is my awesome project'"
        exit 1
    fi
    
    # Sanitize project name
    project=$(sanitize_project_name "$project")
    if ! validate_project_name "$project"; then
        exit 1
    fi
    
    # Validate description length
    if [[ ${#description} -gt 500 ]]; then
        echo "❌ Description is too long (max 500 characters)."
        exit 1
    fi
    
    # Set project description
    set_project_description "$project" "$description"
    
    echo "✅ Description set for project: $project"
    echo "Description: $description"
}

function focus_description_remove() {
    local project="$1"
    
    if [[ -z "$project" ]]; then
        echo "❌ Project name is required."
        echo "Usage: focus description remove <project_name>"
        echo "Example: focus description remove my-project"
        exit 1
    fi
    
    # Sanitize project name
    project=$(sanitize_project_name "$project")
    if ! validate_project_name "$project"; then
        exit 1
    fi
    
    # Remove project description
    remove_project_description "$project"
    
    echo "✅ Description removed for project: $project"
}



function focus_description() {
    local action="$1"
    shift
    
    case "$action" in
        "show"|"view")
            focus_description_show "$@"
            ;;
        "add"|"set"|"edit")
            focus_description_add "$@"
            ;;
        "remove"|"delete"|"clear")
            focus_description_remove "$@"
            ;;
        *)
            echo "❌ Unknown action: $action"
            echo "Available actions:"
            echo "  add      - Add or edit project description"
            echo "  show     - Show project description"
            echo "  remove   - Remove project description"
            echo
            echo "Examples:"
            echo "  focus description add my-project 'This is my awesome project'"
            echo "  focus description show my-project"
            echo "  focus description remove my-project"
            echo
            echo "💡 Tip: Use 'focus report' to see all projects with descriptions"
            exit 1
            ;;
    esac
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    focus_description "$@"
fi
