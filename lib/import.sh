#!/usr/bin/env bash
set -euo pipefail
source "$REFOCUS_ROOT/env.sh"
source "$REFOCUS_ROOT/services/database.sh"
source "$REFOCUS_ROOT/services/cron.sh"
source "$REFOCUS_ROOT/services/help.sh"

wants_help "$@" && show_help import

file="${1:-}"
[[ -z "$file" ]]    && usage_error import
[[ -f "$file" ]]    || { echo "❌ File not found: $file" >&2; exit 1; }

# Detect format
case "$file" in
    *.sql)  fmt=sql  ;;
    *.json) fmt=json ;;
    *)
        head -1 "$file" | grep -q "PRAGMA\|BEGIN\|CREATE\|INSERT" && fmt=sql || fmt=json
        ;;
esac

# Warn if a session is in flight
db_ensure
if is_session_active; then
    IFS='|' read -r _ project _ <<< "$(get_state)"
    echo "⚠  Active session '$project' will be discarded."
elif is_session_paused; then
    IFS='|' read -r _ project _ <<< "$(get_state)"
    echo "⚠  Paused session '$project' will be discarded."
fi

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
    # State is runtime — normalize to idle+disabled regardless of what was exported.
    reset_state_post_import
    echo "✅ Imported from SQL: $file"
    echo "   Run 'focus enable' to resume tracking."
    exit 0
fi

# ── JSON import ───────────────────────────────────────────────────────────────
command -v jq &>/dev/null || { echo "❌ jq required for JSON import. Install it or use a .sql export." >&2; exit 1; }

rm -f "$DB_PATH"
db_init

# Sessions — verbatim, full fidelity. Older exports may carry a 'projects' array;
# that's from the dead model and silently ignored by the '[]?' optional iterator.
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

# Normalize state — db_init defaults focus_disabled=0; set it to 1 explicitly.
reset_state_post_import
echo "✅ Imported from JSON: $file"
echo "   Run 'focus enable' to resume tracking."
