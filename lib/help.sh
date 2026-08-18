#!/usr/bin/env bash
# Help dispatcher. All text lives in docs/help/<cmd>.txt — single source of
# truth, also addressable directly by path. 'focus help' shows the index.
# Resolution itself lives in services/help.sh, so usage errors in every other
# handler render exactly this same text.
set -euo pipefail
source "$REFOCUS_ROOT/services/help.sh"

topic="${1:-global}"
# `focus help --help` asks about help itself, not for a topic named "--help".
case "$topic" in
    -h|--help) topic="help" ;;
esac

show_help "$topic"
