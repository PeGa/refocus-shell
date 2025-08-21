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
    sqlite3 "$DB" "SELECT project FROM $SESSIONS_TABLE WHERE project != '[idle]' ORDER BY end_time DESC LIMIT 1;" 2>/dev/null
}

# Function to get the last session details
get_last_session() {
    sqlite3 "$DB" "SELECT project, end_time, duration_seconds FROM $SESSIONS_TABLE WHERE project != '[idle]' ORDER BY end_time DESC LIMIT 1;" 2>/dev/null
}

# Function to get total time for a project
get_total_project_time() {
    local project="$1"
    local escaped_project
    escaped_project=$(sql_escape "$project")
    sqlite3 "$DB" "SELECT COALESCE(SUM(duration_seconds), 0) FROM $SESSIONS_TABLE WHERE project = '$escaped_project' AND project != '[idle]';" 2>/dev/null
}

# Function to count sessions for a project
count_sessions_for_project() {
    local project="$1"
    local escaped_project
    escaped_project=$(sql_escape "$project")
    sqlite3 "$DB" "SELECT COUNT(*) FROM $SESSIONS_TABLE WHERE project = '$escaped_project';" 2>/dev/null
}

# Function to get sessions in a time range
get_sessions_in_range() {
    local start_time="$1"
    local end_time="$2"
    sqlite3 "$DB" "SELECT project, start_time, end_time, duration_seconds, notes FROM $SESSIONS_TABLE WHERE end_time >= '$start_time' AND end_time <= '$end_time' ORDER BY start_time;" 2>/dev/null
}

# Function to get current focus state
get_focus_state() {
    sqlite3 "$DB" "SELECT active, project, start_time, paused, pause_notes, pause_start_time, previous_elapsed FROM $STATE_TABLE WHERE id = 1;" 2>/dev/null
}

# Function to get focus disabled status
get_focus_disabled() {
    sqlite3 "$DB" "SELECT focus_disabled FROM $STATE_TABLE WHERE id = 1;" 2>/dev/null
}

# Function to get nudging enabled status
get_nudging_enabled() {
    sqlite3 "$DB" "SELECT nudging_enabled FROM $STATE_TABLE WHERE id = 1;" 2>/dev/null
}

# Function to get last focus off time
get_last_focus_off_time() {
    sqlite3 "$DB" "SELECT last_focus_off_time FROM $STATE_TABLE WHERE id = 1;" 2>/dev/null
}

# Function to get current prompt content
get_prompt_content() {
    sqlite3 "$DB" "SELECT prompt_content FROM $STATE_TABLE WHERE id = 1;" 2>/dev/null
}

# Function to get prompt content by type
get_prompt_content_by_type() {
    local prompt_type="$1"
    sqlite3 "$DB" "SELECT prompt_content FROM $STATE_TABLE WHERE prompt_type = '$prompt_type' AND id = 1;" 2>/dev/null
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
    
    # Update the state table with pause information
    sqlite3 "$DB" "UPDATE $STATE_TABLE SET 
        active = $active, 
        project = '$escaped_project', 
        start_time = '$start_time', 
        last_focus_off_time = '$last_focus_off_time',
        paused = ${paused:-0},
        pause_notes = '$escaped_pause_notes',
        pause_start_time = '$pause_start_time',
        previous_elapsed = ${previous_elapsed:-0}
        WHERE id = 1;"
}

# Function to update prompt content
update_prompt_content() {
    local prompt_content="$1"
    local prompt_type="$2"
    
    local escaped_prompt_content
    escaped_prompt_content=$(sql_escape "$prompt_content")
    sqlite3 "$DB" "UPDATE $STATE_TABLE SET prompt_content = '$escaped_prompt_content', prompt_type = '$prompt_type' WHERE id = 1;"
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
    sqlite3 "$DB" "INSERT INTO $SESSIONS_TABLE (project, start_time, end_time, duration_seconds, notes) VALUES ('$escaped_project', '$start_time', '$end_time', $duration, '$escaped_notes');"
}

# Function to update a session
update_session() {
    local project="$1"
    local start_time="$2"
    local end_time="$3"
    local duration="$4"
    
    local escaped_project
    escaped_project=$(sql_escape "$project")
    sqlite3 "$DB" "UPDATE $SESSIONS_TABLE SET start_time = '$start_time', end_time = '$end_time', duration_seconds = $duration WHERE project = '$escaped_project';"
}

# Function to delete sessions for a project
delete_sessions_for_project() {
    local project="$1"
    local escaped_project
    escaped_project=$(sql_escape "$project")
    sqlite3 "$DB" "DELETE FROM $SESSIONS_TABLE WHERE project = '$escaped_project';"
}

# Function to get session info for a project
get_session_info() {
    local project="$1"
    local escaped_project
    escaped_project=$(sql_escape "$project")
    sqlite3 "$DB" "SELECT start_time, end_time, duration_seconds FROM $SESSIONS_TABLE WHERE project = '$escaped_project';" 2>/dev/null
}

# Function to update focus disabled status
update_focus_disabled() {
    local disabled="$1"
    sqlite3 "$DB" "UPDATE $STATE_TABLE SET focus_disabled = $disabled WHERE id = 1;"
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
    
    sqlite3 "$DB" "UPDATE $STATE_TABLE SET active = $active, project = $escaped_project, start_time = '$start_time', prompt_content = $escaped_prompt_content, prompt_type = '$prompt_type', nudging_enabled = $nudging_enabled, focus_disabled = $focus_disabled WHERE id = 1;"
}

# Function to clear all sessions
clear_all_sessions() {
    sqlite3 "$DB" "DELETE FROM sessions;"
}

# Function to clear additional state records
clear_additional_state() {
    sqlite3 "$DB" "DELETE FROM state WHERE id > 1;"
}

# Project description functions
# Function to get project description
get_project_description() {
    local project="$1"
    local escaped_project
    escaped_project=$(sql_escape "$project")
    sqlite3 "$DB" "SELECT description FROM $PROJECTS_TABLE WHERE project = '$escaped_project';" 2>/dev/null
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
    sqlite3 "$DB" "INSERT OR REPLACE INTO $PROJECTS_TABLE (project, description, created_at, updated_at) VALUES ('$escaped_project', '$escaped_description', datetime('now'), datetime('now'));"
}

# Function to remove project description
remove_project_description() {
    local project="$1"
    local escaped_project
    escaped_project=$(sql_escape "$project")
    sqlite3 "$DB" "DELETE FROM $PROJECTS_TABLE WHERE project = '$escaped_project';"
}

# Function to get all projects with descriptions
get_projects_with_descriptions() {
    sqlite3 "$DB" "SELECT project, description FROM $PROJECTS_TABLE ORDER BY project;" 2>/dev/null
}

# Function to check if projects table exists
projects_table_exists() {
    sqlite3 "$DB" "SELECT name FROM sqlite_master WHERE type='table' AND name='$PROJECTS_TABLE';" 2>/dev/null
}

# Function to create projects table if it doesn't exist
ensure_projects_table() {
    if [[ -z "$(projects_table_exists)" ]]; then
        sqlite3 "$DB" "
            CREATE TABLE IF NOT EXISTS $PROJECTS_TABLE (
                project TEXT PRIMARY KEY,
                description TEXT NOT NULL,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL
            );
        "
    fi
}

# Function to migrate existing database to include projects table and notes column
migrate_database() {
    ensure_projects_table
    
    # Check if sessions table has notes column
    local has_notes_column
    has_notes_column=$(sqlite3 "$DB" "PRAGMA table_info($SESSIONS_TABLE);" 2>/dev/null | grep -c "notes" || echo "0")
    
    if [[ "$has_notes_column" -eq 0 ]]; then
        echo "Migrating database: adding notes column to sessions table..."
        sqlite3 "$DB" "ALTER TABLE $SESSIONS_TABLE ADD COLUMN notes TEXT;"
    fi
    
    # Check if state table has pause-related columns
    local has_pause_columns
    has_pause_columns=$(sqlite3 "$DB" "PRAGMA table_info($STATE_TABLE);" 2>/dev/null | grep -c -E "(paused|pause_notes|pause_start_time|previous_elapsed)" || echo "0")
    
    if [[ "$has_pause_columns" -lt 4 ]]; then
        echo "Migrating database: adding pause-related columns to state table..."
        
        # Add paused column
        local has_paused
        has_paused=$(sqlite3 "$DB" "PRAGMA table_info($STATE_TABLE);" 2>/dev/null | grep -c "paused" || echo "0")
        if [[ "$has_paused" -eq 0 ]]; then
            sqlite3 "$DB" "ALTER TABLE $STATE_TABLE ADD COLUMN paused INTEGER DEFAULT 0;"
        fi
        
        # Add pause_notes column
        local has_pause_notes
        has_pause_notes=$(sqlite3 "$DB" "PRAGMA table_info($STATE_TABLE);" 2>/dev/null | grep -c "pause_notes" || echo "0")
        if [[ "$has_pause_notes" -eq 0 ]]; then
            sqlite3 "$DB" "ALTER TABLE $STATE_TABLE ADD COLUMN pause_notes TEXT;"
        fi
        
        # Add pause_start_time column
        local has_pause_start_time
        has_pause_start_time=$(sqlite3 "$DB" "PRAGMA table_info($STATE_TABLE);" 2>/dev/null | grep -c "pause_start_time" || echo "0")
        if [[ "$has_pause_start_time" -eq 0 ]]; then
            sqlite3 "$DB" "ALTER TABLE $STATE_TABLE ADD COLUMN pause_start_time TEXT;"
        fi
        
        # Add previous_elapsed column
        local has_previous_elapsed
        has_previous_elapsed=$(sqlite3 "$DB" "PRAGMA table_info($STATE_TABLE);" 2>/dev/null | grep -c "previous_elapsed" || echo "0")
        if [[ "$has_previous_elapsed" -eq 0 ]]; then
            sqlite3 "$DB" "ALTER TABLE $STATE_TABLE ADD COLUMN previous_elapsed INTEGER DEFAULT 0;"
        fi
    fi
}

# Function to check if a session is currently paused
is_session_paused() {
    local paused
    paused=$(sqlite3 "$DB" "SELECT paused FROM $STATE_TABLE WHERE id = 1;" 2>/dev/null)
    [[ "$paused" -eq 1 ]]
}

# Function to get paused session information
get_paused_session_info() {
    sqlite3 "$DB" "SELECT project, pause_notes, pause_start_time, previous_elapsed FROM $STATE_TABLE WHERE id = 1;" 2>/dev/null
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
    sqlite3 "$DB" "UPDATE $STATE_TABLE SET 
        active = 0, 
        paused = 1,
        pause_notes = '$escaped_pause_notes',
        pause_start_time = '$current_time',
        previous_elapsed = $elapsed_seconds
        WHERE id = 1;"
    
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
    sqlite3 "$DB" "UPDATE $STATE_TABLE SET 
        active = 1, 
        project = '$escaped_project',
        start_time = '$new_start_time',
        paused = 0,
        pause_notes = '',
        pause_start_time = '',
        previous_elapsed = 0
        WHERE id = 1;"
    
    echo "$project|$new_start_time|$include_previous_elapsed"
}

# Function to update nudging enabled status
update_nudging_enabled() {
    local enabled="$1"
    sqlite3 "$DB" "UPDATE $STATE_TABLE SET nudging_enabled = $enabled WHERE id = 1;"
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