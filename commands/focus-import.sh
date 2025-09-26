#!/usr/bin/env bash
# Refocus Shell - Import Subcommand
# Copyright (c) 2025 PeGa
# Licensed under the GNU General Public License v3

# Source bootstrap module
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/focus-bootstrap.sh"

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
