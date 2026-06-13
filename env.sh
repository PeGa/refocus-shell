#!/usr/bin/env bash
# Refocus Shell - Environment loader
# Loads defaults and .env overrides, exports them for all handlers.
# The 'focus config' command (lib/config.sh) reads/writes the .env this loads.
# Defaults can be overridden via REFOCUS_* env vars or the .env file
# co-located with the database.

# Bootstrap: resolve .env location from DB path before DB_PATH is set
_env_bootstrap="$(dirname "${REFOCUS_DB_PATH:-$HOME/.local/refocus/refocus.db}")/.env"
[[ -f "$_env_bootstrap" ]] && source "$_env_bootstrap"
unset _env_bootstrap

DB_PATH="${REFOCUS_DB_PATH:-$HOME/.local/refocus/refocus.db}"
ENV_FILE="$(dirname "$DB_PATH")/.env"    # single source of truth — used by lib/config.sh
NUDGE_INTERVAL="${REFOCUS_NUDGE_INTERVAL:-10}"
MAX_PROJECT_LENGTH="${REFOCUS_MAX_PROJECT_LENGTH:-100}"
DATE_FORMAT="${REFOCUS_DATE_FORMAT:-%Y-%m-%d}"
DATE_SHORT_FORMAT="${REFOCUS_DATE_SHORT_FORMAT:-%Y-%m-%d %H:%M}"
REPORT_LIMIT="${REFOCUS_REPORT_LIMIT:-20}"

export DB_PATH ENV_FILE NUDGE_INTERVAL MAX_PROJECT_LENGTH DATE_FORMAT DATE_SHORT_FORMAT REPORT_LIMIT
