#!/usr/bin/env bash
# Refocus Shell - Start focus session command
# Copyright (C) 2025 PeGa
# Website: https://www.pega.sh
# Email: dev@pega.sh
# Licensed under the GNU General Public License v3

# Start focus session command
# Project validation and session creation
LIB_PATH="$(dirname "${BASH_SOURCE[0]}")"

source "$LIB_PATH/error_handling.sh"

if [ "$#" -ne 1 ]; then
    _error_invalid_argument "session name" 1 $#
fi
SESSION_NAME="$1"
echo "$SESSION_NAME"