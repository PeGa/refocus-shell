#!/usr/bin/env bash
# Refocus Shell - Reset Subcommand
# Copyright (c) 2025 PeGa
# Licensed under the GNU General Public License v3

# Source bootstrap module
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/focus-bootstrap.sh"


function focus_reset() {
    echo "This will delete all focus data and reset the database."
    echo "Are you sure you want to continue? (y/N)"
    read -r response
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        # Stop any active session first
        if is_focus_active; then
            echo "Stopping active session..."
            focus_off
        fi
        
        # Get database path
        local db_path
        if [[ -f "$HOME/.local/refocus/refocus.db" ]]; then
            db_path="$HOME/.local/refocus/refocus.db"
        else
            echo "❌ Database not found. Please install refocus shell first."
            exit 1
        fi
        
        # Reset database
        echo "Resetting database..."
        if reset_database "$db_path"; then
            echo "✅ Database reset successfully"
        else
            echo "❌ Failed to reset database"
            exit 1
        fi
    else
        echo "Reset cancelled."
    fi
}


# Main execution
refocus_script_main focus_reset "$@"
