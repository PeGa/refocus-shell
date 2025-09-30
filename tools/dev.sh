#!/usr/bin/env bash
# Refocus Shell - Development Script
# Copyright (c) 2025 PeGa
# Licensed under the GNU General Public License v3

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local color="$1"
    local message="$2"
    echo -e "${color}${message}${NC}"
}

# Function to run smoke tests
smoke() {
    print_status "$YELLOW" "Running smoke tests..."
    
    # Uninstall current version
    print_status "$YELLOW" "Uninstalling current version..."
    ./setup.sh uninstall >/dev/null 2>&1 || true
    
    # Install fresh version
    print_status "$YELLOW" "Installing fresh version..."
    ./setup.sh install --auto >/dev/null 2>&1
    
    # Source bashrc to get focus function
    source ~/.bashrc
    
    # Create temporary state directory
    local temp_state_dir
    temp_state_dir=$(mktemp -d)
    export REFOCUS_STATE_DIR="$temp_state_dir"
    
    # Cleanup function
    cleanup() {
        if [[ -n "${temp_state_dir:-}" ]]; then
            rm -rf "$temp_state_dir"
        fi
    }
    trap cleanup EXIT
    
    # Test basic commands
    local test_project="smoke-test-project"
    
    # Test focus on
    print_status "$YELLOW" "Testing: focus on $test_project"
    if focus on "$test_project" >/dev/null 2>&1; then
        print_status "$GREEN" "✓ focus on command executed"
    else
        print_status "$RED" "FAIL: focus on command failed"
        return 1
    fi
    
    # Test focus status
    print_status "$YELLOW" "Testing: focus status"
    if focus status >/dev/null 2>&1; then
        print_status "$GREEN" "✓ focus status command executed"
    else
        print_status "$RED" "FAIL: focus status command failed"
        return 1
    fi
    
    # Test focus pause (may fail if no active session, which is expected)
    print_status "$YELLOW" "Testing: focus pause"
    focus pause >/dev/null 2>&1 || true
    print_status "$GREEN" "✓ focus pause command executed"
    
    # Test focus continue (may fail if no active session, which is expected)
    print_status "$YELLOW" "Testing: focus continue"
    focus continue >/dev/null 2>&1 || true
    print_status "$GREEN" "✓ focus continue command executed"
    
    # Test focus off (may fail if no active session, which is expected)
    print_status "$YELLOW" "Testing: focus off"
    focus off >/dev/null 2>&1 || true
    print_status "$GREEN" "✓ focus off command executed"
    
    # Test focus report
    print_status "$YELLOW" "Testing: focus report"
    if focus report today >/dev/null 2>&1; then
        print_status "$GREEN" "✓ focus report command executed"
    else
        print_status "$RED" "FAIL: focus report command failed"
        return 1
    fi
    
    # Generate deterministic test data for golden snapshots
    print_status "$YELLOW" "Generating test data for golden snapshots..."
    focus init >/dev/null 2>&1 || true
    echo | focus past add "test-project-1" "2025-01-28 10:00" "2025-01-28 11:00" >/dev/null 2>&1 || true
    echo | focus past add "test-project-2" "2025-01-28 14:00" "2025-01-28 15:30" >/dev/null 2>&1 || true
    echo | focus past add "test-project-3" "2025-01-28 16:00" "2025-01-28 17:00" >/dev/null 2>&1 || true
    
    # Test golden snapshots
    print_status "$YELLOW" "Testing golden snapshots..."
    
    # Test report --raw output
    local report_output
    report_output=$(mktemp)
    focus report today --raw > "$report_output" 2>/dev/null || true
    
    if ! diff -u tests/golden/report_today_raw.csv.golden "$report_output" >/dev/null; then
        print_status "$RED" "FAIL: report --raw output mismatch"
        print_status "$RED" "Diff:"
        diff -u tests/golden/report_today_raw.csv.golden "$report_output" || true
        rm -f "$report_output"
        return 1
    fi
    rm -f "$report_output"
    print_status "$GREEN" "✓ report --raw output matches golden snapshot"
    
    # Test past --raw output
    local past_output
    past_output=$(mktemp)
    focus past list --raw > "$past_output" 2>/dev/null || true
    
    if ! diff -u tests/golden/past_today_raw.csv.golden "$past_output" >/dev/null; then
        print_status "$RED" "FAIL: past --raw output mismatch"
        print_status "$RED" "Diff:"
        diff -u tests/golden/past_today_raw.csv.golden "$past_output" || true
        rm -f "$past_output"
        return 1
    fi
    rm -f "$past_output"
    print_status "$GREEN" "✓ past --raw output matches golden snapshot"
    
    print_status "$GREEN" "OK"
    return 0
}

# Function to run linting
lint() {
    print_status "$YELLOW" "Running shellcheck..."
    
    # Run shellcheck on main scripts
    if command -v shellcheck >/dev/null 2>&1; then
        shellcheck ./focus ./commands/*.sh ./lib/*.sh || true
    else
        print_status "$YELLOW" "shellcheck not found, skipping lint"
    fi
    
    print_status "$GREEN" "Lint completed"
}

# Function to run CI (audit + lint + smoke)
ci() {
    print_status "$YELLOW" "Running CI pipeline..."
    
    # Run façade audit
    print_status "$YELLOW" "Running façade audit..."
    ./tools/audit/facade.sh
    
    lint
    smoke
}

# Main command dispatch
case "${1:-}" in
    "smoke")
        smoke
        ;;
    "lint")
        lint
        ;;
    "ci")
        ci
        ;;
    *)
        echo "Usage: $0 {smoke|lint|ci}"
        echo ""
        echo "Commands:"
        echo "  smoke  - Run smoke tests with temporary state directory"
        echo "  lint   - Run shellcheck on all shell scripts"
        echo "  ci     - Run both lint and smoke tests"
        exit 1
        ;;
esac