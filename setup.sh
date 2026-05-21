#!/usr/bin/env bash
# Refocus Shell - Minimal Installation Script
# Copyright (C) 2025 PeGa
# Licensed under the GNU General Public License v3

set -euo pipefail

# Source configuration and utilities
SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
source "$SCRIPT_DIR/config.sh"

# CLI Entry Point & Dependency Management
_check_dependencies() {
    local deps=("sqlite3" "jq" "notify-send")
    local missing=()
    for cmd in "${deps[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            missing+=("$cmd")
        fi
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "❌ Missing dependencies: ${missing[*]}"
        echo "   Please install them and try again." >&2
        exit 3
    fi
}

_ensure_dir() {
    local db_dir
    db_dir=$(dirname "$DB_PATH")
    if [[ ! -d "$db_dir" ]]; then
        mkdir -p "$db_dir"
        echo "✓ Created directory: $db_dir"
    fi
}

_initialize_database() {
    echo "✓ Initializing Refocus database at $DB_PATH..."
    sqlite3 "$DB_PATH" <<'SQL'
        CREATE TABLE IF NOT EXISTS refocus_state (
            key TEXT PRIMARY KEY,
            value TEXT,
            created TEXT,
            updated TEXT
        );
        CREATE TABLE IF NOT EXISTS sessions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            project TEXT,
            start_time TEXT,
            end_time TEXT,
            duration_seconds INTEGER DEFAULT 0,
            notes TEXT,
            duration_only INTEGER DEFAULT 0,
            session_date TEXT,
            created TEXT
        );
        CREATE TABLE IF NOT EXISTS projects (
            project TEXT PRIMARY KEY,
            description TEXT,
            created_at TEXT,
            updated_at TEXT
        );
        CREATE TABLE IF NOT EXISTS session_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            session_id INTEGER,
            action TEXT,
            timestamp TEXT,
            FOREIGN KEY(session_id) REFERENCES sessions(id)
        );
        CREATE TABLE IF NOT EXISTS nudge_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            message TEXT,
            timestamp TEXT,
            acknowledged INTEGER DEFAULT 0
        );
SQL
    echo "✓ Database initialized successfully."
}

_install() {
    echo "🔧 Installing Refocus Shell..."
    _check_dependencies
    _ensure_dir
    _initialize_database
    echo "✅ Refocus Shell installation complete."
    echo "   Database: $DB_PATH"
    echo "   Run 'refocus' or 'focus' to start."
}

# Handle CLI arguments
case "${1:-}" in
    install) _install ;;
    check)   _check_dependencies ;;
    init)    _ensure_dir && _initialize_database ;;
    *)       echo "Usage: $0 {install|check|init}" >&2; exit 1 ;;
esac

# Prevent direct execution of this file if sourced without args.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]] && [[ $# -eq 0 ]]; then
    _error_invalid_invocation
fi
