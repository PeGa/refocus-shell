#!/usr/bin/env bash
# Refocus Shell - Logger Utilities
# Copyright (C) 2025 PeGa
# Website: https://www.pega.sh
# Email: dev@pega.sh
# Licensed under the GNU General Public License v3

# Prevent direct execution of this file.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Error: This script is a library and should not be executed directly." >&2
    logger -t refocus -p user.err "[$$] Error: Attempted direct execution of logger.sh."
    exit 7
fi


logger_error() {
<<DOC
Logs error messages to system logger.
Takes single message argument and outputs to user.err facility.
DOC
    logger -t refocus -p user.err "[$$] Error: $1"
}

logger_warning() {
<<DOC
Logs warning messages to system logger.
Takes single message argument and outputs to user.warning facility.
DOC
    logger -t refocus -p user.warning "[$$] Warning: $1"
}

logger_info() {
<<DOC
Logs informational messages to system logger.
Takes single message argument and outputs to user.info facility.
DOC
    logger -t refocus -p user.info "[$$] Info: $1"
}

logger_debug() {
<<DOC
Logs debug messages to system logger.
Takes single message argument and outputs to user.debug facility.
DOC
    logger -t refocus -p user.debug "[$$] Debug: $1"
}
