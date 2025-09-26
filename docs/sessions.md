# Session Management

This guide covers everything about managing focus sessions in Refocus Shell.

## Session Lifecycle

A focus session has several states and transitions:

```
Inactive → Active → Paused → Active → Completed
    ↓        ↓        ↓        ↓         ↓
  No work   Working  Break   Working   Notes
```

## Starting Sessions

### Basic Session Start
```bash
focus on "project-name"
```

This will:
- Mark you as actively focusing on the project
- Start the session timer
- Update your prompt to show `⏳ [project-name]`
- Begin nudge notifications every 10 minutes

### Smart Continuation
```bash
# Continue your last project
focus on

# Or explicitly continue a specific project
focus on "last-project"
```

Refocus Shell remembers your last session and makes it easy to resume.

### Session with Description
```bash
focus on "coding" "Working on authentication system"
```

The description is stored with the session and appears in reports.

### Project Naming Best Practices

**Good project names:**
- `"web-development"`
- `"client-alpha"`
- `"bug-fixes"`
- `"documentation"`
- `"meeting-prep"`

**Avoid:**
- Special characters: `"project@#$"`
- Very long names: `"this-is-an-extremely-long-project-name-that-goes-on-forever"`
- Generic names: `"work"`, `"stuff"`, `"project"`

## Active Sessions

### Checking Status
```bash
focus status
```

Shows comprehensive information:
```
🎯 Currently focusing on: coding
⏱️  Session time: 25m
📝 Current session notes: debugging auth flow
📊 Total time on this project: 2h 15m
```

### Adding Notes During Session
```bash
focus notes add "coding"
```

Prompts you to add notes about what you're working on. These notes are:
- Associated with your most recent session for that project
- Included in reports
- Helpful for context when resuming work

### Session Continuation Rules

When you run `focus on` with a project name:

1. **If no session exists**: Creates a new session
2. **If recent session exists**: Continues that session
3. **If old session exists**: Asks whether to continue or start fresh

## Pausing and Resuming

### Pausing a Session
```bash
focus pause
```

This will:
- Stop the session timer
- Prompt for context notes: `"Focus paused. Please add notes for future recalling:"`
- Switch nudges to "paused" mode
- Keep the session data for resuming

**When to pause:**
- Short breaks (5-30 minutes)
- Interruptions (phone calls, meetings)
- Switching contexts temporarily
- Lunch breaks

### Resuming a Session
```bash
focus continue
```

This will:
- Show you the paused project and notes
- Ask: `"Include previous elapsed time? (y/N)"`
- Resume the session timer
- Restore active nudges

**Time inclusion options:**
- **Yes**: Continues counting from where you left off
- **No**: Starts fresh timer (useful if you were away for hours)

### Paused Session Information
```bash
focus status
```

When paused, shows:
```
⏸️  Session paused: coding
   Total session time: 25m
   Current session notes: debugging auth flow
   
📝 Pause notes: Going to lunch, working on OAuth integration
```

### Multiple Paused Sessions

Refocus Shell only tracks one session at a time:
- You cannot pause multiple projects simultaneously
- Starting a new session while paused will ask you to handle the paused session first
- This is intentional - it encourages focus on one thing at a time

## Stopping Sessions

### Normal Session End
```bash
focus off
```

This will:
- Stop the session timer
- Calculate total session time
- Prompt for session notes
- Save the completed session to history

### Session Notes Prompt
```
📝 What did you accomplish during this focus session? 
(Press Enter to skip, or type a brief description): 
```

**Good session notes:**
- `"Fixed login bug, updated tests"`
- `"Wrote project proposal, scheduled review meeting"`
- `"Researched React patterns, implemented authentication"`

### Stopping Paused Sessions

When you run `focus off` on a paused session:

```
⏸️  Stopping paused focus session on: coding

   Previous session time: 25m
   Pause duration: 15m
   Total session time: 40m

📝 Session notes so far: 
• debugging auth flow (session notes)
• Going to lunch, working on OAuth integration (pause notes)

Please enter current session notes (Enter to skip):
```

The final notes are combined chronologically with previous session and pause notes.

## Session History

### Viewing Recent Sessions
```bash
focus past list        # Last 20 sessions
focus past list 10     # Last 10 sessions
focus past list 50     # Last 50 sessions
```

Shows:
- Session ID
- Project name  
- Start/end times (or "N/A" for duration-only sessions)
- Duration
- Type (Live or Manual)
- Notes (if any)

### Session Types

**Live Sessions:**
- Created with `focus on`/`focus off`
- Have actual start/end timestamps
- Show exact times worked

**Manual Sessions:**
- Added with `focus past add`
- May have timestamps or duration-only
- Useful for reconstructing past work

### Adding Past Sessions

#### With Specific Times
```bash
focus past add "meeting" "2025/09/26-14:00" "2025/09/26-15:30"
```

#### Duration-Only Sessions
```bash
focus past add "planning" --duration "2h30m" --date "today"
focus past add "research" --duration "45m" --date "2025/09/25"
```

#### With Notes
```bash
focus past add "coding" "14:00" "16:00" --notes "Fixed critical authentication bug"
```

### Modifying Sessions

#### Change Project Name
```bash
focus past modify 42 "new-project-name"
```

#### Change Times (Live Sessions Only)
```bash
focus past modify 42 "project" "14:00" "16:00"
```

#### Duration-Only Sessions
For manual/duration-only sessions, you can only change the project name:
```bash
focus past modify 43 "updated-project-name"
```

### Deleting Sessions
```bash
focus past delete 42
```

Permanently removes the session from your history.

## Advanced Session Techniques

### Session Templates (Future Feature)
```bash
# Create reusable session templates
focus template create "daily-standup" "meetings" "15m"
focus template use "daily-standup"
```

### Batch Session Management (Future Feature)
```bash
# Import multiple sessions from CSV
focus past batch-add sessions.csv

# Export specific project sessions
focus export --project "coding"
```

### Session Analytics

View session patterns:
```bash
focus report today     # Today's sessions
focus report week      # This week's focus
focus report custom 30 # Last 30 days
```

## Session State Management

### Checking Session State
```bash
focus status
```

Possible states:
- **Inactive**: No current session
- **Active**: Currently focusing on a project
- **Paused**: Session temporarily stopped

### State Transitions

```bash
# Inactive → Active
focus on "project"

# Active → Paused
focus pause

# Paused → Active
focus continue

# Active/Paused → Inactive
focus off
```

### Preventing State Conflicts

Refocus Shell prevents conflicting states:

```bash
# Can't start new session while paused
focus on "different-project"
# Error: Cannot start new focus session while one is paused.

# Must handle paused session first
focus continue  # Resume
# OR
focus off      # Complete and add notes
```

## Session Data

### What's Stored

Each session stores:
- **Project name**: The project you're focusing on
- **Start time**: When the session began (live sessions)
- **End time**: When the session ended (live sessions)
- **Duration**: Total time spent (all sessions)
- **Notes**: What you accomplished
- **Type**: Live or Manual entry
- **Session date**: Date for duration-only sessions

### Session Notes Management

#### Adding Notes to Existing Sessions
```bash
focus notes add "project-name"
```

This adds notes to your most recent session for that project.

#### Viewing Session Notes
```bash
focus past list 10     # Shows sessions with notes
focus report today     # Includes all session notes
```

## Troubleshooting Sessions

### Can't Start Session
```bash
# Check if focus is disabled
focus status

# Enable if needed
focus enable

# Check for paused sessions
focus status
```

### Lost Session Data
```bash
# Check database
ls ~/.local/refocus/refocus.db

# Reinitialize if needed
focus init

# Check session history
focus past list
```

### Prompt Not Updating
```bash
# Manually update prompt
focus-update-prompt

# Check shell integration
echo $PS1

# Restart shell
exec bash
```

### Time Tracking Issues
```bash
# Check system time
date

# Verify session timestamps
focus past list 5

# Reset if corrupted
focus reset  # WARNING: Deletes all data
```

---

*Next: [Data Management](data.md)*
