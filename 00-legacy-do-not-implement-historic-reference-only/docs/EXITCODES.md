# Refocus Shell - Exit Codes

This document defines the standardized exit codes used throughout the Refocus Shell time tracking tool to provide consistent user experience and error handling.

## Exit Code Standards

| Code | Meaning | Usage | Examples |
|------|---------|-------|----------|
| `0` | Success | Command completed successfully | `focus on project`, `focus status` |
| `1` | Generic Error | General failure, disabled state, system error | Database error, file not writable, disabled shell |
| `2` | Usage/Validation Error | Invalid arguments, input validation failure | Missing required args, invalid date format, bad project name |
| `3` | Not Found | Resource doesn't exist | Session not found, project not found, file not found |
| `4` | Conflict | State conflict, already exists | Already focusing, session already paused, duplicate project |

## Error Helper Functions

The following helper functions are available in `lib/focus-utils.sh` for consistent error handling:

### `die(message)`
- **Exit Code**: `1`
- **Usage**: General failures, system errors
- **Example**: `die "Database connection failed"`

### `usage(message)`
- **Exit Code**: `2`
- **Usage**: Invalid arguments, validation failures
- **Example**: `usage "Project name is required"`

### `not_found(message)`
- **Exit Code**: `3`
- **Usage**: Resource doesn't exist
- **Example**: `not_found "Session ID 123 not found"`

### `conflict(message)`
- **Exit Code**: `4`
- **Usage**: State conflicts, already exists
- **Example**: `conflict "Already focusing on another project"`

## Command-Specific Exit Codes

### Basic Commands

#### `focus on <project>`
- `0`: Successfully started focus session
- `1`: System error (database, file system)
- `2`: Invalid project name (empty, too long, control characters)
- `4`: Already focusing on another project

#### `focus off`
- `0`: Successfully stopped focus session
- `1`: System error
- `3`: No active session to stop

#### `focus pause`
- `0`: Successfully paused focus session
- `1`: System error
- `3`: No active session to pause
- `4`: Session already paused

#### `focus continue`
- `0`: Successfully resumed focus session
- `1`: System error
- `3`: No paused session to continue
- `4`: Session not paused

#### `focus status`
- `0`: Always succeeds (shows current state)

### Management Commands

#### `focus enable`
- `0`: Always succeeds

#### `focus disable`
- `0`: Always succeeds

#### `focus reset`
- `0`: Successfully reset all data
- `1`: Reset failed (permission error, system error)

#### `focus init`
- `0`: Successfully initialized database
- `1`: Initialization failed (permission error, system error)

### Data Commands

#### `focus export [file]`
- `0`: Successfully exported data
- `1`: Export failed (permission error, system error)
- `2`: Invalid filename format

#### `focus import <file>`
- `0`: Successfully imported data
- `1`: Import failed (permission error, system error)
- `2`: Invalid file format
- `3`: File not found

### Past Sessions

#### `focus past add <project> <start> <end>`
- `0`: Successfully added session
- `1`: System error
- `2`: Invalid arguments (missing project, invalid date format)

#### `focus past modify <id> [project] [start] [end]`
- `0`: Successfully modified session
- `1`: System error
- `2`: Invalid arguments
- `3`: Session not found

#### `focus past delete <id>`
- `0`: Successfully deleted session
- `1`: System error
- `3`: Session not found

#### `focus past list [limit]`
- `0`: Always succeeds

### Session Notes

#### `focus notes add <project>`
- `0`: Successfully added notes
- `1`: System error
- `3`: No recent session found for project

### Nudging

#### `focus nudge enable`
- `0`: Always succeeds

#### `focus nudge disable`
- `0`: Always succeeds

#### `focus nudge status`
- `0`: Always succeeds

#### `focus nudge test`
- `0`: Always succeeds

### Reports

#### `focus report today`
- `0`: Always succeeds

#### `focus report week`
- `0`: Always succeeds

#### `focus report month`
- `0`: Always succeeds

#### `focus report custom <days>`
- `0`: Successfully generated report
- `2`: Invalid number of days

### Utility Commands

#### `focus test-nudge`
- `0`: Always succeeds

#### `focus config`
- `0`: Successfully executed config command
- `1`: Configuration error
- `2`: Invalid arguments

#### `focus description`
- `0`: Successfully executed description command
- `1`: System error
- `2`: Invalid arguments
- `3`: Project not found

#### `focus diagnose`
- `0`: Always succeeds

#### `focus help`
- `0`: Always succeeds

## Implementation Guidelines

1. **Use helper functions**: Prefer `die()`, `usage()`, `not_found()`, `conflict()` over raw `exit` calls
2. **Be specific**: Choose the most appropriate exit code for the error condition
3. **Document exceptions**: If a command needs non-standard exit codes, document the reason
4. **Consistent messaging**: Error messages should be clear and actionable
5. **Test exit codes**: Verify that commands return expected exit codes in all scenarios

## Examples

```bash
# Success
focus on coding
echo $?  # 0

# Usage error
focus on ""
echo $?  # 2

# Not found
focus past delete 999
echo $?  # 3

# Conflict
focus on project1
focus on project2  # Already focusing
echo $?  # 4

# Generic error
focus off  # No active session
echo $?  # 1
```

## Notes

- Exit codes should be consistent across all refocus commands
- Helper functions provide standardized error messages and exit codes
- Commands should validate input early and exit with appropriate codes
- System errors (database, file system) should use exit code 1
- User input errors should use exit code 2
- Resource not found errors should use exit code 3
- State conflict errors should use exit code 4
