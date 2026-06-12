# Refocus Shell

**Terminal-first focus and time tracker. Local, private, no daemons.**

```bash
git clone https://github.com/PeGa/refocus-shell && cd refocus-shell && ./setup.sh install
source ~/.bashrc

focus enable                # arm nudge cron, ready to track
focus on customer/project   # start
focus status                # check in
focus pause                 # pit stop — silent, timer remembers
focus continue              # pick up where you left off
focus off                   # stop, capture notes
focus report today          # see your day
```

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Platform: Linux](https://img.shields.io/badge/Platform-Linux-lightgrey.svg)](https://www.linux.org/)
[![Shell: Bash](https://img.shields.io/badge/Shell-Bash-green.svg)](https://www.gnu.org/software/bash/)
[![Database: SQLite](https://img.shields.io/badge/Database-SQLite-yellow.svg)](https://www.sqlite.org/)

---

## Why Refocus?

Most time trackers want you to manage *work*. Refocus tracks *where your focus went* — honest to you and honest to anyone who wants to understand where time went, not just clock seats.

- **No daemons.** No background processes. State lives in SQLite.
- **Prompt integration.** `⏳ [project]` in your shell prompt across all terminals.
- **Pause/resume.** Interruptions happen. Sessions survive them cleanly.
- **Nudging is structural.** A cron job reminds you periodically. It fires whether you're focusing, paused, or idle. It's not a flag you toggle — it's a clock you arm once.
- **Local only.** No telemetry, no cloud, no accounts.

---

## Install

```bash
git clone https://github.com/PeGa/refocus-shell
cd refocus-shell
./setup.sh install
source ~/.bashrc
focus enable
```

The installer: detects your package manager and installs missing deps, copies files to `~/.local/refocus/`, symlinks `focus` into `~/.local/bin/`, and adds the shell integration to `~/.bashrc`.

Reinstalling is safe — existing database and `.env` overrides are preserved.

```bash
./setup.sh uninstall
```

**Dependencies:**

| Package         | Required for                    | Auto-installed |
|-----------------|---------------------------------|----------------|
| `sqlite3`       | everything                      | yes            |
| `libnotify-bin` | desktop nudge notifications     | yes            |
| `cron`          | timed nudges                    | yes            |
| `jq`            | JSON import only                | no             |

---

## Shell integration

The installer adds one line to `~/.bashrc`:

```bash
source ~/.local/refocus/services/focus-function.sh
```

This sources `config.sh` and `database.sh` once at shell startup, hooks `_refocus_prompt` into `PROMPT_COMMAND`, and wraps `focus` as a shell function so the prompt updates immediately after each command.

Prompt states:
```
⏳ [project] user@host:~$   active session
⏸  [project] user@host:~$   paused session
user@host:~$                 not tracking (or disabled)
```

---

## Commands

### Session lifecycle

```bash
focus on [project]    # start; no project = offer to continue last
focus off             # stop and capture notes
focus pause           # pause (silent — no notes; nudge reminds you)
focus continue        # resume carrying elapsed time forward
focus status          # current state, elapsed, last session
```

**`focus on` confirmation flow:**
- No args → offer to continue last project (shows total time logged).
- Named project with prior time → typo guard: *"X has Ym logged. Continue? (Y/n)"*
- Named project, no prior time → start immediately.
- While disabled → hard stop. Run `focus enable` first.
- While active or paused → hard stop. Resolve the existing session first.

**Pause vs off:**
- `pause` is a pit stop. Notes would just be noise — the periodic nudge reminds you the session exists.
- `off` is a real stop. The note prompt is the context anchor: *"what was I doing, what's next."*

**Pause/continue math:**  
`previous_elapsed` is baked into an adjusted `start_time` on resume so that `duration = now - start_time` gives the correct total across any number of pause/continue cycles. Duration while paused is never billed.

### Past sessions

```bash
focus past list [n]                              # last n sessions
focus past add <project> <start> <end>           # with timestamps
focus past add <project> --duration Xh [--date YYYY/MM/DD]  # duration-only
focus past modify <id> [project] [start] [end]   # edit timestamped
focus past modify <id> [project] [--duration Xh] # edit duration-only
focus past delete <id>
```

Duration-only sessions (from `--duration`) have no timestamps. Their `session_date` is used for report filtering. Trying to add timestamps to a duration-only session via `modify` is an error.

### Reports

```bash
focus report today
focus report week
focus report month
focus report custom <days>    # last N days
```

Prints total time, per-project breakdown, and per-session detail with notes.

### Nudge system

Nudging is structural — it's a cron job, not a flag.

```bash
focus enable    # arm cron: fires focus-nudge every NUDGE_INTERVAL minutes
focus disable   # disarm cron (requires no active or paused session)

focus nudge status   # show enabled state + active cron entry
focus nudge test     # fire a test notification; validate the nudge script
```

`focus-nudge` is a self-contained cron payload. It fires in all states:
- Active → *"Focusing on: X (Nm)"*
- Paused → *"Paused: X"*  
- Idle → *"Not focusing on anything."*

It exits silently when disabled. The `REFOCUS_ROOT` is embedded in the cron entry so it resolves correctly under cron's stripped environment.

### Configuration

```bash
focus config show                  # effective values + active overrides
focus config set NUDGE_INTERVAL 5  # write to .env
focus config unset NUDGE_INTERVAL  # remove override
```

| Key                  | Default              | Notes                           |
|----------------------|----------------------|---------------------------------|
| `NUDGE_INTERVAL`     | `10`                 | Nudge frequency, minutes (1–60) |
| `MAX_PROJECT_LENGTH` | `100`                | Max project name length         |
| `DATE_FORMAT`        | `%Y-%m-%d`           | Date format in reports          |
| `DATE_SHORT_FORMAT`  | `%Y-%m-%d %H:%M`     | Datetime in session list        |
| `REPORT_LIMIT`       | `20`                 | Default row limit for past list |
| `DB_PATH`            | `~/.local/refocus/refocus.db` |                        |

Overrides are stored in `.env` co-located with the database. Precedence: env vars → `.env` → built-in defaults.

### Export / Import

```bash
focus export [basename]            # produces basename.sql + basename.json
focus import <file.sql|file.json>  # overwrites all data
```

After import, state is normalized to **idle + disabled**. Run `focus enable` to resume. This is the same conscious-re-arm behavior as `focus reset`.

SQL export is the recommended backup format. JSON export is for portability and human inspection. JSON import requires `jq`.

### Other

```bash
focus enable / focus disable    # toggle tracking globally
focus init                      # (re)initialise the database schema
focus reset                     # wipe ALL data — requires typing "yes"
```

`focus reset` and `focus import` both leave Refocus **disabled**. Intentional: data destruction should require a conscious re-arm.

---

## Time and duration formats

```
YYYY/MM/DD-HH:MM     2025/06/11-14:30   recommended (no quoting)
HH:MM                14:30              today assumed
"yesterday 14:00"
"2 hours ago"
```

Durations (`--duration`): `1h30m`  `2h`  `45m`

---

## Domain model

**Sessions** are the real entity. Every `focus off` writes one row:  
`project | start_time | end_time | duration_seconds | notes | duration_only | session_date`

**Projects** are labels — a string on a session row. There is no projects table, no `focus describe`, no stored project metadata. The name is the identity. Recommended format: `customer/project-name`.

**State** is a single-row table (`id=1`) tracking what's happening *right now*: `active`, `project`, `start_time`, `paused`, `pause_start_time`, `previous_elapsed`, `focus_disabled`, `last_off_time`. State is reset to idle+disabled after `reset` and `import` — it's runtime, not data.

**Nudging** is a cron job, not a flag. `focus enable` arms it. `focus disable` disarms it. `focus_disabled=1` is the kill switch that `focus-nudge` checks on every fire.

---

## Exit codes

| Code | Meaning                                         |
|------|-------------------------------------------------|
| `0`  | success                                         |
| `1`  | runtime/state error (wrong state, not found)    |
| `2`  | usage/argument error                            |

`focus reset` and `focus import` require the literal word `yes` — anything else exits `0` (cancelled, not error).

---

## Architecture (for developers)

Hexagonal / ports-and-adapters layout:

```
lib/*.sh              primary adapters  — receive user input, drive the core
services/database.sh  secondary adapter — the ONLY file that calls sqlite3
services/cron.sh      secondary adapter — cron arm/disarm
services/focus-function.sh  shell integration (PS1, focus() wrapper)
config.sh             constants and .env loader
focus                 dispatcher: sets REFOCUS_ROOT, routes to lib/${cmd}.sh
focus-nudge           self-contained cron payload
docs/help/*.txt       per-command authoritative spec (LLM-addressable by path)
```

No SQL outside `services/database.sh`. No domain ops named `db_*`. Primary adapters call intent-named functions (`start_session`, `is_session_paused`, `set_focus_disabled`). The adapter layer is the only place that knows what column moves.

---

## License

GPL v3. See [LICENSE](LICENSE).
