#!/usr/bin/env bash
set -euo pipefail

REFOCUS_ROOT="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
export REFOCUS_ROOT
source "$REFOCUS_ROOT/config.sh"

cmd="${1:-help}"
shift || true

lib="$REFOCUS_ROOT/lib/${cmd}.sh"
[[ -x "$lib" ]] || { echo "❌ Unknown command: $cmd" >&2; exit 2; }
exec "$lib" "$@"
