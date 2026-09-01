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

sanitize_pipe() {
    # Every session read is pipe-separated (_query -separator '|') and every
    # caller splits on it (IFS='|' read); a literal '|' in stored data
    # desyncs every field after it — reachable through project names, notes,
    # or import. Rather than rejecting it, transliterate to the visually
    # similar U+00A6 (broken bar) at every input boundary, so the character
    # that breaks the format simply never reaches storage. Lossy by design;
    # applied before validation/storage, not on read.
    printf '%s' "${1//|/¦}"
}

_validate_project_name() {
    # '|' is handled by sanitize_pipe before this ever runs. Newline/CR are
    # rejected outright instead — a multi-line project name has no sensible
    # meaning for a short identifier, unlike a pipe character which is
    # ordinary text. Called by every write path that takes a project name
    # from a user-controlled arg. db_import_session_row is exempt on
    # purpose: it is documented as a verbatim reconstruction path, and
    # guarding it would abort an import partway through.
    case "$1" in
        *$'\n'*|*$'\r'*)
            echo "❌ Invalid character in project name." >&2
            echo "   Project names cannot contain newlines or carriage returns." >&2
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
            project          TEXT CHECK (instr(project, '|') = 0 AND instr(project, char(10)) = 0 AND instr(project, char(13)) = 0),
            start_time       TEXT,
            paused           INTEGER NOT NULL DEFAULT 0,
            pause_start_time TEXT,
            previous_elapsed INTEGER NOT NULL DEFAULT 0,
            focus_disabled   INTEGER NOT NULL DEFAULT 0,
            last_off_time    TEXT
        );
        CREATE TABLE IF NOT EXISTS sessions (
            id               INTEGER PRIMARY KEY AUTOINCREMENT,
            project          TEXT NOT NULL CHECK (instr(project, '|') = 0 AND instr(project, char(10)) = 0 AND instr(project, char(13)) = 0),
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
    local start_time="$2"
    local project; project=$(sanitize_pipe "$1")
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
    local start_time="$2" end_time="$3" duration="$4" notes="${5:-}"
    local project; project=$(sanitize_pipe "$1")
    _validate_project_name "$project" || return 2
    _exec "INSERT INTO sessions (project, start_time, end_time, duration_seconds, notes)
           VALUES ('$(_q "$project")', '$(_q "$start_time")', '$(_q "$end_time")',
                   $duration, '$(_q "$notes")');"
}

record_duration_session() {
    local duration="$2" date="$3" notes="${4:-}"
    local project; project=$(sanitize_pipe "$1")
    _validate_project_name "$project" || return 2
    _exec "INSERT INTO sessions (project, duration_seconds, notes, duration_only, session_date)
           VALUES ('$(_q "$project")', $duration, '$(_q "$notes")', 1, '$(_q "$date")');"
}

update_session() {
    local id="$1" start_time="$3" end_time="$4" duration="$5"
    local project; project=$(sanitize_pipe "$2")
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

fold_session_into() {
    # <id> <total-seconds> <session-date> <notes> -> collapse a second session
    # for the same project into the row that already holds that name [#36].
    # The row stops describing one contiguous span the moment two of them share
    # it, so it becomes duration-only and drops its timestamps [CONV-DURONLY];
    # the caller writes the dropped times into the note first, which is the
    # only record of them that survives.
    local id="$1" duration="$2" date="$3" notes="${4:-}"
    _exec "UPDATE sessions SET
        duration_seconds=$duration, notes='$(_q "$notes")',
        duration_only=1, session_date='$(_q "$date")',
        start_time=NULL, end_time=NULL
        WHERE id=$id;"
}

delete_session() {
    local id="$1"
    _exec "DELETE FROM sessions WHERE id=$id;"
}

# ── Sessions: reads ──────────────────────────────────────────────────────────

# Notes are the only free-text column and may hold newlines or pipes, but
# every session read must stay one line per row [PORT]. Encode backslashes
# first so the decode is reversible, then everything else; core/text.sh
# notes_decode reverses it in one pass. char() keeps backslashes (and the
# literal pipe) out of the SQL source entirely. '|' encodes as the hex escape
# \x7c rather than a project-name-style transliteration: notes are free text,
# so the exact byte a user typed should survive the round trip, not get
# silently substituted.
_NOTES_ENCODED="REPLACE(REPLACE(REPLACE(REPLACE(COALESCE(notes,''), char(92), char(92,92)), char(10), char(92,110)), char(13), char(92,114)), char(124), char(92,120,55,99))"

list_sessions() {
    local limit="${1:-$REPORT_LIMIT}"
    _query "SELECT id, project, COALESCE(start_time,''), COALESCE(end_time,''),
                   duration_seconds, $_NOTES_ENCODED, duration_only, COALESCE(session_date,'')
            FROM sessions
            ORDER BY id DESC LIMIT $limit;"
}

_range_where() {
    # <start> <end> -> the WHERE fragment matching sessions in that range,
    # timestamped or duration-only. Shared so list_sessions_in_range and
    # get_project_totals_in_range can never drift apart on what "in range"
    # means — the breakdown must count exactly the sessions the raw listing
    # shows.
    #
    # start/end are always full ISO-8601 (core/time.sh), and the local
    # calendar date is already correct in their first 10 characters — that's
    # the whole point of computing them via `date`/`gdate` in the first
    # place. Using sqlite's date() here converted the string to UTC first,
    # which shifted the boundary by a day for any positive UTC offset (e.g.
    # local midnight "...T00:00:00+10:00" -> UTC "...(prev day)T14:00:00Z" ->
    # date() = yesterday). substr just reads the date already written in the
    # string, no timezone interpretation involved.
    local start="$1" end="$2"
    echo "(
                (duration_only=0 AND end_time >= '$(_q "$start")' AND end_time <= '$(_q "$end")')
                OR
                (duration_only=1 AND session_date >= substr('$(_q "$start")', 1, 10) AND session_date <= substr('$(_q "$end")', 1, 10))
            )"
}

list_sessions_in_range() {
    local start="$1" end="$2"
    _query "SELECT id, project, COALESCE(start_time,''), COALESCE(end_time,''),
                   duration_seconds, $_NOTES_ENCODED, duration_only, COALESCE(session_date,'')
            FROM sessions
            WHERE $(_range_where "$start" "$end")
            ORDER BY COALESCE(end_time, session_date) DESC;"
}

get_project_totals_in_range() {
    # <start> <end> -> project|duration_seconds|session_count, one row per
    # project, ordered by duration_seconds descending. Aggregating in SQL
    # rather than bash means `focus report` has no associative-array
    # dependency — macOS ships bash 3.2, which has none.
    local start="$1" end="$2"
    _query "SELECT project, SUM(duration_seconds), COUNT(*)
            FROM sessions
            WHERE $(_range_where "$start" "$end")
            GROUP BY project
            ORDER BY SUM(duration_seconds) DESC;"
}

get_session() {
    local id="$1"
    _query "SELECT id, project, COALESCE(start_time,''), COALESCE(end_time,''),
                   duration_seconds, $_NOTES_ENCODED, duration_only, COALESCE(session_date,'')
            FROM sessions WHERE id=$id;"
}

get_session_by_project() {
    # <project> [exclude-id] -> the ORIGINAL session carrying that exact project
    # name (lowest id wins), as an 8-field row like get_session, or empty when
    # nothing holds the name. Every write path checks this before adding a row,
    # so a project name never ends up split across duplicate entries [#36].
    # The name is sanitized the same way the write paths sanitize it, or the
    # lookup would miss the row it is about to duplicate.
    local project; project=$(sanitize_pipe "$1")
    local exclude="${2:-}" where
    where="project='$(_q "$project")'"
    [[ -n "$exclude" ]] && where="$where AND id<>$exclude"
    _query "SELECT id, project, COALESCE(start_time,''), COALESCE(end_time,''),
                   duration_seconds, $_NOTES_ENCODED, duration_only, COALESCE(session_date,'')
            FROM sessions WHERE $where ORDER BY id ASC LIMIT 1;"
}

get_total_time() {
    local project="$1"
    _query "SELECT COALESCE(SUM(duration_seconds),0)
            FROM sessions WHERE project='$(_q "$project")';"
}

get_last_session() {
    # Returns: project|end_time-or-session_date|duration_seconds
    # A duration-only row (past add --duration, check-in) has no end_time —
    # order by whichever of the two it has, same fallback list_sessions_in_range
    # already uses, so a check-in-logged session isn't invisible to `focus status`.
    _query "SELECT project, COALESCE(end_time, session_date, ''), duration_seconds
            FROM sessions
            ORDER BY COALESCE(end_time, session_date) DESC LIMIT 1;"
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
    local id="$1" duration="$3"
    local project; project=$(sanitize_pipe "$2")
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
