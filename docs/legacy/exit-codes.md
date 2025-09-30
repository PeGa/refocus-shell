# Refocus Shell - Exit Code Standards

## Overview
This document defines the standardized exit codes used throughout the Refocus Shell project to ensure consistent error handling and programmatic integration.

## Exit Code Definitions

### Success Codes
- **`0`** - Success: Operation completed successfully

### Error Codes
- **`1`** - General Error: Unspecified error occurred
- **`2`** - Invalid Arguments: Command line arguments are invalid or missing
- **`3`** - Database Error: Database operation failed
- **`4`** - Permission Error: Insufficient permissions to perform operation
- **`5`** - File System Error: File or directory operation failed
- **`6`** - Configuration Error: Configuration file or settings issue
- **`7`** - State Error: Invalid application state for requested operation

## Usage Guidelines

### Commands (Scripts)
Commands should use `exit` to terminate the entire script with appropriate exit codes:

```bash
# Success
exit 0

# Invalid arguments
if [[ -z "$project" ]]; then
    echo "❌ Project name is required."
    exit 2
fi

# Database error
if ! execute_sqlite "SELECT * FROM sessions"; then
    echo "❌ Database operation failed."
    exit 3
fi

# Permission error
if [[ ! -w "$DB_PATH" ]]; then
    echo "❌ Insufficient permissions to access database."
    exit 4
fi
```

### Library Functions
Library functions should use `return` to indicate success/failure to calling code:

```bash
# Success
return 0

# General error
return 1

# Let calling command handle exit codes
if ! validate_project_name "$project"; then
    return 1  # Command will handle exit
fi
```

## Error Code Mapping

| Scenario | Exit Code | Description |
|----------|-----------|-------------|
| Command completed successfully | 0 | Normal operation |
| Missing required arguments | 2 | User input validation |
| Invalid argument format | 2 | User input validation |
| Database connection failed | 3 | Database issues |
| SQL query failed | 3 | Database issues |
| Database locked | 3 | Database issues |
| Cannot write to database file | 4 | File permissions |
| Cannot create directories | 4 | File permissions |
| Configuration file not found | 6 | Configuration issues |
| Invalid configuration | 6 | Configuration issues |
| Focus already active when trying to start | 7 | State conflicts |
| No active focus when trying to stop | 7 | State conflicts |
| Other unspecified errors | 1 | Catch-all for unexpected issues |

## Implementation Strategy

### Phase 1: Update Core Commands
1. `focus-on.sh` - Argument validation (2), state errors (7)
2. `focus-off.sh` - State errors (7), database errors (3)
3. `focus-past.sh` - Argument validation (2), database errors (3)

### Phase 2: Update Utility Commands
1. `focus-config.sh` - Configuration errors (6), permission errors (4)
2. `focus-export.sh` - File system errors (5), database errors (3)
3. `focus-import.sh` - File system errors (5), database errors (3)

### Phase 3: Update Library Functions
1. Update validation functions to return appropriate codes
2. Update database functions to return appropriate codes
3. Ensure consistent error propagation

## Testing Exit Codes

### Manual Testing
```bash
# Test argument validation
focus on
echo "Exit code: $?"  # Should be 2

# Test success
focus on "test"
echo "Exit code: $?"  # Should be 0

# Test state error
focus off  # When no session active
echo "Exit code: $?"  # Should be 7
```

### Script Integration
```bash
#!/bin/bash
focus on "my-project"
case $? in
    0) echo "Focus started successfully" ;;
    2) echo "Invalid arguments provided" ;;
    7) echo "Focus already active or invalid state" ;;
    *) echo "Unexpected error occurred" ;;
esac
```

## Migration Notes

### Current State
- Most commands use `exit 1` for all errors
- Library functions use `return 0`/`return 1`
- No distinction between error types

### Migration Approach
1. **Backward Compatible**: Existing `exit 1` becomes `exit 1` (general error)
2. **Incremental**: Update commands one at a time
3. **Documentation**: Update all documentation to reflect new codes
4. **Testing**: Verify each command's exit codes

### Breaking Changes
- None: All existing `exit 1` cases remain valid as general errors
- New codes provide additional specificity without breaking existing integrations

---

*This document should be updated as new error scenarios are identified and standardized.*
