# CONTRACT.md — refocus-shell

> Reverse-engineered specification of the settled design. This document is the
> source of truth for *intent*. The code is the source of truth for *current
> behaviour*. The test suite is the source of truth for *acceptance*.

---

## [READ] How to read this

**Audience.** An agent (or developer) rebuilding refocus-shell from scratch, or
modifying it without drifting from its design.

**Acceptance oracle.** A correct build passes both:
- `tests/audit.sh` — shellcheck clean across all scripts.
- `tests/state-matrix.sh` — the behavioural regression suite.
If your output fails either, it is wrong regardless of how reasonable it looks.
Note the oracle's blind spot (see [INT]): install, shell integration, cron
delivery, and desktop notifications are *not* exercised by it.

**Precedence.**
- Rebuilding from scratch: this contract and `tests/` are the only authorities.
  An invariant (`INV-*`) is never violated — not for convenience, not for an
  edge case, not because a request seems to ask for it.
- Modifying existing code: where this contract and the code disagree, the
  contract states the *intent*; treat the code as possibly buggy and surface the
  conflict rather than silently following either. (A bug in the code is fixed in
  the code, not promoted into this contract.)
- Every rule carries a **WHY**. When you hit a case the rule doesn't name,
  decide by the WHY, not by what's locally convenient.

**Conventions in this file.**
- `RULE` = what must hold. `VIOLATION` = the shape of getting it wrong.
  `WHY` = the reason, load-bearing. `CHECK` = how to falsify it.
- Section codes (`INV-1`, `DM-SESSION`, …) are stable handles for the index.

---

## [WHAT] What refocus-shell is

A terminal focus/time tracker. Bash over SQLite. No daemon. One SQLite database
holds completed **sessions** (history) and a single **state** row (what's
happening now). A **cron job** periodically reminds the user where their
attention is. A shell hook shows current state in the prompt.

Design ethos (this governs ambiguous UX calls): it tracks where attention went
without judgement, gets in the way *just enough* to counter time-blindness, and
stays out of the way *enough* to not become a distraction. It never pressures,
scores, or scolds. Idle is a valid state.

---

## [DM] Domain model

### DM-SESSION · Session is the entity
A session is one completed stretch of focus. It is the only durable record.
Table `sessions`:

```
id                INTEGER PK AUTOINCREMENT
project           TEXT NOT NULL           -- the label, not a foreign key
start_time        TEXT                    -- ISO-8601; NULL for duration-only
end_time          TEXT                    -- ISO-8601; NULL for duration-only
duration_seconds  INTEGER NOT NULL        -- AUTHORITATIVE. never derived at read time
notes             TEXT
duration_only     INTEGER NOT NULL DEFAULT 0
session_date      TEXT                    -- date for duration-only rows; else NULL
```

- `duration_seconds` is authoritative. Reports and totals sum it; they never
  recompute from timestamps. WHY: pause/resume makes wall-clock span ≠ focused
  time; the stored duration already accounts for that.
- A **duration-only** session (`duration_only=1`) has no timestamps, only
  `session_date`. It exists for time tracked in the user's head or logged
  retroactively.

### DM-PROJECT · Project is a label, not an entity
A project is a string on a session row. There is **no projects table**, no
stored project metadata, no project lifecycle. The name *is* the identity.
Convention `customer/project-name`, but unenforced beyond `MAX_PROJECT_LENGTH`.

- VIOLATION: any `projects` table, `focus describe`, stored descriptions, or
  treating a project as a created/deleted object.
- WHY: a label has no lifecycle to manage, nothing to keep in sync, nothing to
  migrate. Identity-by-name means zero ceremony to start tracking something new.

### DM-STATE · State is runtime, not data
A single row (`id=1`, enforced by `CHECK (id=1)`) holds only what is true *right
now*. Table `state`:

```
id                INTEGER PK CHECK(id=1)
active            INTEGER NOT NULL DEFAULT 0    -- a session is running
project           TEXT                          -- current project (active/paused)
start_time        TEXT                          -- current session start
paused            INTEGER NOT NULL DEFAULT 0
pause_start_time  TEXT
previous_elapsed  INTEGER NOT NULL DEFAULT 0    -- focused seconds banked at pause
focus_disabled    INTEGER NOT NULL DEFAULT 0    -- the nudge kill switch
last_off_time     TEXT                          -- set on off; informational
```

- State is reconstructable and disposable. Wiping or normalising it must never
  touch `sessions`. WHY: see INV-5. Restoring a stale "active" state from a
  backup resurrects a session that isn't happening (the import-zombie bug).

### DM-DEAD · Negative space — deliberately removed, never re-add
If you find yourself adding any of these, stop; it is the old model leaking back.

| Removed | Why it's gone |
|---|---|
| `projects` table / `focus describe` | DM-PROJECT — projects are labels |
| `pause_notes` column / note prompt at pause | INV-4 — pause is silent |
| `nudging_enabled` flag | INV-3 — nudging is the cron's existence, not a flag |
| `[idle]` session rows | idle is not a session; never write one |
| `nudge enable` / `nudge disable` commands | replaced by `focus enable`/`disable` |
| recomputing duration from timestamps at read | DM-SESSION — stored duration is authoritative |

Old DBs may still carry `pause_notes` / `nudging_enabled` columns. Leave them.
`db_migrate` is additive-only and never drops columns. Never read them.

---

## [INV] Invariants

### INV-1 · No SQL outside the database adapter
- RULE: within the application — `focus`, `lib/`, `core/`, `env.sh`,
  `focus-nudge`, and all of `services/` except the adapter — nothing calls
  `sqlite3` or builds SQL. Only `services/database.sh` does.
- SCOPE: this binds *application* code. Test harnesses under `tests/` may, and
  must, query `sqlite3` directly. WHY: a test that verified the adapter through
  the adapter would be circular and pass spuriously when the adapter is broken;
  the oracle reads storage independently on purpose.
- VIOLATION: any application file invoking `sqlite3`, or assembling a query string.
- WHY: the adapter is the single point of storage change and the only place that
  needs SQL-injection care (`_q`). One boundary to audit, one file to swap if
  storage ever changes. Leakage rots the boundary back into spaghetti.
- CHECK: `grep -rl sqlite3` over the application files (excluding `tests/`)
  returns only `services/database.sh` and a `command -v sqlite3` probe in `setup.sh`.

### INV-2 · Domain code names intent, never storage
- RULE: handlers call intent functions (`start_session`, `is_session_paused`,
  `set_focus_disabled`). The `db_*` prefix is reserved for storage-mechanism
  operations only: schema lifecycle and serialization (see NAME).
- VIOLATION: a handler calling something named `db_*` to do domain work, or a
  domain function carrying a `db_` prefix.
- WHY: a caller flipping focus state must not know or care which column moves.
  Intent names survive a storage swap; `db_*` correctly signals "this is about
  the database-as-artifact," which domain logic should never reach for.

### INV-3 · Nudging is structural (cron), not a flag
- RULE: nudging exists iff a cron entry for `focus-nudge` exists. `focus enable`
  installs it; `focus disable` removes it. `focus_disabled=1` is only a kill
  switch the payload checks; it is not what "enabled" means.
- VIOLATION: a `nudging_enabled` flag; gating nudges on a state column instead of
  cron; `focus on`/`off`/`pause`/`continue` touching cron.
- WHY: a flag drifts from reality. The disable-while-active bug came from state
  saying one thing and the mechanism doing another. The mechanism (cron) is the
  truth; the flag only lets the payload stay silent without uninstalling.
- CHECK: only `enable`, `disable`, `reset`, `import`, and `setup.sh` touch cron.

### INV-4 · Pause is silent
- RULE: `focus pause` captures nothing — no note, no prompt. The only note in
  the system is captured by `focus off` and written straight to the session.
- VIOLATION: a prompt during pause; a `pause_notes` store; merging notes on stop.
- WHY: an interruption is the worst moment to impose a cognitive task. A note
  prompt mid-pause is friction the user bounces off. `off` is when there are
  spare cycles, and the note there is the re-entry anchor for next time.

### INV-5 · State is runtime; sessions are data
- RULE: any operation that restores or wipes the database must normalise state
  to **idle + disabled** (`reset_state_post_import`), independent of what state
  was in the backup. Sessions are restored verbatim.
- VIOLATION: importing a backup and inheriting its `active`/`paused`/`enabled`.
- WHY: a backup's "active" session is not happening now. Inheriting it produces a
  zombie timer counting since a moment in the past, with cron possibly stripped.
  State is reconstructed by the user, consciously (see CONV-REARM).

---

## [NAME] Naming contract

- `db_*` — reserved for storage-mechanism operations: schema lifecycle
  (`db_init`, `db_migrate`, `db_ensure`) and serialization
  (`db_dump_sql`, `db_load_sql`, `db_export_*`, `db_import_session_row`).
  These are about the database-as-artifact.
- Everything else in the adapter is named by domain intent: predicates
  `is_*`, reads `get_*`/`list_*`, mutations as verbs (`start_session`,
  `record_session`, `set_focus_disabled`).
- Private engine helpers are underscore-prefixed (`_q`, `_exec`, `_query`) and
  never called outside `database.sh`. Same convention for private helpers in any
  file (`_cron_*`, `_refocus_prompt`, `_report`).
- WHY the split: the prefix is a signal. `db_` says "storage mechanism, not
  domain." When an edge case appears (e.g. a new export helper), it gets `db_`
  *because it serializes the artifact*, not because it touches the DB — every
  function touches the DB; that's not the distinction.
- Function names must not collide with shell builtins. (`enable`, `reset` are
  builtins — that is why the *commands* live in `lib/enable.sh` etc. and the
  adapter uses `set_focus_enabled`, not `enable`.)

---

## [ARCH] Architecture & layering

Hexagonal / ports-and-adapters. Three layers plus entry points.

```
focus                       dispatcher. resolves REFOCUS_ROOT, sources env.sh,
                            routes `focus <cmd> [args]` → exec lib/<cmd>.sh
lib/<cmd>.sh                PRIMARY ADAPTERS. one file per command. receive user
                            input, drive the core via intent calls. routable.
core/<topic>.sh             DOMAIN HELPERS. pure functions, string→string/int.
                            no SQL, no cron, no state, no side effects. NOT routable.
services/database.sh        SECONDARY ADAPTER. the only file that speaks SQL (INV-1).
services/cron.sh            SECONDARY ADAPTER. arms/disarms the nudge schedule.
services/focus-function.sh  shell integration: prompt hook + focus() wrapper.
env.sh                      environment loader. reads .env, exports config.
focus-nudge                 self-contained cron payload. sources env.sh + database.sh.
docs/help/<cmd>.txt         per-command help, served verbatim by lib/help.sh.
tests/                      audit.sh (shellcheck) + state-matrix.sh (behaviour).
```

- ARCH-ROUTABLE: the dispatcher routes only to `lib/`, by filename, with no case
  table — adding a command is adding `lib/<cmd>.sh`, nothing to register. A file
  under `core/` or `services/` is never a command. `focus time` must not exist
  because `core/time.sh` exists.
- ARCH-ROOT: the dispatcher sets `REFOCUS_ROOT="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"`
  and exports it. Handlers source `"$REFOCUS_ROOT/env.sh"` etc.; they never
  re-derive root themselves. WHY: one resolution point; a symlinked `focus` in
  `~/.local/bin` still resolves to the real install dir. (Do not substitute
  `cd "$PWD"` or `$0` games — `realpath` on `BASH_SOURCE` is the one correct form.)
- ARCH-SOURCE: every `lib/` handler begins by sourcing `env.sh`, then whatever
  services/core it needs, then calls `db_ensure` if it touches the DB.

---

## [PORT] The adapter surface (services/database.sh)

The exact intent API the core calls through. A rebuild must expose equivalently
named functions with these contracts. Output of reads is pipe-separated.

**Engine (private):** `_q` (escape single quotes), `_exec` (write, dies loud),
`_query` (read, `-separator '|'`).

**Schema (db_*, storage):**
- `db_init` — create tables if absent; `INSERT OR IGNORE` the singleton state row.
- `db_migrate` — additive-only column adds; never drops (DM-DEAD).
- `db_ensure` — `db_init` if no DB file, then `db_migrate`. Idempotent.

**State reads:**
- `get_state` → `active|project|start_time|paused|pause_start_time|previous_elapsed|focus_disabled|last_off_time` (exactly 8 fields, this order, empties as `''`).
- `is_session_active` / `is_session_paused` / `is_focus_disabled` → exit status (0=true).

**State writes:**
- `set_focus_enabled` / `set_focus_disabled` — flip `focus_disabled`.
- `start_session <project> <start_iso>` — active=1, clear pause fields.
- `end_session <now_iso>` — clear to idle, set `last_off_time`.
- `pause_session <elapsed_secs> <now_iso>` — active=0, paused=1, bank `previous_elapsed`.
- `resume_session <new_start_iso>` — active=1, paused=0, clear pause fields.

**Session writes:**
- `record_session <project> <start> <end> <dur> [notes]` — timestamped row.
- `record_duration_session <project> <dur> <date> [notes]` — `duration_only=1`.
- `update_session <id> <project> <start> <end> <dur>` — timestamped edit.
- `update_duration_session <id> <project> <dur>` — never touches timestamps (CONV-DURONLY).
- `delete_session <id>`.

**Session reads** (all 8-field rows: `id|project|start|end|dur|notes|duration_only|session_date`):
- `list_sessions [limit]` — newest first, `limit` defaults to `REPORT_LIMIT`.
- `list_sessions_in_range <start> <end>` — timestamped rows by `end_time`;
  duration-only rows by `session_date`.
- `get_session <id>`.
- `get_total_time <project>` → summed `duration_seconds`.
- `get_last_session` → `project|end_time|duration_seconds` of most recent.
- `get_last_project` → most recent project name.

**Serialization (db_*, storage):**
- `db_dump_sql` → `.dump` to stdout. `db_load_sql <file>` → restore.
- `db_export_state_json` → single JSON object. `db_export_sessions_json` → array.
- `db_import_session_row <7 fields>` — verbatim insert, NULLs preserved.

**State normalisation:**
- `reset_state_post_import` — force idle + disabled (INV-5).

---

## [CORE] The domain-helper surface (core/time.sh)

Pure functions. String/int in, string/int out. No SQL, no cron, no state, no
side effects. Sourced by any layer that needs them; never routable (ARCH-ROUTABLE).

- `fmt_duration <seconds>` → human string. `"2h 15m"` when hours>0, else `"45m"`.
- `parse_duration <str>` → seconds on stdout, or `❌`-message to stderr + return 1.
  Accepts exactly: `XhYm`, `Xh`, `Xm` (e.g. `1h30m`, `2h`, `45m`). Nothing else.
- `parse_time <str>` → ISO-8601 (`date -Iseconds`) on stdout, or `❌` + return 1.
  Normalises `YYYY/MM/DD-HH:MM` to a `date(1)`-parseable form first, then accepts
  anything `date(1)` accepts: `HH:MM` (today assumed), `"yesterday 14:00"`,
  `"2 hours ago"`, etc.
- WHY a separate layer: `parse_duration`/`parse_time` were duplicated inline in
  two `past` branches; one of those copies fed an empty string to `date` and
  silently produced a zero duration (CONV-DURONLY). One definition, one place.

---

## [ENV] Environment loader (env.sh)

Loads configuration and exports it for every component. Sourced first by the
dispatcher, by `focus-nudge`, and by the shell hook.

- Bootstrap: before `DB_PATH` is known, source `"$(dirname "${REFOCUS_DB_PATH:-<default>}")/.env"`
  if present, so a relocated DB's `.env` is honoured.
- Then set and **export** exactly: `DB_PATH`, `ENV_FILE`, `NUDGE_INTERVAL`,
  `MAX_PROJECT_LENGTH`, `DATE_FORMAT`, `DATE_SHORT_FORMAT`, `REPORT_LIMIT`.
  Defaults: DB `~/.local/refocus/refocus.db`, interval `10`, max-len `100`,
  date `%Y-%m-%d`, short `%Y-%m-%d %H:%M`, limit `20`.
- `ENV_FILE` = `"$(dirname "$DB_PATH")/.env"`, computed **here, once**, exported.
- Precedence (high→low): `REFOCUS_*` shell env vars → `.env` → these defaults.
- CONV-ENVFILE: `ENV_FILE` is never re-derived elsewhere; `lib/config.sh` uses
  this export. WHY: re-deriving after a `DB_PATH` change splits reads and writes
  across two `.env` files (the split-brain bug).

---

## [CRON] Nudge scheduling (services/cron.sh)

The mechanism behind INV-3. Two public functions plus private helpers.

- `cron_install` — validate interval (CRON-INTERVAL), build the entry, then
  strip-and-rewrite the live crontab (CRON-STRIP): `crontab -l | grep -vF "$bin"`,
  append the new entry, install the file.
- `cron_remove` — same strip, no append.
- CRON-BIN: the payload path is `"$REFOCUS_ROOT/focus-nudge"`, resolved at call
  time, never hardcoded to the install dir.
- CRON-ENV: the entry embeds the runtime env it needs, because cron runs stripped
  (no `$HOME`, no PATH): `REFOCUS_ROOT=… DISPLAY=… WAYLAND_DISPLAY=… DBUS_SESSION_BUS_ADDRESS=… <bin>`.
  Schedule fires every `NUDGE_INTERVAL` minutes, phased to the current minute for
  a stable offset.
- CRON-STRIP: the strip is **fixed-string** (`grep -vF`), never a regex, and
  always against the user's *live* crontab — never a saved backup. WHY: the path
  contains `.` (a regex wildcard); a regex strip can delete unrelated lines, and
  restoring a stale backup clobbers crontab entries added since install.
- CRON-INTERVAL: reject non-numeric or out-of-range before building a pattern;
  valid range 1–60.

---

## [CMD] Command surface (lib/)

Each handler: source env + deps, `db_ensure`, then the logic below.

### CMD-ON · `focus on [project]`
- disabled → error, "run 'focus enable' first" (exit 1).
- active or paused → error naming the open session (exit 1).
- no project: `get_last_project`; if none → usage (exit 2); else offer to
  continue (show total logged), decline → hint + exit 0.
- named project over `MAX_PROJECT_LENGTH` → exit 2.
- named project with prior time → typo guard "X has Ym logged. Continue? (Y/n)",
  decline → exit 0.
- otherwise `start_session`; notify.

### CMD-OFF · `focus off`
- not active and not paused → error (exit 1).
- active: duration = now − start. paused: duration = `previous_elapsed`.
- prompt for notes (Enter to skip), `record_session`, then `end_session`; notify.
- CMD-OFF-RECOVERY: `off` does **not** check `focus_disabled`. It is the escape
  hatch out of any corrupted/disabled state. WHY: the user must always be able
  to close a session.

### CMD-PAUSE · `focus pause`
- not active → error (exit 1). Else compute elapsed, `pause_session`, notify.
  No note (INV-4).

### CMD-CONTINUE · `focus continue`
- not paused → error (exit 1). Confirm (default yes); decline → stays paused.
- resume by `resume_session` with `start = now − previous_elapsed`. WHY: baking
  banked time into an adjusted start means `duration = now − start` stays correct
  across any number of pause/resume cycles. Paused wall-time is never counted.

### CMD-STATUS · `focus status`
- disabled branch first → "🚫 … 'focus enable' to start", show last session, exit.
- active → elapsed + total logged. paused → banked + paused-for. idle → "Not
  focusing." + last session. Read-only.

### CMD-PAST · `focus past <list|add|modify|delete>`
- `list [n]` — table via `list_sessions`.
- `add <project> <start> <end>` — `parse_time` both (CORE), end>start else exit 2,
  prompt notes, `record_session`.
- `add <project> --duration <D> [--date <date>]` — `parse_duration`, default date
  today, prompt notes, `record_duration_session`.
- `modify <id> [project] [start] [end]` (timestamped row) — recompute duration.
- `modify <id> [project] [--duration <D>]` (duration-only row) — rename and/or
  re-duration ONLY; any timestamp arg → exit 2 (CONV-DURONLY).
- CMD-PAST-ARGS: the leading `[project]` is optional. Detect it as "the next arg
  that is not the `--duration` flag" — never consume `--duration` as the project
  name. So `modify <id> --duration 1h` updates duration and keeps the project;
  `modify <id> newname` renames only; `modify <id> newname --duration 1h` does both.
- `delete <id>` — confirm, `delete_session`.

### CMD-REPORT · `focus report <today|week|month|custom N>`
- compute range, `list_sessions_in_range`, print total + per-project + per-session.
  `custom` requires numeric N (exit 2). Facts only, no score.

### CMD-ENABLE · `focus enable`
- already enabled (`! is_focus_disabled`) → say so, exit 0, touch nothing
  (CONV-IDEMPOTENT-ENABLE). Else `set_focus_enabled` + `cron_install`.

### CMD-DISABLE · `focus disable`
- active or paused → refuse, "run 'focus off' first" (exit 1) (INV-3 illegal state).
  Else `set_focus_disabled` + `cron_remove`.

### CMD-NUDGE · `focus nudge <status|test>`
- diagnostics only. `status`: enabled? + crontab entry. `test`: fire notify-send,
  run `focus-nudge`, show crontab. No `enable`/`disable` subcommands (DM-DEAD).

### CMD-CONFIG · `focus config <show|set|unset>`
- `show`: effective values + overrides from `$ENV_FILE`.
- `set <KEY> <VAL>`: validate KEY against the known set; write `REFOCUS_<KEY>` to
  `$ENV_FILE`. `unset`: remove the line. `$ENV_FILE` from env.sh (CONV-ENVFILE).

### CMD-EXPORT · `focus export [basename]`
- write `<base>.sql` (`db_dump_sql`) and `<base>.json`. Read-only on live data.

### CMD-IMPORT · `focus import <file>`
- detect sql/json by extension then content sniff. Warn if session open. Require
  literal `yes` (CONV-YES). Back up current DB. `cron_remove`. sql → `db_load_sql`;
  json → `db_init` + per-row `db_import_session_row` (needs `jq`). Then
  `reset_state_post_import` (INV-5). Leaves disabled (CONV-REARM).

### CMD-INIT · `focus init`
- `db_init`; report path. Safe to re-run.

### CMD-RESET · `focus reset`
- warn if session open. Require literal `yes` (CONV-YES). `cron_remove`, drop DB,
  `db_init`, `set_focus_disabled`. Leaves disabled (CONV-REARM).

### CMD-HELP · `focus help [cmd]`
- pure dispatch: `cat docs/help/<cmd>.txt`; no arg → `global.txt`; missing → exit 2.
  Help text lives only in `docs/help/`, never duplicated in code.

---

## [NUDGE] The nudge payload (focus-nudge)

The thing cron runs. Self-contained — it cannot assume the shell environment.

- Resolve `REFOCUS_ROOT` (default `~/.local/refocus`), source `env.sh` then
  `database.sh`. WHY standalone: cron invokes it directly, outside any shell init.
- `[[ -f "$DB_PATH" ]] || exit 0` then `is_focus_disabled && exit 0`. Silent when
  there's nothing to nudge about or the kill switch is set (INV-3).
- Read `get_state`; branch:
  - active + project → `"Focusing on: <project> (<Nm>)"` where N = (now−start)/60.
  - paused + project → `"Paused: <project>"`.
  - else → `"Not focusing on anything."`
- Deliver via `notify-send --app-name=Refocus --hint=string:desktop-entry:refocus`,
  falling back to `logger -t refocus` if notify-send is absent.
- NUDGE-HISTORY: the `desktop-entry:refocus` hint matches a `refocus.desktop`
  entry (see INT) so the notification is logged in the desktop's history rather
  than shown-and-discarded. WHY: a nudge you can't scroll back to didn't happen.

---

## [SM] State machine

States are `(active, paused, focus_disabled)`. Legal states only:

```
idle+enabled    0 0 0      idle+disabled   0 0 1
active          1 0 0      paused          0 1 0
```

- SM-INVARIANT: `focus_disabled=1` implies idle (`active=0, paused=0`). The pair
  `active=1, focus_disabled=1` is illegal and unreachable through the commands.
  Enforced by the CMD-DISABLE guard (refuse while active/paused) — one guard at
  the entry point, not scattered checks.
- Transitions: `on` idle→active; `pause` active→paused; `continue` paused→active;
  `off` active|paused→idle; `enable` disabled→enabled (idle); `disable`
  idle→disabled; `reset`/`import` *→idle+disabled.
- `off` is reachable from any active/paused state regardless of `focus_disabled`
  (CMD-OFF-RECOVERY) — the one intentional exception, so a corrupted DB is escapable.

---

## [CONV] Conventions

- CONV-EXIT: `0` success · `1` runtime/state error (wrong state, not found) ·
  `2` usage/argument error. Used consistently; the test suite asserts them.
- CONV-YES: destructive ops (`reset`, `import`) require the user to type the
  literal word `yes`. Anything else cancels cleanly with exit 0 (cancel ≠ error).
- CONV-REARM: `reset` and `import` leave the tool **disabled**. Re-arming is a
  conscious `focus enable`. WHY: destroying or replacing data must not silently
  resume nudging behind the user.
- CONV-IDEMPOTENT-ENABLE: `enable` while already enabled is a no-op that says so.
  WHY: re-running it would re-phase the cron schedule for no reason; calling it
  defensively in scripts must be harmless.
- CONV-DURONLY: a `duration_only=1` row has no timestamps. Never feed an empty
  date string to `date(1)` (it parses as today-midnight and silently yields a
  zero/garbage duration — the data-loss bug). `modify` on such a row accepts only
  rename and `--duration` (see CMD-PAST-ARGS).
- (CONV-ENVFILE lives in [ENV]; CRON-STRIP / CRON-INTERVAL live in [CRON].)

---

## [INT] Install & shell integration — secondary tier

**Not covered by the oracle.** `tests/state-matrix.sh` runs `./focus` directly
against a throwaway `REFOCUS_DB_PATH`; it never installs, never loads the shell
hook, never delivers cron or notifications. These components must be spec-correct
and **hand-verified** — the test suite will not catch a regression here.

### INT-INSTALL · setup.sh
- `install` → install deps (apt/pacman/dnf); copy `env.sh`, `focus`,
  `focus-nudge`, `services/`, `lib/`, `core/`, `docs/` to `~/.local/refocus`;
  symlink `focus` into `~/.local/bin`; add the shell-hook source line to
  `~/.bashrc`; write the desktop entry (INT-DESKTOP); then **arm tracking**
  (`db_init` + `set_focus_enabled` + `cron_install`). WHY arm-on-install: a fresh
  install with `focus_disabled=0` but no cron is the DB-vs-reality mismatch from
  INV-3; install must leave both consistent.
- Reinstall preserves the existing `refocus.db` and `.env` (stash, wipe, restore).
- `uninstall` → `cron_remove`, remove the install dir, the symlink, the desktop
  entry, and the two `.bashrc` lines (anchored sed, not loose regex).

### INT-DESKTOP · refocus.desktop
- Written to `~/.local/share/applications/refocus.desktop`: `NoDisplay=true`
  (keep it out of launchers), `NotifyRcName=refocus`, a stock `Icon`. Its basename
  (`refocus`) is what NUDGE-HISTORY's hint matches.

### INT-SHELL · focus-function.sh
- Sourced from `~/.bashrc`. At shell init (once), source `env.sh` + `database.sh`
  guarded by file existence. WHY source the adapter into the interactive shell:
  the prompt hook reads state through `get_state` (INV-1) instead of its own SQL.
- `_refocus_prompt` (PROMPT_COMMAND hook): `⏳ [project]` when active,
  `⏸  [project]` when paused, original PS1 otherwise.
- `focus()` wrapper: run the dispatcher, then refresh the prompt immediately so
  the marker updates without waiting for the next prompt.

---

## [BUILD] Build guardrails (process, not code)

These bind the agent *generating* the code, not the code itself. They prevented a
recurring class of self-inflicted defects.

- BUILD-NO-REGEN: never emit a whole file through a nested escaping layer
  (a heredoc inside a `python -c "..."`, etc.). Backslashes, glyphs, and quote
  delimiters get silently mangled (a broken `sed` delimiter, dropped UTF-8,
  unquoted heredocs all shipped this way). Prefer surgical edits to exact strings
  read immediately before editing; when writing a whole file, write it directly.
- BUILD-VERIFY: after any change, run `tests/audit.sh` and `tests/state-matrix.sh`.
  A test harness is code too — assert by stable keys (project name), never by
  volatile row id, or the oracle lies.
- BUILD-UTF8: run shellcheck under `LC_ALL=C.UTF-8`; its output encoder crashes on
  multibyte glyphs otherwise.
- BUILD-SCOPE: one concern per change. Touch only the files the task names.

---

## [ACCEPT] Acceptance

A rebuild or change is correct when:
1. `tests/audit.sh` exits 0 (shellcheck clean, SC1090/91 suppressed for the
   genuinely-dynamic `$REFOCUS_ROOT` sources).
2. `tests/state-matrix.sh` exits 0 — every assertion: disable guards, on guards,
   the full on/pause/continue/off cycle, duration-only storage + modify guards
   (including `modify <id> --duration` with no project), import state
   normalisation, config round-trip, help dispatch.
3. `grep -rl sqlite3` over application files (excluding `tests/`) shows only
   `services/database.sh` (+ the `setup.sh` probe).
4. No symbol from DM-DEAD reappears.
5. Hand-verified (oracle blind spot, [INT]): install arms cron and leaves state
   consistent; the shell hook shows the prompt marker; `focus nudge test` lands a
   notification in history.

If you cannot satisfy this contract and the acceptance oracle simultaneously,
stop and surface the conflict. Do not pick one silently.
