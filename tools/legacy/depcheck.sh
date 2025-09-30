#!/usr/bin/env bash
# Refocus Shell - Dependency Checker
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

# Allowed libraries for commands
ALLOWED_LIBS=(
    "lib/focus-bootstrap.sh"
    "lib/focus-utils.sh"
    "lib/focus-db.sh"
    "lib/focus-output.sh"
)

# Function to check if a file is a command
is_command() {
    local file="$1"
    [[ "$file" =~ ^commands/focus-.*\.sh$ ]]
}

# Function to check if a file is a library
is_library() {
    local file="$1"
    [[ "$file" =~ ^lib/focus-.*\.sh$ ]]
}

# Function to check sourcing patterns in a file
check_sourcing() {
    local file="$1"
    local violations=()
    
    # Check for any source statements
    while IFS= read -r line; do
        # Skip comments and empty lines
        if [[ "$line" =~ ^[[:space:]]*# ]] || [[ -z "${line// }" ]]; then
            continue
        fi
        
        # Check for source statements
        if [[ "$line" =~ ^[[:space:]]*source[[:space:]]+ ]]; then
            # Extract the sourced file
            local sourced_file
            sourced_file=$(echo "$line" | sed -E 's/^[[:space:]]*source[[:space:]]+["\x27]?([^"\x27[:space:]]+)["\x27]?.*/\1/')
            
            # Check if it's sourcing a library
            if [[ "$sourced_file" =~ lib/ ]]; then
                # Check if it's an allowed library
                local is_allowed=false
                for allowed_lib in "${ALLOWED_LIBS[@]}"; do
                    if [[ "$sourced_file" == "$allowed_lib" ]] || [[ "$sourced_file" =~ $allowed_lib ]]; then
                        is_allowed=true
                        break
                    fi
                done
                
                if [[ "$is_allowed" == false ]]; then
                    violations+=("Line $((++line_num)): sources '$sourced_file'")
                fi
            fi
        fi
    done < "$file"
    
    # Return violations
    if [[ ${#violations[@]} -gt 0 ]]; then
        printf '%s\n' "${violations[@]}"
    fi
}

# Function to check prompt-related code
check_prompt_code() {
    local file="$1"
    local violations=()
    
    # Check for prompt-related variables/functions
    if grep -q -E "PS1|RPROMPT|PROMPT_COMMAND|precmd" "$file"; then
        # Check if this is focus-function.sh (allowed) or extras/prompt/* (allowed)
        if [[ "$file" != "lib/focus-function.sh" ]] && [[ ! "$file" =~ ^extras/prompt/ ]]; then
            violations+=("Contains prompt-related code (PS1/RPROMPT/PROMPT_COMMAND/precmd)")
        fi
    fi
    
    # Return violations
    if [[ ${#violations[@]} -gt 0 ]]; then
        printf '%s\n' "${violations[@]}"
    fi
}

# Main function
main() {
    local errors=0
    local warnings=0
    
    echo "🔍 Refocus Shell Dependency Checker"
    echo "===================================="
    echo
    
    # Check all command files
    echo "Checking command sourcing patterns..."
    for file in commands/focus-*.sh; do
        if [[ -f "$file" ]]; then
            local sourcing_violations
            sourcing_violations=$(check_sourcing "$file")
            
            if [[ -n "$sourcing_violations" ]]; then
                echo -e "${RED}❌ $file${NC}"
                echo "$sourcing_violations" | sed 's/^/  /'
                ((errors++))
            else
                echo -e "${GREEN}✅ $file${NC}"
            fi
        fi
    done
    
    echo
    
    # Check all files for prompt-related code
    echo "Checking prompt-related code..."
    for file in commands/*.sh lib/*.sh; do
        if [[ -f "$file" ]]; then
            local prompt_violations
            prompt_violations=$(check_prompt_code "$file")
            
            if [[ -n "$prompt_violations" ]]; then
                echo -e "${RED}❌ $file${NC}"
                echo "$prompt_violations" | sed 's/^/  /'
                ((errors++))
            else
                echo -e "${GREEN}✅ $file${NC}"
            fi
        fi
    done
    
    echo
    
    # Summary
    if [[ $errors -eq 0 ]]; then
        echo -e "${GREEN}✅ All dependency checks passed!${NC}"
        echo "Commands only source allowed libraries:"
        for lib in "${ALLOWED_LIBS[@]}"; do
            echo "  - $lib"
        done
        echo
        echo "Prompt-related code is properly isolated in lib/focus-function.sh"
        exit 0
    else
        echo -e "${RED}❌ Found $errors dependency violations${NC}"
        echo
        echo "Commands may ONLY source these libraries:"
        for lib in "${ALLOWED_LIBS[@]}"; do
            echo "  - $lib"
        done
        echo
        echo "Prompt-related code (PS1/RPROMPT/PROMPT_COMMAND/precmd) must exist ONLY in:"
        echo "  - lib/focus-function.sh"
        echo "  - extras/prompt/* (if present)"
        exit 1
    fi
}

# Run main function
main "$@"
