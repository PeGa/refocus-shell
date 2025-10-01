#!/usr/bin/env bash
# Refocus Shell - Stop focus session command
# Copyright (C) 2025 PeGa
# Website: https://www.pega.sh
# Email: dev@pega.sh
# Licensed under the GNU General Public License v3

# Stop focus session command
# Session completion and notes collection
LIB_PATH="$(dirname "${BASH_SOURCE[0]}")"

source "$LIB_PATH/error_handling.sh"

# Prevent direct execution of this file.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    _error_invalid_invocation
fi


echo "Focus session stopped"