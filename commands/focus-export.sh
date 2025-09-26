#!/usr/bin/env bash
# Refocus Shell - Export Subcommand
# Copyright (c) 2025 PeGa
# Licensed under the GNU General Public License v3

# Source bootstrap module
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/focus-bootstrap.sh"

function focus_export() {
    local output_file="$1"
    
    if [[ -z "$output_file" ]]; then
        # Generate default filename
        local timestamp
        timestamp=$(date +%Y%m%d_%H%M%S)
        output_file="refocus-export-${timestamp}"
    fi
    
    # Check if database exists
    if [[ ! -f "$DB" ]]; then
        echo "❌ Database not found: $DB"
        exit 1
    fi
    
    # Generate filenames for both formats
    local sql_file="${output_file}.sql"
    local json_file="${output_file}.json"
    
    # Validate file paths
    if ! validate_file_path "$sql_file" "SQLite output file"; then
        exit 1
    fi
    if ! validate_file_path "$json_file" "JSON output file"; then
        exit 1
    fi
    
    echo "📤 Exporting focus data..."
    echo "   SQLite dump: $sql_file"
    echo "   JSON export: $json_file"
    
    # Create SQLite dump
    execute_sqlite ".dump" "focus_export" > "$sql_file"
    local sql_exit_code=$?
    
    # Create JSON export
    generate_json_export "$json_file"
    local json_exit_code=$?
    
    if [[ $sql_exit_code -eq 0 ]] && [[ $json_exit_code -eq 0 ]]; then
        echo "✅ Focus data exported successfully!"
        echo "📊 Export contains:"
        echo "   - Database schema"
        echo "   - All focus sessions (live and duration-only)"
        echo "   - Current focus state"
        echo "   - Project descriptions"
        echo "   - Pause/resume session data"
        echo ""
        echo "To import this data, use: focus import $sql_file"
        echo "   OR: focus import $json_file"
    else
        echo "❌ Export failed"
        if [[ $sql_exit_code -ne 0 ]]; then
            echo "   SQLite dump failed"
        fi
        if [[ $json_exit_code -ne 0 ]]; then
            echo "   JSON export failed"
        fi
        exit 1
    fi
}


# Main execution
refocus_script_main focus_export "$@"
