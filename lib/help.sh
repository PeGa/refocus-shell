#!/usr/bin/env bash
# Help dispatcher. All text lives in docs/help/<cmd>.txt — single source of
# truth, also addressable directly by path. 'focus help' shows the index.
set -euo pipefail

cmd="${1:-global}"
doc="$REFOCUS_ROOT/docs/help/${cmd}.txt"

if [[ -f "$doc" ]]; then
    cat "$doc"
else
    echo "No help for: $cmd" >&2
    echo "Run 'focus help' for the command list." >&2
    exit 2
fi
