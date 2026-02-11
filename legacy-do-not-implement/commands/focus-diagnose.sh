#!/usr/bin/env bash
# Refocus Shell - Diagnose Subcommand
# Copyright (c) 2025 PeGa
# Licensed under the GNU General Public License v3

# Source bootstrap module
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_DIR/../lib/focus-bootstrap.sh" ]]; then
    source "$SCRIPT_DIR/../lib/focus-bootstrap.sh"
elif [[ -f "$HOME/.local/refocus/lib/focus-bootstrap.sh" ]]; then
    source "$HOME/.local/refocus/lib/focus-bootstrap.sh"
else
    echo "❌ Cannot find focus-bootstrap.sh"
    exit 1
fi

# Source database functions
if [[ -f "$SCRIPT_DIR/../lib/focus-db.sh" ]]; then
    source "$SCRIPT_DIR/../lib/focus-db.sh"
elif [[ -f "$HOME/.local/refocus/lib/focus-db.sh" ]]; then
    source "$HOME/.local/refocus/lib/focus-db.sh"
else
    echo "❌ Cannot find focus-db.sh"
    exit 1
fi

# Function to run comprehensive system diagnostics
focus_diagnose_system() {
    echo "🔍 Refocus Shell System Diagnostics"
    echo "===================================="
    echo
    
    # Set default database path if not set
    local db_path="${DB:-$HOME/.local/refocus/refocus.db}"
    
    # Check database file
    echo "📁 Database File:"
    if [[ -f "$db_path" ]]; then
        echo "   ✅ Database file exists: $db_path"
        echo "   📊 File size: $(du -h "$db_path" | cut -f1)"
        echo "   📅 Last modified: $(stat -c %y "$db_path" 2>/dev/null || stat -f %Sm "$db_path" 2>/dev/null)"
    else
        echo "   ❌ Database file does not exist: $db_path"
    fi
    echo
    
    # Check database directory
    echo "📂 Database Directory:"
    local db_dir
    db_dir=$(dirname "$db_path")
    if [[ -d "$db_dir" ]]; then
        echo "   ✅ Directory exists: $db_dir"
        echo "   📊 Directory permissions: $(ls -ld "$db_dir" | awk '{print $1}')"
        echo "   💾 Available space: $(df -h "$db_dir" | awk 'NR==2 {print $4}')"
    else
        echo "   ❌ Directory does not exist: $db_dir"
    fi
    echo
    
    # Check disk space
    echo "💾 Disk Space Check:"
    if check_disk_space; then
        echo "   ✅ Sufficient disk space available"
    else
        echo "   ❌ Insufficient disk space"
    fi
    echo
    
    # Check permissions
    echo "🔒 Permission Check:"
    if check_database_permissions; then
        echo "   ✅ Database permissions are correct"
    else
        echo "   ❌ Database permission issues detected"
    fi
    echo
    
    # Check database integrity
    echo "🗃️  Database Integrity Check:"
    if check_database_integrity; then
        echo "   ✅ Database integrity is good"
    else
        echo "   ❌ Database integrity issues detected"
    fi
    echo
    
    # Check SQLite availability
    echo "🔧 SQLite Availability:"
    if command -v sqlite3 >/dev/null 2>&1; then
        echo "   ✅ SQLite3 is available: $(sqlite3 --version)"
    else
        echo "   ❌ SQLite3 is not available"
    fi
    echo
    
    # Check system commands
    echo "🛠️  System Commands:"
    local commands=("df" "du" "stat" "ls" "mkdir" "cp" "mv" "rm")
    for cmd in "${commands[@]}"; do
        if command -v "$cmd" >/dev/null 2>&1; then
            echo "   ✅ $cmd is available"
        else
            echo "   ❌ $cmd is not available"
        fi
    done
    echo
    
    # Check log directory
    echo "📝 Log Directory:"
    local log_dir="${REFOCUS_LOG_DIR:-$HOME/.local/refocus}"
    if [[ -d "$log_dir" ]]; then
        echo "   ✅ Log directory exists: $log_dir"
        echo "   📊 Log directory permissions: $(ls -ld "$log_dir" | awk '{print $1}')"
        local error_log="${REFOCUS_ERROR_LOG:-$log_dir/error.log}"
        if [[ -f "$error_log" ]]; then
            echo "   📄 Error log exists: $error_log"
            echo "   📊 Error log size: $(du -h "$error_log" | cut -f1)"
        else
            echo "   ℹ️  No error log file found"
        fi
    else
        echo "   ❌ Log directory does not exist: $log_dir"
    fi
    echo
    
    # Check environment variables
    echo "🌍 Environment Variables:"
    echo "   REFOCUS_DB: ${REFOCUS_DB:-'not set (using default)'}"
    echo "   REFOCUS_LOG_DIR: ${REFOCUS_LOG_DIR:-'not set (using default)'}"
    echo "   REFOCUS_ERROR_LOG: ${REFOCUS_ERROR_LOG:-'not set (using default)'}"
    echo "   VERBOSE: ${VERBOSE:-'not set (using default)'}"
    echo
}

# Function to repair common issues
focus_diagnose_repair() {
    echo "🔧 Refocus Shell System Repair"
    echo "==============================="
    echo
    
    local issues_found=0
    
    # Check and create database directory
    local db_dir
    db_dir=$(dirname "$DB")
    if [[ ! -d "$db_dir" ]]; then
        echo "🔧 Creating database directory: $db_dir"
        if mkdir -p "$db_dir"; then
            echo "   ✅ Database directory created"
        else
            echo "   ❌ Failed to create database directory"
            ((issues_found++))
        fi
    fi
    
    # Check and create log directory
    if [[ ! -d "$REFOCUS_LOG_DIR" ]]; then
        echo "🔧 Creating log directory: $REFOCUS_LOG_DIR"
        if mkdir -p "$REFOCUS_LOG_DIR"; then
            echo "   ✅ Log directory created"
        else
            echo "   ❌ Failed to create log directory"
            ((issues_found++))
        fi
    fi
    
    # Check database file permissions
    if [[ -f "$DB" ]]; then
        echo "🔧 Checking database file permissions"
        if [[ ! -r "$DB" ]] || [[ ! -w "$DB" ]]; then
            echo "   🔧 Fixing database file permissions"
            if chmod 644 "$DB" 2>/dev/null; then
                echo "   ✅ Database file permissions fixed"
            else
                echo "   ❌ Failed to fix database file permissions"
                ((issues_found++))
            fi
        fi
    fi
    
    # Check database integrity and attempt recovery
    if [[ -f "$DB" ]]; then
        echo "🔧 Checking database integrity"
        if ! check_database_integrity; then
            echo "   🔧 Attempting database recovery"
            if attempt_database_recovery; then
                echo "   ✅ Database recovery successful"
            else
                echo "   ❌ Database recovery failed"
                ((issues_found++))
            fi
        fi
    fi
    
    # Initialize database if it doesn't exist
    if [[ ! -f "$DB" ]]; then
        echo "🔧 Initializing new database"
        if focus_init; then
            echo "   ✅ Database initialized successfully"
        else
            echo "   ❌ Failed to initialize database"
            ((issues_found++))
        fi
    fi
    
    echo
    if [[ $issues_found -eq 0 ]]; then
        echo "✅ All repairs completed successfully"
        return 0
    else
        echo "❌ $issues_found issues could not be repaired automatically"
        return 1
    fi
}

# Function to create emergency backup
focus_diagnose_backup() {
    echo "💾 Creating Emergency Backup"
    echo "============================"
    echo
    
    if [[ ! -f "$DB" ]]; then
        echo "❌ No database file to backup: $DB"
        return 1
    fi
    
    if create_database_backup; then
        echo "✅ Emergency backup created successfully"
        return 0
    else
        echo "❌ Failed to create emergency backup"
        return 1
    fi
}

# Function to restore from backup
focus_diagnose_restore() {
    local backup_file="$1"
    
    if [[ -z "$backup_file" ]]; then
        echo "❌ No backup file specified"
        echo "Usage: focus diagnose restore <backup_file>"
        return 1
    fi
    
    if [[ ! -f "$backup_file" ]]; then
        echo "❌ Backup file does not exist: $backup_file"
        return 1
    fi
    
    echo "🔄 Restoring from backup: $backup_file"
    echo "======================================"
    echo
    
    # Create backup of current database
    if [[ -f "$DB" ]]; then
        echo "💾 Creating backup of current database"
        local current_backup="$DB.pre_restore.$(date +%s)"
        if cp "$DB" "$current_backup"; then
            echo "   ✅ Current database backed up as: $current_backup"
        else
            echo "   ❌ Failed to backup current database"
            return 1
        fi
    fi
    
    # Restore from backup
    echo "🔄 Restoring database from backup"
    if cp "$backup_file" "$DB"; then
        echo "   ✅ Database restored successfully"
        
        # Verify restored database
        echo "🔍 Verifying restored database"
        if check_database_integrity; then
            echo "   ✅ Restored database integrity verified"
            return 0
        else
            echo "   ❌ Restored database integrity check failed"
            return 1
        fi
    else
        echo "   ❌ Failed to restore database"
        return 1
    fi
}

# Function to list available backups
focus_diagnose_list_backups() {
    echo "📋 Available Database Backups"
    echo "============================"
    echo
    
    local backup_dir
    backup_dir="$(dirname "$DB")/backups"
    
    if [[ ! -d "$backup_dir" ]]; then
        echo "ℹ️  No backup directory found: $backup_dir"
        return 0
    fi
    
    local backup_count=0
    while IFS= read -r -d '' backup_file; do
        ((backup_count++))
        echo "📄 Backup $backup_count:"
        echo "   File: $backup_file"
        echo "   Size: $(du -h "$backup_file" | cut -f1)"
        echo "   Date: $(stat -c %y "$backup_file" 2>/dev/null || stat -f %Sm "$backup_file" 2>/dev/null)"
        echo
    done < <(find "$backup_dir" -name "refocus_backup_*.db" -print0 2>/dev/null | sort -z)
    
    if [[ $backup_count -eq 0 ]]; then
        echo "ℹ️  No backup files found in: $backup_dir"
    else
        echo "📊 Total backups found: $backup_count"
    fi
}

# Main diagnose function
focus_diagnose() {
    case "${1:-}" in
        system)
            focus_diagnose_system
            ;;
        repair)
            focus_diagnose_repair
            ;;
        backup)
            focus_diagnose_backup
            ;;
        restore)
            focus_diagnose_restore "$2"
            ;;
        list-backups)
            focus_diagnose_list_backups
            ;;
        *)
            echo "Refocus Shell - Diagnose Command"
            echo "================================"
            echo
            echo "Usage: focus diagnose <command>"
            echo
            echo "Commands:"
            echo "  system        - Run comprehensive system diagnostics"
            echo "  repair        - Attempt to repair common issues"
            echo "  backup        - Create emergency database backup"
            echo "  restore <file> - Restore database from backup file"
            echo "  list-backups  - List all available database backups"
            echo
            echo "Examples:"
            echo "  focus diagnose system"
            echo "  focus diagnose repair"
            echo "  focus diagnose backup"
            echo "  focus diagnose restore ~/.local/refocus/backups/refocus_backup_20250101_120000.db"
            echo "  focus diagnose list-backups"
            ;;
    esac
}

# Execute the main function
focus_diagnose "$@"
