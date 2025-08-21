#!/usr/bin/env bash
# Refocus Shell - Help Subcommand
# Copyright (c) 2025 PeGa
# Licensed under the GNU General Public License v3

function focus_help() {
    echo "Refocus Shell - Time Tracking Tool"
    echo "================================"
    echo
    echo "Basic Commands:"
    echo "  focus on [project]     - Start focusing on a project"
    echo "  focus off              - Stop current focus session (will ask for session notes)"
    echo "  focus status           - Show current focus status"
    echo
    echo "Management Commands:"
    echo "  focus enable           - Enable refocus shell"
    echo "  focus disable          - Disable refocus shell"
    echo "  focus reset            - Reset all focus data"
    echo "  focus init             - Initialize database"
    echo
    echo "Data Commands:"
        echo "  focus export [file]    - Export focus data to SQLite dump"
    echo "  focus import <file>    - Import focus data from SQLite dump"
    echo
    echo "Past Sessions:"
    echo "  focus past add <project> <start> <end>  - Add past session (will ask for session notes)"
    echo "  focus past modify <id> [project] [start] [end] - Modify session"
    echo "  focus past delete <id>                  - Delete session"
    echo "  focus past list [limit]                 - List recent sessions"
    echo
    echo "Session Notes:"
    echo "  focus notes add <project>               - Add notes to recent session for a project"
    echo
    echo "Nudging:"
    echo "  focus nudge enable                     - Enable focus reminders (real-time, session-based)"
    echo "  focus nudge disable                    - Disable focus reminders"
    echo "  focus nudge status                     - Show nudging status and next reminder time"
    echo "  focus nudge test                       - Test the notification system"
    echo
    echo "Reports:"
    echo "  focus report today     - Today's focus report"
    echo "  focus report week      - This week's focus report"
    echo "  focus report month     - This month's focus report"
    echo "  focus report custom <days> - Custom period report"
    echo
    echo "Utility Commands:"
    echo "  focus test-nudge       - Test notifications"
    echo "  focus config           - Manage configuration"
    echo "  focus description      - Manage project descriptions"
    echo "  focus help             - Show this help"
    echo
    echo "Examples:"
    echo "  focus on 'coding'      - Start focusing on 'coding' project"
    echo "  focus off              - Stop current focus session"
    echo "  focus status           - Check current status"
    echo "  focus report today     - See today's focus summary"
    echo "  focus past add meeting 2025/07/30-14:15 2025/07/30-15:30  # Specific date"
    echo "  focus past add meeting 14:15 15:30                          # Today's date"
    echo "  focus config show      - Show current configuration"
    echo "  focus config set VERBOSE true - Enable verbose mode"
    echo "  focus description add coding \"Main development project\"      # Add project description"
    echo "  focus description show coding                               # View project description"
    echo
    echo "💡 Tip: Use YYYY/MM/DD-HH:MM format for easy, quote-free dates!"
    echo
    echo "For more detailed help on specific commands, run:"
    echo "  focus <command> --help"
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    focus_help "$@"
fi 