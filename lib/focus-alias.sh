#!/usr/bin/env bash
# Refocus Shell - Safe Alias Implementation (Legacy Stub)
# Copyright (c) 2025 PeGa
# Licensed under the GNU General Public License v3

# This file is maintained for backward compatibility
# The focus-safe function and prompt functions have been moved to focus-function.sh

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Legacy focus-safe function (deprecated - use focus-function.sh instead)
focus-safe() {
    echo "⚠️  focus-safe is deprecated. Please use focus-function.sh instead." >&2
    return 1
}

# Export the function for backward compatibility
export -f focus-safe

# Note: This file is maintained for backward compatibility only.
# All active functionality has been moved to focus-function.sh