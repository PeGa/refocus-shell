#!/usr/bin/env bash
# Refocus Shell - Import Work Data Subcommand
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

function work_import() {
    local input_file="$1"
    
    if [[ -z "$input_file" ]]; then
        echo "❌ No input file specified."
        echo "Usage: work import <file.sql>"
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
    
    # Check if it's a SQLite dump file
    if ! head -1 "$input_file" | grep -q "PRAGMA\|BEGIN\|CREATE\|INSERT"; then
        echo "❌ Not a valid SQLite dump file: $input_file"
        exit 1
    fi
    
    echo "📥 Importing work data from: $input_file"
    echo "⚠️  This will overwrite existing data. Continue? (y/N)"
    read -r response
    
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        echo "Import cancelled."
        exit 0
    fi
    
    # Stop any active session first
    if is_work_active; then
        echo "Stopping active session..."
        work_off
    fi
    
    # Backup current database if it exists
    if [[ -f "$DB" ]]; then
        local backup_file
        backup_file="${DB}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$DB" "$backup_file"
        echo "📋 Created backup: $backup_file"
    fi
    
    # Clear existing database and import the SQLite dump
    rm -f "$DB"
    sqlite3 "$DB" < "$input_file"
    
    if [[ $? -eq 0 ]]; then
        echo "✅ Work data imported successfully from: $input_file"
        echo "📊 Import summary:"
        echo "   - Database restored from SQLite dump"
        echo "   - All tables and data imported"
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
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    work_import "$@"
fi 