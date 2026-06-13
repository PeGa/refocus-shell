# Configuration Guide

This guide covers all configuration options and customization features in Refocus Shell.

## Environment Variables

Refocus Shell can be customized using environment variables that override default settings.

### Database Configuration

#### Custom Database Location
```bash
# Set custom database path
export REFOCUS_DB="/path/to/custom/refocus.db"

# Use project-specific database
export REFOCUS_DB="$HOME/projects/myproject/.refocus.db"

# Temporary database for testing
export REFOCUS_DB="/tmp/refocus-test.db"
```

#### Database Backup Location
```bash
# Custom backup directory
export REFOCUS_BACKUP_DIR="$HOME/backups/refocus"
```

### Debugging and Logging

#### Verbose Output
```bash
# Enable detailed output for debugging
export REFOCUS_VERBOSE=true

# Run commands with verbose output
focus on "test-project"
focus status
focus off
```

#### Custom Log Configuration
```bash
# Custom log facility (for nudges)
export REFOCUS_LOG_FACILITY="user"

# Custom log priority
export REFOCUS_LOG_PRIORITY="notice"
```

### Notification Configuration

#### Custom Notification Commands
```bash
# Custom notification command
export REFOCUS_NOTIFY_CMD="notify-send -i focus"

# Use different notification tools
export REFOCUS_NOTIFY_CMD="kdialog --passivepopup"

# Custom notification with sound
export REFOCUS_NOTIFY_CMD="notify-send -i focus && paplay /usr/share/sounds/bell.wav"
```

#### Nudge Timing
```bash
# Custom nudge interval (in minutes)
export REFOCUS_NUDGE_INTERVAL=15  # Default is 10

# Disable nudges completely
export REFOCUS_NUDGE_ENABLED=false
```

### Prompt Configuration

#### Custom Prompt Format
```bash
# Change prompt prefix
export REFOCUS_PROMPT_FORMAT="🎯 %s"

# Minimal prompt
export REFOCUS_PROMPT_FORMAT="[%s]"

# Detailed prompt
export REFOCUS_PROMPT_FORMAT="⏳ Working on: %s"
```

#### Prompt Colors
```bash
# Custom prompt colors (using ANSI escape codes)
export REFOCUS_PROMPT_COLOR="\033[1;32m"  # Bold green
export REFOCUS_PROMPT_RESET="\033[0m"     # Reset
```

### File Paths

#### Custom Configuration Location
```bash
# Use custom config file
export REFOCUS_CONFIG="/path/to/custom/config.sh"

# Project-specific configuration
export REFOCUS_CONFIG="$PWD/.refocus-config.sh"
```

#### Installation Paths
```bash
# Custom installation directory
export REFOCUS_INSTALL_DIR="$HOME/tools/refocus"

# Custom data directory
export REFOCUS_DATA_DIR="$HOME/.config/refocus"
```

## Configuration Commands

Use `focus config` to manage settings interactively.

### Viewing Configuration

#### Show All Settings
```bash
focus config show
```

Displays:
- Current configuration values
- Environment variable overrides
- Database location and status
- Installation paths

#### Show Specific Setting
```bash
focus config get VERBOSE
focus config get NUDGE_INTERVAL
```

### Modifying Settings

#### Set Configuration Values
```bash
# Enable verbose mode
focus config set VERBOSE true

# Change nudge interval
focus config set NUDGE_INTERVAL 15

# Set custom database path
focus config set DB_PATH "/custom/path/refocus.db"
```

#### Reset Settings
```bash
# Reset specific setting to default
focus config reset VERBOSE

# Reset all settings to defaults
focus config reset --all
```

### Configuration File

Refocus Shell can use a configuration file for persistent settings:

#### Default Configuration File
Location: `~/.config/refocus-shell/config.sh`

```bash
# Refocus Shell Configuration

# Database configuration
REFOCUS_DB="$HOME/.local/refocus/refocus.db"
REFOCUS_BACKUP_DIR="$HOME/.local/refocus/backups"

# Verbose output
REFOCUS_VERBOSE=false

# Nudge configuration
REFOCUS_NUDGE_INTERVAL=10
REFOCUS_NUDGE_ENABLED=true

# Notification configuration
REFOCUS_NOTIFY_CMD="notify-send"

# Prompt configuration
REFOCUS_PROMPT_FORMAT="⏳ %s"
```

#### Creating Custom Configuration
```bash
# Create custom config directory
mkdir -p ~/.config/refocus-shell

# Create configuration file
cat > ~/.config/refocus-shell/config.sh << 'EOF'
#!/bin/bash
# My Refocus Shell Configuration

# Use verbose output
export REFOCUS_VERBOSE=true

# Custom nudge interval
export REFOCUS_NUDGE_INTERVAL=15

# Custom prompt format
export REFOCUS_PROMPT_FORMAT="🎯 [%s]"

# Custom database location
export REFOCUS_DB="$HOME/Documents/refocus.db"
EOF

# Make executable
chmod +x ~/.config/refocus-shell/config.sh
```

## Project Descriptions

Project descriptions provide context and help organize your work.

### Managing Descriptions

#### Add Project Description
```bash
focus description add "coding" "Main development project"
focus description add "meetings" "Team meetings and standups"
focus description add "planning" "Project planning and architecture"
```

#### View Descriptions
```bash
# View specific project description
focus description show "coding"

# List all descriptions
focus description list
```

#### Update Descriptions
```bash
focus description update "coding" "Full-stack web development"
```

#### Remove Descriptions
```bash
focus description remove "old-project"
```

### Description Best Practices

#### Good Descriptions
- **Specific**: "React frontend development for e-commerce platform"
- **Contextual**: "Client meetings for Project Alpha"
- **Actionable**: "Bug fixes for authentication system"

#### Avoid
- **Too generic**: "Work stuff"
- **Too long**: "This is a very long description that goes into unnecessary detail about every aspect..."
- **Inconsistent**: Mixing different styles and formats

### Description Integration

Descriptions appear in:
- `focus status` output
- Report generation
- Project listings
- Export data

## Nudge System Configuration

Configure the notification system to match your workflow.

### Nudge Types

#### Active Session Nudges
Reminders during focus sessions:
```bash
# Enable/disable active nudges
focus nudge enable
focus nudge disable

# Check current status
focus nudge status
```

#### Idle Notifications
Reminders when not focusing:
```bash
# These are controlled by the same setting
focus nudge enable   # Enables both active and idle nudges
focus nudge disable  # Disables both
```

### Nudge Timing

#### Default Timing
- **Interval**: Every 10 minutes
- **Start delay**: First nudge at 10 minutes
- **Rounding**: Times are rounded (10m, 20m, 30m, etc.)

#### Custom Timing
```bash
# Set custom interval
export REFOCUS_NUDGE_INTERVAL=15  # Every 15 minutes

# Or via config
focus config set NUDGE_INTERVAL 15
```

### Nudge Content

#### Active Session Format
"You're focusing on: {project} ({elapsed}m elapsed)"

#### Idle Format  
"You're not focusing on any project"

#### Paused Session Format
"Session paused: {project} - {notes}"

### Testing Nudges

#### Test Notification System
```bash
focus nudge test
```

This will:
- Test `notify-send` functionality
- Check desktop environment compatibility
- Verify notification display

#### Debug Nudge Issues
```bash
# Enable verbose logging
export REFOCUS_VERBOSE=true

# Check nudge status
focus nudge status

# Manual nudge test
focus test-nudge
```

## Shell Integration

Configure how Refocus Shell integrates with your shell environment.

### Prompt Integration

#### Automatic Prompt Updates
The `⏳ [project]` indicator is automatically added to your prompt when a session is active.

#### Manual Prompt Control
```bash
# Manually update prompt
focus-update-prompt

# Restore original prompt
focus-restore-prompt
```

#### Custom Prompt Integration
Add to your `.bashrc` for custom prompt handling:

```bash
# Custom prompt function
update_refocus_prompt() {
    if [[ -f "$HOME/.local/refocus/refocus.db" ]]; then
        local active_project
        active_project=$(sqlite3 "$HOME/.local/refocus/refocus.db" "SELECT project FROM state WHERE active = 1;" 2>/dev/null)
        
        if [[ -n "$active_project" ]]; then
            export PS1="🎯 [$active_project] $REFOCUS_ORIGINAL_PS1"
        else
            export PS1="$REFOCUS_ORIGINAL_PS1"
        fi
    fi
}

# Call after each command
PROMPT_COMMAND="update_refocus_prompt; $PROMPT_COMMAND"
```

### Function Integration

#### Shell Function Configuration
Refocus Shell uses a shell function to maintain session state across commands:

Location: `~/.local/refocus/lib/focus-function.sh`

#### Custom Function Behavior
```bash
# Add custom behavior after focus commands
focus() {
    # Call original focus function
    "$HOME/.local/refocus/focus" "$@"
    
    # Custom behavior
    case "$1" in
        "on")
            echo "🎯 Focus session started - good luck!"
            ;;
        "off")
            echo "✅ Session completed - great work!"
            ;;
    esac
}
```

### Terminal Integration

#### Multi-Terminal Support
The prompt indicator works across all terminals:
- Start focus in terminal 1
- Open terminal 2 → see the indicator
- Works in tmux, screen, multiple tabs

#### Terminal-Specific Configuration
```bash
# Terminal-specific settings
if [[ "$TERM" == "xterm-256color" ]]; then
    export REFOCUS_PROMPT_COLOR="\033[1;32m"
elif [[ "$TERM" == "screen" ]]; then
    export REFOCUS_PROMPT_FORMAT="[%s]"
fi
```

## Advanced Configuration

### Performance Tuning

#### Database Optimization
```bash
# Vacuum database periodically
sqlite3 ~/.local/refocus/refocus.db "VACUUM;"

# Analyze query performance
sqlite3 ~/.local/refocus/refocus.db "ANALYZE;"
```

#### Cron Job Optimization
```bash
# Custom cron timing for nudges
export REFOCUS_CRON_RANDOMIZE=true  # Add random delay

# Reduce cron job overhead
export REFOCUS_CRON_QUIET=true
```

### Security Configuration

#### File Permissions
```bash
# Secure database file
chmod 600 ~/.local/refocus/refocus.db

# Secure configuration
chmod 600 ~/.config/refocus-shell/config.sh
```

#### Restricted Access
```bash
# Lock down refocus directory
chmod 700 ~/.local/refocus

# Prevent accidental deletion
chattr +i ~/.local/refocus/refocus.db  # On ext filesystems
```

### Integration with External Tools

#### IDE Integration
```bash
# VS Code integration
code_with_focus() {
    local project="$1"
    focus on "$project"
    code .
}

alias vscode="code_with_focus"
```

#### Git Integration
```bash
# Automatic focus on git projects
cd_with_focus() {
    cd "$1"
    if [[ -d .git ]]; then
        local project=$(basename "$PWD")
        focus on "$project"
    fi
}

alias cdf="cd_with_focus"
```

#### Task Manager Integration
```bash
# Todoist integration example
start_task() {
    local task_id="$1"
    local task_name=$(todoist show "$task_id" | grep -o 'Task: .*')
    focus on "${task_name#Task: }"
}
```

## Troubleshooting Configuration

### Common Issues

#### Environment Variables Not Working
```bash
# Check if variables are set
printenv | grep REFOCUS

# Verify shell sources configuration
echo $BASH_SOURCE

# Check configuration file
focus config show
```

#### Prompt Not Updating
```bash
# Check shell integration
type focus
type focus-update-prompt

# Reinstall shell integration
./setup.sh install
```

#### Notifications Not Working
```bash
# Test notification system
notify-send "Test" "This is a test"

# Check desktop environment
echo $XDG_CURRENT_DESKTOP
echo $DISPLAY

# Test refocus notifications
focus nudge test
```

### Configuration Reset

#### Reset to Defaults
```bash
# Reset specific settings
focus config reset VERBOSE

# Reset all configuration
focus config reset --all

# Reinstall with defaults
./setup.sh uninstall
./setup.sh install
```

#### Clean Installation
```bash
# Complete removal and reinstall
./setup.sh uninstall
rm -rf ~/.local/refocus
rm -rf ~/.config/refocus-shell
./setup.sh install
```

---

*Next: [Troubleshooting Guide](troubleshooting.md)*
