#!/usr/bin/env bash
# Refocus Shell - Error Handling Utilities
# Copyright (C) 2025 PeGa
# Website: https://www.pega.sh
# Email: dev@pega.sh
# Licensed under the GNU General Public License v3

# Load logger.
LIB_PATH="$(dirname "${BASH_SOURCE[0]}")"
source "$LIB_PATH/logger.sh"

# Prevent this file from being sourced or executed without parameters.
if [ "$#" -eq 0 ]; then
    echo "Error: This file cannot be executed without parameters." >&2
    logger_error "Illegal error handling file execution."
    exit 2
fi


_error_invalid_argument() {
    # This function expects three arguments:
    # '$1': Total arguments received(string)"
    # '$2': Expected number of arguments(integer)"
    # '$3': Number of arguments received(integer)"

    echo "Error: Received $1. Invalid number of arguments. Expected $2, got $3."
    logger_error "$1: Invalid argument error"
    logger_error "Expected $2, got $3."
    exit 2
}