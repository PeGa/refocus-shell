#!/usr/bin/env bash
set -euo pipefail
source "$REFOCUS_ROOT/env.sh"
source "$REFOCUS_ROOT/services/database.sh"
source "$REFOCUS_ROOT/services/help.sh"

wants_help "$@" && show_help init
db_init
echo "✅ Database initialised at $DB_PATH"
