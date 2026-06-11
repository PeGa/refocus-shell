#!/usr/bin/env bash
# Refocus Shell - Configuration
# Override defaults via REFOCUS_* env vars or ~/.local/refocus/.env

# Load user overrides first — they feed into the assignments below
_env="$(dirname "${REFOCUS_DB_PATH:-$HOME/.local/refocus/refocus.db}")/.env"
[[ -f "$_env" ]] && source "$_env"
unset _env

DB_PATH="${REFOCUS_DB_PATH:-$HOME/.local/refocus/refocus.db}"
NUDGE_INTERVAL="${REFOCUS_NUDGE_INTERVAL:-10}"
MAX_PROJECT_LENGTH="${REFOCUS_MAX_PROJECT_LENGTH:-100}"
DATE_FORMAT="${REFOCUS_DATE_FORMAT:-%Y-%m-%d}"
DATE_SHORT_FORMAT="${REFOCUS_DATE_SHORT_FORMAT:-%Y-%m-%d %H:%M}"
REPORT_LIMIT="${REFOCUS_REPORT_LIMIT:-20}"

export DB_PATH NUDGE_INTERVAL MAX_PROJECT_LENGTH DATE_FORMAT DATE_SHORT_FORMAT REPORT_LIMIT
