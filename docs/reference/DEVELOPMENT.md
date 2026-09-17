# Development guide

Refocus is a small Bash program over SQLite, laid out hexagonally (ports and adapters). This document covers the architecture, the rules that keep it honest, and how to run the test suite.

For the contribution workflow (build order, naming, commit discipline), see [CONTRIBUTING.md](CONTRIBUTING.md).

---

## File layout

```
focus                       dispatcher — sets REFOCUS_ROOT, routes focus <cmd> → exec lib/<cmd>.sh
focus-nudge                 self-contained cron payload (nudge). sources env.sh + database.sh + core/time.sh
focus-checkin               self-contained cron payload (check-in). sources env.sh + database.sh + core/time.sh
lib/*.sh                    command handlers — one file per command
core/time.sh                pure helpers — duration/time parsing, owns the GNU/BSD date(1) split
core/text.sh                pure helpers — decodes and indents stored notes
services/database.sh        infrastructure — the ONLY file that speaks SQL
services/cron.sh            infrastructure — arms/disarms nudge and check-in schedules
services/desktop.sh         integration — desktop dialog adapter (kdialog/zenity)
services/editor.sh          integration — captures notes through $EDITOR
services/help.sh            integration — renders docs/help/<cmd>.txt (show_help/usage_error)
services/merge.sh           composer — duplicate-session merge rule
services/period.sh          composer — period resolution (cycle selector → id window)
services/focus-function.sh  shell integration (prompt hook + focus() wrapper)
env.sh                      config loader — reads .env, exports DB_PATH, NUDGE_INTERVAL, etc.
docs/help/<cmd>.txt         per-command help, served verbatim by services/help.sh
setup.sh                    install/uninstall — arms cron on fresh install
tests/                      three test oracles (see below)
```

---

## Architecture rules

Four rules keep the codebase honest:

1. **No SQL outside `services/database.sh`.** Every other file speaks intent (`start_session`, `is_session_paused`, `set_focus_disabled`) and the adapter decides which column moves. This is the single most important invariant — violating it means storage logic leaks into domain code and the hexagonal boundary collapses.

2. **`date(1)` is called only from `core/time.sh`.** GNU and BSD disagree on nearly all of its flags (`--date` vs `-d`, `-Iseconds`, etc.). Every other file goes through `parse_time`, `parse_duration`, `now_epoch`, `iso_to_epoch`, etc. The BSD branch is unreachable on Linux — that's the point; it's tested on macOS via `tests/time-portability.sh`.

3. **No handler spells its own usage string.** `--help` and argument errors both render `docs/help/<cmd>.txt` via `show_help` / `usage_error`. Help is data, never code. If a handler spells its own "Usage:" line, it will drift from the help file.

4. **Domain code never calls storage by name.** Handlers don't say `sessions` or `state` — they say `start_session`, `get_state`, `set_focus_disabled`. The adapter decides the schema.

---

## Dispatch

Dispatch is **dynamic by filename, no case table**. Adding a command means adding `lib/<cmd>.sh` — nothing to register, nothing to update in the dispatcher. A file under `core/` or `services/` is never a command (`core/time.sh` does not create a `focus time`).

Root resolution is exactly:
```bash
REFOCUS_ROOT="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
```
set once by the dispatcher, exported everywhere. Handlers never re-derive it.

---

## Source order

Every handler sources its dependencies in this order:
```
env.sh → services/database.sh → [core/time.sh if needed] → db_ensure
```
Additional services (`editor.sh`, `help.sh`, `cron.sh`, etc.) come after `database.sh`.

---

## Testing

Three test scripts form the verification suite. All must pass before a change is done:

```bash
bash tests/audit.sh              # shellcheck wrapper — static analysis
bash tests/state-matrix.sh       # behavioural regression suite (300+ checks)
bash tests/time-portability.sh   # GNU/BSD date(1) portability probe
```

- **`audit.sh`** runs shellcheck across the entire codebase. Zero warnings allowed.
- **`state-matrix.sh`** exercises the full state machine — enable/disable, on/pause/continue/off, past, report, config, import/export, reset, cycle. Each check asserts exit code and output.
- **`time-portability.sh`** probes `core/time.sh` against the system's `date(1)`. On macOS, run it twice: once with `gdate` on `PATH` and once without, to exercise both branches.

A task is not done until all three exit 0.

---

## Contracts

The full contract lives in `CONTRACTS/MAIN.md`. The digest is `CONTRACTS/START_HERE.md`. Read the digest before acting; expand to `MAIN.md` (via `CONTRACTS/CONTRACT_INDEX.md`) when the digest is not enough.

The contract governs invariants (INV-*), naming conventions (CONV-*), architecture rules (ARCH-*), and command specifications (CMD-*). When the contract and the tests disagree, the contract is the authority.
