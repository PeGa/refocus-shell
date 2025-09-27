#!/usr/bin/env bash
# Refocus Shell Database Functions Library
# Copyright (C) 2025 Pablo Gonzalez
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

# Database configuration
DB_DEFAULT="$HOME/.local/refocus/refocus.db"
DB="${REFOCUS_DB:-$DB_DEFAULT}"
# Table names - these should match what's used in the main script
STATE_TABLE="${STATE_TABLE:-state}"
SESSIONS_TABLE="${SESSIONS_TABLE:-sessions}"
PROJECTS_TABLE="${PROJECTS_TABLE:-projects}"

# Function to safely escape SQL strings
sql_escape() {
    local input="$1"
    # Replace single quotes with double single quotes (SQL escaping)
    echo "$input" | sed "s/'/''/g"
}

# Function to get the last project from sessions
get_last_project() {
    execute_sqlite "SELECT project FROM $SESSIONS_TABLE WHERE project != '[idle]' ORDER BY end_time DESC LIMIT 1;" "get_last_project"
}

# Function to get the last session details
get_last_session() {
    execute_sqlite "SELECT project, end_time, duration_seconds FROM $SESSIONS_TABLE WHERE project != '[idle]' ORDER BY end_time DESC LIMIT 1;" "get_last_session"
}

# Function to get total time for a project
get_total_project_time() {
    local project="$1"
    local escaped_project
    escaped_project=$(sql_escape "$project")
    execute_sqlite "SELECT COALESCE(SUM(duration_seconds), 0) FROM $SESSIONS_TABLE WHERE project = '$escaped_project' AND project != '[idle]';" "get_total_project_time"
}

# Function to count sessions for a project
count_sessions_for_project() {
    local project="$1"
    local escaped_project
    escaped_project=$(sql_escape "$project")
    execute_sqlite "SELECT COUNT(*) FROM $SESSIONS_TABLE WHERE project = '$escaped_project';" "count_sessions_for_project"
}

# Function to get sessions in a time range
get_sessions_in_range() {
    local start_time="$1"
    local end_time="$2"
    local escaped_start_time
    local escaped_end_time
    escaped_start_time=$(sql_escape "$start_time")
    escaped_end_time=$(sql_escape "$end_time")
    execute_sqlite "SELECT project, start_time, end_time, duration_seconds, notes FROM $SESSIONS_TABLE WHERE end_time >= '$escaped_start_time' AND end_time <= '$escaped_end_time' ORDER BY start_time;" "get_sessions_in_range"
}

# Function to get current focus state
get_focus_state() {
    execute_sqlite "SELECT active, project, start_time, paused, pause_notes, pause_start_time, previous_elapsed FROM $STATE_TABLE WHERE id = 1;" "get_focus_state"
}

# Function to get focus disabled status
get_focus_disabled() {
    execute_sqlite "SELECT focus_disabled FROM $STATE_TABLE WHERE id = 1;" "get_focus_disabled"
}

# Function to get nudging enabled status
get_nudging_enabled() {
    execute_sqlite "SELECT nudging_enabled FROM $STATE_TABLE WHERE id = 1;" "get_nudging_enabled"
}

# Function to get last focus off time
get_last_focus_off_time() {
    execute_sqlite "SELECT last_focus_off_time FROM $STATE_TABLE WHERE id = 1;" "get_last_focus_off_time"
}

# Function to get current prompt content
get_prompt_content() {
    execute_sqlite "SELECT prompt_content FROM $STATE_TABLE WHERE id = 1;" "get_prompt_content"
}

# Function to get prompt content by type
get_prompt_content_by_type() {
    local prompt_type="$1"
    local escaped_prompt_type
    escaped_prompt_type=$(sql_escape "$prompt_type")
    execute_sqlite "SELECT prompt_content FROM $STATE_TABLE WHERE prompt_type = '$escaped_prompt_type' AND id = 1;" "get_prompt_content_by_type"
}

# Function to update focus state
update_focus_state() {
    local active="$1"
    local project="$2"
    local start_time="$3"
    local last_focus_off_time="$4"
    local paused="$5"
    local pause_notes="$6"
    local pause_start_time="$7"
    local previous_elapsed="$8"
    
    # Escape project name for SQL
    local escaped_project
    escaped_project=$(sql_escape "$project")
    
    # Escape pause notes for SQL
    local escaped_pause_notes
    escaped_pause_notes=$(sql_escape "$pause_notes")
    
    # Escape timestamps for SQL
    local escaped_start_time
    local escaped_last_focus_off_time
    escaped_start_time=$(sql_escape "$start_time")
    escaped_last_focus_off_time=$(sql_escape "$last_focus_off_time")
    
    # Update the state table with pause information
    execute_sqlite "UPDATE $STATE_TABLE SET 
        active = $active, 
        project = '$escaped_project', 
        start_time = '$escaped_start_time', 
        last_focus_off_time = '$escaped_last_focus_off_time',
        paused = ${paused:-0},
        pause_notes = '$escaped_pause_notes',
        pause_start_time = '$pause_start_time',
        previous_elapsed = ${previous_elapsed:-0}
        WHERE id = 1;" "update_focus_state" >/dev/null
}

# Function to update prompt content
update_prompt_content() {
    local prompt_content="$1"
    local prompt_type="$2"
    
    local escaped_prompt_content
    escaped_prompt_content=$(sql_escape "$prompt_content")
    local escaped_prompt_type
    escaped_prompt_type=$(sql_escape "$prompt_type")
    execute_sqlite "UPDATE $STATE_TABLE SET prompt_content = '$escaped_prompt_content', prompt_type = '$escaped_prompt_type' WHERE id = 1;" "update_prompt_content" >/dev/null
}

# Function to insert a session
insert_session() {
    local project="$1"
    local start_time="$2"
    local end_time="$3"
    local duration="$4"
    local notes="${5:-}"
    
    local escaped_project
    escaped_project=$(sql_escape "$project")
    local escaped_notes
    escaped_notes=$(sql_escape "$notes")
    execute_sqlite "INSERT INTO $SESSIONS_TABLE (project, start_time, end_time, duration_seconds, notes) VALUES ('$escaped_project', '$start_time', '$end_time', $duration, '$escaped_notes');" "insert_session" >/dev/null
}

# Function to insert a duration-only session
insert_duration_only_session() {
    local project="$1"
    local duration="$2"
    local session_date="$3"
    local notes="${4:-}"
    
    local escaped_project
    escaped_project=$(sql_escape "$project")
    local escaped_notes
    escaped_notes=$(sql_escape "$notes")
    execute_sqlite "INSERT INTO $SESSIONS_TABLE (project, start_time, end_time, duration_seconds, notes, duration_only, session_date) VALUES ('$escaped_project', NULL, NULL, $duration, '$escaped_notes', 1, '$session_date');" "insert_duration_only_session" >/dev/null
}

# Function to update a session
update_session() {
    local project="$1"
    local start_time="$2"
    local end_time="$3"
    local duration="$4"
    
    local escaped_project
    local escaped_start_time
    local escaped_end_time
    escaped_project=$(sql_escape "$project")
    escaped_start_time=$(sql_escape "$start_time")
    escaped_end_time=$(sql_escape "$end_time")
    execute_sqlite "UPDATE $SESSIONS_TABLE SET start_time = '$escaped_start_time', end_time = '$escaped_end_time', duration_seconds = $duration WHERE project = '$escaped_project';" "update_session" >/dev/null
}

# Function to delete sessions for a project
delete_sessions_for_project() {
    local project="$1"
    local escaped_project
    escaped_project=$(sql_escape "$project")
    execute_sqlite "DELETE FROM $SESSIONS_TABLE WHERE project = '$escaped_project';" "delete_sessions_for_project" >/dev/null
}

# Function to get session info for a project
get_session_info() {
    local project="$1"
    local escaped_project
    escaped_project=$(sql_escape "$project")
    execute_sqlite "SELECT start_time, end_time, duration_seconds FROM $SESSIONS_TABLE WHERE project = '$escaped_project';" "get_session_info"
}

# Function to update focus disabled status
update_focus_disabled() {
    local disabled="$1"
    execute_sqlite "UPDATE $STATE_TABLE SET focus_disabled = $disabled WHERE id = 1;" "update_focus_disabled" >/dev/null
}

# Function to update nudging enabled status
update_nudging_enabled() {
    local enabled="$1"
    execute_sqlite "UPDATE $STATE_TABLE SET nudging_enabled = $enabled WHERE id = 1;" "update_nudging_enabled" >/dev/null
}

# Function to install cron job for a specific focus session
install_focus_cron_job() {
    local project="$1"
    local start_time="$2"
    
    # Calculate the start minute for cron (current minute when focus started)
    local start_minute
    start_minute=$(date --date="$start_time" +%M 2>/dev/null)
    if [[ $? -ne 0 ]]; then
        start_minute=$(date +%M)
    fi
    
    # Calculate the cron pattern: (start_minute % 10)-59/10
    # Examples: :31 → 1-59/10, :45 → 5-59/10, :37 → 7-59/10
    local ones_digit=$((start_minute % 10))
    local cron_pattern="${ones_digit}-59/10"
    local nudge_script="$HOME/.local/refocus/focus-nudge"
    
    # Create cron job with environment variables for X11/Wayland
    local cron_entry="$cron_pattern * * * * DISPLAY=$DISPLAY WAYLAND_DISPLAY=$WAYLAND_DISPLAY DBUS_SESSION_BUS_ADDRESS=$DBUS_SESSION_BUS_ADDRESS $nudge_script"
    
    # Get current crontab
    local temp_cron_file="/tmp/focus_cron_$$"
    crontab -l 2>/dev/null > "$temp_cron_file" || true
    
    # Remove any existing focus-nudge cron jobs
    sed -i "\|$nudge_script|d" "$temp_cron_file"
    
    # Add the new cron job
    echo "$cron_entry" >> "$temp_cron_file"
    
    # Install the new crontab
    if crontab "$temp_cron_file"; then
        # Cron job installed successfully (silent for user)
        :
    else
        echo "Failed to install cron job" >&2
        rm -f "$temp_cron_file"
        return 1
    fi
    
    rm -f "$temp_cron_file"
}

# Function to remove focus cron job
remove_focus_cron_job() {
    local nudge_script="$HOME/.local/refocus/focus-nudge"
    local temp_cron_file="/tmp/focus_cron_$$"
    
    # Get current crontab
    crontab -l 2>/dev/null > "$temp_cron_file" || true
    
    # Remove any focus-nudge cron jobs
    if grep -q "$nudge_script" "$temp_cron_file" 2>/dev/null; then
        sed -i "\|$nudge_script|d" "$temp_cron_file"
        
        # Install the updated crontab
        if crontab "$temp_cron_file"; then
            # Cron job removed successfully (silent for user)
            :
        else
            echo "Failed to remove cron job" >&2
            rm -f "$temp_cron_file"
            return 1
        fi
    fi
    
    rm -f "$temp_cron_file"
}

# Function to update entire state record (for imports)
update_state_record() {
    local active="$1"
    local project="$2"
    local start_time="$3"
    local prompt_content="$4"
    local prompt_type="$5"
    local nudging_enabled="$6"
    local focus_disabled="$7"
    
    # Escape project name for SQL
    local escaped_project
    if [[ -n "$project" && "$project" != "null" ]]; then
        escaped_project="'$(sql_escape "$project")'"
    else
        escaped_project="NULL"
    fi
    
    # Escape prompt_content for SQL
    local escaped_prompt_content
    if [[ -n "$prompt_content" && "$prompt_content" != "null" ]]; then
        escaped_prompt_content="'$(sql_escape "$prompt_content")'"
    else
        escaped_prompt_content="NULL"
    fi
    
    # Escape timestamps for SQL
    local escaped_start_time
    local escaped_prompt_type
    escaped_start_time=$(sql_escape "$start_time")
    escaped_prompt_type=$(sql_escape "$prompt_type")
    
    sqlite3 "$DB" "UPDATE $STATE_TABLE SET active = $active, project = $escaped_project, start_time = '$escaped_start_time', prompt_content = $escaped_prompt_content, prompt_type = '$escaped_prompt_type', nudging_enabled = $nudging_enabled, focus_disabled = $focus_disabled WHERE id = 1;"
}

# Function to clear all sessions
clear_all_sessions() {
    sqlite3 "$DB" "DELETE FROM $SESSIONS_TABLE;"
}

# Function to clear additional state records
clear_additional_state() {
    sqlite3 "$DB" "DELETE FROM $STATE_TABLE WHERE id > 1;"
}

# Project description functions
# Function to get project description
get_project_description() {
    local project="$1"
    local escaped_project
    escaped_project=$(sql_escape "$project")
    execute_sqlite "SELECT description FROM $PROJECTS_TABLE WHERE project = '$escaped_project';" "get_project_description"
}

# Function to set project description
set_project_description() {
    local project="$1"
    local description="$2"
    local escaped_project
    local escaped_description
    
    escaped_project=$(sql_escape "$project")
    escaped_description=$(sql_escape "$description")
    
    # Use INSERT OR REPLACE to handle both new and existing projects
    execute_sqlite "INSERT OR REPLACE INTO $PROJECTS_TABLE (project, description, created_at, updated_at) VALUES ('$escaped_project', '$escaped_description', datetime('now'), datetime('now'));" "set_project_description" >/dev/null
}

# Function to remove project description
remove_project_description() {
    local project="$1"
    local escaped_project
    escaped_project=$(sql_escape "$project")
    execute_sqlite "DELETE FROM $PROJECTS_TABLE WHERE project = '$escaped_project';" "remove_project_description" >/dev/null
}

# Function to get all projects with descriptions
get_projects_with_descriptions() {
    execute_sqlite "SELECT project, description FROM $PROJECTS_TABLE ORDER BY project;" "get_projects_with_descriptions"
}

# Function to check if projects table exists
projects_table_exists() {
    execute_sqlite "SELECT name FROM sqlite_master WHERE type='table' AND name='$PROJECTS_TABLE';" "projects_table_exists"
}

# Function to create projects table if it doesn't exist
ensure_projects_table() {
    if [[ -z "$(projects_table_exists)" ]]; then
        execute_sqlite "
            CREATE TABLE IF NOT EXISTS $PROJECTS_TABLE (
                project TEXT PRIMARY KEY,
                description TEXT NOT NULL,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL
            );
        " "ensure_projects_table" >/dev/null
    fi
}

# Function to migrate existing database to include projects table and notes column
migrate_database() {
    ensure_projects_table
    
    # Check if sessions table has notes column
    local has_notes_column
    has_notes_column=$(execute_sqlite "PRAGMA table_info($SESSIONS_TABLE);" "migrate_database" | grep -c "notes" || echo "0")
    has_notes_column=$(echo "$has_notes_column" | tr -d '\n')
    
    if [[ "$has_notes_column" -eq 0 ]]; then
        echo "Migrating database: adding notes column to sessions table..."
        execute_sqlite "ALTER TABLE $SESSIONS_TABLE ADD COLUMN notes TEXT;" "migrate_database" >/dev/null
    fi
    
    # Check if sessions table has duration_only column
    local has_duration_only_column
    has_duration_only_column=$(execute_sqlite "PRAGMA table_info($SESSIONS_TABLE);" "migrate_database" | grep -c "duration_only" || echo "0")
    has_duration_only_column=$(echo "$has_duration_only_column" | tr -d '\n')
    
    if [[ "$has_duration_only_column" -eq 0 ]]; then
        echo "Migrating database: adding duration_only column to sessions table..."
        execute_sqlite "ALTER TABLE $SESSIONS_TABLE ADD COLUMN duration_only INTEGER DEFAULT 0;" "migrate_database" >/dev/null
    fi
    
    # Check if sessions table has session_date column
    local has_session_date_column
    has_session_date_column=$(execute_sqlite "PRAGMA table_info($SESSIONS_TABLE);" "migrate_database" | grep -c "session_date" || echo "0")
    has_session_date_column=$(echo "$has_session_date_column" | tr -d '\n')
    
    if [[ "$has_session_date_column" -eq 0 ]]; then
        echo "Migrating database: adding session_date column to sessions table..."
        execute_sqlite "ALTER TABLE $SESSIONS_TABLE ADD COLUMN session_date TEXT;" "migrate_database" >/dev/null
    fi
    
    # Check if sessions table start_time/end_time are nullable (old schema had NOT NULL)
    local start_time_nullable
    start_time_nullable=$(execute_sqlite "PRAGMA table_info($SESSIONS_TABLE);" "migrate_database" | grep "start_time" | grep -c "NOT NULL" || echo "0")
    start_time_nullable=$(echo "$start_time_nullable" | tr -d '\n')
    
    if [[ "$start_time_nullable" -gt 0 ]]; then
        echo "Migrating database: making start_time/end_time nullable in sessions table..."
        # SQLite doesn't support ALTER COLUMN, so we need to recreate the table
        execute_sqlite "
            CREATE TABLE sessions_new (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                project TEXT NOT NULL,
                start_time TEXT,
                end_time TEXT,
                duration_seconds INTEGER NOT NULL,
                notes TEXT,
                duration_only INTEGER DEFAULT 0,
                session_date TEXT
            );
            INSERT INTO sessions_new SELECT id, project, start_time, end_time, duration_seconds, notes, 
                COALESCE(duration_only, 0), COALESCE(session_date, '') FROM $SESSIONS_TABLE;
            DROP TABLE $SESSIONS_TABLE;
            ALTER TABLE sessions_new RENAME TO $SESSIONS_TABLE;
        " "migrate_database" >/dev/null
    fi
    
    # Check if state table has pause-related columns
    local has_pause_columns
    has_pause_columns=$(execute_sqlite "PRAGMA table_info($STATE_TABLE);" "migrate_database" | grep -c -E "(paused|pause_notes|pause_start_time|previous_elapsed)" || echo "0")
    has_pause_columns=$(echo "$has_pause_columns" | tr -d '\n')
    
    if [[ "$has_pause_columns" -lt 4 ]]; then
        echo "Migrating database: adding pause-related columns to state table..."
        
        # Add paused column
        local has_paused
        has_paused=$(execute_sqlite "PRAGMA table_info($STATE_TABLE);" "migrate_database" | grep -c "paused" || echo "0")
        has_paused=$(echo "$has_paused" | tr -d '\n')
        if [[ "$has_paused" -eq 0 ]]; then
            execute_sqlite "ALTER TABLE $STATE_TABLE ADD COLUMN paused INTEGER DEFAULT 0;" "migrate_database" >/dev/null
        fi
        
        # Add pause_notes column
        local has_pause_notes
        has_pause_notes=$(execute_sqlite "PRAGMA table_info($STATE_TABLE);" "migrate_database" | grep -c "pause_notes" || echo "0")
        has_pause_notes=$(echo "$has_pause_notes" | tr -d '\n')
        if [[ "$has_pause_notes" -eq 0 ]]; then
            execute_sqlite "ALTER TABLE $STATE_TABLE ADD COLUMN pause_notes TEXT;" "migrate_database" >/dev/null
        fi
        
        # Add pause_start_time column
        local has_pause_start_time
        has_pause_start_time=$(execute_sqlite "PRAGMA table_info($STATE_TABLE);" "migrate_database" | grep -c "pause_start_time" || echo "0")
        has_pause_start_time=$(echo "$has_pause_start_time" | tr -d '\n')
        if [[ "$has_pause_start_time" -eq 0 ]]; then
            execute_sqlite "ALTER TABLE $STATE_TABLE ADD COLUMN pause_start_time TEXT;" "migrate_database" >/dev/null
        fi
        
        # Add previous_elapsed column
        local has_previous_elapsed
        has_previous_elapsed=$(execute_sqlite "PRAGMA table_info($STATE_TABLE);" "migrate_database" | grep -c "previous_elapsed" || echo "0")
        has_previous_elapsed=$(echo "$has_previous_elapsed" | tr -d '\n')
        if [[ "$has_previous_elapsed" -eq 0 ]]; then
            execute_sqlite "ALTER TABLE $STATE_TABLE ADD COLUMN previous_elapsed INTEGER DEFAULT 0;" "migrate_database" >/dev/null
        fi
    fi
}

# Export function for use in other modules
export -f migrate_database

# Function to check if a session is currently paused
is_session_paused() {
    local paused
    paused=$(execute_sqlite "SELECT paused FROM $STATE_TABLE WHERE id = 1;" "is_session_paused")
    [[ "$paused" -eq 1 ]]
}

# Function to get paused session information
get_paused_session_info() {
    execute_sqlite "SELECT project, pause_notes, pause_start_time, previous_elapsed FROM $STATE_TABLE WHERE id = 1;" "get_paused_session_info"
}

# Function to pause the current focus session
pause_focus_session() {
    local pause_notes="$1"
    local current_time="$2"
    
    # Get current session info
    local current_state
    current_state=$(get_focus_state)
    if [[ -z "$current_state" ]]; then
        return 1
    fi
    
    IFS='|' read -r active project start_time paused pause_notes_old pause_start_time_old previous_elapsed_old <<< "$current_state"
    
    if [[ "$active" -eq 0 ]] || [[ -z "$project" ]]; then
        return 1
    fi
    
    # Calculate elapsed time so far
    local start_ts=$(date --date="$start_time" +%s 2>/dev/null)
    local current_ts=$(date --date="$current_time" +%s 2>/dev/null)
    local elapsed_seconds=0
    
    if [[ -n "$start_ts" ]] && [[ -n "$current_ts" ]]; then
        elapsed_seconds=$((current_ts - start_ts))
    fi
    
    # Escape pause notes for SQL
    local escaped_pause_notes
    escaped_pause_notes=$(sql_escape "$pause_notes")
    
    # Update state to paused
    execute_sqlite "UPDATE $STATE_TABLE SET 
        active = 0, 
        paused = 1,
        pause_notes = '$escaped_pause_notes',
        pause_start_time = '$current_time',
        previous_elapsed = $elapsed_seconds
        WHERE id = 1;" "pause_focus_session" >/dev/null
    
    echo "$project|$elapsed_seconds"
}

# Function to resume a paused session
resume_focus_session() {
    local include_previous_elapsed="$1"
    local current_time="$2"
    
    # Get paused session info
    local paused_info
    paused_info=$(get_paused_session_info)
    if [[ -z "$paused_info" ]]; then
        return 1
    fi
    
    IFS='|' read -r project pause_notes pause_start_time previous_elapsed <<< "$paused_info"
    
    if [[ -z "$project" ]]; then
        return 1
    fi
    
    # Calculate new start time based on whether to include previous elapsed time
    local new_start_time="$current_time"
    if [[ "$include_previous_elapsed" -eq 1 ]]; then
        # Calculate the original start time by subtracting previous elapsed time
        local pause_ts=$(date --date="$pause_start_time" +%s 2>/dev/null)
        local new_start_ts=$((pause_ts - previous_elapsed))
        new_start_time=$(date --date="@$new_start_ts" --iso-8601=seconds 2>/dev/null)
    fi
    
    # Escape project name for SQL
    local escaped_project
    escaped_project=$(sql_escape "$project")
    
    # Update state to active
    execute_sqlite "UPDATE $STATE_TABLE SET 
        active = 1, 
        project = '$escaped_project',
        start_time = '$new_start_time',
        paused = 0,
        pause_notes = '',
        pause_start_time = '',
        previous_elapsed = 0
        WHERE id = 1;" "resume_focus_session" >/dev/null
    
    echo "$project|$new_start_time|$include_previous_elapsed"
}

# Function to update nudging enabled status
update_nudging_enabled() {
    local enabled="$1"
    execute_sqlite "UPDATE $STATE_TABLE SET nudging_enabled = $enabled WHERE id = 1;" "update_nudging_enabled" >/dev/null
}

# Function to install cron job for a specific focus session
install_focus_cron_job() {
    local project="$1"
    local start_time="$2"
    
    # Calculate the start minute for cron (current minute when focus started)
    local start_minute
    start_minute=$(date --date="$start_time" +%M 2>/dev/null)
    if [[ $? -ne 0 ]]; then
        start_minute=$(date +%M)
    fi
    
    # Calculate the cron pattern: (start_minute % 10)-59/10
    # Examples: :31 → 1-59/10, :45 → 5-59/10, :37 → 7-59/10
    local ones_digit=$((start_minute % 10))
    local cron_pattern="${ones_digit}-59/10"
    local nudge_script="$HOME/.local/refocus/focus-nudge"
    
    # Create cron job with environment variables for X11/Wayland
    local cron_entry="$cron_pattern * * * * DISPLAY=$DISPLAY WAYLAND_DISPLAY=$WAYLAND_DISPLAY DBUS_SESSION_BUS_ADDRESS=$DBUS_SESSION_BUS_ADDRESS $nudge_script"
    
    # Get current crontab
    local temp_cron_file="/tmp/focus_cron_$$"
    crontab -l 2>/dev/null > "$temp_cron_file" || true
    
    # Remove any existing focus-nudge cron jobs
    sed -i "\|$nudge_script|d" "$temp_cron_file"
    
    # Add the new cron job
    echo "$cron_entry" >> "$temp_cron_file"
    
    # Install the new crontab
    if crontab "$temp_cron_file"; then
        # Cron job installed successfully (silent for user)
        :
    else
        echo "Failed to install cron job" >&2
        rm -f "$temp_cron_file"
        return 1
    fi
    
    rm -f "$temp_cron_file"
}

# Function to remove focus cron job
remove_focus_cron_job() {
    local nudge_script="$HOME/.local/refocus/focus-nudge"
    local temp_cron_file="/tmp/focus_cron_$$"
    
    # Get current crontab
    crontab -l 2>/dev/null > "$temp_cron_file" || true
    
    # Remove any focus-nudge cron jobs
    if grep -q "$nudge_script" "$temp_cron_file" 2>/dev/null; then
        sed -i "\|$nudge_script|d" "$temp_cron_file"
        
        # Install the updated crontab
        if crontab "$temp_cron_file"; then
            # Cron job removed successfully (silent for user)
            :
        else
            echo "Failed to remove cron job" >&2
            rm -f "$temp_cron_file"
            return 1
        fi
    fi
    
    rm -f "$temp_cron_file"
}
# Function to reset the database
reset_database() {
    local db_path="$1"
    
    if [[ -f "$db_path" ]]; then
        # Create backup before reset
        local backup_path="${db_path}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$db_path" "$backup_path"
        
        # Remove the database file
        rm -f "$db_path"
    fi
    
    # Recreate the database with proper schema
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
    " "reset_database" >/dev/null
    
    return $?
}

# Export function for use in other modules
export -f reset_database
