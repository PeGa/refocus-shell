#!/usr/bin/env bash
# Refocus Shell - Database service and SQLite operations
# Copyright (C) 2025 PeGa
# Licensed under the GNU General Public License v3

set -euo pipefail

# ===========================
# Configuration & Constants
# ===========================

# Default paths (configurable via environment or arguments)
: "${DB_PATH:=$HOME/.local/refocus/refocus.db}"
: "${STATE_TABLE:='state'}"
: "${SESSIONS_TABLE:='sessions'}"
: "${PROJECTS_TABLE:='projects'}"

# ===========================
# Source Existing Infrastructure
# ===========================

# Source logger and date utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/logger.sh"
source "$SCRIPT_DIR/../lib/date-utils.sh"

# ===========================
# Helper Functions
# ===========================

# Sanitize file paths - prevent traversal and special chars
sanitize_path() {
    local path="$1"
    local base_dir
    
    # Get base directory for relative path validation
    base_dir=$(dirname "$DB_PATH" 2>/dev/null || echo ".")
    
    # Normalize path (remove leading ./)
    path="${path#./}"
    
    # Reject path traversal attempts
    if [[ "$path" == *".."* ]]; then
        logger_warn "Invalid path contains traversal: $path"
        return 1
    fi
    
    # Allow only safe characters
    if [[ ! "$path" =~ ^[a-zA-Z0-9_.-]+$ ]]; then
        logger_warn "Invalid path contains special chars: $path"
        return 1
    fi
    
    echo "$path"
}

# Escape single quotes for SQL - secure and simple
sql_quote() {
    local val="$1"
    printf '%s' "${val//\'/\'\'}"
}

# Execute SQL with secure parameterization
# Usage: execute_sql <table> <columns/values> <values...>
execute_sql() {
    local table="$1"
    shift
    local columns="$1"
    shift
    local values=()
    
    # Build value array
    while [[ $# -gt 0 ]]; do
        values+=("$1")
        shift
    done
    
    # Escape all values and build query
    local escaped_values=()
    for val in "${values[@]}"; do
        escaped_values+=("'$(sql_quote "$val")'")
    done
    
    # Execute
    if ! sqlite3 "$DB_PATH" "INSERT OR REPLACE INTO $table ($columns) VALUES (${escaped_values[*]});" >/dev/null 2>&1; then
        logger_error "❌ SQL Error: $table"
        return 1
    fi
}

# Query and return single value - with proper escaping
query_scalar() {
    local query="$1"
    
    # Validation: reasonable length check
    if [[ ${#query} -gt 1000 ]]; then
        logger_warn "Query exceeds safe length (${#query})"
        return 1
    fi
    
    # Escape single quotes in SQL (parameterized queries not available in sqlite3 CLI)
    local escaped_query="${query//\'/\'\'}"
    
    # Execute with error handling
    sqlite3 "$DB_PATH" "$escaped_query" 2>/dev/null || true
}

# Query and return formatted rows
query_rows() {
    local query="$1"
    
    # Validation: reasonable length check
    if [[ ${#query} -gt 1000 ]]; then
        logger_warn "Query exceeds safe length (${#query})"
        return 1
    fi
    
    # Escape single quotes in SQL
    local escaped_query="${query//\'/\'\'}"
    
    sqlite3 -header -column "$DB_PATH" "$escaped_query" 2>/dev/null
}

# ===========================
# State Management
# ===========================

init_state() {
    # Initialize state table with defaults
    execute_sql "$STATE_TABLE" "key, value, created, updated" \
        "refocus_settings" "$(get_timestamp)" "$(get_timestamp)"
}

get_state() {
    local key="$1"
    local default="${2:-"-"}"
    local value
    # Escape single quotes in key
    local escaped_key="${key//\'/\'\'}"
    value=$(query_scalar "SELECT value FROM $STATE_TABLE WHERE key = '$escaped_key';")
    echo "${value:-$default}"
}

set_state() {
    local key="$1"
    local value="$2"
    execute_sql "$STATE_TABLE" "key, value, created, updated" \
        "$key" "$value" "$(get_timestamp)" "$(get_timestamp)"
}

delete_state() {
    local key="$1"
    local escaped_key="${key//\'/\'\'}"
    execute_sql "$STATE_TABLE" "key" "$escaped_key"
}

get_all_states() {
    query_rows "SELECT key, value FROM $STATE_TABLE ORDER BY key;"
}

# ===========================
# Projects Operations
# ===========================

add_project() {
    local project="$1"
    local description="$2"
    execute_sql "$PROJECTS_TABLE" "project, description, created_at, updated_at" \
        "$project" "$(sql_quote "$description")" "$(get_timestamp)" "$(get_timestamp)"
    echo "✓ Project added: $project"
}

get_project() {
    local project="$1"
    local escaped_project="${project//\'/\'\'}"
    local row
    row=$(query_scalar "SELECT project, description FROM $PROJECTS_TABLE WHERE project = '$escaped_project';")
    [[ -z "$row" ]] && { logger_warn "❌ Project not found: $project"; return 1; }
    echo "$row"
}

list_projects() {
    query_rows "SELECT project FROM $PROJECTS_TABLE ORDER BY project;"
}

delete_project() {
    local project="$1"
    local escaped_project="${project//\'/\'\'}"
    execute_sql "$PROJECTS_TABLE" "project" "$escaped_project"
    echo "✓ Project deleted: $project"
}

# ===========================
# Sessions Operations
# ===========================

add_session() {
    local project="$1"
    local start_time="$2"
    local end_time="$3"
    local duration="$4"
    local notes="$5"
    local duration_only="${6:-0}"
    local session_date="${7:-$(get_date)}"
    execute_sql "$SESSIONS_TABLE" "project, start_time, end_time, duration_seconds, notes, duration_only, session_date" \
        "$project" "$start_time" "$end_time" "$duration" "$(sql_quote "$notes")" \
        "$duration_only" "$session_date"
    echo "✓ Session recorded for $project"
}

get_sessions() {
    local project="$1"
    local escaped_project="${project//\'/\'\'}"
    query_rows "SELECT * FROM $SESSIONS_TABLE WHERE project = '$escaped_project' ORDER BY start_time DESC;"
}

get_session_count() {
    local project="$1"
    local escaped_project="${project//\'/\'\'}"
    local count
    if [[ -n "$project" ]]; then
        count=$(query_scalar "SELECT COUNT(*) FROM $SESSIONS_TABLE WHERE project = '$escaped_project';")
    else
        count=$(query_scalar "SELECT COUNT(*) FROM $SESSIONS_TABLE;")
    fi
    echo "$count"
}

# ===========================
# Database Management
# ===========================

backup_database() {
    local db_path="${1:-$DB_PATH}"
    local backup_name="$db_path.backup.$(get_date)_$(get_timestamp)"
    
    # Validate backup target path
    if ! sanitize_path "$(dirname "$backup_name")"; then
        logger_error "Invalid backup target directory"
        return 1
    fi
    
    cp "$db_path" "$backup_name" 2>/dev/null && \
        echo "✓ Database backed up to: $backup_name" || \
        { logger_error "❌ Backup failed"; return 1; }
}

export_database() {
    local output="${1:-$DB_PATH.sql}"
    
    # Validate output path
    if ! sanitize_path "$output"; then
        logger_error "Invalid output path"
        return 1
    fi
    
    sqlite3 "$DB_PATH" ".dump" > "$output" && \
        echo "✓ Database exported to: $output" || \
        { logger_error "❌ Export failed"; return 1; }
}

import_database() {
    local input="${1:-$DB_PATH.sql}"
    
    # Validate input path
    if ! sanitize_path "$input"; then
        logger_error "Invalid input path"
        return 1
    fi
    
    [[ -f "$input" ]] || { logger_error "❌ File not found: $input"; return 1; }
    sqlite3 "$DB_PATH" < "$input" && \
        echo "✓ Database imported from: $input" || \
        { logger_error "❌ Import failed"; return 1; }
}

# ===========================
# Main Entry Point
# ===========================

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    logger_info "ReFocus Database Service"
    logger_info "Configuration:"
    logger_info "  Database: $DB_PATH"
    logger_info "  State Table: $STATE_TABLE"
    logger_info "  Available functions:"
    logger_info "    Projects:   add_project, get_project, list_projects, delete_project"
    logger_info "    Sessions:   add_session, get_sessions, get_session_count"
    logger_info "    State:      init_state, get_state, set_state, get_all_states"
    logger_info "    Database:   backup, export, import"
fi