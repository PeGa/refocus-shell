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
# PRIVATE SQL EXECUTION HELPERS
# =============================================================================

# Private SQL helpers
_db_q() { sqlite3 -noheader -csv "$DB" "$1" 2>/dev/null; }
_db_exec() { sqlite3 -noheader -csv "$DB" "$1" 2>/dev/null; }
_db_query_sessions() {
    local columns="$1" where="$2" order="$3" limit="$4"
    local sql="SELECT $columns FROM $SESSIONS_TABLE"
    [[ -n "$where" ]] && sql="$sql WHERE $where"
    [[ -n "$order" ]] && sql="$sql ORDER BY $order"
    [[ -n "$limit" ]] && sql="$sql LIMIT $limit"
    _db_q "$sql;"
}

# =============================================================================
# PUBLIC DATABASE API (6-7 functions only)
# =============================================================================

db_init() { _ensure_database_directory; _migrate_database; }
db_start_session() {
    local project="$1" description="$2" start_ts="$3"
    _pre_database_operation_check || return 1
    _update_focus_state 1 "$project" "$start_ts" 0 "" "" 0
}
db_end_session() {
    local end_ts="$1" note="$2"
    _pre_database_operation_check || return 1
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
    local duration_seconds start_ts end_ts_parsed
    start_ts=$(date -d "$start_time" +%s 2>/dev/null)
    end_ts_parsed=$(date -d "$end_ts" +%s 2>/dev/null)
    if [[ -n "$start_ts" ]] && [[ -n "$end_ts_parsed" ]]; then
        duration_seconds=$((end_ts_parsed - start_ts))
    else
        duration_seconds=0
    fi
    _insert_session "$project" "$start_time" "$end_ts" "$duration_seconds" "$note"
    _update_focus_state 0 "" "" 0 "" "" 0
    _update_state_record "last_focus_off_time" "$end_ts"
}

db_pause() {
    local now_ts="$1" reason="$2"
    _pre_database_operation_check || return 1
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
    local elapsed start_ts now_ts_parsed
    start_ts=$(date -d "$start_time" +%s 2>/dev/null)
    now_ts_parsed=$(date -d "$now_ts" +%s 2>/dev/null)
    if [[ -n "$start_ts" ]] && [[ -n "$now_ts_parsed" ]]; then
        elapsed=$((now_ts_parsed - start_ts))
    else
        elapsed=0
    fi
    _update_focus_state 1 "$project" "$start_time" 1 "$reason" "$now_ts" "$elapsed"
}
db_resume() {
    local now_ts="$1"
    _pre_database_operation_check || return 1
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
    local new_start_time
    new_start_time=$(date -d "$now_ts - $previous_elapsed seconds" +%Y-%m-%dT%H:%M:%S)
    _update_focus_state 1 "$project" "$new_start_time" 0 "" "" 0
}
db_get_active() { _get_focus_state; }
db_list() {
    local range_spec="${1:-today}"
    _get_sessions_in_range "$range_spec"
}
db_stats() {
    local detailed=false range_spec
    if [[ "$1" == "--detailed" ]]; then
        detailed=true
        range_spec="$2"
    else
        range_spec="$1"
    fi
    range_spec="${range_spec:-today}"
    if [[ "$detailed" == true ]]; then
        _db_stats_detailed "$range_spec"
    else
        _get_session_stats "$range_spec"
    fi
}

_db_stats_detailed() {
    local range_spec="${1:-today}" start_date end_date
    case "$range_spec" in
        "today") start_date=$(date +%Y-%m-%d); end_date="$start_date" ;;
        "yesterday") start_date=$(date -d "yesterday" +%Y-%m-%d); end_date="$start_date" ;;
        "7d"|"week") start_date=$(date -d "7 days ago" +%Y-%m-%d); end_date=$(date +%Y-%m-%d) ;;
        "30d"|"month") start_date=$(date -d "30 days ago" +%Y-%m-%d); end_date=$(date +%Y-%m-%d) ;;
        *) if [[ "$range_spec" == *","* ]]; then
               start_date="${range_spec%%,*}"; end_date="${range_spec##*,}"
           else
               start_date="$range_spec"; end_date="$range_spec"
           fi ;;
    esac
    local results
    results=$(_db_q "
        WITH R AS (SELECT project, duration_seconds FROM $SESSIONS_TABLE WHERE DATE(start_time) >= '$start_date' AND DATE(start_time) <= '$end_date')
        SELECT COUNT(*), IFNULL(SUM(duration_seconds), 0), IFNULL(SUM(duration_seconds) / COUNT(*), 0), COUNT(DISTINCT CASE WHEN project != '[idle]' THEN project END) FROM R
        UNION ALL
        SELECT project, COUNT(*), SUM(duration_seconds), MIN(start_time), MAX(end_time) FROM $SESSIONS_TABLE WHERE project != '[idle]' AND DATE(start_time) >= '$start_date' AND DATE(start_time) <= '$end_date' GROUP BY project
        UNION ALL
        SELECT project, start_time, end_time, duration_seconds, notes, duration_only, session_date FROM $SESSIONS_TABLE WHERE project != '[idle]' AND ((end_time >= '$start_date' AND end_time <= '$end_date') OR (duration_only = 1 AND session_date >= '$start_date' AND session_date <= '$end_date')) ORDER BY COALESCE(end_time, session_date) DESC;
    ")
    local summary_line project_lines session_lines
    summary_line=$(echo "$results" | head -n1)
    project_lines=$(echo "$results" | sed -n '2,$p' | grep -v '^[0-9]*,[0-9]*,[0-9]*,[0-9]*$' | head -n -1)
    session_lines=$(echo "$results" | tail -n +2 | grep -v '^[0-9]*,[0-9]*,[0-9]*,[0-9]*$' | tail -n +$(($(echo "$project_lines" | wc -l) + 1)))
    echo "SUMMARY:$summary_line"
    echo "PROJECTS:$project_lines"
    echo "SESSIONS:$session_lines"
}

# Private helper functions
_sql_escape() { echo "$1" | sed "s/'/''/g"; }

_check_disk_space() {
    local db_dir=$(dirname "$DB")
    [[ ! -d "$db_dir" ]] && { echo "❌ Database directory does not exist: $db_dir" >&2; return 1; }
    local available_mb
    if command -v df >/dev/null 2>&1; then
        available_mb=$(df "$db_dir" | awk 'NR==2 {print int($4/1024)}')
    else
        available_mb=1000
    fi
    if [[ "$available_mb" -lt "$MIN_DISK_SPACE_MB" ]]; then
        echo "❌ Insufficient disk space: ${available_mb}MB available, ${MIN_DISK_SPACE_MB}MB required" >&2
        return 1
    fi
}
_check_database_permissions() {
    local db_dir=$(dirname "$DB")
    [[ ! -w "$db_dir" ]] && { echo "❌ No write permission to database directory: $db_dir" >&2; return 1; }
    [[ -f "$DB" && ! -w "$DB" ]] && { echo "❌ No write permission to database file: $DB" >&2; return 1; }
}
_check_database_integrity() {
    [[ ! -f "$DB" ]] && return 0
    sqlite3 "$DB" "SELECT 1;" >/dev/null 2>&1 || { echo "❌ Database file is corrupted or unreadable: $DB" >&2; return 1; }
}
_pre_database_operation_check() {
    _check_disk_space && _check_database_permissions && _check_database_integrity
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
    
    _db_query_sessions "rowid, project, start_time, end_time, duration_seconds, notes" "DATE(start_time) >= '$start_date' AND DATE(start_time) <= '$end_date'" "start_time DESC"
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


# Function to update state record
_update_state_record() {
    local key="$1"
    local value="$2"
    
    local escaped_value
    escaped_value=$(_sql_escape "$value")
    
    _db_exec "UPDATE $STATE_TABLE SET $key = '$escaped_value';"
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


# Function to get session statistics
_get_session_stats() {
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
    
    # Batch all statistics into one query
    local stats
    stats=$(_db_q "
        WITH R AS (
            SELECT project, duration_seconds
            FROM $SESSIONS_TABLE
            WHERE DATE(start_time) >= '$start_date' AND DATE(start_time) <= '$end_date'
        )
        SELECT
            COUNT(*) AS total_sessions,
            IFNULL(SUM(duration_seconds), 0) AS total_duration,
            IFNULL(SUM(duration_seconds) / COUNT(*), 0) AS avg_duration,
            COUNT(DISTINCT CASE WHEN project != '[idle]' THEN project END) AS projects_count
        FROM R;
    ")
    
    if [[ -z "$stats" ]]; then
        echo "0|0|0|0"
    else
        echo "$stats"
    fi
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
    local state_data
    state_data=$(_get_all_state_data)
    if [[ -n "$state_data" ]]; then
        echo "$state_data" | cut -d',' -f8
    fi
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
    local state_data
    state_data=$(_get_all_state_data)
    if [[ -n "$state_data" ]]; then
        disabled=$(echo "$state_data" | cut -d',' -f8)
        if [[ "$disabled" -eq 1 ]]; then
            return 0
        else
            return 1
        fi
    else
        return 1
    fi
}

# Function: _get_nudging_enabled_public
# Description: Get nudging enabled status (PRIVATE)
# Usage: _get_nudging_enabled_public
# Returns: 1 if enabled, 0 if disabled
_get_nudging_enabled_public() {
    local state_data
    state_data=$(_get_all_state_data)
    if [[ -n "$state_data" ]]; then
        echo "$state_data" | cut -d',' -f9
    fi
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