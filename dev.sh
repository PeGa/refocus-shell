#!/usr/bin/env bash
set -euo pipefail

# Refocus Shell - Development Tools
# Copyright (c) 2025 PeGa
# Licensed under the GNU General Public License v3

# Function to run smoke test for prompt cache integration
smoke() {
    echo "Running smoke test for prompt cache integration..."
    
    # Clean up any existing test directories
    rm -rf ~/.local/refocus/test-*
    
    # Create temporary state directory
    export REFOCUS_STATE_DIR="$(mktemp -d -t refocus-smoke-XXXX)"
    echo "Using test state directory: $REFOCUS_STATE_DIR"
    
    # Test focus on command
    ./focus on demo "cache test"
    
    # Verify prompt.cache was created
    test -f "$REFOCUS_STATE_DIR/prompt.cache"
    
    # Verify initial cache content
    grep -q '^on|demo|0$' "$REFOCUS_STATE_DIR/prompt.cache"
    
    # Test focus status command
    ./focus status
    
    # Verify cache was updated (minutes may have changed)
    grep -q '^on|demo|' "$REFOCUS_STATE_DIR/prompt.cache"
    
    # Test focus off command
    echo "done" | ./focus off
    
    # Verify final cache content
    grep -q '^off|-|-$' "$REFOCUS_STATE_DIR/prompt.cache"
    
    echo "OK"
}

# Function to run shellcheck on shell scripts
lint() {
    echo "Running shellcheck on shell scripts..."
    
    # Check main focus script
    shellcheck ./focus
    
    # Check all command scripts
    shellcheck ./commands/*.sh
    
    # Check all library scripts
    shellcheck ./lib/*.sh
    
    echo "Shellcheck completed successfully"
}

# Main script logic
case "${1:-}" in
    smoke)
        smoke
        ;;
    lint)
        lint
        ;;
    *)
        echo "Usage: $0 {smoke|lint}"
        echo ""
        echo "Commands:"
        echo "  smoke  - Run smoke test for prompt cache integration"
        echo "  lint   - Run shellcheck on all shell scripts"
        exit 1
        ;;
esac
