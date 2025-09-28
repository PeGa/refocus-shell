# Refocus Shell - Public Contract

This document defines the public contract for the Refocus Shell time tracking tool, including commands, flags, environment variables, exit codes, and usage examples.

## Commands

### Basic Commands

#### `focus on <project>`
Start focusing on a project.

**Usage:** `focus on <project>`

**Parameters:**
- `project` (required): Project name (max 100 chars, no control characters)

**Exit Codes:**
- `0`: Success
- `1`: Already active session, disabled state, or session paused
- `2`: Invalid arguments (missing project name)

**Examples:**
```bash
focus on coding
focus on "my-project"
focus on meeting
```

#### `focus off`
Stop current focus session.

**Usage:** `focus off`

**Parameters:** None

**Exit Codes:**
- `0`: Success
- `1`: No active session to stop

**Examples:**
```bash
focus off
```

#### `focus pause`
Pause current focus session.

**Usage:** `focus pause`

**Parameters:** None

**Exit Codes:**
- `0`: Success
- `1`: No active session to pause, disabled state

**Examples:**
```bash
focus pause
```

#### `focus continue`
Resume paused focus session.

**Usage:** `focus continue`

**Parameters:** None

**Exit Codes:**
- `0`: Success
- `1`: No paused session to continue, disabled state

**Examples:**
```bash
focus continue
```

#### `focus status`
Show current focus status.

**Usage:** `focus status`

**Parameters:** None

**Exit Codes:**
- `0`: Success (always)

**Examples:**
```bash
focus status
```

### Management Commands

#### `focus enable`
Enable refocus shell.

**Usage:** `focus enable`

**Parameters:** None

**Exit Codes:**
- `0`: Success (always)

**Examples:**
```bash
focus enable
```

#### `focus disable`
Disable refocus shell.

**Usage:** `focus disable`

**Parameters:** None

**Exit Codes:**
- `0`: Success (always)

**Examples:**
```bash
focus disable
```

#### `focus reset`
Reset all focus data.

**Usage:** `focus reset`

**Parameters:** None

**Exit Codes:**
- `0`: Success
- `1`: Reset failed

**Examples:**
```bash
focus reset
```

#### `focus init`
Initialize database.

**Usage:** `focus init`

**Parameters:** None

**Exit Codes:**
- `0`: Success
- `1`: Initialization failed

**Examples:**
```bash
focus init
```

### Data Commands

#### `focus export [file]`
Export focus data.

**Usage:** `focus export [file]`

**Parameters:**
- `file` (optional): Output filename (defaults to timestamped name)

**Exit Codes:**
- `0`: Success
- `1`: Export failed

**Examples:**
```bash
focus export
focus export my-backup.sql
```

#### `focus import <file>`
Import focus data.

**Usage:** `focus import <file>`

**Parameters:**
- `file` (required): Input filename (SQLite dump or JSON)

**Exit Codes:**
- `0`: Success
- `1`: Import failed, file not found
- `2`: Invalid file format

**Examples:**
```bash
focus import backup.sql
focus import data.json
```

### Past Sessions

#### `focus past add <project> <start> <end>`
Add past session.

**Usage:** `focus past add <project> <start> <end>`

**Parameters:**
- `project` (required): Project name
- `start` (required): Start time (YYYY/MM/DD-HH:MM or HH:MM)
- `end` (required): End time (YYYY/MM/DD-HH:MM or HH:MM)

**Exit Codes:**
- `0`: Success
- `1`: Invalid arguments, parsing failed
- `2`: Invalid date format

**Examples:**
```bash
focus past add meeting 2025/07/30-14:15 2025/07/30-15:30
focus past add meeting 14:15 15:30
```

#### `focus past modify <id> [project] [start] [end]`
Modify session.

**Usage:** `focus past modify <id> [project] [start] [end]`

**Parameters:**
- `id` (required): Session ID
- `project` (optional): New project name
- `start` (optional): New start time
- `end` (optional): New end time

**Exit Codes:**
- `0`: Success
- `1`: Session not found, modification failed
- `2`: Invalid arguments

**Examples:**
```bash
focus past modify 1 "new-project"
focus past modify 1 "" "15:00" "16:00"
```

#### `focus past delete <id>`
Delete session.

**Usage:** `focus past delete <id>`

**Parameters:**
- `id` (required): Session ID

**Exit Codes:**
- `0`: Success
- `1`: Session not found, deletion failed

**Examples:**
```bash
focus past delete 1
```

#### `focus past list [limit]`
List recent sessions.

**Usage:** `focus past list [limit]`

**Parameters:**
- `limit` (optional): Number of sessions to show (default: 20)

**Exit Codes:**
- `0`: Success (always)

**Examples:**
```bash
focus past list
focus past list 10
```

### Session Notes

#### `focus notes add <project>`
Add notes to recent session.

**Usage:** `focus notes add <project>`

**Parameters:**
- `project` (required): Project name

**Exit Codes:**
- `0`: Success
- `1`: No recent session found

**Examples:**
```bash
focus notes add coding
```

### Nudging

#### `focus nudge enable`
Enable focus reminders.

**Usage:** `focus nudge enable`

**Parameters:** None

**Exit Codes:**
- `0`: Success (always)

**Examples:**
```bash
focus nudge enable
```

#### `focus nudge disable`
Disable focus reminders.

**Usage:** `focus nudge disable`

**Parameters:** None

**Exit Codes:**
- `0`: Success (always)

**Examples:**
```bash
focus nudge disable
```

#### `focus nudge status`
Show nudging status.

**Usage:** `focus nudge status`

**Parameters:** None

**Exit Codes:**
- `0`: Success (always)

**Examples:**
```bash
focus nudge status
```

#### `focus nudge test`
Test notification system.

**Usage:** `focus nudge test`

**Parameters:** None

**Exit Codes:**
- `0`: Success (always)

**Examples:**
```bash
focus nudge test
```

### Reports

#### `focus report today`
Today's focus report.

**Usage:** `focus report today [--raw]`

**Parameters:**
- `--raw` (optional): Output machine-readable format with epoch timestamps and CSV data

**Exit Codes:**
- `0`: Success (always)

**Examples:**
```bash
focus report today
focus report today --raw
```

#### `focus report week`
This week's focus report.

**Usage:** `focus report week [--raw]`

**Parameters:**
- `--raw` (optional): Output machine-readable format with epoch timestamps and CSV data

**Exit Codes:**
- `0`: Success (always)

**Examples:**
```bash
focus report week
focus report week --raw
```

#### `focus report month`
This month's focus report.

**Usage:** `focus report month [--raw]`

**Parameters:**
- `--raw` (optional): Output machine-readable format with epoch timestamps and CSV data

**Exit Codes:**
- `0`: Success (always)

**Examples:**
```bash
focus report month
focus report month --raw
```

#### `focus report custom <days>`
Custom period report.

**Usage:** `focus report custom <days> [--raw]`

**Parameters:**
- `days` (required): Number of days to report
- `--raw` (optional): Output machine-readable format with epoch timestamps and CSV data

**Exit Codes:**
- `0`: Success
- `2`: Invalid arguments

**Examples:**
```bash
focus report custom 7
focus report custom 30
focus report custom 7 --raw
```

### Utility Commands

#### `focus test-nudge`
Test notifications.

**Usage:** `focus test-nudge`

**Parameters:** None

**Exit Codes:**
- `0`: Success (always)

**Examples:**
```bash
focus test-nudge
```

#### `focus config`
Manage configuration.

**Usage:** `focus config [subcommand]`

**Subcommands:**
- `show`: Show current configuration
- `validate`: Validate configuration
- `set <key> <value>`: Set configuration value

**Exit Codes:**
- `0`: Success
- `1`: Configuration error
- `2`: Invalid arguments

**Examples:**
```bash
focus config show
focus config set VERBOSE true
focus config validate
```

#### `focus description`
Manage project descriptions.

**Usage:** `focus description [subcommand]`

**Subcommands:**
- `add <project> <description>`: Add project description
- `show <project>`: Show project description
- `list`: List all project descriptions

**Exit Codes:**
- `0`: Success
- `1`: Project not found
- `2`: Invalid arguments

**Examples:**
```bash
focus description add coding "Main development project"
focus description show coding
focus description list
```

#### `focus diagnose`
System diagnostics and repair.

**Usage:** `focus diagnose`

**Parameters:** None

**Exit Codes:**
- `0`: Success (always)

**Examples:**
```bash
focus diagnose
```

#### `focus help`
Show help.

**Usage:** `focus help`

**Parameters:** None

**Exit Codes:**
- `0`: Success (always)

**Examples:**
```bash
focus help
```

## Environment Variables

### Database Configuration
- `REFOCUS_DB_PATH`: Database file path (default: `$HOME/.local/refocus/refocus.db`)
- `REFOCUS_STATE_TABLE`: State table name (default: `state`)
- `REFOCUS_SESSIONS_TABLE`: Sessions table name (default: `sessions`)
- `REFOCUS_PROJECTS_TABLE`: Projects table name (default: `projects`)

### Installation Paths
- `REFOCUS_INSTALL_DIR`: Installation directory (default: `$HOME/.local/bin`)
- `REFOCUS_DATA_DIR`: Data directory (default: `$HOME/.local/refocus`)

### Behavior Configuration
- `REFOCUS_VERBOSE`: Enable verbose mode (default: `false`)
- `REFOCUS_IDLE_THRESHOLD`: Idle session threshold in seconds (default: `60`)
- `REFOCUS_MAX_PROJECT_LENGTH`: Maximum project name length (default: `100`)

### Notification Configuration
- `REFOCUS_NOTIFICATIONS`: Enable notifications (default: `true`)
- `REFOCUS_NOTIFICATION_TIMEOUT`: Notification timeout in milliseconds (default: `5000`)

### Nudging Configuration
- `REFOCUS_NUDGING`: Enable nudging (default: `true`)
- `REFOCUS_NUDGE_INTERVAL`: Nudging interval in minutes (default: `10`)

### Reporting Configuration
- `REFOCUS_REPORT_LIMIT`: Default report limit (default: `20`)
- `REFOCUS_DATE_FORMAT`: Date format for reports (default: `%Y-%m-%d %H:%M`)
- `REFOCUS_TIME_FORMAT`: Time format for reports (default: `%H:%M`)

### Raw Mode Format
When using the `--raw` flag with report commands, output is formatted as CSV with the following structure:

**Summary Data:**
- `start_time,end_time`: Period boundaries (epoch timestamps)
- `total_duration_seconds,total_sessions,active_projects`: Summary statistics

**Session Data:**
- `project,start_time,end_time,duration_seconds,notes,duration_only,session_date`: Individual session details
- All timestamps are in epoch format for machine processing
- Empty fields are represented as empty strings

### Export/Import Configuration
- `REFOCUS_EXPORT_FORMAT`: Export filename format (default: `refocus-export-%Y%m%d_%H%M%S.sql`)
- `REFOCUS_EXPORT_DIR`: Export directory (default: current directory)

### Validation Configuration
- `REFOCUS_MAX_SESSION_HOURS`: Maximum session duration in hours (default: `24`)
- `REFOCUS_MIN_SESSION_SECONDS`: Minimum session duration in seconds (default: `1`)

### Debug Configuration
- `REFOCUS_DEBUG`: Enable debug mode (default: `false`)
- `REFOCUS_LOG_FILE`: Log file path (default: none)

## Configuration Precedence

1. Environment variables (highest priority)
2. User configuration file (`$XDG_CONFIG_HOME/refocus/refocus.conf` or `$HOME/.config/refocus/refocus.conf`)
3. Default values (lowest priority)

## Exit Codes

- `0`: Success
- `1`: General error (disabled state, no active session, etc.)
- `2`: Invalid arguments or input validation failure

## Date/Time Formats

### Supported Input Formats
- `YYYY/MM/DD-HH:MM`: Specific date and time
- `YYYY/MM/DD`: Specific date (time defaults to 00:00)
- `HH:MM`: Time only (date defaults to today)

### Duration Formats
- `XhYm`: Hours and minutes (e.g., `1h30m`)
- `Xh`: Hours only (e.g., `2h`)
- `Xm`: Minutes only (e.g., `45m`)
- `X.Yh`: Decimal hours (e.g., `1.5h`)

## Examples

### Basic Workflow
```bash
# Start focusing
focus on coding
focus status

# Pause and resume
focus pause
focus continue

# Stop session
focus off
```

### Past Session Management
```bash
# Add past session
focus past add meeting 2025/07/30-14:15 2025/07/30-15:30

# List recent sessions
focus past list 10

# Modify session
focus past modify 1 "updated-project"
```

### Reporting
```bash
# Generate reports
focus report today
focus report week
focus report custom 7

# Generate machine-readable reports
focus report today --raw
focus report week --raw
focus report custom 7 --raw
```

### Configuration
```bash
# Show configuration
focus config show

# Enable verbose mode
focus config set VERBOSE true

# Validate configuration
focus config validate
```

### Data Management
```bash
# Export data
focus export backup.sql

# Import data
focus import backup.sql

# Reset all data
focus reset
```

## Notes

- All commands support `--help` flag for detailed help
- Project names are sanitized (control characters removed, whitespace trimmed)
- Session notes are optional and can be skipped by pressing Enter
- The system automatically handles idle sessions between focus sessions
- Cron jobs are automatically managed for nudging functionality
- Database migrations are handled automatically on startup
