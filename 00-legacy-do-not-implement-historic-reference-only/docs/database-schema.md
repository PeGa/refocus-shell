# Database Schema Standardization

This document describes the standardized database schema and migration patterns for Refocus Shell.

## Overview

Refocus Shell uses SQLite3 for data storage with three main tables:
- **state**: Application state and configuration
- **sessions**: Focus session data
- **projects**: Project descriptions and metadata

## Standardized Schema

### State Table
```sql
CREATE TABLE IF NOT EXISTS state (
    id INTEGER PRIMARY KEY,
    active INTEGER DEFAULT 0,
    project TEXT,
    start_time TEXT,
    prompt_content TEXT,
    prompt_type TEXT DEFAULT 'default',
    nudging_enabled BOOLEAN DEFAULT 1,
    focus_disabled BOOLEAN DEFAULT 0,
    last_focus_off_time TEXT,
    paused INTEGER DEFAULT 0,
    pause_notes TEXT,
    pause_start_time TEXT,
    previous_elapsed INTEGER DEFAULT 0
);
```

### Sessions Table
```sql
CREATE TABLE IF NOT EXISTS sessions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    project TEXT NOT NULL,
    start_time TEXT,
    end_time TEXT,
    duration_seconds INTEGER NOT NULL,
    notes TEXT,
    duration_only INTEGER DEFAULT 0,
    session_date TEXT
);
```

### Projects Table
```sql
CREATE TABLE IF NOT EXISTS projects (
    project TEXT PRIMARY KEY,
    description TEXT NOT NULL,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);
```

## Table Name Variables

All database operations use standardized table name variables:

```bash
# Standard table name variables
STATE_TABLE="${STATE_TABLE:-state}"
SESSIONS_TABLE="${SESSIONS_TABLE:-sessions}"
PROJECTS_TABLE="${PROJECTS_TABLE:-projects}"
```

### Usage Pattern
```bash
# Correct usage
execute_sqlite "SELECT * FROM $SESSIONS_TABLE WHERE project = 'test';" "function_name"

# Avoid hardcoded table names
execute_sqlite "SELECT * FROM sessions WHERE project = 'test';" "function_name"  # ❌ Don't do this
```

## Migration System

### Migration Function
The `migrate_database()` function handles schema evolution:

```bash
# Called automatically during bootstrap
migrate_database
```

### Migration Checks
The migration function checks for:
1. **Notes column** in sessions table
2. **Duration-only columns** (`duration_only`, `session_date`) in sessions table
3. **Nullable timestamps** (start_time/end_time) in sessions table
4. **Pause-related columns** in state table

### Migration Process
```bash
# Check if column exists
has_column=$(execute_sqlite "PRAGMA table_info($TABLE);" "migrate_database" | grep -c "column_name" || echo "0")

# Add column if missing
if [[ "$has_column" -eq 0 ]]; then
    execute_sqlite "ALTER TABLE $TABLE ADD COLUMN column_name TYPE DEFAULT value;" "migrate_database" >/dev/null
fi
```

## Schema Evolution History

### Version 1 (Original)
- Basic sessions table with NOT NULL timestamps
- No notes column
- No duration-only sessions

### Version 2 (Current)
- Added notes column to sessions
- Added duration_only and session_date columns
- Made start_time/end_time nullable
- Added pause functionality to state table

## Database Operations

### Standardized Functions
All database operations use the `execute_sqlite()` function:

```bash
# Standard pattern
execute_sqlite "SQL_QUERY" "function_name" [output_redirect]

# Examples
execute_sqlite "SELECT * FROM $SESSIONS_TABLE WHERE project = 'test';" "get_sessions"
execute_sqlite "INSERT INTO $SESSIONS_TABLE (...) VALUES (...);" "insert_session" >/dev/null
```

### Error Handling
```bash
# All database operations include error handling
if ! execute_sqlite "SELECT * FROM $SESSIONS_TABLE"; then
    echo "❌ Database error occurred"
    return 1
fi
```

## File-Specific Schema Definitions

### Primary Schema Files
- **lib/focus-db.sh**: Main schema definitions and migration
- **setup.sh**: Installation schema (must match current schema)
- **commands/focus-init.sh**: Initialization schema (must match current schema)
- **commands/focus-import.sh**: Import schema (must match current schema)

### Schema Consistency
All schema definitions must be identical across files:

```sql
-- This schema must be identical in all files
CREATE TABLE IF NOT EXISTS sessions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    project TEXT NOT NULL,
    start_time TEXT,
    end_time TEXT,
    duration_seconds INTEGER NOT NULL,
    notes TEXT,
    duration_only INTEGER DEFAULT 0,
    session_date TEXT
);
```

## Testing Schema Consistency

### Verification Commands
```bash
# Check current schema
sqlite3 ~/.local/refocus/refocus.db ".schema sessions"
sqlite3 ~/.local/refocus/refocus.db ".schema state"
sqlite3 ~/.local/refocus/refocus.db ".schema projects"

# Test database operations
focus past add "test" --duration "1h" --date "today"
focus past list 1
```

### Migration Testing
```bash
# Test migration on fresh database
rm ~/.local/refocus/refocus.db
focus init
# Verify schema matches expected structure
```

## Best Practices

### For Developers
1. **Always use table name variables** - Never hardcode table names
2. **Update all schema files** - Keep setup.sh, focus-init.sh, focus-import.sh in sync
3. **Test migrations** - Verify migration works on old databases
4. **Use execute_sqlite()** - Never call sqlite3 directly in commands

### For Schema Changes
1. **Add migration logic** - Update migrate_database() function
2. **Update all schema files** - Ensure consistency across all files
3. **Test thoroughly** - Verify old databases migrate correctly
4. **Document changes** - Update this file with schema evolution

### For Database Operations
1. **Use standardized functions** - execute_sqlite(), get_session_info(), etc.
2. **Handle errors gracefully** - Check return codes and provide meaningful messages
3. **Use proper escaping** - Use sql_escape() for user input
4. **Test edge cases** - Empty results, invalid data, etc.

## Troubleshooting

### Common Issues
1. **Schema mismatch**: Different files create different schemas
2. **Missing columns**: Migration didn't run or failed
3. **Hardcoded table names**: Using "sessions" instead of "$SESSIONS_TABLE"

### Debugging Commands
```bash
# Check schema
sqlite3 ~/.local/refocus/refocus.db ".schema"

# Check table info
sqlite3 ~/.local/refocus/refocus.db "PRAGMA table_info(sessions);"

# Test migration
focus init  # Re-runs migration

# Check for hardcoded names
grep -r "FROM sessions" commands/ lib/
grep -r "FROM state" commands/ lib/
```

## Future Considerations

### Schema Versioning
Consider implementing explicit schema versioning:
```sql
CREATE TABLE schema_version (
    version INTEGER PRIMARY KEY,
    applied_at TEXT NOT NULL
);
```

### Migration Rollback
For complex migrations, consider rollback capabilities:
```bash
# Backup before migration
cp refocus.db refocus.db.backup

# Rollback if needed
cp refocus.db.backup refocus.db
```

### Performance Optimization
- Add indexes for frequently queried columns
- Consider partitioning for large datasets
- Implement database cleanup routines

---

*This document ensures database schema consistency across all Refocus Shell components.*
