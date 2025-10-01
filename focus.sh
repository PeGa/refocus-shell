#!/usr/bin/env bash
# Refocus Shell - Main entry point
# Copyright (C) 2025 PeGa
# Website: https://www.pega.sh
# Email: dev@pega.sh
# Licensed under the GNU General Public License v3

# Main entry point for refocus shell
# Command dispatcher and argument parser
case "$1" in
    on)
        exec "$(dirname "$0")/lib/on.sh" "$2"
        ;;
    *)
        echo "Unknown command: $1"
        exit 1
        ;;
esac