#!/usr/bin/env bash
# Refocus Shell - Import Subcommand
# Copyright (c) 2025 PeGa
# Licensed under the GNU General Public License v3

# Source bootstrap module
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/focus-bootstrap.sh"

import_from_json() {
    local input_file="$1"
    
    # Validate JSON file
    if ! command -v jq >/dev/null 2>&1; then
        echo "❌ jq is required for JSON import but not installed."
        echo "Please install jq: sudo apt-get install jq"
        return 1
    fi
    
    # Validate JSON structure
    if ! jq empty "$input_file" 2>/dev/null; then
        echo "❌ Invalid JSON file: $input_file"
        return 1
    fi
    
    # Check schema version
    local schema_version
    schema_version=$(jq -r '.schema_version // "unknown"' "$input_file")
    if [[ "$schema_version" != "1.0" ]]; then
        echo "⚠️  Warning: Schema version $schema_version may not be compatible with current version"
    fi
    
    # Clear existing database
    rm -f "$DB"
    
    # Initialize database with proper schema
    execute_sqlite "
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
            start_time TEXT,
            end_time TEXT,
            duration_seconds INTEGER NOT NULL,
            notes TEXT,
            duration_only INTEGER DEFAULT 0,
            session_date TEXT
        );
        
        CREATE TABLE IF NOT EXISTS projects (
            project TEXT PRIMARY KEY,
            description TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
        );
        
        INSERT OR IGNORE INTO state (id, active, project, start_time, prompt_content, prompt_type, nudging_enabled, focus_disabled, last_focus_off_time, paused, pause_notes, pause_start_time, previous_elapsed)
        VALUES (1, 0, NULL, NULL, NULL, 'default', 1, 0, NULL, 0, NULL, NULL, 0);
    " "import_from_json" >/dev/null
    
    if [[ $? -ne 0 ]]; then
        echo "❌ Failed to initialize database schema"
        return 1
    fi
    
    # Import state data
    local state_data
    state_data=$(jq -r '.data.state // empty' "$input_file")
    if [[ -n "$state_data" ]] && [[ "$state_data" != "null" ]]; then
        local active project start_time prompt_content prompt_type nudging_enabled focus_disabled last_focus_off_time paused pause_notes pause_start_time previous_elapsed
        
        active=$(jq -r '.active // 0' <<< "$state_data")
        project=$(jq -r '.project // null' <<< "$state_data")
        start_time=$(jq -r '.start_time // null' <<< "$state_data")
        prompt_content=$(jq -r '.prompt_content // null' <<< "$state_data")
        prompt_type=$(jq -r '.prompt_type // "default"' <<< "$state_data")
        nudging_enabled=$(jq -r '.nudging_enabled // true' <<< "$state_data")
        focus_disabled=$(jq -r '.focus_disabled // false' <<< "$state_data")
        last_focus_off_time=$(jq -r '.last_focus_off_time // null' <<< "$state_data")
        paused=$(jq -r '.paused // 0' <<< "$state_data")
        pause_notes=$(jq -r '.pause_notes // null' <<< "$state_data")
        pause_start_time=$(jq -r '.pause_start_time // null' <<< "$state_data")
        previous_elapsed=$(jq -r '.previous_elapsed // 0' <<< "$state_data")
        
        # Convert boolean values to integers
        [[ "$nudging_enabled" == "true" ]] && nudging_enabled=1 || nudging_enabled=0
        [[ "$focus_disabled" == "true" ]] && focus_disabled=1 || focus_disabled=0
        
        # Escape SQL strings and handle null values properly
        project=$(sql_escape "$project")
        start_time=$(sql_escape "$start_time")
        prompt_content=$(sql_escape "$prompt_content")
        prompt_type=$(sql_escape "$prompt_type")
        last_focus_off_time=$(sql_escape "$last_focus_off_time")
        pause_notes=$(sql_escape "$pause_notes")
        pause_start_time=$(sql_escape "$pause_start_time")
        
        # Convert null strings to actual NULL for SQL, otherwise keep quoted
        if [[ "$project" == "null" ]]; then
            project="NULL"
        else
            project="'$project'"
        fi
        
        if [[ "$start_time" == "null" ]]; then
            start_time="NULL"
        else
            start_time="'$start_time'"
        fi
        
        if [[ "$prompt_content" == "null" ]]; then
            prompt_content="NULL"
        else
            prompt_content="'$prompt_content'"
        fi
        
        if [[ "$last_focus_off_time" == "null" ]]; then
            last_focus_off_time="NULL"
        else
            last_focus_off_time="'$last_focus_off_time'"
        fi
        
        if [[ "$pause_notes" == "null" ]]; then
            pause_notes="NULL"
        else
            pause_notes="'$pause_notes'"
        fi
        
        if [[ "$pause_start_time" == "null" ]]; then
            pause_start_time="NULL"
        else
            pause_start_time="'$pause_start_time'"
        fi
        
        execute_sqlite "UPDATE $STATE_TABLE SET 
            active = $active,
            project = $project,
            start_time = $start_time,
            prompt_content = $prompt_content,
            prompt_type = '$prompt_type',
            nudging_enabled = $nudging_enabled,
            focus_disabled = $focus_disabled,
            last_focus_off_time = $last_focus_off_time,
            paused = $paused,
            pause_notes = $pause_notes,
            pause_start_time = $pause_start_time,
            previous_elapsed = $previous_elapsed
            WHERE id = 1;" "import_from_json" >/dev/null
    fi
    
    # Import sessions data
    local sessions_data
    sessions_data=$(jq -r '.data.sessions // empty' "$input_file")
    if [[ -n "$sessions_data" ]] && [[ "$sessions_data" != "null" ]]; then
        local session_count
        session_count=$(jq '. | length' <<< "$sessions_data")
        
        for ((i=0; i<session_count; i++)); do
            local session
            session=$(jq ".[$i]" <<< "$sessions_data")
            
            local id project start_time end_time duration_seconds notes duration_only session_date
            
            id=$(jq -r '.id // null' <<< "$session")
            project=$(jq -r '.project // ""' <<< "$session")
            start_time=$(jq -r '.start_time // null' <<< "$session")
            end_time=$(jq -r '.end_time // null' <<< "$session")
            duration_seconds=$(jq -r '.duration_seconds // 0' <<< "$session")
            notes=$(jq -r '.notes // null' <<< "$session")
            duration_only=$(jq -r '.duration_only // false' <<< "$session")
            session_date=$(jq -r '.session_date // null' <<< "$session")
            
            # Convert boolean values to integers
            [[ "$duration_only" == "true" ]] && duration_only=1 || duration_only=0
            
            # Escape SQL strings and handle null values properly
            project=$(sql_escape "$project")
            start_time=$(sql_escape "$start_time")
            end_time=$(sql_escape "$end_time")
            notes=$(sql_escape "$notes")
            session_date=$(sql_escape "$session_date")
            
            # Convert null strings to actual NULL for SQL, otherwise keep quoted
            if [[ "$start_time" == "null" ]]; then
                start_time="NULL"
            else
                start_time="'$start_time'"
            fi
            
            if [[ "$end_time" == "null" ]]; then
                end_time="NULL"
            else
                end_time="'$end_time'"
            fi
            
            if [[ "$notes" == "null" ]]; then
                notes="NULL"
            else
                notes="'$notes'"
            fi
            
            if [[ "$session_date" == "null" ]]; then
                session_date="NULL"
            else
                session_date="'$session_date'"
            fi
            
            execute_sqlite "INSERT INTO $SESSIONS_TABLE (id, project, start_time, end_time, duration_seconds, notes, duration_only, session_date) 
                VALUES ($id, '$project', $start_time, $end_time, $duration_seconds, $notes, $duration_only, $session_date);" "import_from_json" >/dev/null
        done
    fi
    
    # Import projects data
    local projects_data
    projects_data=$(jq -r '.data.projects // empty' "$input_file")
    if [[ -n "$projects_data" ]] && [[ "$projects_data" != "null" ]]; then
        local project_count
        project_count=$(jq '. | length' <<< "$projects_data")
        
        for ((i=0; i<project_count; i++)); do
            local project
            project=$(jq ".[$i]" <<< "$projects_data")
            
            local project_name description created_at updated_at
            
            project_name=$(jq -r '.project // ""' <<< "$project")
            description=$(jq -r '.description // ""' <<< "$project")
            created_at=$(jq -r '.created_at // ""' <<< "$project")
            updated_at=$(jq -r '.updated_at // ""' <<< "$project")
            
            # Escape SQL strings
            project_name=$(sql_escape "$project_name")
            description=$(sql_escape "$description")
            created_at=$(sql_escape "$created_at")
            updated_at=$(sql_escape "$updated_at")
            
            execute_sqlite "INSERT OR REPLACE INTO $PROJECTS_TABLE (project, description, created_at, updated_at) 
                VALUES ('$project_name', '$description', '$created_at', '$updated_at');" "import_from_json" >/dev/null
        done
    fi
    
    return 0
}

function focus_import() {
    local input_file="$1"
    
    if [[ -z "$input_file" ]]; then
        echo "❌ No input file specified."
        echo "Usage: focus import <file.sql|file.json>"
        echo ""
        echo "Supported formats:"
        echo "  - SQLite dump files (.sql)"
        echo "  - JSON export files (.json)"
        exit 1
    fi
    
    # Validate file path
    if ! validate_file_path "$input_file" "Input file"; then
        exit 1
    fi
    
    if [[ ! -f "$input_file" ]]; then
        echo "❌ File not found: $input_file"
        exit 1
    fi
    
    # Detect file type
    local file_type=""
    if [[ "$input_file" == *.json ]]; then
        file_type="json"
    elif [[ "$input_file" == *.sql ]]; then
        file_type="sql"
    else
        # Try to detect by content
        if head -1 "$input_file" | grep -q "PRAGMA\|BEGIN\|CREATE\|INSERT"; then
            file_type="sql"
        elif head -1 "$input_file" | grep -q "schema_version\|refocus_version"; then
            file_type="json"
        else
            echo "❌ Unable to determine file type. Please use .sql or .json extension."
            exit 1
        fi
    fi
    
    echo "📥 Importing focus data from: $input_file"
    echo "📋 Detected format: $file_type"
    echo "⚠️  This will overwrite existing data. Continue? (y/N)"
    read -r response
    
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        echo "Import cancelled."
        exit 0
    fi
    
    # Stop any active session first
    if is_focus_active; then
        echo "Stopping active session..."
        focus_off
    fi
    
    # Backup current database if it exists
    if [[ -f "$DB" ]]; then
        local backup_file
        backup_file="${DB}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$DB" "$backup_file"
        echo "📋 Created backup: $backup_file"
    fi
    
    # Import based on file type
    if [[ "$file_type" == "json" ]]; then
        import_from_json "$input_file"
    else
        import_from_sql "$input_file"
    fi
    
    if [[ $? -eq 0 ]]; then
        echo "✅ Focus data imported successfully from: $input_file"
        echo "📊 Import summary:"
        if [[ "$file_type" == "json" ]]; then
            echo "   - Database restored from JSON export"
            echo "   - All sessions, state, and projects imported"
        else
            echo "   - Database restored from SQLite dump"
            echo "   - All tables and data imported"
        fi
    else
        echo "❌ Import failed"
        if [[ -f "$backup_file" ]]; then
            echo "🔄 Restoring from backup..."
            cp "$backup_file" "$DB"
        fi
        exit 1
    fi
}


# Main execution
refocus_script_main focus_import "$@"
