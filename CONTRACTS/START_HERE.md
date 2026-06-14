# CONTRACT_DIGEST.md — refocus-shell

> Load-first primer for an agent working on this codebase. Compressed for a small
> context window and ordered by *what models get wrong*, not by topic. Every line
> cites a handle into `CONTRACT.md`; expand the handle when you need the WHY.
> **This file is a pointer, not the authority.** Authority = `CONTRACT.md` + `tests/`.

---

## 0 · Prime directive

A terminal focus/time tracker. Bash over one SQLite DB. No daemon. A **cron job**
nudges; a **shell hook** shows state in the prompt. Hexagonal: handlers name
intent, one file speaks SQL. You are correct iff `tests/audit.sh` **and**
`tests/state-matrix.sh` both exit 0 — no matter how reasonable your change looks.
`[ACCEPT]`

---

## 1 · DO NOT RE-ADD (negative space) — top failure mode

If you reach for any of these, you're channelling the dead architecture. Stop.
`[DM-DEAD]`

| Don't add | Because |
|---|---|
| `projects` table / `focus describe` / stored project metadata | a project is a **string on a session row**, not an entity `[DM-PROJECT]` |
| `pause_notes` / any note prompt at pause | pause is **silent** `[INV-4]` |
| `nudging_enabled` flag / gating nudges on a state column | nudging *is* the cron's existence `[INV-3]` |
| `[idle]` session rows | idle is a state, never a session row |
| `nudge enable` / `nudge disable` commands | replaced by `focus enable`/`disable` |
| recomputing duration from timestamps at read time | `duration_seconds` is authoritative `[DM-SESSION]` |

Old DBs may carry `pause_notes` / `nudging_enabled` columns. **Leave them.**
`db_migrate` is additive-only, never drops. Never read them.

---

## 2 · The five invariants (never violated, not for any edge case)

- **INV-1 · No SQL outside the adapter.** Only `services/database.sh` calls
  `sqlite3` or builds SQL. App code goes through intent functions.
  Tests under `tests/` *must* query `sqlite3` directly (independent oracle).
  CHECK: `grep -rl sqlite3` over app files (excl. `tests/`) → only
  `services/database.sh` (+ a `command -v` probe in `setup.sh`).
- **INV-2 · Name intent, never storage.** Handlers call `start_session`,
  `is_session_paused`, `set_focus_disabled`. The `db_*` prefix is reserved for
  schema lifecycle + serialization only — not domain work. `[NAME]`
- **INV-3 · Nudging is structural.** It exists iff a cron entry exists.
  `enable` installs, `disable` removes. `focus_disabled=1` is *only* a kill
  switch the payload checks — it is not what "enabled" means. `on`/`off`/`pause`/
  `continue` **never** touch cron. Only `enable`/`disable`/`reset`/`import`/`setup.sh` do.
- **INV-4 · Pause is silent.** `focus pause` captures nothing. The only note in
  the system is captured by `focus off`, written straight to the session.
- **INV-5 · State is runtime; sessions are data.** Any restore/wipe normalises
  state to **idle + disabled** (`reset_state_post_import`), regardless of the
  backup's state. Sessions restore verbatim. (Prevents the import-zombie timer.)

---

## 3 · Layering map

```
focus                     dispatcher: sets+exports REFOCUS_ROOT, routes focus <cmd> → exec lib/<cmd>.sh
lib/<cmd>.sh              PRIMARY adapter, one per command, routable, drives core via intent calls
core/<topic>.sh           DOMAIN helpers, pure str/int→str/int, NO sql/cron/state, NOT routable
services/database.sh      SECONDARY adapter, the ONLY file that speaks SQL (INV-1)
services/cron.sh          SECONDARY adapter, arms/disarms nudge schedule
services/focus-function.sh shell integration: prompt hook + focus() wrapper
env.sh                    config loader, sourced first everywhere, exports DB_PATH etc.
focus-nudge               self-contained cron payload, sources env.sh + database.sh
docs/help/<cmd>.txt       help served verbatim by lib/help.sh, never duplicated in code
```

- Dispatch is **dynamic by filename, no case table**. Adding a command = adding
  `lib/<cmd>.sh`. A file under `core/`/`services/` is never a command —
  `core/time.sh` does **not** create a `focus time`. `[ARCH-ROUTABLE]`
- Root resolution is exactly
  `REFOCUS_ROOT="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"`, set once by the
  dispatcher, exported. Handlers never re-derive it. No `$0`/`cd $PWD` games. `[ARCH-ROOT]`
- Every handler: source `env.sh` → its deps → `db_ensure` if it touches the DB. `[ARCH-SOURCE]`

---

## 4 · Hard contracts (get these byte-exact)

**`get_state` returns exactly 8 pipe-separated fields, this order, empties as `''`:**
```
active|project|start_time|paused|pause_start_time|previous_elapsed|focus_disabled|last_off_time
```
`[PORT]` `[DM-STATE]`

**Session reads return 8-field rows:**
```
id|project|start|end|dur|notes|duration_only|session_date
```

**Legal states only** `(active, paused, focus_disabled)`: `[SM]`
```
idle+enabled  0 0 0     idle+disabled  0 0 1
active        1 0 0     paused         0 1 0
```
`active=1, focus_disabled=1` is **illegal and unreachable**. One guard enforces it
(CMD-DISABLE refuses while active/paused). `off` is the *one* exception — reachable
from any active/paused state regardless of `focus_disabled`, so a corrupt DB is
escapable. `[SM-INVARIANT]` `[CMD-OFF-RECOVERY]`

**`continue` math:** resume with `start = now − previous_elapsed`, so
`duration = now − start` stays correct across any number of pause cycles. Paused
wall-time is never counted. `[CMD-CONTINUE]`

**`off` duration:** active → `now − start`; paused → `previous_elapsed`. `[CMD-OFF]`

---

## 5 · Conventions

- **Exit codes:** `0` success · `1` runtime/state error · `2` usage/arg error.
  The suite asserts these. `[CONV-EXIT]`
- **Destructive ops** (`reset`, `import`) require the literal word `yes`; anything
  else cancels cleanly with exit 0 (cancel ≠ error). `[CONV-YES]`
- **`reset`/`import` leave the tool disabled.** Re-arming is a conscious
  `focus enable`. `[CONV-REARM]`
- **`enable` while enabled** is a no-op that says so (don't re-phase cron). `[CONV-IDEMPOTENT-ENABLE]`
- **duration-only rows** have no timestamps — never feed an empty date to
  `date(1)` (parses as today-midnight → silent zero duration). `modify` on them
  accepts rename + `--duration` only. `[CONV-DURONLY]`
- **`ENV_FILE`** is computed once in `env.sh` and exported; never re-derived
  (split-brain `.env` bug). `[CONV-ENVFILE]`
- **cron strip** is fixed-string (`grep -vF`), never regex, always against the
  *live* crontab (the path contains `.`). `[CRON-STRIP]`

---

## 6 · Build guardrails (bind YOU, the generating agent)

- **BUILD-NO-REGEN:** never emit a whole file through a nested escaping layer
  (heredoc inside `python -c`, etc.) — backslashes, UTF-8, and quote delimiters
  get silently mangled. Surgical edits to exact strings read immediately before
  editing; when writing a whole file, write it directly. *(This is the #1 way
  local models corrupt this repo.)*
- **BUILD-VERIFY:** after any change run both test scripts. Assert by stable keys
  (project name), never volatile row id.
- **BUILD-UTF8:** run shellcheck under `LC_ALL=C.UTF-8`.
- **BUILD-SCOPE:** one concern per change; touch only the files the task names.

---

## 7 · Done check

1. `tests/audit.sh` exits 0 (shellcheck clean).
2. `tests/state-matrix.sh` exits 0.
3. `grep -rl sqlite3` over app files (excl. `tests/`) → only `services/database.sh`.
4. No DM-DEAD symbol reappeared.
5. Hand-verify the oracle's blind spot `[INT]`: install arms cron + leaves state
   consistent; shell hook shows the prompt marker; `focus nudge test` lands a
   notification in history.

If the contract and the oracle can't both be satisfied, **stop and surface the
conflict** — don't pick one silently.
