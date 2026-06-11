# Refocus Shell

**Terminal-first focus tracker for neurodivergent minds — local, private, no daemons.**

```bash
git clone https://github.com/PeGa/refocus-shell && cd refocus-shell && ./setup.sh install
source ~/.bashrc

focus on "my-project"   # start
focus status            # check in
focus off               # stop + notes
focus report today      # see your day
```

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Platform: Linux](https://img.shields.io/badge/Platform-Linux-lightgrey.svg)](https://www.linux.org/)
[![Shell: Bash](https://img.shields.io/badge/Shell-Bash-green.svg)](https://www.gnu.org/software/bash/)
[![Database: SQLite](https://img.shields.io/badge/Database-SQLite-yellow.svg)](https://www.sqlite.org/)
[![Privacy: Local-First](https://img.shields.io/badge/Privacy-Local--First-brightgreen.svg)](https://en.wikipedia.org/wiki/Local-first_software)

---

## Why Refocus?

Most time trackers want you to manage *work*. Refocus tracks *where your focus went* — honest to you and honest to anyone above you who wants to steer the team, not clock the seats.

- **No daemons.** No background processes. State lives in SQLite.
- **Multi-terminal prompt.** Start in one terminal, `⏳ [project]` shows up in all of them.
- **Pause/resume.** Multi-day sessions are valid. Breaks are unjudgmental.
- **Local only.** No telemetry, no cloud sync, no accounts. Your patterns are yours.
- **GPLv3.** Free software with a privacy-first philosophy baked in.

---

## Install

```bash
git clone https://github.com/PeGa/refocus-shell
cd refocus-shell
./setup.sh install
```

The installer:
- auto-detects your package manager and installs `sqlite3`, `libnotify-bin`, and `cron` if missing
- copies everything to `~/.local/refocus/`
- symlinks `focus` into `~/.local/bin/`
- appends shell integration to `~/.bashrc`

Then activate the integration in your current shell:

```bash
source ~/.bashrc
```

To uninstall:

```bash
./setup.sh uninstall
```

### Shell Integration

The installer adds one line to your `~/.bashrc`:

```bash
source ~/.local/refocus/services/focus-function.sh
```

This does two things:

1. Hooks `_refocus_prompt` into `PROMPT_COMMAND` — your prompt reads state from the DB on every `Enter`, zero spawned processes.
2. Wraps `focus` as a shell function so the prompt updates *immediately* after any command, without waiting for the next prompt.

Prompt states:
```
⏳ [project] user@host:~$   # active session
⏸  [project] user@host:~$   # paused session
user@host:~$                 # not tracking
```

---

## Commands

### Session lifecycle

```bash
focus on [project]      # start session; no project = continue last
focus off               # stop and capture notes
focus pause             # pause with context notes
focus continue          # resume paused session
focus status            # current state, elapsed time, last session
```

`focus continue` asks whether to carry forward the prior elapsed time or restart the timer.

### Past sessions

```bash
focus past list [n]                         # last n sessions (default 20)
focus past add <project> <start> <end>      # add with timestamps
focus past add <project> --duration Xh [--date YYYY/MM/DD]   # duration-only entry
focus past modify <id> [project] [start] [end]
focus past delete <id>
```

### Reports

```bash
focus report today
focus report week
focus report month
focus report custom <days>    # e.g. focus report custom 14
```

Reports print to stdout: total time, project breakdown, per-session detail with notes.

### Nudges

```bash
focus nudge enable     # turn on cron-based reminders (every NUDGE_INTERVAL minutes)
focus nudge disable
focus nudge status     # shows state + active crontab entry
focus nudge test       # fires a test notification + validates the nudge script
```

The cron entry is installed dynamically when you `focus on` and removed on `focus off` — interval anchors to your session start minute so nudges land at consistent offsets, not random cron ticks.

### Project descriptions

```bash
focus describe add <project> "description"
focus describe show <project>
focus describe remove <project>
focus describe list
```

Descriptions show up in `focus status` and `focus report`.

### Export / Import

```bash
focus export [basename]          # produces basename.sql + basename.json
focus import <file.sql|file.json>
```

Export uses `sqlite3 -json` (no extra deps). JSON import requires `jq`.

SQL export is the safe backup format. JSON export is human-readable and portable.

### Configuration

```bash
focus config show                  # effective values + active overrides
focus config set <KEY> <value>     # write to ~/.local/refocus/.env
focus config unset <KEY>           # remove override, revert to default
```

Valid keys and defaults:

| Key                  | Default              | Description                     |
|----------------------|----------------------|---------------------------------|
| `NUDGE_INTERVAL`     | `10`                 | Nudge frequency in minutes      |
| `MAX_PROJECT_LENGTH` | `100`                | Max project name length (chars) |
| `DATE_FORMAT`        | `%Y-%m-%d`           | Date format in reports          |
| `DATE_SHORT_FORMAT`  | `%Y-%m-%d %H:%M`     | Datetime format in session list |
| `REPORT_LIMIT`       | `20`                 | Default row limit for `past list` |
| `DB_PATH`            | `~/.local/refocus/refocus.db` | Database path            |

All keys can also be set via `REFOCUS_<KEY>` environment variables — they take precedence over `~/.local/refocus/.env`, which takes precedence over built-in defaults.

### Other

```bash
focus enable / focus disable    # toggle tracking globally
focus init                      # (re)initialise the database
focus reset                     # wipe ALL data — requires typing "yes"
```

---

## Time and duration formats

Anywhere a timestamp is accepted:

```
YYYY/MM/DD-HH:MM     2025/06/11-14:30   (recommended — no quoting needed)
HH:MM                14:30              (today assumed)
"yesterday 14:00"
"2 hours ago"
```

Durations (`--duration`):

```
1h30m   2h   45m
```

---

## Privacy & design philosophy

**No cloud, no telemetry.** All data is in `~/.local/refocus/refocus.db`. Nothing leaves your machine.

**No gamification.** No streaks, no points, no badges. Focus isn't linear and the tool doesn't pretend it is.

**Pause is not failure.** Sessions can span multiple days. Multi-hour gaps mid-session are fine. The tool tracks what you tell it, not what it infers.

**No daemons.** The cron entry for nudges is installed when you `focus on` and removed when you `focus off`. Zero persistent processes when you're not tracking.

---

## Dependencies

| Package         | Required for                        | Auto-installed |
|-----------------|-------------------------------------|----------------|
| `sqlite3`       | everything                          | yes            |
| `libnotify-bin` | desktop notifications (nudges)      | yes            |
| `cron`          | timed nudges                        | yes            |
| `jq`            | JSON import only                    | no             |

---

## License

Refocus Shell is licensed under the GNU General Public License v3.0. See [LICENSE](LICENSE) for details.
