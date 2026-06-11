#!/usr/bin/env bash
cat << 'EOF'
Refocus Shell — terminal-first focus tracker

Usage: focus <command> [args]

  on [project]           Start a session (resumes last if no project given)
  off                    Stop session, capture notes
  pause                  Pause with notes
  continue               Resume paused session
  status                 Current state

  past list [n]          Last n sessions (default 20)
  past add <p> <s> <e>   Add past session with timestamps
  past add <p> --duration Xh [--date YYYY/MM/DD]
  past modify <id> ...   Edit a session
  past delete <id>       Delete a session

  report today|week|month|custom <days>

  nudge enable|disable|status
  describe add <p> <desc>
  describe show|remove|list

  enable / disable       Toggle focus tracking
  init                   Initialise DB
  reset                  Wipe all data

Time formats: YYYY/MM/DD-HH:MM  HH:MM  "yesterday 14:00"  "2 hours ago"
EOF
