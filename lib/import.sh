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
    sqlite3 "$DB_PATH" < "$file"
    echo "✅ Imported from SQL: $file"
    exit 0
fi

# ── JSON import ───────────────────────────────────────────────────────────────
command -v jq &>/dev/null || { echo "❌ jq required for JSON import. Install it or use a .sql export." >&2; exit 1; }

rm -f "$DB_PATH"
db_init

# Sessions
jq -c '.sessions[]?' "$file" | while IFS= read -r row; do
    project=$(jq -r '.project'          <<< "$row")
    start=$(  jq -r '.start_time  // ""' <<< "$row")
    end=$(    jq -r '.end_time    // ""' <<< "$row")
    dur=$(    jq -r '.duration_seconds'  <<< "$row")
    notes=$(  jq -r '.notes       // ""' <<< "$row")
    donly=$(  jq -r '.duration_only // 0' <<< "$row")
    sdate=$(  jq -r '.session_date // ""' <<< "$row")

    sqlite3 "$DB_PATH" "INSERT INTO sessions
        (project, start_time, end_time, duration_seconds, notes, duration_only, session_date)
        VALUES ('$(_q "$project")',
                $([ -n "$start" ] && echo "'$(_q "$start")'" || echo "NULL"),
                $([ -n "$end"   ] && echo "'$(_q "$end")'"   || echo "NULL"),
                $dur,
                '$(_q "$notes")',
                $donly,
                $([ -n "$sdate" ] && echo "'$(_q "$sdate")'" || echo "NULL"));"
done

# Projects
jq -c '.projects[]?' "$file" | while IFS= read -r row; do
    name=$(jq -r '.name'        <<< "$row")
    desc=$(jq -r '.description' <<< "$row")
    cat=$(jq -r '.created_at'   <<< "$row")
    sqlite3 "$DB_PATH" "INSERT OR REPLACE INTO projects (name, description, created_at)
        VALUES ('$(_q "$name")', '$(_q "$desc")', '$(_q "$cat")');"
done

echo "✅ Imported from JSON: $file"
