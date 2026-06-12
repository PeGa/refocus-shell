#!/usr/bin/env bash
# Show help. Per-command help reads from docs/help/<cmd>.txt if it exists.

cmd="${1:-}"

if [[ -n "$cmd" ]]; then
    doc="$REFOCUS_ROOT/docs/help/${cmd}.txt"
    if [[ -f "$doc" ]]; then
        cat "$doc"
    else
        echo "No help available for: $cmd" >&2
        echo "Run focus help for the full command list." >&2
        exit 2
    fi
    exit 0
fi

cat << HELP
Refocus Shell -- terminal-first focus tracker

Usage: focus <command> [args]

Session lifecycle
  on [project]      Start a session (offers last project if none given)
  off               Stop session and capture notes
  pause             Pause current session (silent -- nudge reminds you)
  continue          Resume paused session carrying elapsed time forward
  status            Current state: focusing / paused / idle / disabled

Past sessions
  past list [n]                               Last n sessions (default 20)
  past add <project> <start> <end>            Add with timestamps
  past add <project> --duration Xh [--date YYYY/MM/DD]
  past modify <id> [project] [start] [end]    Edit timestamped session
  past modify <id> [project] [--duration Xh]  Edit duration-only session
  past delete <id>

Reports
  report today|week|month|custom <days>

Nudge diagnostics
  nudge status      Show enabled state and cron entry
  nudge test        Fire a test notification

Configuration
  config show
  config set <KEY> <value>
  config unset <KEY>

Import / Export
  export [basename]             Produces basename.sql + basename.json
  import <file.sql|file.json>   Overwrites data; state reset to idle+disabled

System
  enable            Enable Refocus and arm the nudge cron
  disable           Disable (requires no active or paused session)
  init              Initialise database
  reset             Wipe ALL data -- requires typing yes

Time formats   YYYY/MM/DD-HH:MM  HH:MM  yesterday 14:00  2 hours ago
Duration       1h30m  2h  45m

Run focus help <command> for per-command detail.

Note: nudging fires while Refocus is enabled, in all states.
      focus disable is the only way to silence it, and requires
      no active or paused session.
HELP
