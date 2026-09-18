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
read -r ans || true
[[ "$ans" == "yes" ]] || { echo "Cancelled."; exit 0; }

# Backup current DB if it exists
if [[ -f "$DB_PATH" ]]; then
    backup="${DB_PATH}.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$DB_PATH" "$backup"
    echo "   Backed up to: $backup"
fi

cron_remove 2>/dev/null || true
cron_checkin_remove 2>/dev/null || true

# The new database is built beside the live one and swapped in only once it is
# complete. Import used to delete first and discover whether the input was
# usable afterwards: unparseable JSON, or a dump truncated by an interrupted
# export or a full disk, left no working database at all — and since a file
# still existed, db_ensure took it for one and every later command died on
# "no such table: sessions". Nothing is removed until the replacement stands
# up, so a bad file now costs nothing but the error message.
live_db="$DB_PATH"
incoming="${live_db}.incoming.$$"
rm -f "$incoming"
trap 'rm -f "$incoming"' EXIT
DB_PATH="$incoming"

_swap_in() {
    # Refuse to install anything that isn't a complete database, whatever the
    # loader thought of it.
    if ! is_schema_present; then
        echo "❌ Import produced no usable database — $file is incomplete or not a refocus export." >&2
        echo "   Nothing was changed; your data is untouched." >&2
        exit 1
    fi
    DB_PATH="$live_db"
    mv "$incoming" "$live_db"
    trap - EXIT
}

# ── SQL import ────────────────────────────────────────────────────────────────
if [[ "$fmt" == "sql" ]]; then
    db_load_sql "$file" || {
        echo "❌ Could not load SQL from: $file" >&2
        echo "   Nothing was changed; your data is untouched." >&2
        exit 1
    }
    # State is runtime — normalize to idle+disabled regardless of what was exported.
    reset_state_post_import
    _swap_in
    echo "✅ Imported from SQL: $file"
    echo "   Run 'focus enable' to resume tracking."
    exit 0
fi

# ── JSON import ───────────────────────────────────────────────────────────────
command -v jq &>/dev/null || { echo "❌ jq required for JSON import. Install it or use a .sql export." >&2; exit 1; }

# Parse before building anything: jq's own error is the clearest description of
# a broken file, and reporting it here costs the user nothing.
jq empty "$file" 2>/dev/null || {
    echo "❌ Not valid JSON: $file" >&2
    # jq's own message names the line and column; `|| true` because this
    # pipeline is expected to fail — under pipefail its status would otherwise
    # become the script's, and jq's exit 5 would escape instead of the 1 that
    # CONV-EXIT calls for.
    jq empty "$file" 2>&1 | sed 's/^/   /' >&2 || true
    echo "   Nothing was changed; your data is untouched." >&2
    exit 1
}

# A refocus JSON import always carries a top-level "sessions" array — a real
# export always has one, and a hand-built minimal file only needs one. {},
# [], or an unrelated JSON document have no such key, but `.sessions[]?`
# below iterates zero times for any of them silently, which looks identical
# to importing a real, empty history [CONV-ABSENT].
jq -e 'type == "object" and has("sessions") and (.sessions | type == "array")' \
    "$file" >/dev/null 2>&1 || {
    echo "❌ Not a refocus JSON export: $file" >&2
    echo "   Expected a top-level \"sessions\" array; found something else." >&2
    echo "   Nothing was changed; your data is untouched." >&2
    exit 1
}

db_init

# Sessions — verbatim, full fidelity. Older exports may carry a 'projects' array;
# that's from the dead model and silently ignored by the '[]?' optional iterator.
#
# Two tiers, split by representability, not weirdness [CONV-ABSENT]: content
# the app *could* have written is accepted and sanitised per row ('|' → '¦',
# newlines folded — the same boundary discipline every write path applies);
# a shape no app write path can produce aborts the WHOLE import before the
# swap — fail early, name the row, write nothing. The loop runs in the main
# shell (process substitution, not a pipe) precisely so that refusal can exit.
import_row_num=0
_bad_import_row() {
    echo "❌ Row $import_row_num (project '$project'): $1" >&2
    echo "   Import refused — nothing was changed; your data is untouched." >&2
    echo "   Fix the row in the file, or restore the .sql export instead." >&2
    exit 1
}
while IFS= read -r row; do
    import_row_num=$(( import_row_num + 1 ))
    project=$(jq -r '.project'            <<< "$row")
    project=$(sanitize_pipe "$project")
    # db_import_session_row skips _validate_project_name on purpose, but the
    # DB's own CHECK constraint still rejects a newline/CR — which would take
    # down every row after it. Fold them here, same as '|' above.
    project="${project//$'\n'/ }"
    project="${project//$'\r'/ }"
    start=$(  jq -r '.start_time  // ""'  <<< "$row")
    end=$(    jq -r '.end_time    // ""'  <<< "$row")
    dur=$(    jq -r '.duration_seconds'   <<< "$row")
    notes=$(  jq -r '.notes       // ""'  <<< "$row")
    donly=$(  jq -r '.duration_only // 0' <<< "$row")
    sdate=$(  jq -r '.session_date // ""' <<< "$row")

    [[ "$donly" == "0" || "$donly" == "1" ]] \
        || _bad_import_row "duration_only is '$donly' (want 0 or 1)"
    [[ "$dur" =~ ^[0-9]+$ ]] \
        || _bad_import_row "duration_seconds is '$dur' (want a non-negative integer)"
    if [[ "$donly" == "1" ]]; then
        [[ "$sdate" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] \
            || _bad_import_row "duration-only but session_date is '$sdate' (want YYYY-MM-DD)"
    else
        [[ -n "$start" && -n "$end" ]] \
            || _bad_import_row "timestamped row with no timestamps"
    fi

    db_import_session_row "$project" "$start" "$end" "$dur" "$notes" "$donly" "$sdate"
done < <(jq -c '.sessions[]?' "$file")

# Normalize state — db_init defaults focus_disabled=0; set it to 1 explicitly.
reset_state_post_import
_swap_in
echo "✅ Imported from JSON: $file"
echo "   Run 'focus enable' to resume tracking."
