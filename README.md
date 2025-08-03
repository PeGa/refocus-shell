# Refocus Shell

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Platform: Linux](https://img.shields.io/badge/Platform-Linux-lightgrey.svg)](https://www.linux.org/)
[![Shell: Bash](https://img.shields.io/badge/Shell-Bash-green.svg)](https://www.gnu.org/software/bash/)
[![Database: SQLite](https://img.shields.io/badge/Database-SQLite-yellow.svg)](https://www.sqlite.org/)
[![Privacy: Local-First](https://img.shields.io/badge/Privacy-Local--First-brightgreen.svg)](https://en.wikipedia.org/wiki/Local-first_software)

> 🧠 **Built for neurodivergent devs, sysadmins, and anyone tired of forgetting where their time went.**  
> Refocus Shell is a terminal-first, privacy-conscious time tracker that nudges, reflects, and gets out of your way.

## 📚 Table of Contents
- [Who It's For](#who-its-for)
- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
- [Smart Work Continuation](#smart-work-continuation)
- [Enhanced Status Information](#enhanced-status-information)
- [Cumulative Time Tracking](#cumulative-time-tracking)
- [Past Session Management](#past-session-management)
- [Discrete Session Management](#discrete-session-management)
- [Work Reports](#work-reports)
- [Nudging System](#nudging-system)
- [Data Import/Export](#data-importexport)
- [Configuration](#configuration)
- [Uninstallation](#uninstallation)
- [Dependencies](#dependencies)
- [Database](#database)
- [Troubleshooting](#troubleshooting)
- [Development](#development)
- [License](#license)

## Who Should Use This?

- **Neurodivergent users** (ADHD/autistic) seeking better time awareness without overwhelming complexity
- **Developers and sysadmins** who need **low-friction structure** for billable hour tracking
- **Freelancers** tired of guessing where their hours went
- **People who want to respect their own pace**, not corporate metrics
- **Anyone who wants local-first, privacy-respecting workflow tools**
- **People who don't want their productivity tools to spy on them**

> 💡 **Pro Tip**: The `⏳ [project]` prompt tag works **across all terminals** - start work in one terminal, and every new terminal you open will show your current project!

## Features

- **Core Work Tracking**: `work on/off/status` commands
- **Smart Continuation**: `work on` without project continues last session
- **Enhanced Status**: Rich context about last session and time tracking
- **Cumulative Time Tracking**: Shows total time invested in each project across sessions
- **Past Session Management**: Add, modify, and delete historical work sessions with flexible timestamp formats
- **Work Reports**: Generate markdown reports for today, week, month, or custom periods
- **Discrete Session Management**: ADHD-friendly work/idle session tracking with automatic break tracking
- **Desktop Notifications**: `notify-send` integration
- **Shell Integration**: Dynamic prompt modification with `⏳ [Project]` indicator
- **Intelligent Nudging**: Periodic reminders every 10 minutes via cron
- **Refocus Shell Control**: `work enable/disable` commands
- **Data Import/Export**: SQLite dump-based backup and restore functionality
- **Professional Installation**: Interactive setup with dependency management and installation method choice
- **Cross-Distribution Support**: Ubuntu/Debian, Arch/Manjaro, Fedora/RHEL, openSUSE
- **Verbose Mode**: `--verbose` flag for debugging and detailed output
- **Function vs Script Installation**: Choose between automatic prompt updates or traditional script execution

## Installation

### Quick Start

```bash
# Clone the repository
git clone https://github.com/PeGa/refocus-shell
cd refocus-shell

# Run the interactive installer
./setup.sh install
```

The installer will:
- Detect your Linux distribution
- Install required dependencies (`sqlite3`, `notify-send`, `jq`)
- Set up the database and configuration
- Offer installation method choice (Function vs Script)
- Configure shell integration for prompt modification
- Set up cron jobs for nudging functionality

### Installation Methods

Refocus Shell offers two installation methods:

#### Function Installation (Recommended)
- **Automatic prompt updates** - no manual `update-prompt` calls needed
- **Works in all shell environments** - bash, zsh, etc.
- **Seamless integration** - `work` command available immediately
- **Default choice** for new installations

#### Script Installation (Traditional)
- **Traditional executable script** - works like any other command
- **Manual prompt updates** - requires `update-prompt` calls
- **May need PATH configuration** - depends on installation location
- **Backward compatibility** - for users who prefer explicit control

### Non-Interactive Installation

For automated deployments or CI/CD:

```bash
# Auto-install with all defaults
./setup.sh install --auto

# Verbose output for debugging
./setup.sh install --auto --verbose
```

### Installation Options

| Option | Description |
|--------|-------------|
| `--auto` | Non-interactive installation with defaults |
| `--verbose` | Show detailed installation steps |
| `--help` | Show installation help |

## Usage

### Basic Commands

```bash
work on "project"     # Start working on a project
work off              # Stop current work session
work status           # Show current work status
work help             # Show all available commands
```

### Quick Examples

```bash
# Start working
work on "coding"
work on "meeting"
work on "planning"

# Check status
work status

# Stop working
work off

# Add past sessions with flexible timestamps
work past add "project" "2025/07/30-14:00" "2025/07/30-16:00"  # Add past work session
work past add "meeting" "14:00" "15:30"           # Today's times
work past add "coding" "2025/07/30-14:00" "16:00" # Specific date
work past add "planning" "2 hours ago" "1 hour ago" # Relative times

# Generate reports
work report today
work report week
work report month
work report custom 7  # Last 7 days

# Manage data
work export backup.sql
work import backup.sql
work reset  # Reset all data (with confirmation)
```

### Smart Work Continuation

Refocus Shell remembers your last project and session:

```bash
$ work on "coding"
Started work on: coding

$ work off
Stopped work on: coding (Duration: 2h 15m)

$ work on  # No project specified
Started work on: coding  # Continues last project
```

### Enhanced Status Information

Get rich context about your work:

```bash
$ work status
⏳ [coding] Started: 14:30 (2h 15m ago)
📊 Total time on coding: 12h 45m (across 8 sessions)
🕐 Last session: coding (2h 15m, ended 2h 15m ago)
💡 Tip: Run 'work report today' to see today's summary
```

### Cumulative Time Tracking

Refocus Shell tracks total time across all sessions:

```bash
$ work report today
📊 Today's Work Summary
=======================

⏰ Total work time: 6h 30m
📋 Total sessions: 4
🎯 Active projects: 2

📈 Project Breakdown:
  coding: 4h 15m (2 sessions)
  meeting: 2h 15m (2 sessions)

📅 Recent Sessions:
  1. coding (14:30-16:45, 2h 15m)
  2. meeting (10:00-12:15, 2h 15m)
  3. coding (09:00-11:00, 2h 00m)
  4. meeting (08:00-09:00, 1h 00m)
```

### Past Session Management

Add, modify, and delete historical work sessions with flexible timestamp formats:

```bash
# Add past sessions
work past add "meeting" "14:00" "15:30"                          # Today's times
work past add "coding" "2025/07/30-14:00" "2025/07/30-16:00"     # Specific date
work past add "planning" "2 hours ago" "1 hour ago"               # Relative times
work past add "review" "yesterday 14:00" "yesterday 16:00"       # Yesterday
work past add "team meeting" "2025/07/30-14:00" "2025/07/30-16:00" # Full date

# List recent sessions
work past list 10

# Modify a session
work past modify 1 "new-project" "2025/07/30-15:00" "2025/07/30-17:00"

# Delete a session
work past delete 1
```

**Supported Date Formats:**
- `YYYY/MM/DD-HH:MM` (recommended: `2025/07/30-14:30`)
- `HH:MM` (today's date)
- `'YYYY-MM-DD HH:MM'` (quoted datetime)
- `'YYYY-MM-DDTHH:MM'` (ISO format)
- Relative dates (`'yesterday 14:30'`, `'2 hours ago'`, etc.)

**Data Backup:**
- SQLite dump format (`.sql` files)
- Complete database backup including schema and data
- Automatic timestamped filenames
- Safe import with backup creation

### Discrete Session Management

Track work and idle sessions separately:

```bash
$ work on "coding"
Started work on: coding

$ work off
Stopped work on: coding (Duration: 1h 30m)
Idle time detected: 15m (will be tracked separately)

$ work status
⏳ [coding] Started: 14:30 (1h 30m ago)
📊 Total time on coding: 8h 45m (across 6 sessions)
🕐 Last session: coding (1h 30m, ended 1h 30m ago)
💤 Idle time: 15m (since last session)
```

### Work Reports

Generate detailed markdown reports:

```bash
# Today's report
work report today

# This week's report
work report week

# This month's report
work report month

# Custom period (last 7 days)
work report custom 7
```

Example report output:
```markdown
# Work Report - 2025-07-30

## Summary
- **Total work time**: 6h 30m
- **Total sessions**: 4
- **Active projects**: 2

## Project Breakdown
| Project | Sessions | Total Time |
|---------|----------|------------|
| coding  | 2        | 4h 15m     |
| meeting | 2        | 2h 15m     |

## Recent Sessions
1. **coding** (14:30-16:45, 2h 15m)
2. **meeting** (10:00-12:15, 2h 15m)
3. **coding** (09:00-11:00, 2h 00m)
4. **meeting** (08:00-09:00, 1h 00m)
```

### Nudging System

Get periodic reminders to check your work status:

```bash
# Test notifications
work test-nudge

# Check nudging status
work status  # Shows if nudging is enabled

# Disable nudging (if needed)
work config set NUDGING false
```

Nudging occurs every 10 minutes via cron and shows:
- Current project and session duration
- Total time on the project
- Gentle reminder to take breaks

### Data Import/Export

Backup and restore your work data:

```bash
# Export all data to SQLite dump
work export backup.sql

# Import data from SQLite dump
work import backup.sql

# Export with timestamped filename
work export  # Creates work-export-20250802_143022.sql
```

### Configuration

View and modify settings:

```bash
# Show current configuration
work config show

# Set verbose mode
work config set VERBOSE true

# Set notification timeout
work config set NOTIFICATION_TIMEOUT 10000

# Reset to defaults
work config reset
```

Available settings:
- `VERBOSE`: Enable detailed output
- `NOTIFICATIONS`: Enable/disable desktop notifications
- `NUDGING`: Enable/disable periodic reminders
- `NUDGE_INTERVAL`: Minutes between nudges (default: 10)
- `IDLE_THRESHOLD`: Minutes before idle detection (default: 60)
- `MAX_PROJECT_LENGTH`: Maximum project name length (default: 100)
- `REPORT_LIMIT`: Number of sessions in reports (default: 20)

## Uninstallation

```bash
# Run the uninstaller
./setup.sh uninstall

# Or uninstall non-interactively
./setup.sh uninstall --auto
```

The uninstaller will:
- Remove all refocus shell files and directories
- Clean up shell integration (prompt functions)
- Remove cron jobs
- Optionally delete the database (with confirmation)
- Create backups of modified configuration files

## Dependencies

Refocus Shell requires these system packages:

### Ubuntu/Debian
```bash
sudo apt update
sudo apt install sqlite3 libnotify-bin
```

### Arch/Manjaro
```bash
sudo pacman -S sqlite libnotify
```

### Fedora/RHEL
```bash
sudo dnf install sqlite libnotify
```

### openSUSE
```bash
sudo zypper install sqlite3 libnotify-tools
```

## Database

Refocus Shell uses SQLite for data storage:

- **Location**: `~/.local/work/timelog.db`
- **Tables**: `state` (current session), `sessions` (historical data)
- **Backup**: Use `work export` for data backup
- **Reset**: Use `work reset` to clear all data

### Database Schema

```sql
-- Current work state
CREATE TABLE state (
    id INTEGER PRIMARY KEY,
    active INTEGER DEFAULT 0,
    project TEXT,
    start_time TEXT,
    prompt_content TEXT,
    prompt_type TEXT DEFAULT 'default',
    nudging_enabled BOOLEAN DEFAULT 1,
    work_disabled BOOLEAN DEFAULT 0,
    last_work_off_time TEXT
);

-- Historical sessions
CREATE TABLE sessions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    project TEXT NOT NULL,
    start_time TEXT NOT NULL,
    end_time TEXT NOT NULL,
    duration_seconds INTEGER NOT NULL
);
```

## Troubleshooting

### Common Issues

**"work command not found"**
```bash
# Reinstall and source bashrc
./setup.sh install --auto
source ~/.bashrc
```

**"update-prompt: command not found"**
```bash
# Reinstall with function method
./setup.sh install --auto
source ~/.bashrc
```

**Notifications not working**
```bash
# Test notifications
work test-nudge

# Check if notify-send is installed
which notify-send

# Install if missing
sudo apt install libnotify-bin  # Ubuntu/Debian
```

**Database errors**
```bash
# Reset database
work reset

# Or reinitialize
work init
```

**Shell integration not working**
```bash
# Reinstall with function method
./setup.sh install --auto
source ~/.bashrc

# Or manually source
source ~/.local/work/shell-integration.sh
```

### Verbose Mode

Enable detailed output for debugging:

```bash
# Set verbose mode
work config set VERBOSE true

# Or use --verbose flag
./setup.sh install --verbose
```

### Log Files

Refocus Shell logs to:
- **Installation logs**: Check terminal output during setup
- **Database**: All data stored in `~/.local/work/timelog.db`
- **Configuration**: Settings in `~/.config/refocus-shell/config.sh`

## Development

### Project Structure

```
refocus-shell/
├── work                    # Main dispatcher script
├── setup.sh               # Installation/uninstallation script
├── config.sh              # Configuration management
├── work-nudge             # Nudging script (cron job)
├── commands/              # Subcommand implementations
│   ├── work-on.sh
│   ├── work-off.sh
│   ├── work-status.sh
│   ├── work-past.sh
│   ├── work-report.sh
│   └── ...
├── lib/                   # Shared libraries
│   ├── work-db.sh        # Database operations
│   ├── work-utils.sh     # Utility functions
│   ├── work-function.sh  # Shell function implementation
│   └── work-alias.sh     # Safe alias implementation
├── docs/                  # Documentation
│   ├── ROADMAP.md
│   ├── TODO.md
│   └── ...
└── README.md             # This file
```

### Contributing

1. **Fork the repository**
2. **Create a feature branch**: `git checkout -b feature/amazing-feature`
3. **Make your changes**
4. **Test thoroughly**: Run `./setup.sh install --auto` and test all functionality
5. **Commit your changes**: `git commit -m 'Add amazing feature'`
6. **Push to the branch**: `git push origin feature/amazing-feature`
7. **Open a Pull Request**

### Testing

```bash
# Install in development mode
./setup.sh install --auto

# Test all commands
work help
work on "test"
work status
work off
work past add "test" "2025/07/30-14:00" "2025/07/30-16:00"
work report today

# Test uninstallation
./setup.sh uninstall --auto
```

## License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.

---

**Made with ❤️ for neurodivergent developers and sysadmins who need better time awareness without overwhelming complexity.** 
