#!/usr/bin/env bash
# Refocus Shell - Project Management Subcommand
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

function focus_project_show() {
    local project="$1"
    
    if [[ -z "$project" ]]; then
        echo "❌ Project name is required."
        echo "Usage: focus project show <project_name>"
        echo "Example: focus project show my-project"
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
        echo "To add a description, use: focus project set $project <description>"
    fi
}

function focus_project_set() {
    local project="$1"
    local description="$2"
    
    if [[ -z "$project" ]]; then
        echo "❌ Project name is required."
        echo "Usage: focus project set <project_name> <description>"
        echo "Example: focus project set my-project 'This is my awesome project'"
        exit 1
    fi
    
    if [[ -z "$description" ]]; then
        echo "❌ Description is required."
        echo "Usage: focus project set <project_name> <description>"
        echo "Example: focus project set my-project 'This is my awesome project'"
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

function focus_project_remove() {
    local project="$1"
    
    if [[ -z "$project" ]]; then
        echo "❌ Project name is required."
        echo "Usage: focus project remove <project_name>"
        echo "Example: focus project remove my-project"
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

function focus_project_list() {
    echo "📋 Projects with Descriptions"
    echo "============================"
    
    # Get all projects with descriptions
    local projects
    projects=$(get_projects_with_descriptions)
    
    if [[ -z "$projects" ]]; then
        echo "No projects with descriptions found."
        echo ""
        echo "To add a description to a project, use:"
        echo "  focus project set <project_name> <description>"
        return 0
    fi
    
    while IFS='|' read -r project description; do
        if [[ -n "$project" ]]; then
            echo ""
            echo "📋 $project"
            echo "   $description"
        fi
    done <<< "$projects"
}

function focus_project() {
    local action="$1"
    shift
    
    case "$action" in
        "show"|"view")
            focus_project_show "$@"
            ;;
        "set"|"add"|"edit")
            focus_project_set "$@"
            ;;
        "remove"|"delete"|"clear")
            focus_project_remove "$@"
            ;;
        "list"|"ls")
            focus_project_list
            ;;
        *)
            echo "❌ Unknown action: $action"
            echo "Available actions:"
            echo "  show     - Show project description"
            echo "  set      - Set or edit project description"
            echo "  remove   - Remove project description"
            echo "  list     - List all projects with descriptions"
            echo
            echo "Examples:"
            echo "  focus project show my-project"
            echo "  focus project set my-project 'This is my awesome project'"
            echo "  focus project remove my-project"
            echo "  focus project list"
            exit 1
            ;;
    esac
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    focus_project "$@"
fi
