#!/usr/bin/env bash
# Refocus Shell - Reset Refocus Shell Subcommand
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
            focus_disabled BOOLEAN DEFAULT 0,
            last_focus_off_time TEXT
        );
        
        CREATE TABLE IF NOT EXISTS sessions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            project TEXT NOT NULL,
            start_time TEXT NOT NULL,
            end_time TEXT NOT NULL,
            duration_seconds INTEGER NOT NULL
        );
        
        -- Insert initial state
        INSERT OR IGNORE INTO state (id, active, project, start_time, prompt_content, prompt_type, nudging_enabled, focus_disabled, last_focus_off_time)
        VALUES (1, 0, NULL, NULL, NULL, 'default', 1, 0, NULL);
    "
    
    if [[ $? -eq 0 ]]; then
        echo "Database initialized successfully"
    else
        echo "Failed to initialize database"
        return 1
    fi
}

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
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    focus_reset "$@"
fi 