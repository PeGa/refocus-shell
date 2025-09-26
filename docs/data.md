# Data Management

This guide covers backing up, restoring, and managing your Refocus Shell data.

## Data Storage

Refocus Shell stores all data locally in SQLite databases:

- **Database location**: `~/.local/refocus/refocus.db`
- **Data included**: Sessions, projects, state, configuration
- **Format**: SQLite3 database file
- **Privacy**: 100% local, no cloud sync, no telemetry

## Export and Import

### Export Formats

Refocus Shell supports two export formats:

#### SQLite Dump (.sql)
- Complete database dump
- Backward compatible
- Can be restored with standard SQLite tools
- Includes schema and all data

#### JSON Export (.json)
- Human-readable format
- Version control friendly
- Cross-platform compatible
- Schema versioned for future compatibility

### Exporting Data

#### Export with Timestamp
```bash
focus export
# Creates: refocus-export-20250926_143022.sql and refocus-export-20250926_143022.json
```

#### Export with Custom Name
```bash
focus export my-backup
# Creates: my-backup.sql and my-backup.json
```

#### Export to Specific Directory
```bash
focus export ~/backups/refocus-backup
# Creates files in ~/backups/
```

### What's Included in Exports

Every export contains:
- **All focus sessions** (live and duration-only)
- **Current focus state** (active project, start time, etc.)
- **Project descriptions**
- **Configuration settings**
- **Pause/resume session data**
- **Database schema** (for compatibility)

### Importing Data

#### Auto-Detection Import
```bash
focus import backup-file
# Automatically detects .sql or .json format
```

#### Import SQLite Dump
```bash
focus import backup.sql
```

#### Import JSON Export
```bash
focus import backup.json
```

### Import Process

When importing:
1. **Validation**: File format and structure are verified
2. **Backup**: Current database is backed up automatically
3. **Confirmation**: Prompts for confirmation (will overwrite existing data)
4. **Import**: Database is cleared and restored from file
5. **Verification**: Import success is confirmed

```bash
focus import my-backup.json
📥 Importing focus data from: my-backup.json
📋 Detected format: json
⚠️  This will overwrite existing data. Continue? (y/N) y
📋 Created backup: /home/user/.local/refocus/refocus.db.backup.20250926_143022
✅ Focus data imported successfully from: my-backup.json
```

## Past Session Management

### Adding Historical Sessions

#### With Specific Times
```bash
focus past add "meeting" "2025/09/26-14:00" "2025/09/26-15:30"
focus past add "coding" "yesterday-09:00" "yesterday-17:00"
focus past add "research" "2025/09/20-10:30" "2025/09/20-12:00"
```

#### Flexible Time Formats
```bash
# Relative times (today assumed)
focus past add "standup" "09:00" "09:30"
focus past add "planning" "14:15" "15:45"

# Relative dates
focus past add "debugging" "yesterday-16:00" "yesterday-18:30"
focus past add "review" "monday-10:00" "monday-11:00"

# Specific dates
focus past add "workshop" "2025/09/25-13:00" "2025/09/25-17:00"
```

#### Duration-Only Sessions
Perfect for reconstructing work from memory or notes:

```bash
# Duration with date
focus past add "coding" --duration "2h30m" --date "today"
focus past add "meetings" --duration "1h15m" --date "yesterday"
focus past add "planning" --duration "45m" --date "2025/09/25"

# Duration with notes
focus past add "debugging" --duration "3h" --date "today" --notes "Fixed critical auth bug"
```

#### Adding Notes
```bash
# Notes during command
focus past add "research" "10:00" "12:00" --notes "Studied React patterns and authentication"

# Prompted for notes (if not provided)
focus past add "coding" "14:00" "16:00"
📝 What did you accomplish during this focus session? 
(Press Enter to skip, or type a brief description): Implemented user registration flow
```

### Viewing Session History

#### List Recent Sessions
```bash
focus past list        # Last 20 sessions
focus past list 10     # Last 10 sessions
focus past list 50     # Last 50 sessions
```

#### Session List Format
```
📋 Recent focus sessions (last 20):

ID   Project              Start               End                 Duration Type  
---- -------------------- ------------------- ------------------- -------- ------
42   coding               2025-09-26 14:00    2025-09-26 16:00    120m     Live  
     📝 Implemented user authentication
41   meeting              N/A                 N/A                 60m      Manual
     📝 Weekly team standup
40   research             2025-09-25 10:00    2025-09-25 12:00    120m     Live  
39   planning             N/A                 N/A                 45m      Manual
     📝 Project roadmap planning
```

#### Session Types
- **Live**: Created with `focus on`/`focus off` (has real timestamps)
- **Manual**: Added with `focus past add` (may be duration-only)

### Modifying Sessions

#### Change Project Name Only
```bash
focus past modify 42 "new-project-name"
```

#### Change Complete Session (Live Sessions Only)
```bash
focus past modify 42 "project" "14:00" "16:00"
focus past modify 42 "project" "2025/09/26-14:00" "2025/09/26-16:00"
```

#### Duration-Only Session Limitations
For duration-only (manual) sessions:
- ✅ Can change project name
- ❌ Cannot change start/end times (they don't exist)
- ✅ Duration is preserved

```bash
# This works - just changes project name
focus past modify 43 "updated-project"

# This fails - can't modify times for duration-only sessions
focus past modify 43 "project" "14:00" "16:00"
❌ Cannot modify start time for duration-only sessions.
```

#### No-Change Detection
```bash
focus past modify 42 "same-project-name"
📋 Session 42 details:
   Project: same-project-name
   Start: 2025-09-26 14:00
   End: 2025-09-26 16:00
   Duration: 120 minutes

💡 No changes specified. Use 'focus past modify <id> <new_project>' to modify.
```

### Deleting Sessions
```bash
focus past delete 42
❌ Are you sure you want to delete session 42? (y/N): y
✅ Deleted session 42
```

**Warning**: Deletion is permanent and cannot be undone (unless you have backups).

## Backup Strategies

### Automated Daily Backups
Create a script for daily backups:

```bash
#!/bin/bash
# ~/bin/refocus-daily-backup.sh

BACKUP_DIR="$HOME/backups/refocus"
DATE=$(date +%Y%m%d)

mkdir -p "$BACKUP_DIR"
cd ~/.local/refocus

focus export "$BACKUP_DIR/refocus-backup-$DATE"

# Keep only last 30 days of backups
find "$BACKUP_DIR" -name "refocus-backup-*.sql" -mtime +30 -delete
find "$BACKUP_DIR" -name "refocus-backup-*.json" -mtime +30 -delete

echo "✅ Refocus backup completed: $BACKUP_DIR/refocus-backup-$DATE"
```

Add to crontab for automatic execution:
```bash
# Run daily at 11:59 PM
59 23 * * * ~/bin/refocus-daily-backup.sh
```

### Version Control Integration
Store backups in git for versioned history:

```bash
# Create backup repository
mkdir ~/refocus-backups
cd ~/refocus-backups
git init

# Add backup script
cat > backup.sh << 'EOF'
#!/bin/bash
cd ~/refocus-backups
focus export refocus-data
git add .
git commit -m "Backup $(date +%Y-%m-%d)"
EOF

chmod +x backup.sh

# Run weekly
./backup.sh
```

### Pre-Migration Backups
Always backup before major changes:

```bash
# Before major system updates
focus export "backup-before-system-update-$(date +%Y%m%d)"

# Before installing new versions
focus export "backup-before-refocus-update-$(date +%Y%m%d)"

# Before data manipulation
focus export "backup-before-cleanup-$(date +%Y%m%d)"
```

## Data Analysis

### Export for Analysis
```bash
# Export data for external analysis
focus export analysis-data

# Use jq to analyze JSON exports
jq '.data.sessions[] | select(.project == "coding")' analysis-data.json
```

### Session Queries
Use the JSON export with `jq` for complex queries:

```bash
# Sessions for specific project
jq '.data.sessions[] | select(.project == "coding")' backup.json

# Sessions by duration
jq '.data.sessions[] | select(.duration_seconds > 3600)' backup.json

# Recent sessions
jq '.data.sessions[] | select(.session_date == "2025-09-26")' backup.json

# Duration-only vs live sessions
jq '.data.sessions[] | select(.duration_only == true)' backup.json
```

### Database Queries
Direct SQLite queries on the database:

```bash
# Sessions by project
sqlite3 ~/.local/refocus/refocus.db "SELECT project, COUNT(*), SUM(duration_seconds)/60 as minutes FROM sessions GROUP BY project;"

# Recent activity
sqlite3 ~/.local/refocus/refocus.db "SELECT project, start_time, duration_seconds/60 as minutes FROM sessions WHERE start_time > date('now', '-7 days');"

# Duration statistics
sqlite3 ~/.local/refocus/refocus.db "SELECT AVG(duration_seconds)/60 as avg_minutes, MAX(duration_seconds)/60 as max_minutes FROM sessions;"
```

## Data Migration

### Between Systems
1. **Export on old system**:
   ```bash
   focus export migration-backup
   ```

2. **Install Refocus Shell on new system**:
   ```bash
   git clone https://github.com/PeGa/refocus-shell
   cd refocus-shell
   ./setup.sh install
   ```

3. **Import on new system**:
   ```bash
   focus import migration-backup.json
   ```

### Data Cleanup

#### Remove Old Sessions
```bash
# List very old sessions
focus past list 100 | tail -20

# Delete specific sessions
focus past delete 15
focus past delete 16
```

#### Project Consolidation
```bash
# Rename project across all sessions
sqlite3 ~/.local/refocus/refocus.db "UPDATE sessions SET project = 'web-dev' WHERE project = 'frontend';"

# Merge similar projects (requires manual review)
focus past list | grep -E "(coding|development|dev)"
```

## Data Recovery

### Automatic Backups
Refocus Shell automatically creates backups during imports:

```bash
ls ~/.local/refocus/refocus.db.backup.*
# refocus.db.backup.20250926_143022
# refocus.db.backup.20250925_091530
```

### Manual Recovery
```bash
# Restore from automatic backup
cp ~/.local/refocus/refocus.db.backup.20250926_143022 ~/.local/refocus/refocus.db

# Restore from export
focus import my-backup.json
```

### Database Corruption Recovery
```bash
# Check database integrity
sqlite3 ~/.local/refocus/refocus.db "PRAGMA integrity_check;"

# If corrupted, restore from backup
cp ~/.local/refocus/refocus.db.backup.* ~/.local/refocus/refocus.db

# Or reinitialize (loses all data)
focus reset
```

## Data Privacy and Security

### Local Storage
- All data stored locally in `~/.local/refocus/`
- No cloud sync or external connections
- No telemetry or data collection
- Full control over your data

### File Permissions
```bash
# Check data file permissions
ls -la ~/.local/refocus/
# Should be readable/writable by user only

# Fix permissions if needed
chmod 700 ~/.local/refocus/
chmod 600 ~/.local/refocus/refocus.db
```

### Secure Deletion
```bash
# Securely delete old backups
shred -u old-backup.sql
shred -u old-backup.json

# Or use secure delete tools
wipe old-backup.sql
srm old-backup.json
```

---

*Next: [Reports and Analytics](reports.md)*
