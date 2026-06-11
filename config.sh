#!/usr/bin/env bash
# Refocus Shell - Configuration defaults
# Override any of these via ~/.local/refocus/.env

DB_PATH="${REFOCUS_DB_PATH:-$HOME/.local/refocus/refocus.db}"
NUDGE_INTERVAL="${REFOCUS_NUDGE_INTERVAL:-10}"
MAX_PROJECT_LENGTH="${REFOCUS_MAX_PROJECT_LENGTH:-100}"
DATE_FORMAT="${REFOCUS_DATE_FORMAT:-%Y-%m-%d}"
DATE_SHORT_FORMAT="${REFOCUS_DATE_SHORT_FORMAT:-%Y-%m-%d %H:%M}"
REPORT_LIMIT="${REFOCUS_REPORT_LIMIT:-20}"

# User overrides — sourced here so they apply everywhere config.sh is sourced
_env="$(dirname "$DB_PATH")/.env"
[[ -f "$_env" ]] && source "$_env"
unset _env

export DB_PATH NUDGE_INTERVAL MAX_PROJECT_LENGTH DATE_FORMAT DATE_SHORT_FORMAT REPORT_LIMIT
