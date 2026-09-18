#!/usr/bin/env bash
set -euo pipefail
source "$REFOCUS_ROOT/env.sh"
source "$REFOCUS_ROOT/services/database.sh"
source "$REFOCUS_ROOT/core/time.sh"
source "$REFOCUS_ROOT/services/help.sh"

wants_help "$@" && show_help export

db_ensure

_json_escape() {
    # Minimal string escaper for the hand-built JSON header below — db_path
    # is a filesystem path the user configured, not app-generated data, so
    # unlike exported_at (algorithmic, no special characters) it needs
    # escaping before going inside a quoted JSON string. Backslash first, so
    # later substitutions' own backslashes are never re-escaped.
    local str="$1"
    str="${str//\\/\\\\}"
    str="${str//\"/\\\"}"
    str="${str//$'\n'/\\n}"
    str="${str//$'\r'/\\r}"
    str="${str//$'\t'/\\t}"
    printf '%s' "$str"
}

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
    echo "  \"db_path\": \"$(_json_escape "$DB_PATH")\","
    echo "  \"state\":"
    db_export_state_json
    echo ","
    echo "  \"sessions\":"
    db_export_sessions_json
    echo "}"
} > "$json_file"

echo "✅ JSON: $json_file"
