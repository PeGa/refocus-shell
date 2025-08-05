#!/usr/bin/env bash
# Refocus Shell - Initialize Database Subcommand
# Copyright (c) 2025 PeGa
# Licensed under the GNU General Public License v3

# Source libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$HOME/.local/focus/lib/focus-db.sh" ]]; then
    source "$HOME/.local/focus/lib/focus-db.sh"
    source "$HOME/.local/focus/lib/focus-utils.sh"
else
    source "$SCRIPT_DIR/../lib/focus-db.sh"
    source "$SCRIPT_DIR/../lib/focus-utils.sh"
fi

function focus_init() {
    local db_path="$1"
    
    # Use default database path if not provided
    if [[ -z "$db_path" ]]; then
        if [[ -f "$HOME/.local/focus/timelog.db" ]]; then
            db_path="$HOME/.local/focus/timelog.db"
        else
            db_path="$HOME/.local/focus/timelog.db"
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
            work_disabled BOOLEAN DEFAULT 0,
            last_work_off_time TEXT
        );
        
        CREATE TABLE IF NOT EXISTS sessions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            project TEXT NOT NULL,
            start_time TEXT NOT NULL,
            end_time TEXT NOT NULL,
            duration_seconds INTEGER NOT NULL
        );
        
        INSERT OR IGNORE INTO state (id, active, project, start_time, prompt_content, prompt_type, nudging_enabled, work_disabled, last_work_off_time) 
        VALUES (1, 0, NULL, NULL, NULL, 'default', 1, 0, NULL);
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
        echo "use the default location: ~/.local/focus/timelog.db"
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