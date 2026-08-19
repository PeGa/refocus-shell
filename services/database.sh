#!/usr/bin/env bash
# Refocus Shell - Database adapter (secondary adapter / port implementation)
#
# This is the ONLY file that speaks SQL. The rest of the app talks to it
# through domain-intent functions: callers say *what*, the adapter handles *how*.
#
# Naming contract:
#   db_*   → strict storage-mechanism ops only: schema lifecycle (init/migrate/
#            ensure) and serialization (dump/export/import). These are about the
#            database-as-artifact, not the domain.
#   else   → domain-intent verbs (start_session, is_session_active, get_state...).
#            A caller flipping focus state calls set_focus_disabled(), never a
#            db_* function. It must not know or care which column moves.

# ── Internal engine ──────────────────────────────────────────────────────────

_q() {
    # Escape single quotes for SQL literals.
    printf '%s' "${1//\'/\'\'}"
}

_exec() {
    # Fire-and-forget write. Dies loud on error.
    sqlite3 "$DB_PATH" "$1" || { echo "❌ DB write failed" >&2; return 1; }
}

_query() {
    # Read query; outputs pipe-separated rows to stdout.
    sqlite3 -separator '|' "$DB_PATH" "$1"
}

_validate_project_name() {
    # Every session read is pipe-separated (_query -separator '|') and every
    # caller splits on it (IFS='|' read); a project name carrying '|' or a
    # newline desyncs every field after it. Called by every write path that
    # takes a project name from a user-controlled arg. db_import_session_row
    # is exempt on purpose: it is documented as a verbatim reconstruction
    # path, and guarding it would abort an import partway through.
    case "$1" in
        *'|'*|*$'\n'*|*$'\r'*)
            echo "❌ Invalid character in project name." >&2
            echo "   Project names cannot contain: | (pipe), newline, carriage return" >&2
            return 2 ;;
    esac
}

# ── Schema lifecycle (db_*: storage-mechanism) ───────────────────────────────

db_init() {
    mkdir -p "$(dirname "$DB_PATH")"
    _exec "
        CREATE TABLE IF NOT EXISTS state (
            id               INTEGER PRIMARY KEY CHECK (id = 1),
            active           INTEGER NOT NULL DEFAULT 0,
            project          TEXT,
            start_time       TEXT,
            paused           INTEGER NOT NULL DEFAULT 0,
            pause_start_time TEXT,
            previous_elapsed INTEGER NOT NULL DEFAULT 0,
            focus_disabled   INTEGER NOT NULL DEFAULT 0,
            last_off_time    TEXT
        );
        CREATE TABLE IF NOT EXISTS sessions (
            id               INTEGER PRIMARY KEY AUTOINCREMENT,
            project          TEXT NOT NULL,
            start_time       TEXT,
            end_time         TEXT,
            duration_seconds INTEGER NOT NULL,
            notes            TEXT,
            duration_only    INTEGER NOT NULL DEFAULT 0,
            session_date     TEXT
        );
        INSERT OR IGNORE INTO state (id) VALUES (1);
    "
}

db_migrate() {
    # Idempotent: brings older schema forward. Additive only — never drops.
    local scols
    scols=$(sqlite3 "$DB_PATH" "PRAGMA table_info(sessions);" | awk -F'|' '{print $2}')
    echo "$scols" | grep -q "^notes$"         || _exec "ALTER TABLE sessions ADD COLUMN notes         TEXT;"
    echo "$scols" | grep -q "^duration_only$" || _exec "ALTER TABLE sessions ADD COLUMN duration_only INTEGER NOT NULL DEFAULT 0;"
    echo "$scols" | grep -q "^session_date$"  || _exec "ALTER TABLE sessions ADD COLUMN session_date  TEXT;"
    # pause_notes, nudging_enabled: removed from model; stale columns in old DBs are harmless.
}

db_ensure() {
    [[ -f "$DB_PATH" ]] || db_init
    db_migrate
}

# ── State: reads ─────────────────────────────────────────────────────────────

get_state() {
    # Outputs: active|project|start_time|paused|pause_start_time|previous_elapsed|focus_disabled|last_off_time
    _query "SELECT active, COALESCE(project,''), COALESCE(start_time,''),
                   paused, COALESCE(pause_start_time,''),
                   previous_elapsed, focus_disabled,
                   COALESCE(last_off_time,'')
            FROM state WHERE id=1;"
}

is_session_active()  { [[ "$(_query "SELECT active         FROM state WHERE id=1;")" == "1" ]]; }
is_session_paused()  { [[ "$(_query "SELECT paused         FROM state WHERE id=1;")" == "1" ]]; }
is_focus_disabled()  { [[ "$(_query "SELECT focus_disabled FROM state WHERE id=1;")" == "1" ]]; }

# ── State: writes ────────────────────────────────────────────────────────────

set_focus_enabled() {
    _exec "UPDATE state SET focus_disabled=0 WHERE id=1;"
}

set_focus_disabled() {
    _exec "UPDATE state SET focus_disabled=1 WHERE id=1;"
}

start_session() {
    local project="$1" start_time="$2"
    _validate_project_name "$project" || return 2
    _exec "UPDATE state SET
        active=1, project='$(_q "$project")', start_time='$(_q "$start_time")',
        paused=0, pause_start_time=NULL, previous_elapsed=0
        WHERE id=1;"
}

end_session() {
    local now="$1"
    _exec "UPDATE state SET
        active=0, project=NULL, start_time=NULL,
        paused=0, pause_start_time=NULL, previous_elapsed=0,
        last_off_time='$(_q "$now")'
        WHERE id=1;"
}

pause_session() {
    local elapsed="$1" now="$2"
    _exec "UPDATE state SET
        active=0, paused=1,
        pause_start_time='$(_q "$now")',
        previous_elapsed=$elapsed
        WHERE id=1;"
}

resume_session() {
    local new_start="$1"
    _exec "UPDATE state SET
        active=1, paused=0,
        start_time='$(_q "$new_start")',
        pause_start_time=NULL, previous_elapsed=0
        WHERE id=1;"
}

# ── Sessions: writes ─────────────────────────────────────────────────────────

record_session() {
    local project="$1" start_time="$2" end_time="$3" duration="$4" notes="${5:-}"
    _validate_project_name "$project" || return 2
    _exec "INSERT INTO sessions (project, start_time, end_time, duration_seconds, notes)
           VALUES ('$(_q "$project")', '$(_q "$start_time")', '$(_q "$end_time")',
                   $duration, '$(_q "$notes")');"
}

record_duration_session() {
    local project="$1" duration="$2" date="$3" notes="${4:-}"
    _validate_project_name "$project" || return 2
    _exec "INSERT INTO sessions (project, duration_seconds, notes, duration_only, session_date)
           VALUES ('$(_q "$project")', $duration, '$(_q "$notes")', 1, '$(_q "$date")');"
}

update_session() {
    local id="$1" project="$2" start_time="$3" end_time="$4" duration="$5"
    _validate_project_name "$project" || return 2
    _exec "UPDATE sessions SET
        project='$(_q "$project")', start_time='$(_q "$start_time")',
        end_time='$(_q "$end_time")', duration_seconds=$duration
        WHERE id=$id;"
}

update_session_notes() {
    # Notes are orthogonal to timing: this is the one session edit that is legal
    # on duration-only rows too, since it bolts no timestamps onto them
    # [CONV-DURONLY].
    local id="$1" notes="$2"
    _exec "UPDATE sessions SET notes='$(_q "$notes")' WHERE id=$id;"
}

delete_session() {
    local id="$1"
    _exec "DELETE FROM sessions WHERE id=$id;"
}

# ── Sessions: reads ──────────────────────────────────────────────────────────

# Notes are the only free-text column and may hold newlines, but every session
# read must stay one line per row [PORT]. Encode backslashes first so the decode
# is reversible, then the line breaks; core/text.sh notes_decode reverses it.
# char() keeps backslashes out of the SQL source entirely.
_NOTES_ENCODED="REPLACE(REPLACE(REPLACE(COALESCE(notes,''), char(92), char(92,92)), char(10), char(92,110)), char(13), char(92,114))"

list_sessions() {
    local limit="${1:-$REPORT_LIMIT}"
    _query "SELECT id, project, COALESCE(start_time,''), COALESCE(end_time,''),
                   duration_seconds, $_NOTES_ENCODED, duration_only, COALESCE(session_date,'')
            FROM sessions
            ORDER BY id DESC LIMIT $limit;"
}

list_sessions_in_range() {
    local start="$1" end="$2"
    _query "SELECT id, project, COALESCE(start_time,''), COALESCE(end_time,''),
                   duration_seconds, $_NOTES_ENCODED, duration_only, COALESCE(session_date,'')
            FROM sessions
            WHERE (
                (duration_only=0 AND end_time >= '$(_q "$start")' AND end_time <= '$(_q "$end")')
                OR
                (duration_only=1 AND session_date >= date('$(_q "$start")') AND session_date <= date('$(_q "$end")'))
            )
            ORDER BY COALESCE(end_time, session_date) DESC;"
}

get_project_totals_in_range() {
    # <start> <end> -> project|duration_seconds|session_count, one row per
    # project, ordered by duration_seconds descending.
    #
    # Same WHERE clause as list_sessions_in_range on purpose: report's
    # per-project breakdown must count exactly the sessions the raw listing
    # shows. Aggregating here rather than in bash means `focus report` has no
    # associative-array dependency — macOS ships bash 3.2, which has none.
    local start="$1" end="$2"
    _query "SELECT project, SUM(duration_seconds), COUNT(*)
            FROM sessions
            WHERE (
                (duration_only=0 AND end_time >= '$(_q "$start")' AND end_time <= '$(_q "$end")')
                OR
                (duration_only=1 AND session_date >= date('$(_q "$start")') AND session_date <= date('$(_q "$end")'))
            )
            GROUP BY project
            ORDER BY SUM(duration_seconds) DESC;"
}

get_session() {
    local id="$1"
    _query "SELECT id, project, COALESCE(start_time,''), COALESCE(end_time,''),
                   duration_seconds, $_NOTES_ENCODED, duration_only, COALESCE(session_date,'')
            FROM sessions WHERE id=$id;"
}

get_total_time() {
    local project="$1"
    _query "SELECT COALESCE(SUM(duration_seconds),0)
            FROM sessions WHERE project='$(_q "$project")';"
}

get_last_session() {
    # Returns: project|end_time|duration_seconds
    _query "SELECT project, COALESCE(end_time,''), duration_seconds
            FROM sessions WHERE end_time IS NOT NULL
            ORDER BY end_time DESC LIMIT 1;"
}

get_last_project() {
    _query "SELECT project FROM sessions
            ORDER BY id DESC LIMIT 1;"
}

# ── Serialization (db_*: storage-mechanism) ──────────────────────────────────

db_dump_sql() {
    sqlite3 "$DB_PATH" .dump
}

db_load_sql() {
    # Restore a .dump into the DB. Caller removes the old file first.
    sqlite3 "$DB_PATH" < "$1"
}

db_export_state_json() {
    # Single JSON object (array wrapper stripped), or empty.
    sqlite3 -json "$DB_PATH" "SELECT * FROM state WHERE id=1;" \
        | tr -d '\n' | sed 's/^\[//;s/\]$//'
}

db_export_sessions_json() {
    local result
    result=$(sqlite3 -json "$DB_PATH" "SELECT * FROM sessions ORDER BY id;")
    echo "${result:-[]}"
}

db_import_session_row() {
    # Verbatim, full-fidelity insert for import paths. Bypasses domain logic on
    # purpose: it reconstructs a stored row exactly, NULLs preserved.
    local project="$1" start_time="$2" end_time="$3" duration="$4" \
          notes="$5" duration_only="$6" session_date="$7"
    local start_sql end_sql date_sql
    [[ -n "$start_time"   ]] && start_sql="'$(_q "$start_time")'"  || start_sql="NULL"
    [[ -n "$end_time"     ]] && end_sql="'$(_q "$end_time")'"      || end_sql="NULL"
    [[ -n "$session_date" ]] && date_sql="'$(_q "$session_date")'" || date_sql="NULL"
    _exec "INSERT INTO sessions
        (project, start_time, end_time, duration_seconds, notes, duration_only, session_date)
        VALUES ('$(_q "$project")', $start_sql, $end_sql,
                $duration, '$(_q "$notes")', $duration_only, $date_sql);"
}

update_duration_session() {
    # Rename and/or re-duration a duration-only session. Never touches timestamps.
    local id="$1" project="$2" duration="$3"
    _validate_project_name "$project" || return 2
    _exec "UPDATE sessions SET project='$(_q "$project")', duration_seconds=$duration WHERE id=$id;"
}

reset_state_post_import() {
    # State is runtime, not data. After any import, normalize to idle+disabled.
    # Sessions were restored verbatim. User must 'focus enable' consciously.
    _exec "UPDATE state SET
        active=0, project=NULL, start_time=NULL,
        paused=0, pause_start_time=NULL, previous_elapsed=0,
        focus_disabled=1, last_off_time=NULL
        WHERE id=1;"
}
