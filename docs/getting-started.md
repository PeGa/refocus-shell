# Getting Started with Refocus Shell

This guide will get you up and running with Refocus Shell in minutes.

## Prerequisites

Before starting, ensure you have the required dependencies installed:

- **sqlite3** - Database for storing focus sessions
- **notify-send** - Desktop notifications (libnotify-bin on Debian/Ubuntu)
- **jq** - JSON processing for import/export features

The installer will automatically detect and install missing dependencies.

## Quick Installation

```bash
# Clone and install
git clone https://github.com/PeGa/refocus-shell
cd refocus-shell
./setup.sh install

# Restart your shell or source your profile
source ~/.bashrc
```

## Your First Focus Session

Let's start your first focus session:

```bash
# Start focusing on a project
focus on "my-first-project"

# Check your status
focus status

# Work for a while... you'll get gentle nudges every 10 minutes

# Stop your session and add notes
focus off
```

When you run `focus off`, you'll be prompted to add notes about what you accomplished:

```
📝 What did you accomplish during this focus session? 
(Press Enter to skip, or type a brief description): 
```

## Core Workflow

The basic Refocus Shell workflow is simple:

### 1. Start a Session
```bash
focus on "project-name"
```

### 2. Work and Get Nudged
- You'll see `⏳ [project-name]` in your prompt
- Every 10 minutes, you'll get a gentle reminder
- The prompt works across all terminals

### 3. Check Progress Anytime
```bash
focus status
```

Shows:
- Current project
- Time elapsed
- Total time on this project
- Session notes (if any)

### 4. End Your Session
```bash
focus off
```

Prompts you to add notes about what you accomplished.

## Essential Commands

Here are the commands you'll use daily:

```bash
# Session management
focus on "project"      # Start focusing
focus off               # Stop and add notes
focus status            # Check current status
focus pause             # Pause (saves context notes)
focus continue          # Resume paused session

# Quick history
focus past list 5       # Show last 5 sessions
focus report today      # Today's focus summary

# System control
focus enable            # Enable focus tracking
focus disable           # Disable focus tracking
focus help              # Show all commands
```

## Understanding Nudges

Refocus Shell has three types of notifications:

### 1. Active Session Nudges
When you're focusing: **"You're focusing on: project (20m elapsed)"**
- Appears every 10 minutes during active sessions
- Helps you stay aware of time passing
- Shows rounded time (10m, 20m, 30m, etc.)

### 2. Idle Notifications  
When you're not focusing: **"You're not focusing on any project"**
- Gentle reminder every 10 minutes when idle
- Only appears if focus tracking is enabled
- Stops when you start a session or disable tracking

### 3. Paused Session Reminders
When you have a paused session: **"Session paused: project - your notes"**
- Reminds you about paused work
- Includes the context notes you added when pausing

### Managing Nudges

```bash
# Control nudging
focus nudge enable      # Enable nudges (default)
focus nudge disable     # Disable nudges
focus nudge status      # Check nudge status
focus nudge test        # Test your notifications

# System-wide control
focus disable           # Disable all focus tracking
focus enable            # Re-enable focus tracking
```

## Smart Continuation

Refocus Shell remembers your last project:

```bash
# Start working on "coding"
focus on "coding"
focus off

# Later, just run focus on without a project name
focus on
# Automatically continues "coding"
```

This is perfect for resuming work after breaks or across different terminal sessions.

## Prompt Integration

The `⏳ [project]` prompt indicator works across all terminals:

- Start a focus session in one terminal
- Open a new terminal → see the focus indicator
- Works in tmux, screen, and multiple terminal windows
- Updates automatically when you start/stop sessions

## Session Notes

Session notes help you remember what you accomplished:

### Adding Notes When Stopping
```bash
focus off
# Prompts: "What did you accomplish during this focus session?"
```

### Adding Notes to Past Sessions
```bash
focus notes add "project-name"
# Prompts for notes about your most recent session for that project
```

### Viewing Notes
```bash
focus past list        # Shows sessions with notes
focus report today     # Includes all notes in daily report
```

## Pause and Resume

Perfect for stepping away without losing context:

```bash
# Pause your session
focus pause
# Prompts: "Focus paused. Please add notes for future recalling:"

# Resume later
focus continue
# Asks: "Include previous elapsed time? (y/N)"
```

**When to pause:**
- Short breaks (coffee, bathroom, phone call)
- Interruptions that won't last long
- Switching contexts temporarily

**When to stop (`focus off`):**
- End of work session
- Switching to a different project
- Long breaks or end of day

## Verification

Verify your installation is working:

```bash
# Check the command works
focus help

# Check database was created
ls ~/.local/refocus/refocus.db

# Test notifications
focus nudge test

# Start a test session
focus on "test"
focus status
focus off
```

## Next Steps

Now that you're set up:

1. **[Session Management](sessions.md)** - Learn advanced session techniques
2. **[Configuration](configuration.md)** - Customize your experience  
3. **[Reports](reports.md)** - Generate focus analytics
4. **[Data Management](data.md)** - Backup and manage your data

## Quick Tips

- **Project names**: Use descriptive, consistent names like `"web-development"` or `"client-work"`
- **Notes**: Be specific about what you accomplished for future reference
- **Nudges**: Start with default settings, adjust later if needed
- **Multiple projects**: You can only focus on one project at a time (this is intentional)
- **Breaks**: Use `focus pause` for short breaks, `focus off` when switching projects

---

*Next: [Session Management Guide](sessions.md)*
