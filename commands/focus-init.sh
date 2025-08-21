#!/usr/bin/env bash
# Refocus Shell - Initialize Database Subcommand
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

function focus_init() {
    local db_path="$1"
    
    # Ensure database is migrated to include projects table
    migrate_database
    
    # Use default database path if not provided
    if [[ -z "$db_path" ]]; then
        if [[ -f "$HOME/.local/refocus/refocus.db" ]]; then
            db_path="$HOME/.local/refocus/refocus.db"
        else
            db_path="$HOME/.local/refocus/refocus.db"
        fi
    fi
    
    echo "Initializing database at: $db_path"
    
    # Create directory if it doesn't exist
    local db_dir=$(dirname "$db_path")
    mkdir -p "$db_dir"
    
    # Create database and tables
    sqlite3 "$db_path" "
        CREATE TABLE IF NOT EXISTS state (
            id INTEGER PRIMARY KEY,
            active INTEGER DEFAULT 0,
            project TEXT,
            start_time TEXT,
            prompt_content TEXT,
            prompt_type TEXT DEFAULT 'default',
            nudging_enabled BOOLEAN DEFAULT 1,
            focus_disabled BOOLEAN DEFAULT 0,
            last_focus_off_time TEXT,
            paused INTEGER DEFAULT 0,
            pause_notes TEXT,
            pause_start_time TEXT,
            previous_elapsed INTEGER DEFAULT 0
        );
        
        CREATE TABLE IF NOT EXISTS sessions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            project TEXT NOT NULL,
            start_time TEXT NOT NULL,
            end_time TEXT NOT NULL,
            duration_seconds INTEGER NOT NULL,
            notes TEXT
        );
        
        INSERT OR IGNORE INTO state (id, active, project, start_time, prompt_content, prompt_type, nudging_enabled, focus_disabled, last_focus_off_time, paused, pause_notes, pause_start_time, previous_elapsed) 
        VALUES (1, 0, NULL, NULL, NULL, 'default', 1, 0, NULL, 0, NULL, NULL, 0);
        
        -- Create projects table for storing project descriptions
        CREATE TABLE IF NOT EXISTS projects (
            project TEXT PRIMARY KEY,
            description TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
        );
    "
    
    if [[ $? -eq 0 ]]; then
        echo "✅ Database initialized successfully"
        echo "📊 Database location: $db_path"
    else
        echo "❌ Failed to initialize database"
        exit 1
    fi
}

# Main execution
case "${1:-}" in
    "help"|"--help"|"-h")
        echo "Refocus Shell - Initialize Database"
        echo "================================"
        echo ""
        echo "Usage: focus init [database_path]"
        echo ""
        echo "This command initializes a new refocus shell database with the required"
        echo "tables and default state. If no database path is provided, it will"
        echo "use the default location: ~/.local/refocus/refocus.db"
        echo ""
        echo "Examples:"
        echo "  focus init                    # Initialize with default path"
        echo "  focus init /path/to/db.db     # Initialize with custom path"
        echo ""
        echo "Note: This command is typically not needed as the database is"
        echo "      automatically initialized during installation."
        ;;
    *)
        focus_init "$1"
        ;;
esac 