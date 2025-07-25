# Work Manager

A simple command-line work tracking tool that helps you track time spent on different projects with intelligent nudging reminders.

## Features

- **Simple Commands**: `work on "project"`, `work off`, `work status`
- **Database Storage**: SQLite database for persistent tracking
- **Desktop Notifications**: Uses `notify-send` for desktop notifications
- **Shell Integration**: Automatic prompt modification to show work status
- **Session Management**: Track active sessions and elapsed time
- **Intelligent Nudging**: Periodic reminders about work status (every 10 minutes)
- **Work Manager Control**: Enable/disable work tracking and nudging
- **Reset Capability**: Reset database to start fresh

## Installation

### Quick Install
```bash
./install.sh install
```

The installer will:
- Install dependencies (`notify-send`, `sqlite3`)
- Set up the database
- Install the work script to your system
- Install the work-nudge script for periodic reminders
- Set up cron job for automatic nudging (every 10 minutes)
- Configure shell integration for prompt modification

### Manual Installation

1. **Install Dependencies**:
   ```bash
   ./install.sh deps
   ```

2. **Initialize Database**:
   ```bash
   ./install.sh init
   ```

3. **Setup Shell Integration** (optional):
   ```bash
   ./install.sh shell-setup
   ```

## Usage

### Basic Commands

```bash
# Start working on a project
work on "My Project"

# Stop current work session
work off

# Check current status
work status

# Enable work manager (if disabled)
work enable

# Disable work manager (stops active sessions)
work disable

# Send manual nudge (for testing)
work nudge

# Reset database (delete all data)
work reset

# Verbose mode for debugging
work --verbose on "project"
```

### Nudging System

The work manager includes an intelligent nudging system that sends periodic reminders:

- **Every 10 minutes**: Automatic reminders about your work status
- **When working**: "You're working on: [Project] (Xm elapsed)"
- **When not working**: "You're not working on any project"
- **Desktop notifications**: Uses `notify-send` for non-intrusive reminders
- **System logging**: Logs all nudging activity to system log

#### Nudging Control

```bash
# Enable work manager and nudging
work enable

# Disable work manager (stops all work sessions and nudging)
work disable
```

**Note**: When work manager is disabled, you cannot start new work sessions and no nudging will occur.

### Verbose Mode

Use the `--verbose` flag to see detailed output during operations:

```bash
work --verbose on "project"
work --verbose off
work --verbose status
```

This is useful for debugging and understanding what the work manager is doing behind the scenes.

### Shell Integration

The work manager includes shell integration that modifies your terminal prompt to show when you're actively working:

- **Normal prompt**: `user@host:~/path$ `
- **Work prompt**: `user@host:~/path ⏳ [Project Name] $ `

The shell integration:
- Automatically detects your shell (bash, zsh, fish)
- Modifies your RC file (`.bashrc`, `.zshrc`, etc.)
- Saves your original prompt and restores it when work stops
- Works across all new terminal sessions

### Installation Options

```bash
# Full installation with shell integration and nudging
./install.sh install

# Install dependencies only
./install.sh deps

# Initialize database only
./install.sh init

# Reset database (delete all data)
./install.sh reset

# Setup shell integration only
./install.sh shell-setup
```

## Uninstallation

```bash
./install.sh uninstall
```

**Note**: The uninstaller will remove shell integration from your RC file and remove the cron job for nudging, but you may need to manually restart your terminal or run `source ~/.bashrc` for changes to take effect.

## Dependencies

- `notify-send`: For desktop notifications
- `sqlite3`: For database operations

The installer will automatically install these dependencies using your system's package manager.

## Database

The work manager uses SQLite to store:
- Current work state (active/inactive, project, start time, prompt file)
- Work sessions (project, start time, end time, duration)
- Nudging settings (enabled/disabled)
- Work manager state (enabled/disabled)

Database location: `~/.local/work/timelog.db`

## Configuration

The work manager can be configured via `~/.local/work/config.sh`:

```bash
# Nudging interval in minutes (default: 10)
WORK_NUDGE_INTERVAL=10

# Logging facility (default: user)
WORK_LOG_FACILITY="user"

# Logging priority (default: notice)
WORK_LOG_PRIORITY="notice"
```

## Shell Support

Currently tested with:
- **Bash**: Full support with prompt modification
- **Zsh**: Full support with prompt modification  
- **Fish**: Basic support (prompt modification may need adjustment)

## Troubleshooting

### Shell Integration Not Working
1. Check if shell integration is installed: `./install.sh shell-setup`
2. Restart your terminal or run `source ~/.bashrc`
3. Verify the integration script exists: `ls ~/.local/work/shell_integration.sh`

### Prompt Not Updating
- Run `source ~/.bashrc` to apply changes to current terminal
- Check if the prompt file exists: `ls ~/.local/work/prompt.sh`

### Nudging Not Working
- Check if cron job exists: `crontab -l`
- Verify work-nudge script exists: `ls ~/.local/work/work-nudge`
- Check if work manager is enabled: `work status`
- Test manual nudge: `work nudge`

### Database Issues
- Reset the database: `work reset`
- Reinitialize: `./install.sh init`

## Development

The work manager consists of:
- `work`: Main work tracking script
- `work-nudge`: Nudging script for periodic reminders
- `install.sh`: Installation and setup script
- `config.sh`: Configuration file template
- `~/.local/work/`: Data directory with database, prompt files, and configuration

## License

This project is open source and available under the MIT License. 