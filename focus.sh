#!/usr/bin/env bash
# Refocus Shell - Main CLI Entry Point
# Copyright (C) 2025 PeGa
# Website: https://www.pega.sh
# Email: dev@pega.sh
# Licensed under the GNU General Public License v3

set -euo pipefail

# ===========================
# Configuration
# ===========================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"
source "$SCRIPT_DIR/services/database.sh"

# ===========================
# Command Dispatcher
# ===========================

usage() {
    cat << 'EOF'
ReFocus Shell - A lightweight CLI for managing focus sessions

Usage: focus <command> [arguments]

Commands:
  on "project"       Start a focus session
  off                Stop current session (capture notes)
  pause              Pause current session
  continue           Resume paused session
  status             Show current session status
  past list          List all sessions
  past add "proj" "start" "end"  Add a past session
  report [today|week|month]   Generate report
  export             Export data to JSON/SQLite
  import <file>      Import from backup

Examples:
  focus on "coding"              # Start tracking
  focus off "debugging auth"     # Stop with notes
  focus status                   # Check progress
  focus report today             # Daily summary

EOF
}

case "${1:-}" in
    on|off|pause|continue|status|past|report|export|import|nudge|config)
        shift
        "$SCRIPT_DIR/lib/$1.sh" "$@"
        ;;
    help|--help|-h|"")
        usage
        exit 0
        ;;
    *)
        echo "Unknown command: $1" >&2
        echo "Run 'focus help' for usage." >&2
        exit 2
        ;;
esac