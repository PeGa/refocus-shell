#!/usr/bin/env bash
# Refocus Shell - Configuration and environment setup
# Copyright (C) 2025 PeGa
# Website: https://www.pega.sh
# Email: dev@pega.sh
# Licensed under the GNU General Public License v3

# Configuration and environment setup
# Global variables and default settings

# Load error handling.
LIB_PATH="$(dirname "${BASH_SOURCE[0]}")/lib"
source "$LIB_PATH/error_handling.sh"

# --- Global Configuration Variables ---
# Application metadata
readonly APP_NAME="Refocus Shell"
readonly APP_VERSION="0.1.0"
readonly APP_HOME="$(dirname "$(dirname "${BASH_SOURCE[0]}")")"

# Database paths & table names
readonly DB_PATH="${HOME}/.local/refocus/refocus.db"
readonly REFOCUS_STATE_TABLE="refocus_state"
readonly SESSIONS_TABLE="sessions"
readonly PROJECTS_TABLE="projects"
readonly HISTORY_TABLE="session_history"
readonly NUDGES_TABLE="nudge_logs"

# Default intervals & settings
readonly DEFAULT_NUDGE_INTERVAL=3000      # seconds (50 minutes)
readonly DEFAULT_REPORT_PERIOD="today"    # today|week|month
readonly DATE_FORMAT="YYYY-MM-DD HH:MM:SS"
readonly LOG_LEVEL="INFO"                 # DEBUG, INFO, WARN, ERROR
readonly MAX_SESSION_DURATION=28800       # seconds (8 hours)
readonly NUDGE_ENABLED="false"

# CLI defaults
readonly CLI_PREFIX="focus"

# Prevent direct execution of this file.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    _error_invalid_invocation
fi
