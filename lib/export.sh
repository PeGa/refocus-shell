#!/usr/bin/env bash
set -euo pipefail
source "$REFOCUS_ROOT/env.sh"
source "$REFOCUS_ROOT/services/database.sh"
source "$REFOCUS_ROOT/core/time.sh"
source "$REFOCUS_ROOT/services/help.sh"

wants_help "$@" && show_help export

db_ensure

timestamp=$(date +%Y%m%d_%H%M%S)
base="${1:-refocus-export-$timestamp}"
sql_file="${base}.sql"
json_file="${base}.json"

# ── SQL dump ──────────────────────────────────────────────────────────────────
db_dump_sql > "$sql_file"
echo "✅ SQL:  $sql_file"

# ── JSON export ───────────────────────────────────────────────────────────────
{
    echo "{"
    echo "  \"exported_at\": \"$(now_iso)\","
    echo "  \"db_path\": \"$DB_PATH\","
    echo "  \"state\":"
    db_export_state_json
    echo ","
    echo "  \"sessions\":"
    db_export_sessions_json
    echo "}"
} > "$json_file"

echo "✅ JSON: $json_file"
