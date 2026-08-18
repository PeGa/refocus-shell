# Refocus Shell

**A terminal focus tracker that respects your attention instead of policing it.**

Local. Private. No daemons. No streaks. No guilt.

```bash
git clone https://github.com/PeGa/refocus-shell
cd refocus-shell
./setup.sh install
source ~/.bashrc

focus on customer/project   # start — tracking is already on
focus status                # where am I right now?
focus pause                 # stepping away — no questions asked
focus continue              # back
focus off                   # done — jot a note for next time
focus report today          # where did the day actually go?
```

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Platform: Linux](https://img.shields.io/badge/Platform-Linux-lightgrey.svg)](https://www.linux.org/)
[![Shell: Bash](https://img.shields.io/badge/Shell-Bash-green.svg)](https://www.gnu.org/software/bash/)
[![Database: SQLite](https://img.shields.io/badge/Database-SQLite-yellow.svg)](https://www.sqlite.org/)

---

## The idea

Most time trackers are built to extract productivity. They count streaks, set goals, and make you feel the gap when you miss. For a brain that's wired a little differently — ADHD, autistic, AuDHD — that pressure backfires. Shame doesn't start tasks. A streak you'll inevitably break just hands you a reason to quit the whole thing.

Refocus was built from the opposite premise: **a brain that loses track of time doesn't need to be pushed harder. It needs a quiet external clock** — one that tells you where your attention is right now, and otherwise leaves you completely alone.

So that's all it does. It tracks where your focus went, honestly, without an opinion about it. Idle is a valid state. A four-hour hyperfocus is a valid state. The tool's only job is to make sure you *know* which one you're in.

Three rules it holds itself to:

- **It doesn't pressure you.** No streaks, no scores, no goals, no nagging about how much you "should" have done. The reports are facts, not verdicts. When you're not focusing on anything, it says *"Not focusing on anything"* — a neutral observation, never a scold.

- **It gets in the way just enough to prevent forgetting.** Every few minutes a small notification tells you what you're tracking — or that you're tracking nothing. That's the external clock for time-blindness: enough to surface a three-hour hyperfocus tunnel, or catch the *"wait, am I even still tracking this?"* gap. You can ignore it. It won't escalate.

- **It stays out of the way enough to not become a distraction itself.** No daemon humming in the background. No dashboard begging to be checked. No app window competing for the attention you're trying to protect. Refocus lives in two places: a small marker in your shell prompt, and a periodic notification. The tool you never have to manage.

---

## Designed around how the brain actually works

The behaviour isn't generic. Specific choices exist for specific reasons:

- **Pause asks you nothing.** Stepping away for a meeting or a coffee shouldn't cost you a cognitive toll. `focus pause` is silent — no prompt, no note, no friction. It's *"I'll be right back."* The periodic nudge quietly reminds you the session is still open so you don't lose it.

- **Notes come only when you stop, and they're for you.** `focus off` is the one moment it asks *"what did you accomplish?"* — because by then you've got the spare cycles, and the note is a re-entry anchor for next time. It defeats the *"what was I even doing?"* blank you hit when you come back hours or days later. It is not a status report for anyone else.

- **Starting is one word, or none.** `focus on` with no project offers to continue what you were last on. Low ignition cost matters when starting is the hard part.

- **Hyperfocus stays visible.** While a session runs, the nudge shows elapsed time — *"Focusing on: writing (143m)."* For a brain that disappears into a task, that's a gentle *"hey, it's been a while"* with zero instruction to stop. You decide.

- **It never silently re-arms.** After a `reset` or an `import`, Refocus deliberately leaves itself **disabled**. It won't quietly start nudging you again on its own. Re-engaging is a conscious choice you make with `focus enable`.

---

## Install

```bash
git clone https://github.com/PeGa/refocus-shell
cd refocus-shell
./setup.sh install
source ~/.bashrc
```

The installer detects your package manager and pulls any missing dependencies, copies the program to `~/.local/refocus/`, symlinks `focus` into `~/.local/bin/`, adds one line of shell integration to `~/.bashrc`, registers a desktop entry so notifications land in your notification history, **and arms tracking right away** — you don't need a separate enable step. After `source ~/.bashrc`, `focus on <project>` just works.

Reinstalling is safe: your database and `.env` overrides are preserved across upgrades.

```bash
./setup.sh uninstall
```

Removes the program, the symlink, the desktop entry, the shell integration, and the nudge schedule. Your exported data (if any) is untouched.

**Dependencies:**

| Package         | Required for                | Auto-installed |
|-----------------|-----------------------------|----------------|
| `sqlite3`       | everything                  | yes            |
| `libnotify-bin` | desktop notifications       | yes            |
| `cron`          | the periodic nudge          | yes            |
| `jq`            | JSON import only            | no             |

Works on Debian/Ubuntu (`apt`), Arch (`pacman`), and Fedora (`dnf`).

---

## In your prompt

The shell integration shows what you're tracking, right where you already look:

```
⏳ [customer/project] user@host:~$    actively focusing
⏸  [customer/project] user@host:~$    paused
user@host:~$                          idle (or disabled)
```

It updates the moment you run a `focus` command — no waiting for the next nudge. There's no daemon doing this; it's a lightweight hook that reads the current state once per prompt.

---

## Commands

### The focus cycle

```bash
focus on [project]    # start; no project = offer to continue your last one
focus pause           # pause — silent, the timer remembers where it was
focus continue        # resume, carrying your elapsed time forward
focus off             # stop, and capture a note for next time
focus status          # what's happening right now
```

**`focus on` is forgiving:**
- No project name → it offers to continue your last one (and shows the total time you've logged on it).
- A name you've used before → a gentle typo guard: *"`X` has 45m logged. Continue? (Y/n)"* — so a fat-fingered project name doesn't quietly start a duplicate ledger.
- A brand-new name → it just starts.
- Already focusing, or paused → it stops you and says what's open, so you never stack two sessions by accident.

**Why pause and off are different:**
- **`pause`** is a pit stop. Short interruption, you'll be right back. No note — a note would just be friction you don't need mid-step. The nudge keeps reminding you the session is open.
- **`off`** is a real stop. The note prompt is the point: *what was I doing, what's next.* That note is what saves you when you come back later.

Pausing never costs you billable time — the clock only counts the minutes you were actually focused, across any number of pause/resume cycles.

### Looking back and fixing up

```bash
focus past list [n]                                  # recent sessions
focus past add <project> <start> <end>               # log one with timestamps
focus past add <project> --duration 2h30m [--date YYYY/MM/DD]   # log one by duration
focus past modify <id> [project] [start] [end]       # fix a timestamped session
focus past modify <id> [project] [--duration 2h]     # fix a duration-only session
focus past delete <id>
```

Forgot to start the timer? Log it after the fact. Duration-only entries (for time you tracked in your head, or retroactively) carry a date but no clock times — and Refocus won't let you accidentally corrupt one by bolting fake timestamps onto it later.

### Reports

```bash
focus report today
focus report week
focus report month
focus report custom 14      # last 14 days
```

Total time, a per-project breakdown, and every session with its notes. Plain facts about where your attention went. No score attached.

### The nudge

Nudging is the external clock. It's a cron job that fires every few minutes and tells you, plainly:

- focusing → *"Focusing on: project (Nm)"*
- paused → *"Paused: project"*
- idle → *"Not focusing on anything."*

It's armed when you install (and by `focus enable`), and silenced by `focus disable`. It fires in every state on purpose — the idle reminder is what catches the days that quietly slip away from you. Notifications register with your desktop, so they show up in your notification history (KDE Plasma, GNOME, and other XDG-compliant desktops) rather than flashing and vanishing.

```bash
focus enable          # arm the nudge (install does this for you)
focus disable         # silence it (only when no session is open)
focus nudge status    # is it on? what's the schedule?
focus nudge test      # fire a test notification, check it lands
```

`focus disable` won't let you turn off tracking while a session is still running — a live timer with no reminders is exactly the state that loses you an afternoon. Close the session first.

### Configuration

```bash
focus config show                     # what's in effect, and what you've overridden
focus config set NUDGE_INTERVAL 5     # nudge every 5 minutes instead of 10
focus config unset NUDGE_INTERVAL     # back to default
```

| Key                  | Default                        | What it does                          |
|----------------------|--------------------------------|---------------------------------------|
| `NUDGE_INTERVAL`     | `10`                           | Minutes between nudges (1–60)         |
| `MAX_PROJECT_LENGTH` | `100`                          | Longest allowed project name          |
| `DATE_FORMAT`        | `%Y-%m-%d`                     | Date format in reports                |
| `DATE_SHORT_FORMAT`  | `%Y-%m-%d %H:%M`               | Datetime in the session list          |
| `REPORT_LIMIT`       | `20`                           | Default rows in `past list`           |
| `DB_PATH`            | `~/.local/refocus/refocus.db`  | Where your data lives                 |

Overrides live in a `.env` file next to your database. A new nudge interval takes effect the next time you `enable` (or `disable` then `enable`).

### Backup and restore

```bash
focus export [basename]               # writes basename.sql and basename.json
focus import <file.sql|file.json>     # replace everything from a backup
```

The `.sql` dump is the reliable backup format — it restores exactly. The `.json` is human-readable and portable (importing it needs `jq`). After any import, Refocus leaves itself disabled so it can't surprise you — run `focus enable` when you're ready to pick back up.

### Housekeeping

```bash
focus init      # (re)create the database
focus reset     # wipe everything — asks you to type "yes"
```

Both `reset` and `import` leave tracking disabled afterward. Destroying or replacing data should never silently flip the tool back on behind you.

---

## Time and duration formats

```
YYYY/MM/DD-HH:MM     2025/06/11-14:30    recommended — no quoting needed
HH:MM                14:30               today assumed
"yesterday 14:00"
"2 hours ago"
```

Durations: `1h30m`  ·  `2h`  ·  `45m`

---

## How it thinks about your data

**Sessions** are the real thing. Every `focus off` writes one row: the project, when it started and ended, how long it actually ran, and your note.

**Projects** are just labels — a name on a session. There's no project database, nothing to set up or maintain. The name *is* the identity. A `customer/project` convention reads well in reports, but that's a suggestion, not a rule.

**State** is a single row that tracks only what's happening *right now* — what you're focused on, whether you're paused, whether tracking is on. It's runtime, not history; wiping it never touches your sessions.

**The nudge** is a scheduled job, not a setting buried in a database. You arm it and silence it directly, and it does exactly one thing: remind you where your attention is.

---

## Exit codes

| Code | Meaning                                        |
|------|------------------------------------------------|
| `0`  | success                                        |
| `1`  | wrong state (e.g. nothing to pause)            |
| `2`  | usage / bad argument                           |

Destructive commands (`reset`, `import`) require you to type the literal word `yes`. Anything else cancels cleanly.

---

## For developers

Refocus is a small Bash program over SQLite, laid out hexagonally (ports and adapters):

```
focus                       dispatcher — routes `focus <cmd>` to lib/<cmd>.sh
lib/*.sh                    command handlers (primary adapters)
core/time.sh                pure helpers — duration/time parsing, no I/O
core/text.sh                pure helpers — decodes and indents stored notes
services/database.sh        the ONLY file that speaks SQL (secondary adapter)
services/help.sh            renders docs/help/*.txt for --help and usage errors
services/editor.sh          opens $EDITOR to capture a note
services/cron.sh            arms and disarms the nudge schedule
services/focus-function.sh  shell integration (prompt + focus() wrapper)
env.sh                      loads defaults and .env, exports config
focus-nudge                 the self-contained payload cron runs
docs/help/*.txt             per-command reference (also served by `focus help`)
tests/                      shellcheck wrapper + state-machine regression suite
```

Two rules keep it honest: **no SQL lives outside `services/database.sh`**, and **domain code never calls storage by name** — handlers ask for intent (`start_session`, `is_session_paused`, `set_focus_disabled`) and the adapter decides which column moves. Two more keep it portable and predictable: **`date(1)` is called only from `core/time.sh`** (GNU and BSD disagree on nearly all of its flags), and **no handler spells its own usage string** — `--help` and argument errors both render `docs/help/<cmd>.txt`, so they can never drift apart.

Run `tests/audit.sh` for static analysis and `tests/state-matrix.sh` for the behavioural regression suite. On macOS, also run `tests/time-portability.sh` — twice, with and without `gdate` on `PATH` — since the BSD branch of the time layer is unreachable on Linux.

---

## License

GPL v3. See [LICENSE](LICENSE).
