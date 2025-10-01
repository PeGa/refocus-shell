#!/usr/bin/env bash
# Refocus Shell - Error Handling Utilities
# Copyright (C) 2025 PeGa
# Website: https://www.pega.sh
# Email: dev@pega.sh
# Licensed under the GNU General Public License v3


# exit codes
# 0   success
# 1   generic error
# 2   bad arguments
# 3   missing dependency
# 4   database error
# 5   config error
# 6   runtime/session error
# 7   invalid invocation

# Load logger.
LIB_PATH="$(dirname "${BASH_SOURCE[0]}")"
source "$LIB_PATH/logger.sh"


_error_invalid_invocation() {
    echo "Error: This script is a library and should not be executed directly." >&2
    logger_error "Attempted direct execution of error_handling.sh."
    exit 7
}

# Prevent direct execution of this file.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    _error_invalid_invocation
fi


_error_invalid_argument() {
    # This function expects three arguments:
    # '$1': Expected number of arguments(integer)"
    # '$2': Number of arguments received(integer)"
    # '$3': Total arguments received(string)"

    echo "[Error] Received:" "$3"
    echo "        Invalid number of arguments."
    echo "        Expected $1, got $2."
    logger_error "$3: Invalid argument error"
    logger_error "Expected $1, got $2."
    exit 2
}