#!/usr/bin/env bash
# Refocus Shell - Reset Refocus Shell Subcommand
# Copyright (c) 2025 PeGa
# Licensed under the GNU General Public License v3

# Source libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$HOME/.local/work/lib/work-db.sh" ]]; then
    source "$HOME/.local/work/lib/work-db.sh"
    source "$HOME/.local/work/lib/work-utils.sh"
else
    source "$SCRIPT_DIR/../lib/work-db.sh"
    source "$SCRIPT_DIR/../lib/work-utils.sh"
fi

# Set table names
STATE_TABLE="${STATE_TABLE:-state}"
SESSIONS_TABLE="${SESSIONS_TABLE:-sessions}"

# Function to reset database
reset_database() {
    local db_path="$1"
    
    echo "Resetting database at: $db_path"
    
    # Remove the database file
    rm -f "$db_path"
    echo "Database deleted."
    
    # Reinitialize the database
    init_database "$db_path"
    echo "Database reset complete."
}

# Function to initialize database
init_database() {
    local db_path="$1"
    
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
        echo "Database initialized successfully"
    else
        echo "Failed to initialize database"
        return 1
    fi
}

function work_reset() {
    echo "This will delete all work data and reset the database."
    echo "Are you sure you want to continue? (y/N)"
    read -r response
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        # Stop any active session first
        if is_work_active; then
            echo "Stopping active session..."
            work_off
        fi
        
        # Get database path
        local db_path
        if [[ -f "$HOME/.local/work/timelog.db" ]]; then
            db_path="$HOME/.local/work/timelog.db"
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
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    work_reset "$@"
fi 