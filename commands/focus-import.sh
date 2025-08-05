#!/usr/bin/env bash
# Refocus Shell - Import Focus Data Subcommand
# Copyright (c) 2025 PeGa
# Licensed under the GNU General Public License v3

# Source libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$HOME/.local/refocus/lib/focus-db.sh" ]]; then
    source "$HOME/.local/refocus/lib/focus-db.sh"
    source "$HOME/.local/refocus/lib/focus-utils.sh"
else
    source "$SCRIPT_DIR/../lib/focus-db.sh"
    source "$SCRIPT_DIR/../lib/focus-utils.sh"
fi

function focus_import() {
    local input_file="$1"
    
    if [[ -z "$input_file" ]]; then
        echo "❌ No input file specified."
        echo "Usage: focus import <file.sql>"
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
    
    echo "📥 Importing focus data from: $input_file"
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
    
    # Clear existing database and import the SQLite dump
    rm -f "$DB"
    sqlite3 "$DB" < "$input_file"
    
    if [[ $? -eq 0 ]]; then
        echo "✅ Focus data imported successfully from: $input_file"
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
    focus_import "$@"
fi 