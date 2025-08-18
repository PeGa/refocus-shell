# Refocus Shell

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Platform: Linux](https://img.shields.io/badge/Platform-Linux-lightgrey.svg)](https://www.linux.org/)
[![Shell: Bash](https://img.shields.io/badge/Shell-Bash-green.svg)](https://www.gnu.org/software/bash/)
[![Database: SQLite](https://img.shields.io/badge/Database-SQLite-yellow.svg)](https://www.sqlite.org/)
[![Privacy: Local-First](https://img.shields.io/badge/Privacy-Local--First-brightgreen.svg)](https://en.wikipedia.org/wiki/Local-first_software)

> 🧠 **Built for neurodivergent devs, sysadmins, and anyone tired of forgetting where their time went (e.g. me).**  
> Refocus Shell is a terminal-first, privacy-conscious time tracker that nudges, reflects, and gets out of your way.

## 📚 Table of Contents
- [Who It's For](#who-its-for)
- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
- [Command Reference](#command-reference)
- [Smart Focus Continuation](#smart-focus-continuation)
- [Enhanced Status Information](#enhanced-status-information)
- [Project Descriptions](#project-descriptions)
- [Cumulative Time Tracking](#cumulative-time-tracking)
- [Past Session Management](#past-session-management)
- [Discrete Session Management](#discrete-session-management)
- [Focus Reports](#focus-reports)
- [Nudging System](#nudging-system)
- [Data Import/Export](#data-importexport)
- [Configuration](#configuration)
- [Documentation](#documentation)
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

> 💡 **Pro Tip**: The `⏳ [project]` prompt tag works **across all terminals** - start focus in one terminal, and every new terminal you open will show your current project!

## Features

- **Core Focus Tracking**: `focus on/off/status` commands
- **Smart Continuation**: `focus on` without project continues last session
- **Enhanced Status**: Rich context about last session and time tracking
- **Cumulative Time Tracking**: Shows total time invested in each project across sessions
- **Project Descriptions**: Optional descriptions for projects to provide context and clarity
- **Past Session Management**: Add, modify, and delete historical focus sessions with flexible timestamp formats
- **Focus Reports**: Generate markdown reports for today, week, month, or custom periods
- **Discrete Session Management**: ADHD-friendly focus/idle session tracking with automatic break tracking
- **Desktop Notifications**: `notify-send` integration
- **Shell Integration**: Dynamic prompt modification with `⏳ [Project]` indicator
- **Intelligent Nudging**: Periodic reminders every 10 minutes via cron
- **Refocus Shell Control**: `focus enable/disable` commands
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
- **Seamless integration** - `focus` command available immediately
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
focus on "project"     # Start focusing on a project
focus off              # Stop current focus session
focus status           # Show current focus status
focus help             # Show all available commands
```

### Quick Examples

```bash
# Start focusing
focus on "coding"
focus on "meeting"
focus on "planning"

# Check status
focus status

# Stop focusing
focus off

# Add past sessions with flexible timestamps
focus past add "project" "2025/07/30-14:00" "2025/07/30-16:00"  # Add past focus session
focus past add "meeting" "14:00" "15:30"           # Today's times
focus past add "coding" "2025/07/30-14:00" "16:00" # Specific date
focus past add "planning" "2 hours ago" "1 hour ago" # Relative times

# Generate reports
focus report today
focus report week
focus report month
focus report custom 7  # Last 7 days

# Manage data
focus export backup.sql
focus import backup.sql
focus reset  # Reset all data (with confirmation)
```

### Smart Focus Continuation

Refocus Shell remembers your last project and session:

```bash
$ focus on "coding"
Started focus on: coding

$ focus off
Stopped focus on: coding (Duration: 2h 15m)

$ focus on  # No project specified
Started focus on: coding  # Continues last project
```

### Enhanced Status Information

Get rich context about your focus:

```bash
$ focus status
⏳ [coding] Started: 14:30 (2h 15m ago)
📋 This is my main development project for the web application
📊 Total time on coding: 12h 45m (across 8 sessions)
🕐 Last session: coding (2h 15m, ended 2h 15m ago)
💡 Tip: Run 'focus report today' to see today's summary
```

### Project Descriptions

Add context and clarity to your projects with optional descriptions:

```bash
# Set a project description
focus project set "coding" "Main development project for the web application"

# View a project description
focus project show "coding"

# List all projects with descriptions
focus project list

# Remove a project description
focus project remove "coding"
```

**Benefits:**
- **Distinguish similar projects**: "meeting" vs "meeting-client" vs "meeting-team"
- **Quick context**: Remember what a project was about months later
- **Better reporting**: Understand your work patterns with descriptive context
- **Lightweight documentation**: Simple notes without complex project management overhead

**Example workflow:**
```bash
$ focus project set "refactor" "Refactoring the authentication system to use OAuth2"
$ focus on refactor
$ focus status
⏳ Focusing on: refactor — 0m elapsed
📋 Refactoring the authentication system to use OAuth2
```

## Command Reference

### Core Commands

| Command | Description | Example |
|---------|-------------|---------|
| `focus on [project]` | Start focusing on a project | `focus on "coding"` |
| `focus off` | Stop current focus session | `focus off` |
| `focus status` | Show current focus status | `focus status` |
| `focus help` | Show all available commands | `focus help` |

### Project Management

| Command | Description | Example |
|---------|-------------|---------|
| `focus project set <project> <description>` | Set project description | `focus project set "meeting" "Client consultation"` |
| `focus project show <project>` | View project description | `focus project show "meeting"` |
| `focus project list` | List all projects with descriptions | `focus project list` |
| `focus project remove <project>` | Remove project description | `focus project remove "meeting"` |

### Session Management

| Command | Description | Example |
|---------|-------------|---------|
| `focus past add <project> <start> <end>` | Add past session | `focus past add "meeting" "14:00" "15:30"` |
| `focus past list [limit]` | List recent sessions | `focus past list 10` |
| `focus past modify <id> [project] [start] [end]` | Modify session | `focus past modify 1 "new-project" "15:00" "17:00"` |
| `focus past delete <id>` | Delete session | `focus past delete 1` |

### Reporting

| Command | Description | Example |
|---------|-------------|---------|
| `focus report today` | Today's focus report | `focus report today` |
| `focus report week` | This week's focus report | `focus report week` |
| `focus report month` | This month's focus report | `focus report month` |
| `focus report custom <days>` | Custom period report | `focus report custom 7` |

### Data Management

| Command | Description | Example |
|---------|-------------|---------|
| `focus export [file]` | Export focus data | `focus export backup.sql` |
| `focus import <file>` | Import focus data | `focus import backup.sql` |
| `focus reset` | Reset all data | `focus reset` |
| `focus init` | Initialize database | `focus init` |

### System Control

| Command | Description | Example |
|---------|-------------|---------|
| `focus enable` | Enable refocus shell | `focus enable` |
| `focus disable` | Disable refocus shell | `focus disable` |
| `focus config show` | Show configuration | `focus config show` |
| `focus config set <key> <value>` | Set configuration | `focus config set VERBOSE true` |
| `focus test-nudge` | Test notifications | `focus test-nudge` |

### Cumulative Time Tracking

Refocus Shell tracks total time across all sessions:

```bash
$ focus report today
📊 Today's Work Summary
=======================

⏰ Total focus time: 6h 30m
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

Add, modify, and delete historical focus sessions with flexible timestamp formats:

```bash
# Add past sessions
focus past add "meeting" "14:00" "15:30"                          # Today's times
focus past add "coding" "2025/07/30-14:00" "2025/07/30-16:00"     # Specific date
focus past add "planning" "2 hours ago" "1 hour ago"               # Relative times
focus past add "review" "yesterday 14:00" "yesterday 16:00"       # Yesterday
focus past add "team meeting" "2025/07/30-14:00" "2025/07/30-16:00" # Full date

# List recent sessions
focus past list 10

# Modify a session
focus past modify 1 "new-project" "2025/07/30-15:00" "2025/07/30-17:00"

# Delete a session
focus past delete 1
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

Track focus and idle sessions separately:

```bash
$ focus on "coding"
Started focus on: coding

$ focus off
Stopped focus on: coding (Duration: 1h 30m)
Idle time detected: 15m (will be tracked separately)

$ focus status
⏳ [coding] Started: 14:30 (1h 30m ago)
📊 Total time on coding: 8h 45m (across 6 sessions)
🕐 Last session: coding (1h 30m, ended 1h 30m ago)
💤 Idle time: 15m (since last session)
```

### Focus Reports

Generate detailed markdown reports:

```bash
# Today's report
focus report today

# This week's report
focus report week

# This month's report
focus report month

# Custom period (last 7 days)
focus report custom 7
```

Example report output:
```markdown
# Work Report - 2025-07-30

## Summary
- **Total work time**: 6h 30m
- **Total sessions**: 4
- **Active projects**: 2

## Project Breakdown
| Project | Sessions | Total Time | Description |
|---------|----------|------------|-------------|
| coding  | 2        | 4h 15m     | Main development project for the web application |
| meeting | 2        | 2h 15m     | Client consultation and planning session |

## Recent Sessions
1. **coding** (14:30-16:45, 2h 15m)
2. **meeting** (10:00-12:15, 2h 15m)
3. **coding** (09:00-11:00, 2h 00m)
4. **meeting** (08:00-09:00, 1h 00m)
```

### Nudging System

Get periodic reminders to check your focus status:

```bash
# Test notifications
focus test-nudge

# Check nudging status
focus status  # Shows if nudging is enabled

# Disable nudging (if needed)
focus config set NUDGING false
```

Nudging occurs every 10 minutes via cron and shows:
- Current project and session duration
- Total time on the project
- Gentle reminder to take breaks

### Data Import/Export

Backup and restore your focus data, including project descriptions:

```bash
# Export all data to SQLite dump
focus export backup.sql

# Import data from SQLite dump
focus import backup.sql

# Export with timestamped filename
focus export  # Creates focus-export-20250802_143022.sql
```

**Export includes:**
- Database schema and all tables
- All focus sessions and timing data
- Current focus state and configuration
- **Project descriptions and metadata**
- Complete data integrity for backup/restore

### Configuration

View and modify settings:

```bash
# Show current configuration
focus config show

# Set verbose mode
focus config set VERBOSE true

# Set notification timeout
focus config set NOTIFICATION_TIMEOUT 10000

# Reset to defaults
focus config reset
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

- **Location**: `~/.local/refocus/refocus.db`
- **Tables**: `state` (current session), `sessions` (historical data)
- **Backup**: Use `focus export` for data backup
- **Reset**: Use `focus reset` to clear all data

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

-- Project descriptions
CREATE TABLE projects (
    project TEXT PRIMARY KEY,
    description TEXT NOT NULL,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);
```

## Troubleshooting

### Common Issues

**"focus command not found"**
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
focus test-nudge

# Check if notify-send is installed
which notify-send

# Install if missing
sudo apt install libnotify-bin  # Ubuntu/Debian
```

**Database errors**
```bash
# Reset database
focus reset

# Or reinitialize
focus init
```

**Shell integration not working**
```bash
# Reinstall with function method
./setup.sh install --auto
source ~/.bashrc

# Or manually source
source ~/.local/refocus/shell-integration.sh
```

### Verbose Mode

Enable detailed output for debugging:

```bash
# Set verbose mode
focus config set VERBOSE true

# Or use --verbose flag
./setup.sh install --verbose
```

### Log Files

Refocus Shell logs to:
- **Installation logs**: Check terminal output during setup
- **Database**: All data stored in `~/.local/refocus/refocus.db`
- **Configuration**: Settings in `~/.config/refocus-shell/config.sh`

## Documentation

For detailed documentation on specific features:

- **[Project Descriptions](docs/doc/PROJECT_DESCRIPTIONS.md)** - Complete guide to managing project descriptions
- **[Prompt Integration](docs/doc/PROMPT_SOLUTIONS.md)** - Solutions for shell integration issues
- **[CLI Roadmap](CLI%20ROADMAP.md)** - Development status and future plans

## Development

### Project Structure

```
refocus-shell/
├── focus                    # Main dispatcher script
├── setup.sh               # Installation/uninstallation script
├── config.sh              # Configuration management
├── focus-nudge             # Nudging script (cron job)
├── commands/              # Subcommand implementations
│   ├── focus-on.sh
│   ├── focus-off.sh
│   ├── focus-status.sh
│   ├── focus-project.sh  # Project description management
│   ├── focus-past.sh
│   ├── focus-report.sh
│   └── ...
├── lib/                   # Shared libraries
│   ├── focus-db.sh        # Database operations
│   ├── focus-utils.sh     # Utility functions
│   ├── focus-function.sh  # Shell function implementation
│   └── focus-alias.sh     # Safe alias implementation
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
focus help
focus on "test"
focus status
focus off
focus past add "test" "2025/07/30-14:00" "2025/07/30-16:00"
focus report today

# Test project descriptions
focus project set "test" "This is a test project for development"
focus project show "test"
focus project list
focus on "test"
focus status  # Should show description
focus report today  # Should show description in report
focus project remove "test"

# Test uninstallation
./setup.sh uninstall --auto
```

## License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.

---

**Made with ❤️ by and for neurodivergent developers and sysadmins who need better time awareness without overwhelming complexity.** 
