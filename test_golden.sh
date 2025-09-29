#!/usr/bin/env bash
# Test golden snapshots

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    local color="$1"
    local message="$2"
    echo -e "${color}${message}${NC}"
}

# Create temporary state directory
temp_state_dir=$(mktemp -d)
export REFOCUS_STATE_DIR="$temp_state_dir"

# Cleanup function
cleanup() {
    if [[ -n "${temp_state_dir:-}" ]]; then
        rm -rf "$temp_state_dir"
    fi
}
trap cleanup EXIT

print_status "$YELLOW" "Testing golden snapshots..."

# Generate deterministic test data
print_status "$YELLOW" "Generating test data..."
focus init >/dev/null 2>&1 || true
echo | focus past add "test-project-1" "2025-01-28 10:00" "2025-01-28 11:00" >/dev/null 2>&1 || true
echo | focus past add "test-project-2" "2025-01-28 14:00" "2025-01-28 15:30" >/dev/null 2>&1 || true
echo | focus past add "test-project-3" "2025-01-28 16:00" "2025-01-28 17:00" >/dev/null 2>&1 || true

# Test report --raw output
print_status "$YELLOW" "Testing report --raw output..."
report_output=$(mktemp)
focus report today --raw > "$report_output" 2>/dev/null || true

if ! diff -u tests/golden/report_today_raw.csv.golden "$report_output" >/dev/null; then
    print_status "$RED" "FAIL: report --raw output mismatch"
    print_status "$RED" "Diff:"
    diff -u tests/golden/report_today_raw.csv.golden "$report_output" || true
    rm -f "$report_output"
    exit 1
fi
rm -f "$report_output"
print_status "$GREEN" "✓ report --raw output matches golden snapshot"

# Test past --raw output
print_status "$YELLOW" "Testing past --raw output..."
past_output=$(mktemp)
focus past list --raw > "$past_output" 2>/dev/null || true

if ! diff -u tests/golden/past_today_raw.csv.golden "$past_output" >/dev/null; then
    print_status "$RED" "FAIL: past --raw output mismatch"
    print_status "$RED" "Diff:"
    diff -u tests/golden/past_today_raw.csv.golden "$past_output" || true
    rm -f "$past_output"
    exit 1
fi
rm -f "$past_output"
print_status "$GREEN" "✓ past --raw output matches golden snapshot"

print_status "$GREEN" "✅ All golden snapshot tests passed"
