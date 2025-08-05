#!/usr/bin/env bash
# Refocus Shell - Export Focus Data Subcommand
# Copyright (c) 2025 PeGa
# Licensed under the GNU General Public License v3

# Source libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$HOME/.local/focus/lib/focus-db.sh" ]]; then
    source "$HOME/.local/focus/lib/focus-db.sh"
    source "$HOME/.local/focus/lib/focus-utils.sh"
else
    source "$SCRIPT_DIR/../lib/focus-db.sh"
    source "$SCRIPT_DIR/../lib/focus-utils.sh"
fi

function focus_export() {
    local output_file="$1"
    
    if [[ -z "$output_file" ]]; then
        # Generate default filename
        local timestamp
        timestamp=$(date +%Y%m%d_%H%M%S)
        output_file="focus-export-${timestamp}.sql"
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
    
    echo "📤 Exporting focus data to: $output_file"
    
    # Create SQLite dump
    sqlite3 "$DB" .dump > "$output_file"
    
    if [[ $? -eq 0 ]]; then
        echo "✅ Focus data exported successfully to: $output_file"
        echo "📊 Export contains:"
        echo "   - Database schema"
        echo "   - All focus sessions"
        echo "   - Current focus state"
        echo ""
        echo "To import this data, use: focus import $output_file"
    else
        echo "❌ Export failed"
        exit 1
    fi
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    focus_export "$@"
fi 