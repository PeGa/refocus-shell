# Troubleshooting Guide

This guide helps you diagnose and fix common issues with Refocus Shell.

## Installation Issues

### Command Not Found

#### Symptoms
```bash
$ focus on "test"
bash: focus: command not found
```

#### Diagnosis
```bash
# Check if focus is installed
which focus
ls -la ~/.local/refocus/

# Check shell integration
type focus
grep -r "refocus" ~/.bashrc ~/.profile
```

#### Solutions

**Option 1: Reinstall**
```bash
cd refocus-shell
./setup.sh install
source ~/.bashrc
```

**Option 2: Manual shell integration**
```bash
echo 'source ~/.local/refocus/lib/focus-function.sh' >> ~/.bashrc
source ~/.bashrc
```

**Option 3: Check PATH**
```bash
# If using manual installation
echo 'export PATH="$PATH:$HOME/.local/bin"' >> ~/.bashrc
source ~/.bashrc
```

### Dependencies Missing

#### Symptoms
```bash
$ focus on "test"  
./focus: line 25: sqlite3: command not found
```

#### Solutions
```bash
# Debian/Ubuntu
sudo apt-get install sqlite3 libnotify-bin jq

# Arch/Manjaro  
sudo pacman -S sqlite libnotify jq

# Fedora/RHEL
sudo dnf install sqlite libnotify jq

# openSUSE
sudo zypper install sqlite3 libnotify-tools jq
```

### Permission Errors

#### Symptoms
```bash
$ focus on "test"
mkdir: cannot create directory '/home/user/.local/refocus': Permission denied
```

#### Solutions
```bash
# Fix directory permissions
sudo chown -R $USER:$USER ~/.local
chmod 755 ~/.local

# Create directories manually
mkdir -p ~/.local/refocus
chmod 755 ~/.local/refocus
```

## Database Issues

### Database Not Found

#### Symptoms
```bash
$ focus status
❌ Database not found: /home/user/.local/refocus/refocus.db
```

#### Diagnosis
```bash
# Check database file
ls -la ~/.local/refocus/refocus.db

# Check directory
ls -la ~/.local/refocus/

# Check environment variable
echo $REFOCUS_DB
```

#### Solutions

**Initialize new database:**
```bash
focus init
```

**Restore from backup:**
```bash
# Check for automatic backups
ls ~/.local/refocus/refocus.db.backup.*

# Restore latest backup
cp ~/.local/refocus/refocus.db.backup.* ~/.local/refocus/refocus.db
```

**Import from export:**
```bash
focus import backup.json
```

### Database Corruption

#### Symptoms
```bash
$ focus status
Error: database disk image is malformed
```

#### Diagnosis
```bash
# Check database integrity
sqlite3 ~/.local/refocus/refocus.db "PRAGMA integrity_check;"

# Check file permissions
ls -la ~/.local/refocus/refocus.db

# Check disk space
df -h ~/.local/refocus/
```

#### Solutions

**Option 1: Restore from backup**
```bash
ls ~/.local/refocus/refocus.db.backup.*
cp ~/.local/refocus/refocus.db.backup.20250926_143022 ~/.local/refocus/refocus.db
```

**Option 2: Recover data**
```bash
# Try to dump recoverable data
sqlite3 ~/.local/refocus/refocus.db ".dump" > recovered_data.sql

# Create new database
rm ~/.local/refocus/refocus.db
focus init

# Import recovered data
sqlite3 ~/.local/refocus/refocus.db < recovered_data.sql
```

**Option 3: Nuclear option (loses all data)**
```bash
focus reset
```

### Migration Errors

#### Symptoms
```bash
$ focus on "test"
Error: in prepare, no such table: sessions
```

#### Solutions
```bash
# Force migration
focus init

# Or reset and restore
focus export backup  # If possible
focus reset
focus import backup.json
```

## Notification Issues

### Nudges Not Appearing

#### Symptoms
- No desktop notifications during focus sessions
- No idle reminders when not focusing

#### Diagnosis
```bash
# Check nudge status
focus nudge status

# Test notification system
focus nudge test

# Check if notifications are enabled
notify-send "Test" "This should appear"

# Check desktop environment
echo $XDG_CURRENT_DESKTOP
echo $DISPLAY
echo $WAYLAND_DISPLAY
```

#### Solutions

**Enable nudges:**
```bash
focus nudge enable
```

**Fix notification dependencies:**
```bash
# Install notification tools
sudo apt-get install libnotify-bin

# Test manual notification
notify-send "Test" "Manual test"
```

**Check cron jobs:**
```bash
# View active cron jobs
crontab -l

# Look for refocus entries
crontab -l | grep focus-nudge
```

**Debug cron environment:**
```bash
# Enable verbose logging
export REFOCUS_VERBOSE=true

# Check logs
journalctl -f | grep focus-nudge
tail -f /var/log/syslog | grep focus-nudge
```

### Wall Messages Instead of Desktop Notifications

#### Symptoms
```bash
Broadcast message from user@host (Thu Sep 26 14:20:02 2025):
FOCUS NUDGE: Focus Reminder - You're focusing on: project (10m elapsed)
```

#### Cause
Desktop notifications are failing, falling back to `wall` command.

#### Solutions

**Fix display environment for cron:**
```bash
# Check current environment
env | grep -E "(DISPLAY|WAYLAND|DBUS)"

# The installer should handle this automatically
./setup.sh install
```

**Manual cron environment fix:**
```bash
# Edit crontab
crontab -e

# Ensure the entry includes environment variables:
DISPLAY=:0
WAYLAND_DISPLAY=wayland-0
DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus
*/10 * * * * /home/user/.local/refocus/focus-nudge
```

### Duplicate Notifications

#### Symptoms
- Both desktop notifications AND wall messages
- Multiple notifications for the same event

#### Solutions
```bash
# Check for multiple cron entries
crontab -l | grep focus-nudge

# Remove duplicate entries
crontab -e  # Remove extra lines

# Check for background processes
ps aux | grep focus-nudge
```

## Prompt Issues

### Prompt Not Updating

#### Symptoms
- `⏳ [project]` doesn't appear in prompt
- Prompt shows wrong project
- Prompt doesn't clear after `focus off`

#### Diagnosis
```bash
# Check shell function
type focus
type focus-update-prompt

# Check original prompt backup
echo $REFOCUS_ORIGINAL_PS1

# Check current prompt
echo $PS1
```

#### Solutions

**Manual prompt update:**
```bash
focus-update-prompt
```

**Reinstall shell integration:**
```bash
./setup.sh install
source ~/.bashrc
```

**Manual prompt restoration:**
```bash
focus-restore-prompt
export PS1="$REFOCUS_ORIGINAL_PS1"
```

### Prompt Appears in Wrong Terminals

#### Symptoms
- Prompt shows in terminals where focus wasn't started
- Inconsistent prompt across terminals

#### Explanation
This is normal behavior - the prompt indicator works across all terminals to show your current focus state.

#### Disable if unwanted
```bash
# Remove prompt integration
export REFOCUS_PROMPT_FORMAT=""

# Or disable via configuration
focus config set PROMPT_FORMAT ""
```

## Session Issues

### Can't Start Session

#### Symptoms
```bash
$ focus on "project"
❌ Cannot start new focus session while one is paused.
```

#### Solutions
```bash
# Check current status
focus status

# Handle paused session
focus continue  # Resume paused session
# OR
focus off      # Complete paused session
```

### Lost Session Data

#### Symptoms
- Sessions missing from `focus past list`
- Incorrect session times
- Missing notes

#### Diagnosis
```bash
# Check recent sessions
focus past list 20
focus past list -n 50  # Alternative flag format

# Check database directly
sqlite3 ~/.local/refocus/refocus.db "SELECT * FROM sessions ORDER BY id DESC LIMIT 10;"

# Check for data corruption
sqlite3 ~/.local/refocus/refocus.db "PRAGMA integrity_check;"
```

#### Solutions
```bash
# Restore from backup
focus import backup.json

# Or check automatic backups
ls ~/.local/refocus/refocus.db.backup.*
cp ~/.local/refocus/refocus.db.backup.* ~/.local/refocus/refocus.db
```

### Time Calculation Errors

#### Symptoms
- Negative session durations
- Impossibly long sessions
- Wrong elapsed time in nudges

#### Diagnosis
```bash
# Check system time
date

# Check session data
focus past list 5
focus past list -n 10  # Alternative flag format

# Check for invalid sessions
sqlite3 ~/.local/refocus/refocus.db "SELECT * FROM sessions WHERE duration_seconds < 0 OR duration_seconds > 86400;"
```

#### Solutions
```bash
# Fix system time
sudo ntpdate -s time.nist.gov

# Delete invalid sessions
focus past delete <session_id>

# Or modify session times
focus past modify <session_id> "project" "14:00" "16:00"
```

## Performance Issues

### Slow Commands

#### Symptoms
- `focus status` takes several seconds
- `focus past list` is very slow
- Reports take a long time to generate

#### Diagnosis
```bash
# Check database size
ls -lh ~/.local/refocus/refocus.db

# Count sessions
sqlite3 ~/.local/refocus/refocus.db "SELECT COUNT(*) FROM sessions;"

# Check for database issues
sqlite3 ~/.local/refocus/refocus.db "PRAGMA integrity_check;"
```

#### Solutions
```bash
# Optimize database
sqlite3 ~/.local/refocus/refocus.db "VACUUM;"
sqlite3 ~/.local/refocus/refocus.db "ANALYZE;"

# Clean up old sessions
focus past list 100
focus past list -n 200  # Alternative flag format
# Delete very old sessions manually:
focus past delete <old_session_id>
```

### High Memory Usage

#### Symptoms
- High memory usage during report generation
- System becomes slow when using Refocus Shell

#### Solutions
```bash
# Generate smaller reports
focus report custom 7   # Instead of custom 365

# Use database queries for large datasets
sqlite3 ~/.local/refocus/refocus.db "SELECT project, COUNT(*) FROM sessions GROUP BY project;"
```

## Debug Mode

### Enable Debug Output

```bash
# Enable verbose output
export REFOCUS_VERBOSE=true

# Run commands with debug info
focus on "debug-test"
focus status
focus off
```

### Debug Information

Verbose mode shows:
- Database queries being executed
- File operations
- Cron job management
- Notification attempts
- Prompt updates

### Log Analysis

#### System Logs
```bash
# Check system logs for refocus entries
journalctl -u cron | grep focus-nudge
tail -f /var/log/syslog | grep focus

# Check user logs
journalctl --user | grep focus
```

#### Application Logs
```bash
# Enable logging to file
export REFOCUS_LOG_FILE="$HOME/.local/refocus/debug.log"

# Run commands and check log
focus on "test"
cat ~/.local/refocus/debug.log
```

## Recovery Procedures

### Complete Reinstall

```bash
# Backup data first
focus export emergency-backup

# Uninstall completely
./setup.sh uninstall
rm -rf ~/.local/refocus
rm -rf ~/.config/refocus-shell

# Clean shell configuration
grep -v "refocus" ~/.bashrc > ~/.bashrc.new
mv ~/.bashrc.new ~/.bashrc

# Reinstall
./setup.sh install
source ~/.bashrc

# Restore data
focus import emergency-backup.json
```

### Emergency Data Recovery

#### From Automatic Backups
```bash
# Find backup files
find ~/.local/refocus -name "*.backup.*"

# Restore most recent
cp ~/.local/refocus/refocus.db.backup.* ~/.local/refocus/refocus.db
```

#### From Export Files
```bash
# Find export files
find ~ -name "refocus-export-*.json" -o -name "refocus-export-*.sql"

# Import most recent
focus import ~/path/to/export.json
```

#### From Git History (if versioned)
```bash
# If you've been versioning exports
cd ~/refocus-backups
git log --oneline
git checkout <commit> -- refocus-data.json
focus import refocus-data.json
```

## Getting Help

### Information Gathering

Before seeking help, gather this information:

```bash
# System information
uname -a
echo $SHELL
echo $XDG_CURRENT_DESKTOP

# Refocus Shell version and status
focus help
focus status
focus config show

# Installation details
ls -la ~/.local/refocus/
ls -la ~/.local/bin/focus

# Error reproduction
export REFOCUS_VERBOSE=true
# Run the problematic command
```

### Common Solutions Summary

1. **Installation issues**: Reinstall with `./setup.sh install`
2. **Database issues**: `focus init` or restore from backup
3. **Notification issues**: Check dependencies and cron jobs
4. **Prompt issues**: `focus-update-prompt` or reinstall
5. **Performance issues**: Database optimization with `VACUUM`
6. **Data loss**: Restore from automatic backups or exports

### When All Else Fails

```bash
# Nuclear option - complete reset (LOSES ALL DATA)
focus reset

# Start fresh
focus init
focus on "recovery-test"
focus status
```

---

*Next: [Advanced Usage](advanced.md)*
