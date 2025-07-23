# Work Manager

A simple command-line work tracking tool that helps you track time spent on different projects.

## Features

- **Simple Commands**: `work on "project"`, `work off`, `work status`
- **Database Storage**: SQLite database for persistent tracking
- **Desktop Notifications**: Uses `notify-send` for desktop notifications
- **Shell Integration**: Automatic prompt modification to show work status
- **Session Management**: Track active sessions and elapsed time
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

# Reset database (delete all data)
work reset
```

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
# Full installation with shell integration
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

**Note**: The uninstaller will remove shell integration from your RC file, but you may need to manually restart your terminal or run `source ~/.bashrc` for changes to take effect.

## Dependencies

- `notify-send`: For desktop notifications
- `sqlite3`: For database operations

The installer will automatically install these dependencies using your system's package manager.

## Database

The work manager uses SQLite to store:
- Current work state (active/inactive, project, start time)
- Work sessions (project, start time, end time, duration)

Database location: `~/.local/work/timelog.db`

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

### Database Issues
- Reset the database: `work reset`
- Reinitialize: `./install.sh init`

## Development

The work manager consists of:
- `work`: Main work tracking script
- `install.sh`: Installation and setup script
- `~/.local/work/`: Data directory with database and prompt files

## License

This project is open source and available under the MIT License. 