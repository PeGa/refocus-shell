#!/usr/bin/env bash
set -euo pipefail
source "$REFOCUS_ROOT/config.sh"
source "$REFOCUS_ROOT/services/database.sh"
db_ensure
db_flip_flag focus_disabled 0
echo "✅ Refocus enabled."
