#!/usr/bin/env bash
# Refocus Shell - Description Subcommand
# Copyright (c) 2025 PeGa
# Licensed under the GNU General Public License v3

# Source bootstrap module
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/focus-bootstrap.sh"

function focus_description_add() {
    local project="$1"
    local description="$2"
    
    if [[ -z "$project" ]]; then
        echo "❌ Project name is required."
        echo "Usage: focus description add <project> <description>"
        echo ""
        echo "Examples:"
        echo "  focus description add 'coding' 'Main development project'"
        echo "  focus description add meeting 'Weekly team standup'"
        exit 1
    fi
    
    if [[ -z "$description" ]]; then
        echo "❌ Session notes are required."
        echo "Usage: focus description add <project> <description>"
        echo ""
        echo "Examples:"
        echo "  focus description add 'coding' 'Main development project'"
        echo "  focus description add meeting 'Weekly team standup'"
        exit 1
    fi
    
    # Sanitize and validate project name
    project=$(sanitize_project_name "$project")
    if ! validate_project_name "$project"; then
        exit 1
    fi
    
    # Set project description
    set_project_description "$project" "$description"
    echo "✅ Added session notes for project: $project"
    echo "   Notes: $description"
}

function focus_description_show() {
    local project="$1"
    
    if [[ -z "$project" ]]; then
        echo "❌ Project name is required."
        echo "Usage: focus description show <project>"
        echo ""
        echo "Examples:"
        echo "  focus description show 'coding'"
        echo "  focus description show meeting"
        exit 1
    fi
    
    # Sanitize and validate project name
    project=$(sanitize_project_name "$project")
    if ! validate_project_name "$project"; then
        exit 1
    fi
    
    # Get project description
    local description
    description=$(get_project_description "$project")
    
    if [[ -n "$description" ]]; then
        echo "📝 Project: $project"
        echo "   Notes: $description"
    else
        echo "ℹ️  No session notes found for project: $project"
        echo "   Use 'focus description add $project <notes>' to add some"
    fi
}

function focus_description_remove() {
    local project="$1"
    
    if [[ -z "$project" ]]; then
        echo "❌ Project name is required."
        echo "Usage: focus description remove <project>"
        echo ""
        echo "Examples:"
        echo "  focus description remove 'coding'"
        echo "  focus description remove meeting"
        exit 1
    fi
    
    # Sanitize and validate project name
    project=$(sanitize_project_name "$project")
    if ! validate_project_name "$project"; then
        exit 1
    fi
    
    # Check if description exists
    local description
    description=$(get_project_description "$project")
    
    if [[ -z "$description" ]]; then
        echo "ℹ️  No description found for project: $project"
        exit 0
    fi
    
    echo "🗑️  Removing session notes for project: $project"
    echo "   Current notes: $description"
    echo "Are you sure? (y/N)"
    read -r response
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        remove_project_description "$project"
        echo "✅ Session notes removed for project: $project"
    else
        echo "Removal cancelled."
    fi
}

function focus_description_list() {
    echo "📋 Project Session Notes:"
    echo
    
    local projects
    projects=$(get_projects_with_descriptions)
    
    if [[ -z "$projects" ]]; then
        echo "No project session notes found."
        echo "Use 'focus description add <project> <notes>' to add notes"
        return 0
    fi
    
    while IFS='|' read -r project description; do
        echo "📝 $project:"
        echo "   $description"
        echo
    done <<< "$projects"
}

function focus_description() {
    local action="$1"
    shift
    
    case "$action" in
        "add")
            focus_description_add "$@"
            ;;
        "show"|"view")
            focus_description_show "$@"
            ;;
        "remove"|"delete"|"del"|"rm")
            focus_description_remove "$@"
            ;;
        "list"|"ls")
            focus_description_list "$@"
            ;;
        *)
            echo "❌ Unknown action: $action"
            echo "Available actions:"
            echo "  add     - Add a description to a project"
            echo "  show    - Show description for a project"
            echo "  remove  - Remove description from a project"
            echo "  list    - List all project descriptions"
            echo
            echo "Examples:"
            echo "  focus description add 'coding' 'Main development project'"
            echo "  focus description show 'coding'"
            echo "  focus description remove 'coding'"
            echo "  focus description list"
            exit 1
            ;;
    esac
}


# Main execution
refocus_script_main focus_description_add "$@"
