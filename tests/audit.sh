#!/usr/bin/env bash
# Refocus Shell - Static analysis wrapper
#
# Usage: tests/audit.sh [root-dir]
#   root-dir defaults to the repo root (one level up from this script)
#
# Runs shellcheck -x on every shell script with:
#   - LC_ALL=C.UTF-8 so multi-byte glyphs don't crash shellcheck's output encoder
#   - SC1090/SC1091 suppressed globally: lib/ handlers source $REFOCUS_ROOT/*
#     which is a genuinely dynamic path; shellcheck cannot follow it and the
#     warnings add no signal.
#
# Exit 0 = clean. Exit 1 = findings. Non-zero from any individual file counts.

set -euo pipefail
export LC_ALL=C.UTF-8 LANG=C.UTF-8

ROOT="${1:-$(dirname "$(realpath "${BASH_SOURCE[0]}")")/../}"
cd "$ROOT"

TARGETS=(
    focus
    focus-nudge
    config.sh
    setup.sh
    core/*.sh
    lib/*.sh
    services/*.sh
)

fail=0
for f in "${TARGETS[@]}"; do
    [[ -f "$f" ]] || continue
    if shellcheck -x -e SC1090,SC1091 "$f"; then
        echo "  ok  $f"
    else
        fail=1
    fi
done

if [[ $fail -eq 0 ]]; then
    echo "✅ shellcheck: all clean"
else
    echo "❌ shellcheck: findings above" >&2
fi

exit $fail
