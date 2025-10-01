#!/usr/bin/env bash
# Refocus Shell - Error Handling Utilities
# Copyright (C) 2025 PeGa
# Website: https://www.pega.sh
# Email: dev@pega.sh
# Licensed under the GNU General Public License v3


logger_error() {
    logger -t refocus -p user.err "[$$] Error: $1"
}

logger_warning() {
    logger -t refocus -p user.warning "[$$] Warning: $1"
}

logger_info() {
    logger -t refocus -p user.info "[$$] Info: $1"
}

logger_debug() {
    logger -t refocus -p user.debug "[$$] Debug: $1"
}
