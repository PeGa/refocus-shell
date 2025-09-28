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
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DB_DEFAULT="$HOME/.local/refocus/refocus.db"
DB="${REFOCUS_DB:-$DB_DEFAULT}"

# Table names (defaults if not set by bootstrap)
SESSIONS_TABLE="${REFOCUS_SESSIONS_TABLE:-sessions}"
STATE_TABLE="${REFOCUS_STATE_TABLE:-state}"
PROJECTS_TABLE="${REFOCUS_PROJECTS_TABLE:-projects}"
PROMPT_TABLE="${REFOCUS_PROMPT_TABLE:-prompts}"

# Minimum disk space required (in MB)
MIN_DISK_SPACE_MB=10

# =============================================================================
# PRIVATE SQL EXECUTION HELPER
# =============================================================================

# Function: _db_exec
# Description: Execute SQL query with consistent flags (PRIVATE)
# Usage: _db_exec <sql_query>
# Parameters:
#   $1 - SQL query string
# Returns: Query results in CSV format
_db_exec() {
    sqlite3 -noheader -csv "$DB" "$1" 2>/dev/null
}

# =============================================================================
# PUBLIC DATABASE API (6-7 functions only)
# =============================================================================

# Function: db_init
# Description: Initialize database and ensure all tables exist
# Usage: db_init
# Returns: 0 on success, 1 on failure
db_init() {
    _ensure_database_directory
    _migrate_database
    return $?
}

# Function: db_start_session
# Description: Start a new focus session
# Usage: db_start_session <project> <description> <start_ts> [tags...]
# Parameters:
#   $1 - project: Project name
#   $2 - description: Session description (can be empty)
#   $3 - start_ts: Start timestamp in ISO format
#   $4+ - tags: Optional tags (not currently used)
# Returns: 0 on success, 1 on failure
db_start_session() {
    local project="$1"
    local description="$2"
    local start_ts="$3"
    shift 3
    local tags="$*"
    
    _pre_database_operation_check || return 1
    
    # Update focus state to active
    _update_focus_state 1 "$project" "$start_ts" 0 "" "" 0
    
    return 0
}

# Function: db_end_session
# Description: End the current focus session
# Usage: db_end_session <end_ts> <note>
# Parameters:
#   $1 - end_ts: End timestamp in ISO format
#   $2 - note: Session note (can be empty)
# Returns: 0 on success, 1 on failure
db_end_session() {
    local end_ts="$1"
    local note="$2"
    
    _pre_database_operation_check || return 1
    
    # Get current session info
    local state
    state=$(_get_focus_state)
    if [[ -z "$state" ]]; then
        echo "❌ No active session to end" >&2
        return 1
    fi
    
    IFS='|' read -r active project start_time paused pause_notes pause_start_time previous_elapsed <<< "$state"
    
    if [[ "$active" -ne 1 ]]; then
        echo "❌ No active session to end" >&2
        return 1
    fi
    
    # Calculate duration
    local duration_seconds
    duration_seconds=$(_calculate_duration "$start_time" "$end_ts")
    
    # Insert session record
    _insert_session "$project" "$start_time" "$end_ts" "$duration_seconds" "$note"
    
    # Update focus state to inactive
    _update_focus_state 0 "" "" 0 "" "" 0
    
    # Update last focus off time
    _update_state_record "last_focus_off_time" "$end_ts"
    
    return 0
}

# Function: db_pause
# Description: Pause the current focus session
# Usage: db_pause <now_ts> <reason>
# Parameters:
#   $1 - now_ts: Current timestamp in ISO format
#   $2 - reason: Pause reason (can be empty)
# Returns: 0 on success, 1 on failure
db_pause() {
    local now_ts="$1"
    local reason="$2"
    
    _pre_database_operation_check || return 1
    
    # Get current session info
    local state
    state=$(_get_focus_state)
    if [[ -z "$state" ]]; then
        echo "❌ No active session to pause" >&2
        return 1
    fi
    
    IFS='|' read -r active project start_time paused pause_notes pause_start_time previous_elapsed <<< "$state"
    
    if [[ "$active" -ne 1 ]]; then
        echo "❌ No active session to pause" >&2
        return 1
    fi
    
    if [[ "$paused" -eq 1 ]]; then
        echo "❌ Session is already paused" >&2
        return 1
    fi
    
    # Calculate elapsed time so far
    local elapsed
    elapsed=$(_calculate_duration "$start_time" "$now_ts")
    
    # Update focus state to paused
    _update_focus_state 1 "$project" "$start_time" 1 "$reason" "$now_ts" "$elapsed"
    
    return 0
}

# Function: db_resume
# Description: Resume a paused focus session
# Usage: db_resume <now_ts>
# Parameters:
#   $1 - now_ts: Current timestamp in ISO format
# Returns: 0 on success, 1 on failure
db_resume() {
    local now_ts="$1"
    
    _pre_database_operation_check || return 1
    
    # Get current session info
    local state
    state=$(_get_focus_state)
    if [[ -z "$state" ]]; then
        echo "❌ No session to resume" >&2
        return 1
    fi
    
    IFS='|' read -r active project start_time paused pause_notes pause_start_time previous_elapsed <<< "$state"
    
    if [[ "$paused" -ne 1 ]]; then
        echo "❌ No paused session to resume" >&2
        return 1
    fi
    
    # Calculate new start time accounting for previous elapsed time
    local new_start_time
    new_start_time=$(date -d "$now_ts - $previous_elapsed seconds" +%Y-%m-%dT%H:%M:%S)
    
    # Update focus state to active (unpaused)
    _update_focus_state 1 "$project" "$new_start_time" 0 "" "" 0
    
    return 0
}

# Function: db_get_active
# Description: Get the currently active session
# Usage: db_get_active
# Returns: CSV row with session info or empty if no active session
# Format: active|project|start_time|paused|pause_notes|pause_start_time|previous_elapsed
db_get_active() {
    _get_focus_state
}

# Function: db_list
# Description: List sessions in a date range
# Usage: db_list <range_spec>
# Parameters:
#   $1 - range_spec: Date range specification (e.g., "today", "yesterday", "7d", "2025-01-01,2025-01-31")
# Returns: CSV rows with session data
# Format: id|project|start_time|end_time|duration_seconds|notes
db_list() {
    local range_spec="$1"
    
    if [[ -z "$range_spec" ]]; then
        range_spec="today"
    fi
    
    _get_sessions_in_range "$range_spec"
}

# Function: db_stats
# Description: Get aggregated statistics for a date range
# Usage: db_stats [--detailed] <range_spec>
# Parameters:
#   $1 - Optional --detailed flag for detailed output
#   $2 - range_spec: Date range specification
# Returns: CSV with statistics
# Format: total_sessions|total_duration|avg_duration|projects_count
#         (or detailed format if --detailed flag is used)
db_stats() {
    local detailed=false
    local range_spec
    
    # Check for --detailed flag
    if [[ "$1" == "--detailed" ]]; then
        detailed=true
        range_spec="$2"
    else
        range_spec="$1"
    fi
    
    if [[ -z "$range_spec" ]]; then
        range_spec="today"
    fi
    
    if [[ "$detailed" == true ]]; then
        _db_stats_detailed "$range_spec"
    else
        _get_session_stats "$range_spec"
    fi
}

# Function: _db_stats_detailed
# Description: Get detailed statistics including project breakdowns for a date range (PRIVATE)
# Usage: _db_stats_detailed <range_spec>
# Parameters:
#   $1 - range_spec: Date range specification
# Returns: Multiple CSV sections:
#   - Summary: total_sessions|total_duration|avg_duration|projects_count
#   - Project breakdown: project|sessions|duration|earliest_start|latest_end
#   - Session details: project|start_time|end_time|duration_seconds|notes|duration_only|session_date
_db_stats_detailed() {
    local range_spec="$1"
    
    if [[ -z "$range_spec" ]]; then
        range_spec="today"
    fi
    
    # Get basic stats
    local basic_stats
    basic_stats=$(_get_session_stats "$range_spec")
    
    # Get detailed project breakdown
    local project_stats
    project_stats=$(_get_project_stats "$range_spec")
    
    # Get session details
    local session_details
    session_details=$(_get_sessions_in_range_detailed "$range_spec")
    
    # Output all sections
    echo "SUMMARY:$basic_stats"
    echo "PROJECTS:$project_stats"
    echo "SESSIONS:$session_details"
}

# =============================================================================
# PRIVATE HELPER FUNCTIONS (all functions below are internal)
# =============================================================================

# Function to safely escape SQL strings
_sql_escape() {
    local input="$1"
    # Replace single quotes with double single quotes (SQL escaping)
    echo "$input" | sed "s/'/''/g"
}

# Function to check available disk space
_check_disk_space() {
    local db_dir
    db_dir=$(dirname "$DB")
    
    # Ensure directory exists
    if [[ ! -d "$db_dir" ]]; then
        echo "❌ Database directory does not exist: $db_dir" >&2
        return 1
    fi
    
    # Get available space in MB
    local available_mb
    if command -v df >/dev/null 2>&1; then
        available_mb=$(df "$db_dir" | awk 'NR==2 {print int($4/1024)}')
    else
        # Fallback if df is not available
        available_mb=1000
    fi
    
    if [[ "$available_mb" -lt "$MIN_DISK_SPACE_MB" ]]; then
        echo "❌ Insufficient disk space: ${available_mb}MB available, ${MIN_DISK_SPACE_MB}MB required" >&2
        return 1
    fi
    
    return 0
}

# Function to check database permissions
_check_database_permissions() {
    local db_dir
    db_dir=$(dirname "$DB")
    
    # Check if we can write to the database directory
    if [[ ! -w "$db_dir" ]]; then
        echo "❌ No write permission to database directory: $db_dir" >&2
        return 1
    fi
    
    # Check if database file exists and is writable
    if [[ -f "$DB" ]] && [[ ! -w "$DB" ]]; then
        echo "❌ No write permission to database file: $DB" >&2
        return 1
    fi
    
    return 0
}

# Function to check database integrity
_check_database_integrity() {
    if [[ ! -f "$DB" ]]; then
        return 0  # Database doesn't exist yet, that's fine
    fi
    
    # Check if database is readable
    if ! sqlite3 "$DB" "SELECT 1;" >/dev/null 2>&1; then
        echo "❌ Database file is corrupted or unreadable: $DB" >&2
        return 1
    fi
    
    return 0
}

# Function to perform pre-database operation checks
_pre_database_operation_check() {
    _check_disk_space || return 1
    _check_database_permissions || return 1
    _check_database_integrity || return 1
    return 0
}

# Function to create database backup
_create_database_backup() {
    if [[ ! -f "$DB" ]]; then
        return 0  # No database to backup
    fi
    
    local backup_file
    backup_file="${DB}.backup.$(date +%Y%m%d_%H%M%S)"
    
    if cp "$DB" "$backup_file" 2>/dev/null; then
        echo "📋 Created database backup: $backup_file"
        return 0
    else
        echo "❌ Failed to create database backup" >&2
        return 1
    fi
}

# Function to attempt database recovery
_attempt_database_recovery() {
    echo "🔄 Attempting database recovery..." >&2
    
    # Create backup of corrupted database
    _create_database_backup
    
    # Try to recover data using .dump
    local dump_file
    dump_file="${DB}.recovery.$(date +%Y%m%d_%H%M%S).sql"
    
    if sqlite3 "$DB" ".dump" > "$dump_file" 2>/dev/null; then
        echo "📋 Created recovery dump: $dump_file" >&2
        echo "   You can manually inspect and restore data from this file" >&2
    fi
    
    # Remove corrupted database
    rm -f "$DB"
    
    echo "🗑️  Removed corrupted database" >&2
    echo "   Run 'focus init' to recreate the database" >&2
    
    return 1
}

# Function to get last project
_get_last_project() {
    _db_exec "SELECT project FROM $SESSIONS_TABLE WHERE project != '[idle]' ORDER BY rowid DESC LIMIT 1;"
}

# Function to get last session
_get_last_session() {
    _db_exec "SELECT project, start_time, end_time, duration_seconds, notes FROM $SESSIONS_TABLE ORDER BY rowid DESC LIMIT 1;"
}

# Function to get total project time
_get_total_project_time() {
    local project="$1"
    local escaped_project
    escaped_project=$(_sql_escape "$project")
    
    _db_exec "SELECT COALESCE(SUM(duration_seconds), 0) FROM $SESSIONS_TABLE WHERE project = '$escaped_project' AND project != '[idle]';"
}

# Function to count sessions for project
_count_sessions_for_project() {
    local project="$1"
    local escaped_project
    escaped_project=$(_sql_escape "$project")
    
    _db_exec "SELECT COUNT(*) FROM $SESSIONS_TABLE WHERE project = '$escaped_project' AND project != '[idle]';"
}

# Function to get sessions in range
_get_sessions_in_range() {
    local range_spec="$1"
    local start_date end_date
    
    # Parse range specification
    case "$range_spec" in
        "today")
            start_date=$(date +%Y-%m-%d)
            end_date="$start_date"
            ;;
        "yesterday")
            start_date=$(date -d "yesterday" +%Y-%m-%d)
            end_date="$start_date"
            ;;
        "7d"|"week")
            start_date=$(date -d "7 days ago" +%Y-%m-%d)
            end_date=$(date +%Y-%m-%d)
            ;;
        "30d"|"month")
            start_date=$(date -d "30 days ago" +%Y-%m-%d)
            end_date=$(date +%Y-%m-%d)
            ;;
        *)
            # Assume it's a date range like "2025-01-01,2025-01-31"
            if [[ "$range_spec" == *","* ]]; then
                start_date="${range_spec%%,*}"
                end_date="${range_spec##*,}"
            else
                start_date="$range_spec"
                end_date="$range_spec"
            fi
            ;;
    esac
    
    _db_exec "SELECT rowid, project, start_time, end_time, duration_seconds, notes FROM $SESSIONS_TABLE WHERE DATE(start_time) >= '$start_date' AND DATE(start_time) <= '$end_date' ORDER BY start_time DESC;"
}

# Function to get all state data in one query
_get_all_state_data() {
    _db_exec "SELECT active, current_project, start_time, paused, pause_notes, pause_start_time, previous_elapsed, focus_disabled, nudging_enabled, last_focus_off_time FROM $STATE_TABLE LIMIT 1;"
}

# Function to get focus state
_get_focus_state() {
    local state_data
    state_data=$(_get_all_state_data)
    if [[ -n "$state_data" ]]; then
        echo "$state_data" | cut -d',' -f1-7
    fi
}

# Function to get focus disabled status
_get_focus_disabled() {
    local state_data
    state_data=$(_get_all_state_data)
    if [[ -n "$state_data" ]]; then
        echo "$state_data" | cut -d',' -f8
    fi
}

# Function to get nudging enabled status
_get_nudging_enabled() {
    local state_data
    state_data=$(_get_all_state_data)
    if [[ -n "$state_data" ]]; then
        echo "$state_data" | cut -d',' -f9
    fi
}

# Function to get last focus off time
_get_last_focus_off_time() {
    local state_data
    state_data=$(_get_all_state_data)
    if [[ -n "$state_data" ]]; then
        echo "$state_data" | cut -d',' -f10
    fi
}

# Function to get prompt content
_get_prompt_content() {
    _db_exec "SELECT content FROM $PROMPT_TABLE ORDER BY rowid DESC LIMIT 1;"
}

# Function to get prompt content by type
_get_prompt_content_by_type() {
    local type="$1"
    _db_exec "SELECT content FROM $PROMPT_TABLE WHERE type = '$type' ORDER BY rowid DESC LIMIT 1;"
}

# Function to update focus state
_update_focus_state() {
    local active="$1"
    local current_project="$2"
    local start_time="$3"
    local paused="$4"
    local pause_notes="$5"
    local pause_start_time="$6"
    local previous_elapsed="$7"
    
    local escaped_project
    escaped_project=$(_sql_escape "$current_project")
    
    local escaped_pause_notes
    escaped_pause_notes=$(_sql_escape "$pause_notes")
    
    _db_exec "UPDATE $STATE_TABLE SET active = $active, current_project = '$escaped_project', start_time = '$start_time', paused = $paused, pause_notes = '$escaped_pause_notes', pause_start_time = '$pause_start_time', previous_elapsed = $previous_elapsed;"
}

# Function to update prompt content
_update_prompt_content() {
    local content="$1"
    local type="${2:-default}"
    
    local escaped_content
    escaped_content=$(_sql_escape "$content")
    
    _db_exec "INSERT OR REPLACE INTO $PROMPT_TABLE (type, content) VALUES ('$type', '$escaped_content');"
}

# Function to insert session
_insert_session() {
    local project="$1"
    local start_time="$2"
    local end_time="$3"
    local duration_seconds="$4"
    local notes="$5"
    
    local escaped_project
    escaped_project=$(_sql_escape "$project")
    
    local escaped_notes
    escaped_notes=$(_sql_escape "$notes")
    
    _db_exec "INSERT INTO $SESSIONS_TABLE (project, start_time, end_time, duration_seconds, notes) VALUES ('$escaped_project', '$start_time', '$end_time', $duration_seconds, '$escaped_notes');"
}

# Function to insert duration-only session
_insert_duration_only_session() {
    local project="$1"
    local duration_seconds="$2"
    local session_date="$3"
    local notes="$4"
    
    local escaped_project
    escaped_project=$(_sql_escape "$project")
    
    local escaped_notes
    escaped_notes=$(_sql_escape "$notes")
    
    _db_exec "INSERT INTO $SESSIONS_TABLE (project, start_time, end_time, duration_seconds, notes, duration_only, session_date) VALUES ('$escaped_project', '', '', $duration_seconds, '$escaped_notes', 1, '$session_date');"
}

# Function to update session
_update_session() {
    local session_id="$1"
    local project="$2"
    local start_time="$3"
    local end_time="$4"
    local duration_seconds="$5"
    local notes="$6"
    
    local escaped_project
    escaped_project=$(_sql_escape "$project")
    
    local escaped_notes
    escaped_notes=$(_sql_escape "$notes")
    
    _db_exec "UPDATE $SESSIONS_TABLE SET project = '$escaped_project', start_time = '$start_time', end_time = '$end_time', duration_seconds = $duration_seconds, notes = '$escaped_notes' WHERE rowid = $session_id;"
}

# Function to delete sessions for project
_delete_sessions_for_project() {
    local project="$1"
    local escaped_project
    escaped_project=$(_sql_escape "$project")
    
    _db_exec "DELETE FROM $SESSIONS_TABLE WHERE project = '$escaped_project';"
}

# Function to get session info
_get_session_info() {
    local session_id="$1"
    _db_exec "SELECT project, start_time, end_time, duration_seconds, notes FROM $SESSIONS_TABLE WHERE rowid = $session_id;"
}

# Function to update focus disabled status
_update_focus_disabled() {
    local disabled="$1"
    _db_exec "UPDATE $STATE_TABLE SET focus_disabled = $disabled;"
}

# Function to update nudging enabled status
_update_nudging_enabled() {
    local enabled="$1"
    _db_exec "UPDATE $STATE_TABLE SET nudging_enabled = $enabled;"
}

# Function to install focus cron job
_install_focus_cron_job() {
    local script_path="$1"
    local interval="${2:-5}"
    
    # Remove existing cron job
    _remove_focus_cron_job
    
    # Add new cron job
    (crontab -l 2>/dev/null; echo "*/$interval * * * * $script_path") | crontab -
}

# Function to remove focus cron job
_remove_focus_cron_job() {
    crontab -l 2>/dev/null | grep -v "focus-nudge" | crontab -
}

# Function to update state record
_update_state_record() {
    local key="$1"
    local value="$2"
    
    local escaped_value
    escaped_value=$(_sql_escape "$value")
    
    _db_exec "UPDATE $STATE_TABLE SET $key = '$escaped_value';"
}

# Function to clear all sessions
_clear_all_sessions() {
    _db_exec "DELETE FROM $SESSIONS_TABLE;"
}

# Function to clear additional state
_clear_additional_state() {
    _db_exec "DELETE FROM $PROMPT_TABLE;"
    _db_exec "DELETE FROM $PROJECTS_TABLE;"
}

# Function to get project description
_get_project_description() {
    local project="$1"
    local escaped_project
    escaped_project=$(_sql_escape "$project")
    
    _db_exec "SELECT description FROM $PROJECTS_TABLE WHERE project = '$escaped_project';"
}

# Function to set project description
_set_project_description() {
    local project="$1"
    local description="$2"
    
    local escaped_project
    escaped_project=$(_sql_escape "$project")
    
    local escaped_description
    escaped_description=$(_sql_escape "$description")
    
    local now
    now=$(date -Iseconds)
    
    _db_exec "INSERT OR REPLACE INTO $PROJECTS_TABLE (project, description, created_at, updated_at) VALUES ('$escaped_project', '$escaped_description', '$now', '$now');"
}

# Function to remove project description
_remove_project_description() {
    local project="$1"
    local escaped_project
    escaped_project=$(_sql_escape "$project")
    
    _db_exec "DELETE FROM $PROJECTS_TABLE WHERE project = '$escaped_project';"
}

# Function to get projects with descriptions
_get_projects_with_descriptions() {
    _db_exec "SELECT project, description FROM $PROJECTS_TABLE ORDER BY project;"
}

# Function to check if projects table exists
_projects_table_exists() {
    _db_exec "SELECT name FROM sqlite_master WHERE type='table' AND name='$PROJECTS_TABLE';"
}

# Function to ensure projects table exists
_ensure_projects_table() {
    if [[ -z "$(_projects_table_exists)" ]]; then
        sqlite3 "$DB" "CREATE TABLE $PROJECTS_TABLE (
            project TEXT PRIMARY KEY,
            description TEXT,
            created_at TEXT,
            updated_at TEXT
        );" 2>/dev/null
    fi
}

# Function to calculate duration between timestamps
_calculate_duration() {
    local start_time="$1"
    local end_time="$2"
    
    local start_ts
    start_ts=$(date -d "$start_time" +%s 2>/dev/null)
    
    local end_ts
    end_ts=$(date -d "$end_time" +%s 2>/dev/null)
    
    if [[ -n "$start_ts" ]] && [[ -n "$end_ts" ]]; then
        echo $((end_ts - start_ts))
    else
        echo 0
    fi
}

# Function to get session statistics
_get_session_stats() {
    local range_spec="$1"
    local sessions
    sessions=$(_get_sessions_in_range "$range_spec")
    
    if [[ -z "$sessions" ]]; then
        echo "0|0|0|0"
        return
    fi
    
    local total_sessions=0
    local total_duration=0
    local projects=()
    
    while IFS='|' read -r id project start_time end_time duration_seconds notes; do
        ((total_sessions++))
        ((total_duration += duration_seconds))
        
        # Track unique projects
        if [[ -n "$project" ]] && [[ "$project" != "[idle]" ]]; then
            local found=false
            for p in "${projects[@]}"; do
                if [[ "$p" == "$project" ]]; then
                    found=true
                    break
                fi
            done
            if [[ "$found" == false ]]; then
                projects+=("$project")
            fi
        fi
    done <<< "$sessions"
    
    local avg_duration=0
    if [[ $total_sessions -gt 0 ]]; then
        avg_duration=$((total_duration / total_sessions))
    fi
    
    echo "$total_sessions|$total_duration|$avg_duration|${#projects[@]}"
}

# Function to get project statistics
_get_project_stats() {
    local range_spec="$1"
    local sessions
    sessions=$(_get_sessions_in_range_detailed "$range_spec")
    
    if [[ -z "$sessions" ]]; then
        return
    fi
    
    # Track project statistics
    declare -A project_sessions
    declare -A project_durations
    declare -A project_earliest
    declare -A project_latest
    
    while IFS='|' read -r project start_time end_time duration_seconds notes duration_only session_date; do
        if [[ -n "$project" ]] && [[ "$project" != "[idle]" ]]; then
            # Initialize if not exists
            if [[ -z "${project_sessions[$project]}" ]]; then
                project_sessions[$project]=0
                project_durations[$project]=0
                project_earliest[$project]=""
                project_latest[$project]=""
            fi
            
            # Update counts
            project_sessions[$project]=$((${project_sessions[$project]} + 1))
            project_durations[$project]=$((${project_durations[$project]} + duration_seconds))
            
            # Update date ranges
            if [[ "$duration_only" == "1" ]]; then
                # Duration-only session
                if [[ -z "${project_earliest[$project]}" ]] || [[ "$session_date" < "${project_earliest[$project]}" ]]; then
                    project_earliest[$project]="$session_date"
                fi
                if [[ -z "${project_latest[$project]}" ]] || [[ "$session_date" > "${project_latest[$project]}" ]]; then
                    project_latest[$project]="$session_date"
                fi
            else
                # Regular session
                if [[ -z "${project_earliest[$project]}" ]] || [[ "$start_time" < "${project_earliest[$project]}" ]]; then
                    project_earliest[$project]="$start_time"
                fi
                if [[ -z "${project_latest[$project]}" ]] || [[ "$end_time" > "${project_latest[$project]}" ]]; then
                    project_latest[$project]="$end_time"
                fi
            fi
        fi
    done <<< "$sessions"
    
    # Output project statistics
    for project in "${!project_sessions[@]}"; do
        echo "$project|${project_sessions[$project]}|${project_durations[$project]}|${project_earliest[$project]}|${project_latest[$project]}"
    done
}

# Function to get sessions in range with detailed information
_get_sessions_in_range_detailed() {
    local range_spec="$1"
    local start_date end_date
    
    # Parse range specification
    case "$range_spec" in
        "today")
            start_date=$(date +%Y-%m-%d)
            end_date="$start_date"
            ;;
        "yesterday")
            start_date=$(date -d "yesterday" +%Y-%m-%d)
            end_date="$start_date"
            ;;
        "7d"|"week")
            start_date=$(date -d "7 days ago" +%Y-%m-%d)
            end_date=$(date +%Y-%m-%d)
            ;;
        "30d"|"month")
            start_date=$(date -d "30 days ago" +%Y-%m-%d)
            end_date=$(date +%Y-%m-%d)
            ;;
        *)
            # Assume it's a date range like "2025-01-01,2025-01-31"
            if [[ "$range_spec" == *","* ]]; then
                start_date="${range_spec%%,*}"
                end_date="${range_spec##*,}"
            else
                start_date="$range_spec"
                end_date="$range_spec"
            fi
            ;;
    esac
    
    # Get sessions including duration-only sessions
    _db_exec "SELECT project, start_time, end_time, duration_seconds, notes, duration_only, session_date FROM $SESSIONS_TABLE WHERE project != '[idle]' AND ((end_time >= '$start_date' AND end_time <= '$end_date') OR (duration_only = 1 AND session_date >= '$start_date' AND session_date <= '$end_date')) ORDER BY COALESCE(end_time, session_date) DESC;"
}

# Function to ensure database directory exists
_ensure_database_directory() {
    local db_dir
    db_dir=$(dirname "$DB")
    
    if [[ ! -d "$db_dir" ]]; then
        mkdir -p "$db_dir" || {
            echo "❌ Failed to create database directory: $db_dir" >&2
            return 1
        }
    fi
    
    return 0
}

# Function to ensure indices exist
_ensure_indices() {
    # Check and create indices if they don't exist
    local indices=(
        "idx_sessions_project:$SESSIONS_TABLE(project)"
        "idx_sessions_start_time:$SESSIONS_TABLE(start_time)"
        "idx_sessions_end_time:$SESSIONS_TABLE(end_time)"
        "idx_sessions_session_date:$SESSIONS_TABLE(session_date)"
        "idx_sessions_duration_only:$SESSIONS_TABLE(duration_only)"
    )
    
    for index_spec in "${indices[@]}"; do
        local index_name="${index_spec%%:*}"
        local index_def="${index_spec##*:}"
        
        # Check if index exists
        local exists
        exists=$(_db_exec "SELECT name FROM sqlite_master WHERE type='index' AND name='$index_name';")
        
        if [[ -z "$exists" ]]; then
            _db_exec "CREATE INDEX $index_name ON $index_def;"
        fi
    done
}

# Function to migrate database
_migrate_database() {
    # Check if database exists
    if [[ ! -f "$DB" ]]; then
        # Create new database
        sqlite3 "$DB" "
            CREATE TABLE $SESSIONS_TABLE (
                project TEXT,
                start_time TEXT,
                end_time TEXT,
                duration_seconds INTEGER,
                notes TEXT,
                duration_only INTEGER DEFAULT 0,
                session_date TEXT
            );
            
            CREATE TABLE $STATE_TABLE (
                active INTEGER DEFAULT 0,
                current_project TEXT,
                start_time TEXT,
                paused INTEGER DEFAULT 0,
                pause_notes TEXT,
                pause_start_time TEXT,
                previous_elapsed INTEGER DEFAULT 0,
                focus_disabled INTEGER DEFAULT 0,
                nudging_enabled INTEGER DEFAULT 1,
                last_focus_off_time TEXT
            );
            
            CREATE TABLE $PROMPT_TABLE (
                type TEXT,
                content TEXT
            );
            
            -- Add indices for frequently queried columns
            CREATE INDEX idx_sessions_project ON $SESSIONS_TABLE(project);
            CREATE INDEX idx_sessions_start_time ON $SESSIONS_TABLE(start_time);
            CREATE INDEX idx_sessions_end_time ON $SESSIONS_TABLE(end_time);
            CREATE INDEX idx_sessions_session_date ON $SESSIONS_TABLE(session_date);
            CREATE INDEX idx_sessions_duration_only ON $SESSIONS_TABLE(duration_only);
            
            INSERT INTO $STATE_TABLE DEFAULT VALUES;
        " 2>/dev/null
        
        if [[ $? -ne 0 ]]; then
            echo "❌ Failed to create database" >&2
            return 1
        fi
    fi
    
    # Ensure projects table exists
    _ensure_projects_table
    
    # Ensure indices exist (for existing databases)
    _ensure_indices
    
    return 0
}

# Additional private API functions (internal use only)
_get_focus_disabled_public() {
    _get_focus_disabled
}

_update_prompt_content_public() {
    _update_prompt_content "$@"
}

# =============================================================================
# PUBLIC FAÇADE FUNCTIONS (for diagnose/import commands)
# =============================================================================

# Function: _is_focus_active
# Description: Check if there's an active focus session (PRIVATE)
# Usage: _is_focus_active
# Returns: 0 if active, 1 if not active
_is_focus_active() {
    local state
    state=$(_get_focus_state)
    if [[ -z "$state" ]]; then
        return 1
    fi
    
    IFS='|' read -r active project start_time paused pause_notes pause_start_time previous_elapsed <<< "$state"
    if [[ "$active" -eq 1 ]]; then
        return 0
    else
        return 1
    fi
}

# Function: _check_disk_space_public
# Description: Check if there's sufficient disk space (PRIVATE)
# Usage: _check_disk_space_public
# Returns: 0 if sufficient, 1 if insufficient
_check_disk_space_public() {
    _check_disk_space
}

# Function: _check_database_permissions_public
# Description: Check database file and directory permissions (PRIVATE)
# Usage: _check_database_permissions_public
# Returns: 0 if permissions are correct, 1 if not
_check_database_permissions_public() {
    _check_database_permissions
}

# Function: _check_database_integrity_public
# Description: Check database integrity (PRIVATE)
# Usage: _check_database_integrity_public
# Returns: 0 if integrity is good, 1 if not
_check_database_integrity_public() {
    _check_database_integrity
}

# Function: _create_database_backup_public
# Description: Create a database backup (PRIVATE)
# Usage: _create_database_backup_public
# Returns: 0 on success, 1 on failure
_create_database_backup_public() {
    _create_database_backup
}

# Function: _attempt_database_recovery_public
# Description: Attempt to recover a corrupted database (PRIVATE)
# Usage: _attempt_database_recovery_public
# Returns: 0 on success, 1 on failure
_attempt_database_recovery_public() {
    _attempt_database_recovery
}

# Function: _sql_escape_public
# Description: Escape SQL strings safely (PRIVATE)
# Usage: _sql_escape_public <string>
# Returns: escaped string
_sql_escape_public() {
    _sql_escape "$1"
}

# Function: _is_focus_disabled_public
# Description: Check if focus is disabled (PRIVATE)
# Usage: _is_focus_disabled_public
# Returns: 0 if disabled, 1 if enabled
_is_focus_disabled_public() {
    local disabled
    disabled=$(_get_focus_disabled)
    if [[ "$disabled" -eq 1 ]]; then
        return 0
    else
        return 1
    fi
}

# Function: _get_nudging_enabled_public
# Description: Get nudging enabled status (PRIVATE)
# Usage: _get_nudging_enabled_public
# Returns: 1 if enabled, 0 if disabled
_get_nudging_enabled_public() {
    _get_nudging_enabled
}

# Function: db_get_state
# Description: Get the current focus state as CSV
# Usage: db_get_state
# Returns: CSV row with state info
# Format: active|project|start_time|paused|pause_notes|pause_start_time|previous_elapsed
db_get_state() {
    _get_focus_state
}

# Export only the public DB API functions
export -f db_init db_start_session db_end_session db_pause db_resume db_get_active db_get_state db_list db_stats