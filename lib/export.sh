#!/usr/bin/env bash
set -euo pipefail
source "$REFOCUS_ROOT/config.sh"
source "$REFOCUS_ROOT/services/database.sh"

db_ensure

timestamp=$(date +%Y%m%d_%H%M%S)
base="${1:-refocus-export-$timestamp}"
sql_file="${base}.sql"
json_file="${base}.json"

# ── SQL dump ──────────────────────────────────────────────────────────────────
sqlite3 "$DB_PATH" .dump > "$sql_file"
echo "✅ SQL:  $sql_file"

# ── JSON export ───────────────────────────────────────────────────────────────
# sqlite3 -json available since 3.33 (2020). Ubuntu 24 ships 3.45. Safe.
{
    echo "{"
    echo "  \"exported_at\": \"$(date -Iseconds)\","
    echo "  \"db_path\": \"$DB_PATH\","

    echo "  \"state\":"
    sqlite3 -json "$DB_PATH" "SELECT * FROM state WHERE id=1;" \
        | tr -d '\n' | sed 's/^\[//;s/\]$//'
    echo ","

    echo "  \"sessions\":"
    result=$(sqlite3 -json "$DB_PATH" "SELECT * FROM sessions ORDER BY id;")
    echo "${result:-[]}"
    echo ","

    echo "  \"projects\":"
    result=$(sqlite3 -json "$DB_PATH" "SELECT * FROM projects ORDER BY name;")
    echo "${result:-[]}"
    echo "}"
} > "$json_file"

echo "✅ JSON: $json_file"
