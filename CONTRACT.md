# Refocus Shell - Development Contract

## Project Structure

```
refocus-shell/
├── focus.sh
├── config.sh
├── docs/
│   ├── varied-stuff-and-files.md
│   ├── CONTRACT.md
│   └── help/
│       ├── global.txt
│       ├── on.txt
│       ├── off.txt
│       ├── past.txt
│       ├── export.txt
│       ├── import.txt
│       ├── report.txt
│       ├── nudge.txt
│       └── cron-mgmt.txt
├── services/
│   ├── database.sh
│   ├── cron.sh
│   └── focus-function.sh
├── lib/
│   ├── on.sh
│   ├── off.sh
│   ├── past.sh
│   ├── export.sh
│   ├── import.sh
│   ├── report.sh
│   ├── nudge.sh
│   └── help.sh
├── data/
│   └── refocus.db
└── tests/   (empty for now)
```

## Development Approach

1. **Stub-First Development**: All files start as minimal stubs with 1-2 lines of comments
2. **Iterative Implementation**: You implement features incrementally, making decisions as you go
3. **AI Assistance**: I provide shortcuts, suggestions, and help with implementation details
4. **Keep It Simple**: Focus on core functionality first, avoid over-engineering
5. **Documentation-Driven**: Update docs as features are implemented, not before

## Core Principles

- **Simplicity over Complexity**: Start simple, add complexity only when needed
- **Working over Perfect**: Get it working first, then improve
- **User-Focused**: Built for neurodivergent users who need gentle focus management
- **Local-First**: All data stays local, no cloud dependencies
- **Terminal-Native**: CLI-first approach with optional GUI integrations

## File Responsibilities

- `focus.sh`: Main entry point, command dispatcher
- `config.sh`: Configuration and environment setup
- `services/`: Core system services (database, cron, shell integration)
- `lib/`: Command implementations
- `docs/help/`: Command-specific help text
- `data/`: SQLite database and local data storage
