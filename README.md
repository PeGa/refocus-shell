# Work Manager

A privacy-first, FLOSS command-line tool for tracking work sessions with intelligent nudging and cross-device synchronization capabilities.

## Features

- **Core Work Tracking**: `work on/off/status` commands
- **Smart Continuation**: `work on` without project continues last session
- **Enhanced Status**: Rich context about last session and time tracking
- **Past Session Management**: Add, modify, and delete historical work sessions
- **Desktop Notifications**: `notify-send` integration
- **Shell Integration**: Dynamic prompt modification with `⏳ [Project]` indicator
- **Intelligent Nudging**: Periodic reminders every 10 minutes via cron
- **Work Manager Control**: `work enable/disable` commands
- **Data Import/Export**: JSON-based backup and restore functionality
- **Professional Installation**: Interactive setup with dependency management
- **Cross-Distribution Support**: Ubuntu/Debian, Arch/Manjaro, Fedora/RHEL, openSUSE
- **Verbose Mode**: `--verbose` flag for debugging

## Installation

### Quick Start

```bash
# Clone the repository
git clone <repository-url>
cd work-manager

# Run the interactive installer
./setup.sh install
```

The installer will:
- Detect your Linux distribution
- Install required dependencies (`sqlite3`, `notify-send`, `jq`)
- Set up the database and configuration
- Install the `work` command system-wide
- Configure shell integration for prompt modification
- Set up cron jobs for nudging functionality

### Manual Installation

If you prefer manual installation:

```bash
# Install dependencies (Ubuntu/Debian example)
sudo apt-get install sqlite3 libnotify-bin jq

# Run setup
./setup.sh install
```

## Usage

### Basic Commands

```bash
work on "project-name"    # Start tracking work on a project
work on                   # Continue with last project (interactive)
work off                  # Stop tracking work
work status               # Show current work status
work past add "project" <minutes>    # Add past work session
work past modify "project" <minutes>  # Modify session duration
work past delete "project"            # Delete a session
```

### Advanced Commands

```bash
work enable               # Enable work manager functionality
work disable              # Disable work manager (stops active sessions)
work test-nudge           # Send manual nudge notification (testing)
work export [file]        # Export data to JSON file
work import <file>        # Import data from JSON file
work reset                # Reset database (delete all data)
```

### Options

```bash
work --verbose            # Show detailed output
```

### Examples

```bash
# Start working on a project
work on "website-redesign"

# Continue with last project (interactive)
work on

# Check status (shows last session when not working)
work status

# Add a past work session (45 minutes)
work past add "meeting" 45

# Modify an existing session duration
work past modify "coding" 120

# Export your data
work export my-backup.json

# Import data from another device
work import backup.json

# Test nudging functionality
work test-nudge
```

## Smart Work Continuation

Work Manager intelligently remembers your last project and makes it easy to continue:

- **Last Project Detection**: When you run `work on` without a project, it asks if you want to continue with your last project
- **Interactive Confirmation**: "Last project was: [Project]. Continue? (Y/n)"
- **Graceful Handling**: If you decline, it provides helpful guidance
- **No Project Fallback**: If no previous project exists, it guides you to specify a project

### Example:
```bash
$ work on
Last project was: website-redesign
Continue? (Y/n)
y
Started work on: website-redesign
```

## Enhanced Status Information

When you're not currently working, `work status` provides rich context about your last session:

- **Last Session Details**: Shows project name and duration
- **Time Tracking**: Displays how long since your last work session
- **Clear Formatting**: Uses emojis and clear labels for better readability

### Example:
```bash
$ work status
✅ Not currently tracking work.
📊 Last session: website-redesign (45m)
⏰ Time since last work: 2h 15m
```

## Past Session Management

Work Manager allows you to manage historical work sessions that may have been missed or need adjustment:

- **Add Past Sessions**: `work past add "project" <minutes>` - Add a session that ended X minutes ago
- **Modify Sessions**: `work past modify "project" <minutes>` - Change the duration of an existing session
- **Delete Sessions**: `work past delete "project"` - Remove a session with confirmation
- **Smart Timestamps**: Sessions are created with end time = now, start time = X minutes ago
- **Validation**: Input validation ensures proper project names and time values

### Example:
```bash
$ work past add "team-meeting" 90
✅ Added past session: team-meeting (90m)

$ work past modify "coding" 180
✅ Modified session: coding (180m)

$ work past delete "old-project"
🗑️  Deleting session: old-project (45m)
Session: 2025-07-25T10:00:00-03:00 to 2025-07-25T10:45:00-03:00
Are you sure? (y/N)
✅ Session deleted: old-project
```

## Nudging System

Work Manager includes an intelligent nudging system that periodically reminds you about your work status:

- **Active Work**: "You're working on: [Project] (X minutes elapsed)"
- **No Active Work**: "You're not working on any project"
- **Configurable**: 10-minute intervals by default
- **Privacy-First**: No external services, runs locally via cron

### Control Nudging

```bash
work enable               # Enable nudging (default)
work disable              # Disable nudging
work test-nudge           # Send manual test notification
```

## Data Import/Export

Work Manager supports JSON-based data backup and restoration:

### Export Data

```bash
work export                    # Export to timestamped file
work export my-data.json      # Export to specific file
```

### Import Data

```bash
work import backup.json        # Import from JSON file
```

The import system uses a **merge strategy** rather than full override, preserving existing data while adding imported sessions.

## Verbose Mode

Use `--verbose` for detailed output and debugging:

```bash
work --verbose on "project"   # Detailed startup information
work --verbose status         # Show database queries and state
work --verbose export         # Show export details
```

## Uninstallation

To completely remove Work Manager:

```bash
./setup.sh uninstall
```

This will:
- Remove the `work` command
- Remove cron jobs for nudging
- Remove shell integration
- Optionally remove the database (you'll be prompted)

## Dependencies

- **sqlite3**: Database storage
- **notify-send**: Desktop notifications
- **jq**: JSON processing for import/export
- **bash**: Shell scripting (already available on Linux)

## Database

Work Manager uses SQLite for data storage:

- **Location**: `~/.local/work/timelog.db`
- **Tables**: `sessions` (work history), `state` (current status)
- **Schema**: Includes support for nudging, prompts, and sync features

## Configuration

Configuration is stored in `~/.local/work/config.sh`:

```bash
# Nudging interval in minutes
WORK_NUDGE_INTERVAL=10

# Logging facility
WORK_LOG_FACILITY="user"

# Logging priority
WORK_LOG_PRIORITY="notice"
```

## Troubleshooting

### Common Issues

**"work command not found"**
```bash
# Clear shell command cache
hash -r

# Or reinstall
./setup.sh install
```

**"notify-send not available"**
```bash
# Install notification daemon
sudo apt-get install libnotify-bin  # Ubuntu/Debian
sudo pacman -S libnotify           # Arch/Manjaro
```

**"Database not found"**
```bash
# Reinitialize database
./setup.sh reset
```

**Nudging not working**
```bash
# Test manually
work test-nudge

# Check cron jobs
crontab -l

# Reinstall nudging
./setup.sh install
```

**Import/Export issues**
```bash
# Check JSON format
jq . your-file.json

# Verify dependencies
which jq
```

## Development

### Project Structure

```
work-manager/
├── work                    # Main work tracking script
├── work-nudge             # Cron-executed nudging script
├── setup.sh               # Installation and setup script
├── config.sh              # Configuration template
├── COPYING                # Full GPLv3 license text
├── LICENSE                # License summary
└── README.md              # This file
```

### Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

## 🛡️ License Philosophy

This project is licensed under the **GNU General Public License v3.0 (GPLv3)** — a conscious choice based on values, not convenience.

Work Manager isn't just a tool. It's a time-awareness companion, designed to support focus, reduce burnout, and reinforce personal sovereignty over your workflow.

### Why GPLv3?

The GPL ensures that this project — and any forks or derivatives — remain **free** and **respectful of user rights**. It guarantees:

- 🔒 **Privacy-first tooling**: No telemetry, no lock-in.
- 👥 **Community contribution**: Improvements stay shared.
- 🧠 **Sovereignty over code and behavior**: No one can take this and sell it back to you.

### This project is not:

- A feature demo for a future paid tier  
- A product to be enclosed in proprietary platforms  
- A silent backend for surveillance-driven "productivity" apps

### This project *is*:

- FLOSS-first, user-centric, and minimal by design  
- Built to run locally, offline, and without dependencies you don't control  
- A statement that the tools we use to manage our time should **serve us — not extract from us**

If you fork or extend this project, you're very welcome to — as long as your version respects the same freedoms.

**This isn't viral licensing.  
This is licensing with purpose.**

### What This Means for Users

- **You own your data**: No one can lock you into a proprietary ecosystem
- **You control your tools**: Full source access means full transparency
- **You choose your sync**: Whether import/export or self-hosted, you decide
- **You protect your privacy**: No hidden telemetry, no data mining

### What This Means for Developers

- **Build on our work**: Fork, extend, improve — just keep it free
- **Contribute back**: Share improvements with the community
- **Respect user rights**: Don't take this and make it proprietary
- **Think long-term**: Consider the impact of your changes on user sovereignty

For the complete license text, see the [COPYING](COPYING) file. 