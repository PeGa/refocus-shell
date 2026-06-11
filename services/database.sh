#!/usr/bin/env bash
# Refocus Shell - Database driver
# SQLAlchemy-like abstraction: callers say *what*, driver handles *how*.
# No SQL outside this file.

# ── Internal engine ──────────────────────────────────────────────────────────

_q() {
    # Escape single quotes for SQL literals.
    printf '%s' "${1//\'/\'\'}"
}

_db_exec() {
    # Fire-and-forget write. Dies loud on error.
    sqlite3 "$DB_PATH" "$1" || { echo "❌ DB write failed" >&2; return 1; }
}

_db_query() {
    # Read query; outputs pipe-separated rows to stdout.
    sqlite3 -separator '|' "$DB_PATH" "$1"
}

# ── Schema ────────────────────────────────────────────────────────────────────

db_init() {
    mkdir -p "$(dirname "$DB_PATH")"
    _db_exec "
        CREATE TABLE IF NOT EXISTS state (
            id               INTEGER PRIMARY KEY CHECK (id = 1),
            active           INTEGER NOT NULL DEFAULT 0,
            project          TEXT,
            start_time       TEXT,
            paused           INTEGER NOT NULL DEFAULT 0,
            pause_notes      TEXT,
            pause_start_time TEXT,
            previous_elapsed INTEGER NOT NULL DEFAULT 0,
            nudging_enabled  INTEGER NOT NULL DEFAULT 1,
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
        CREATE TABLE IF NOT EXISTS projects (
            name             TEXT PRIMARY KEY,
            description      TEXT NOT NULL,
            created_at       TEXT NOT NULL
        );
        INSERT OR IGNORE INTO state (id) VALUES (1);
    "
}

db_ensure() {
    # Lazy init: only hits disk once the db file exists.
    [[ -f "$DB_PATH" ]] || db_init
}

# ── State: reads ─────────────────────────────────────────────────────────────

db_get_state() {
    # Outputs: active|project|start_time|paused|pause_notes|pause_start_time|previous_elapsed|nudging_enabled|focus_disabled|last_off_time
    _db_query "SELECT active, COALESCE(project,''), COALESCE(start_time,''),
                      paused, COALESCE(pause_notes,''), COALESCE(pause_start_time,''),
                      previous_elapsed, nudging_enabled, focus_disabled,
                      COALESCE(last_off_time,'')
               FROM state WHERE id=1;"
}

db_is_active()   { [[ "$(_db_query "SELECT active       FROM state WHERE id=1;")" == "1" ]]; }
db_is_paused()   { [[ "$(_db_query "SELECT paused       FROM state WHERE id=1;")" == "1" ]]; }
db_is_disabled() { [[ "$(_db_query "SELECT focus_disabled FROM state WHERE id=1;")" == "1" ]]; }
db_nudging_on()  { [[ "$(_db_query "SELECT nudging_enabled FROM state WHERE id=1;")" == "1" ]]; }

# ── State: writes ─────────────────────────────────────────────────────────────

db_start_session() {
    local project="$1" start_time="$2"
    _db_exec "UPDATE state SET
        active=1, project='$(_q "$project")', start_time='$(_q "$start_time")',
        paused=0, pause_notes=NULL, pause_start_time=NULL, previous_elapsed=0
        WHERE id=1;"
}

db_end_session() {
    local now="$1"
    _db_exec "UPDATE state SET
        active=0, project=NULL, start_time=NULL,
        paused=0, pause_notes=NULL, pause_start_time=NULL, previous_elapsed=0,
        last_off_time='$(_q "$now")'
        WHERE id=1;"
}

db_pause_session() {
    local elapsed="$1" notes="$2" now="$3"
    _db_exec "UPDATE state SET
        active=0, paused=1,
        pause_notes='$(_q "$notes")', pause_start_time='$(_q "$now")',
        previous_elapsed=$elapsed
        WHERE id=1;"
}

db_resume_session() {
    local new_start="$1"
    _db_exec "UPDATE state SET
        active=1, paused=0,
        start_time='$(_q "$new_start")',
        pause_notes=NULL, pause_start_time=NULL, previous_elapsed=0
        WHERE id=1;"
}

db_flip_flag() {
    # db_flip_flag <nudging_enabled|focus_disabled> <0|1>
    local flag="$1" value="$2"
    case "$flag" in
        nudging_enabled|focus_disabled) ;;
        *) echo "❌ Unknown flag: $flag" >&2; return 1 ;;
    esac
    _db_exec "UPDATE state SET $flag=$value WHERE id=1;"
}

# ── Sessions: writes ──────────────────────────────────────────────────────────

db_insert_session() {
    local project="$1" start_time="$2" end_time="$3" duration="$4" notes="${5:-}"
    _db_exec "INSERT INTO sessions (project, start_time, end_time, duration_seconds, notes)
              VALUES ('$(_q "$project")', '$(_q "$start_time")', '$(_q "$end_time")',
                      $duration, '$(_q "$notes")');"
}

db_insert_duration_session() {
    local project="$1" duration="$2" date="$3" notes="${4:-}"
    _db_exec "INSERT INTO sessions (project, duration_seconds, notes, duration_only, session_date)
              VALUES ('$(_q "$project")', $duration, '$(_q "$notes")', 1, '$(_q "$date")');"
}

db_update_session() {
    local id="$1" project="$2" start_time="$3" end_time="$4" duration="$5"
    _db_exec "UPDATE sessions SET
        project='$(_q "$project")', start_time='$(_q "$start_time")',
        end_time='$(_q "$end_time")', duration_seconds=$duration
        WHERE id=$id;"
}

db_delete_session() {
    local id="$1"
    _db_exec "DELETE FROM sessions WHERE id=$id;"
}

# ── Sessions: reads ───────────────────────────────────────────────────────────

db_list_sessions() {
    local limit="${1:-$REPORT_LIMIT}"
    _db_query "SELECT id, project, COALESCE(start_time,''), COALESCE(end_time,''),
                      duration_seconds, COALESCE(notes,''), duration_only, COALESCE(session_date,'')
               FROM sessions WHERE project != '[idle]'
               ORDER BY id DESC LIMIT $limit;"
}

db_list_sessions_in_range() {
    local start="$1" end="$2"
    _db_query "SELECT id, project, COALESCE(start_time,''), COALESCE(end_time,''),
                      duration_seconds, COALESCE(notes,''), duration_only, COALESCE(session_date,'')
               FROM sessions
               WHERE project != '[idle]'
               AND (
                   (duration_only=0 AND end_time >= '$(_q "$start")' AND end_time <= '$(_q "$end")')
                   OR
                   (duration_only=1 AND session_date >= date('$(_q "$start")') AND session_date <= date('$(_q "$end")'))
               )
               ORDER BY COALESCE(end_time, session_date) DESC;"
}

db_get_session() {
    local id="$1"
    _db_query "SELECT id, project, COALESCE(start_time,''), COALESCE(end_time,''),
                      duration_seconds, COALESCE(notes,''), duration_only, COALESCE(session_date,'')
               FROM sessions WHERE id=$id;"
}

db_get_total_time() {
    local project="$1"
    _db_query "SELECT COALESCE(SUM(duration_seconds),0)
               FROM sessions WHERE project='$(_q "$project")';"
}

db_get_last_session() {
    # Returns: project|end_time|duration_seconds
    _db_query "SELECT project, COALESCE(end_time,''), duration_seconds
               FROM sessions WHERE project != '[idle]' AND end_time IS NOT NULL
               ORDER BY end_time DESC LIMIT 1;"
}

db_get_last_project() {
    _db_query "SELECT project FROM sessions
               WHERE project != '[idle]'
               ORDER BY id DESC LIMIT 1;"
}

# ── Projects ──────────────────────────────────────────────────────────────────

db_set_description() {
    local project="$1" desc="$2"
    _db_exec "INSERT OR REPLACE INTO projects (name, description, created_at)
              VALUES ('$(_q "$project")', '$(_q "$desc")', datetime('now'));"
}

db_get_description() {
    local project="$1"
    _db_query "SELECT description FROM projects WHERE name='$(_q "$project")';"
}

db_rm_description() {
    local project="$1"
    _db_exec "DELETE FROM projects WHERE name='$(_q "$project")';"
}

db_list_descriptions() {
    _db_query "SELECT name, description FROM projects ORDER BY name;"
}
