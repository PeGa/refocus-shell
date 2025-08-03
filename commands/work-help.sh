#!/usr/bin/env bash
# Refocus Shell - Help Subcommand
# Copyright (c) 2025 PeGa
# Licensed under the GNU General Public License v3

function work_help() {
    echo "Refocus Shell - Time Tracking Tool"
    echo "================================"
    echo
    echo "Basic Commands:"
    echo "  work on [project]     - Start working on a project"
    echo "  work off              - Stop current work session"
    echo "  work status           - Show current work status"
    echo
    echo "Management Commands:"
    echo "  work enable           - Enable refocus shell"
    echo "  work disable          - Disable refocus shell"
    echo "  work reset            - Reset all work data"
    echo "  work init             - Initialize database"
    echo
    echo "Data Commands:"
    echo "  work export [file]    - Export work data to SQLite dump"
echo "  work import <file>    - Import work data from SQLite dump"
    echo
    echo "Past Sessions:"
    echo "  work past add <project> <start> <end>  - Add past session"
    echo "  work past modify <id> [project] [start] [end] - Modify session"
    echo "  work past delete <id>                  - Delete session"
    echo "  work past list [limit]                 - List recent sessions"
    echo
    echo "Reports:"
    echo "  work report today     - Today's work report"
    echo "  work report week      - This week's work report"
    echo "  work report month     - This month's work report"
    echo "  work report custom <days> - Custom period report"
    echo
    echo "Utility Commands:"
    echo "  work test-nudge       - Test notifications"
    echo "  work config           - Manage configuration"
    echo "  work help             - Show this help"
    echo
    echo "Examples:"
    echo "  work on 'coding'      - Start working on 'coding' project"
    echo "  work off              - Stop current work session"
    echo "  work status           - Check current status"
    echo "  work report today     - See today's work summary"
    echo "  work past add meeting 2025/07/30-14:15 2025/07/30-15:30  # Specific date"
    echo "  work past add meeting 14:15 15:30                          # Today's date"
    echo "  work config show      - Show current configuration"
    echo "  work config set VERBOSE true - Enable verbose mode"
    echo
    echo "💡 Tip: Use YYYY/MM/DD-HH:MM format for easy, quote-free dates!"
    echo
    echo "For more detailed help on specific commands, run:"
    echo "  work <command> --help"
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    work_help "$@"
fi 