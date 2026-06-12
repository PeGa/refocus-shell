#!/usr/bin/env bash
set -euo pipefail
source "$REFOCUS_ROOT/config.sh"
source "$REFOCUS_ROOT/services/database.sh"
source "$REFOCUS_ROOT/services/cron.sh"

file="${1:-}"
[[ -z "$file" ]]    && { echo "Usage: focus import <file.sql|file.json>" >&2; exit 2; }
[[ -f "$file" ]]    || { echo "❌ File not found: $file" >&2; exit 1; }

# Detect format
case "$file" in
    *.sql)  fmt=sql  ;;
    *.json) fmt=json ;;
    *)
        # Sniff content
        head -1 "$file" | grep -q "PRAGMA\|BEGIN\|CREATE\|INSERT" && fmt=sql || fmt=json
        ;;
esac

echo -n "⚠  Import will overwrite all data. Continue? (yes/N): "
read -r ans
[[ "$ans" == "yes" ]] || { echo "Cancelled."; exit 0; }

# Backup current DB if it exists
if [[ -f "$DB_PATH" ]]; then
    backup="${DB_PATH}.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$DB_PATH" "$backup"
    echo "   Backed up to: $backup"
fi

cron_remove 2>/dev/null || true

# ── SQL import ────────────────────────────────────────────────────────────────
if [[ "$fmt" == "sql" ]]; then
    rm -f "$DB_PATH"
    db_load_sql "$file"
    echo "✅ Imported from SQL: $file"
    exit 0
fi

# ── JSON import ───────────────────────────────────────────────────────────────
command -v jq &>/dev/null || { echo "❌ jq required for JSON import. Install it or use a .sql export." >&2; exit 1; }

rm -f "$DB_PATH"
db_init

# Sessions — full fidelity through the adapter. Older exports may carry a
# 'projects' array; it's from the dead model and is ignored on purpose.
jq -c '.sessions[]?' "$file" | while IFS= read -r row; do
    project=$(jq -r '.project'            <<< "$row")
    start=$(  jq -r '.start_time  // ""'  <<< "$row")
    end=$(    jq -r '.end_time    // ""'  <<< "$row")
    dur=$(    jq -r '.duration_seconds'   <<< "$row")
    notes=$(  jq -r '.notes       // ""'  <<< "$row")
    donly=$(  jq -r '.duration_only // 0' <<< "$row")
    sdate=$(  jq -r '.session_date // ""' <<< "$row")
    db_import_session_row "$project" "$start" "$end" "$dur" "$notes" "$donly" "$sdate"
done

echo "✅ Imported from JSON: $file"
