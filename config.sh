#!/usr/bin/env bash
# Refocus Shell - Configuration and environment setup
# Copyright (C) 2025 PeGa
# Website: https://www.pega.sh
# Email: dev@pega.sh
# Licensed under the GNU General Public License v3

# Configuration and environment setup
# Global variables and default settings

# Load error handling.
LIB_PATH="$(dirname "${BASH_SOURCE[0]}")"

source "$LIB_PATH/error_handling.sh"

# Prevent direct execution of this file.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    _error_invalid_invocation
fi
