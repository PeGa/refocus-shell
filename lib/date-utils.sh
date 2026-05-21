#!/usr/bin/env bash
# Refocus Shell - Shared date utilities
# Lightweight, stateless, import anywhere
# Provides timestamp/date utilities for cross-file consistency
#
# Usage:
#   source lib/date-utils.sh
#   get_timestamp          # or use custom: get_timestamp "$1"
#   get_date               # or use custom: get_date "$1"
#

# Load error handling.
LIB_PATH="$(dirname "${BASH_SOURCE[0]}")"
source "$LIB_PATH/error_handling.sh"

# Prevent direct execution of this file.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    _error_invalid_invocation
fi

# Default date commands (overridable, but not editable)
: "${date_cmd:='date -Iseconds'}"
: "${date_short:='date +%Y-%m-%d'}"

# Get timestamp (with optional override)
get_timestamp() {
    local ts="$1"
    [[ -n "$ts" ]] && echo "$ts" || echo "$date_cmd"
}

# Get date only (YYYY-MM-DD format, with optional override)
get_date() {
    local d="$1"
    [[ -n "$d" ]] && echo "$d" || echo "$date_short"
}

# Execute a command with timestamp
ts_execute() {
    get_timestamp "$1"
}

# Execute a command with date  
d_execute() {
    get_date "$1"
}
