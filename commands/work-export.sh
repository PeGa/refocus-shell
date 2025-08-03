#!/usr/bin/env bash
# Refocus Shell - Export Work Data Subcommand
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

function work_export() {
    local output_file="$1"
    
    if [[ -z "$output_file" ]]; then
        # Generate default filename
        local timestamp
        timestamp=$(date +%Y%m%d_%H%M%S)
        output_file="work-export-${timestamp}.sql"
    fi
    
    # Validate file path
    if ! validate_file_path "$output_file" "Output file"; then
        exit 1
    fi
    
    # Check if database exists
    if [[ ! -f "$DB" ]]; then
        echo "❌ Database not found: $DB"
        exit 1
    fi
    
    echo "📤 Exporting work data to: $output_file"
    
    # Create SQLite dump
    sqlite3 "$DB" .dump > "$output_file"
    
    if [[ $? -eq 0 ]]; then
        echo "✅ Work data exported successfully to: $output_file"
        echo "📊 Export contains:"
        echo "   - Database schema"
        echo "   - All work sessions"
        echo "   - Current work state"
        echo ""
        echo "To import this data, use: work import $output_file"
    else
        echo "❌ Export failed"
        exit 1
    fi
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    work_export "$@"
fi 