#!/usr/bin/env bash
# Refocus Shell - Façade Audit Tool
# Copyright (C) 2025 PeGa
# Website: https://www.pega.sh
# Email: dev@pega.sh
# Licensed under the GNU General Public License v3

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Approved public DB functions
APPROVED_DB_FUNCTIONS=(
    "db_init"
    "db_start_session"
    "db_end_session"
    "db_pause"
    "db_resume"
    "db_get_active"
    "db_get_state"
    "db_list"
    "db_stats"
)

# Commands allowed to use sqlite3 directly
ALLOWED_SQLITE_COMMANDS=(
    "init"
    "diagnose"
    "import"
)

print_status() {
    local color="$1"
    local message="$2"
    echo -e "${color}${message}${NC}"
}

check_db_exports() {
    print_status "$YELLOW" "Checking lib/focus-db.sh exports..."
    
    local exports
    exports=$(grep -n 'export -f ' lib/focus-db.sh | sed 's/.*export -f //' | tr ' ' '\n' | sort -u)
    
    local invalid_exports=()
    while IFS= read -r export_func; do
        if [[ -n "$export_func" ]]; then
            local is_approved=false
            for approved in "${APPROVED_DB_FUNCTIONS[@]}"; do
                if [[ "$export_func" == "$approved" ]]; then
                    is_approved=true
                    break
                fi
            done
            if [[ "$is_approved" == "false" ]]; then
                invalid_exports+=("$export_func")
            fi
        fi
    done <<< "$exports"
    
    if [[ ${#invalid_exports[@]} -gt 0 ]]; then
        print_status "$RED" "❌ Invalid exports in lib/focus-db.sh:"
        for export_func in "${invalid_exports[@]}"; do
            echo "  - $export_func"
        done
        return 1
    fi
    
    print_status "$GREEN" "✅ All exports are approved"
    return 0
}

check_command_db_calls() {
    print_status "$YELLOW" "Checking command DB function calls..."
    
    local violations=()
    
    # Check for private DB function calls in commands
    for cmd_file in commands/*.sh; do
        if [[ -f "$cmd_file" ]]; then
            local cmd_name
            cmd_name=$(basename "$cmd_file" .sh | sed 's/focus-//')
            
            # Check for private DB function calls (exclude public db_* functions)
            local private_calls
            private_calls=$(grep -n '_db_\|_get_.*_public\|_set_.*_public\|_migrate' "$cmd_file" | grep -E 'db|state' || true)
            
            if [[ -n "$private_calls" ]]; then
                violations+=("$cmd_name: private DB function calls found")
            fi
        fi
    done
    
    if [[ ${#violations[@]} -gt 0 ]]; then
        print_status "$RED" "❌ Private DB function calls found:"
        for violation in "${violations[@]}"; do
            echo "  - $violation"
        done
        return 1
    fi
    
    print_status "$GREEN" "✅ No private DB function calls found"
    return 0
}

check_sqlite_usage() {
    print_status "$YELLOW" "Checking direct sqlite3 usage..."
    
    local warnings=()
    
    # Check for direct sqlite3 usage in commands
    for cmd_file in commands/*.sh; do
        if [[ -f "$cmd_file" ]]; then
            local cmd_name
            cmd_name=$(basename "$cmd_file" .sh | sed 's/focus-//')
            
            # Check if this command is allowed to use sqlite3
            local is_allowed=false
            for allowed in "${ALLOWED_SQLITE_COMMANDS[@]}"; do
                if [[ "$cmd_name" == "$allowed" ]]; then
                    is_allowed=true
                    break
                fi
            done
            
            if [[ "$is_allowed" == "false" ]]; then
                local sqlite_usage
                sqlite_usage=$(grep -n 'sqlite3' "$cmd_file" || true)
                
                if [[ -n "$sqlite_usage" ]]; then
                    warnings+=("$cmd_name: direct sqlite3 usage found")
                fi
            fi
        fi
    done
    
    if [[ ${#warnings[@]} -gt 0 ]]; then
        print_status "$YELLOW" "⚠️  Direct sqlite3 usage warnings:"
        for warning in "${warnings[@]}"; do
            echo "  - $warning"
        done
    else
        print_status "$GREEN" "✅ No unauthorized sqlite3 usage found"
    fi
    
    return 0
}

main() {
    print_status "$YELLOW" "🔍 Running façade audit..."
    
    local exit_code=0
    
    # Check DB exports
    if ! check_db_exports; then
        exit_code=1
    fi
    
    # Check command DB calls
    if ! check_command_db_calls; then
        exit_code=1
    fi
    
    # Check sqlite3 usage (warnings only)
    check_sqlite_usage
    
    if [[ $exit_code -eq 0 ]]; then
        print_status "$GREEN" "✅ Façade audit passed"
    else
        print_status "$RED" "❌ Façade audit failed"
    fi
    
    exit $exit_code
}

main "$@"
