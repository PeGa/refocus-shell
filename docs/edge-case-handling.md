# Edge Case Handling

This document describes the comprehensive edge case handling implemented in Refocus Shell to address disk space, permission errors, and database corruption issues.

## Overview

Refocus Shell now includes robust edge case handling for three critical areas:

1. **Disk Space Management** - Prevents operations when insufficient disk space is available
2. **Permission Error Handling** - Detects and reports file permission issues
3. **Database Corruption Detection and Recovery** - Automatically detects and attempts to recover from database corruption

## Implementation Details

### Disk Space Checking

#### Functions Added
- `check_disk_space()` - Verifies sufficient disk space before database operations
- `pre_database_operation_check()` - Comprehensive pre-operation validation

#### Configuration
- `MIN_DISK_SPACE_MB=10` - Minimum required disk space (configurable)

#### Behavior
- Checks available disk space before write operations (INSERT, UPDATE, DELETE, CREATE, DROP, ALTER)
- Returns exit code 5 (File system error) if insufficient space
- Provides detailed error messages with available space information
- Gracefully handles systems where `df` command is not available

#### Example Error Handling
```bash
❌ Insufficient disk space: 5MB available, 10MB required
   Database directory: /home/user/.local/refocus
```

### Permission Error Handling

#### Functions Added
- `check_database_permissions()` - Validates file and directory permissions
- Enhanced `execute_sqlite()` with permission error detection

#### Behavior
- Checks read/write permissions for database directory and file
- Detects SQLite permission errors ("permission denied", "readonly database")
- Returns exit code 4 (Permission error) for permission issues
- Provides detailed permission information in error messages

#### Example Error Handling
```bash
❌ Permission error detected
   Database file: /home/user/.local/refocus/refocus.db
   File permissions: -rw-r--r-- 1 user user 1024 Jan 1 12:00 refocus.db
```

### Database Corruption Detection and Recovery

#### Functions Added
- `check_database_integrity()` - Performs SQLite integrity checks
- `attempt_database_recovery()` - Attempts automatic database recovery
- `create_database_backup()` - Creates timestamped backups before risky operations

#### Behavior
- Uses SQLite's `PRAGMA integrity_check` to detect corruption
- Automatically attempts recovery by dumping and restoring the database
- Creates backups of corrupted files before recovery attempts
- Returns exit code 3 (Database error) for corruption issues
- Retries operations after successful recovery

#### Recovery Process
1. Create dump of corrupted database
2. Backup corrupted file with timestamp
3. Restore database from dump
4. Verify integrity of restored database
5. Retry original operation if recovery successful

#### Example Recovery
```bash
❌ Database corruption detected
   Attempting recovery...
🔧 Attempting database recovery...
✅ Database recovery successful
   Corrupted file backed up as: refocus.db.corrupted.1640995200
✅ Database recovered, retrying operation...
```

## Enhanced Error Handling in execute_sqlite()

The `execute_sqlite()` function has been enhanced with comprehensive error detection:

### Error Pattern Detection
- **Disk Space Errors**: "disk I/O error", "database or disk is full"
- **Permission Errors**: "permission denied", "readonly database"  
- **Corruption Errors**: "database disk image is malformed", "corrupt"

### Exit Code Mapping
- `0` - Success
- `1` - General error
- `3` - Database error (corruption, SQL errors)
- `4` - Permission error
- `5` - File system error (disk space)

### Automatic Recovery
- Corruption detection triggers automatic recovery attempt
- Successful recovery allows operation retry
- Failed recovery preserves original error information

## Diagnose Command

A new `focus diagnose` command provides comprehensive system diagnostics and repair capabilities:

### Commands Available
- `focus diagnose system` - Run comprehensive system diagnostics
- `focus diagnose repair` - Attempt to repair common issues
- `focus diagnose backup` - Create emergency database backup
- `focus diagnose restore <file>` - Restore database from backup
- `focus diagnose list-backups` - List available backups

### System Diagnostics Include
- Database file existence and permissions
- Directory permissions and available space
- SQLite availability and version
- System command availability
- Log directory status
- Environment variable configuration

### Repair Capabilities
- Create missing directories
- Fix file permissions
- Initialize new database if missing
- Attempt database recovery
- Comprehensive error reporting

## Backup System

### Automatic Backups
- Created before risky database operations
- Stored in `~/.local/refocus/backups/`
- Timestamped naming: `refocus_backup_YYYYMMDD_HHMMSS.db`

### Manual Backups
- `focus diagnose backup` - Create emergency backup
- `focus diagnose list-backups` - View available backups
- `focus diagnose restore <file>` - Restore from backup

## Configuration

### Environment Variables
- `REFOCUS_DB` - Database file path
- `REFOCUS_LOG_DIR` - Log directory path
- `REFOCUS_ERROR_LOG` - Error log file path
- `MIN_DISK_SPACE_MB` - Minimum required disk space

### Default Values
- Database: `~/.local/refocus/refocus.db`
- Log directory: `~/.local/refocus`
- Error log: `~/.local/refocus/error.log`
- Minimum disk space: `10MB`

## Error Logging

All edge case errors are logged to the error log file with:
- Timestamp
- Context (function name)
- Error message
- SQL command (for database errors)

## Best Practices

### For Users
1. Run `focus diagnose system` regularly to check system health
2. Use `focus diagnose repair` if experiencing issues
3. Create backups before major operations
4. Monitor disk space in database directory

### For Developers
1. All database operations automatically include edge case checks
2. Use standardized exit codes for error handling
3. Log all errors with context information
4. Test edge case scenarios during development

## Testing Edge Cases

### Disk Space Testing
```bash
# Fill disk to test space checking
dd if=/dev/zero of=/tmp/fillup bs=1M count=1000
focus on "test-project"  # Should fail with disk space error
```

### Permission Testing
```bash
# Remove write permissions
chmod 444 ~/.local/refocus/refocus.db
focus on "test-project"  # Should fail with permission error
```

### Corruption Testing
```bash
# Corrupt database file
echo "corrupt" > ~/.local/refocus/refocus.db
focus status  # Should detect corruption and attempt recovery
```

## Troubleshooting

### Common Issues
1. **"Insufficient disk space"** - Free up space in database directory
2. **"Permission denied"** - Check file/directory permissions
3. **"Database corruption"** - Use `focus diagnose repair` or restore from backup

### Recovery Steps
1. Run `focus diagnose system` to identify issues
2. Use `focus diagnose repair` for automatic fixes
3. Create backup with `focus diagnose backup`
4. Restore from backup if needed: `focus diagnose restore <file>`

## Future Enhancements

- Configurable disk space thresholds
- Automatic cleanup of old backups
- Network storage support
- Real-time monitoring and alerts
- Integration with system monitoring tools
