#!/usr/bin/env bash
cat << 'HELP'
Refocus Shell — terminal-first focus tracker

Usage: focus <command> [args]

  on [project]           Start a session (offers to continue last if no project given)
  off                    Stop session and capture notes
  pause                  Pause current session (silent — nudge reminds you)
  continue               Resume paused session
  status                 Current state

  past list [n]          Last n sessions (default 20)
  past add <p> <s> <e>   Add past session with timestamps
  past add <p> --duration Xh [--date YYYY/MM/DD]
  past modify <id> ...   Edit a session
  past delete <id>       Delete a session

  report today|week|month|custom <days>

  nudge status           Show nudging state and cron entry
  nudge test             Test notification and nudge script

  config show            Effective configuration
  config set <KEY> <val> Set a user override
  config unset <KEY>     Remove override (revert to default)

  export [basename]      Export to .sql and .json
  import <file>          Import from .sql or .json

  enable                 Enable Refocus (installs nudge cron)
  disable                Disable Refocus (removes nudge cron)
  init                   Initialise DB
  reset                  Wipe all data (leaves Refocus disabled)

Time formats: YYYY/MM/DD-HH:MM  HH:MM  "yesterday 14:00"  "2 hours ago"
Duration:     1h30m  2h  45m

Note: nudging is always active while Refocus is enabled.
      'focus disable' is the only way to silence it.
HELP
