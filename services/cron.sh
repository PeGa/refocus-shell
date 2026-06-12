#!/usr/bin/env bash
# Refocus Shell - Cron management
#
# NUDGE_BIN is resolved at call time from REFOCUS_ROOT, not hardcoded.
# The cron entry embeds REFOCUS_ROOT so focus-nudge resolves config/db
# correctly under cron stripped environment (no HOME, no PATH).

_cron_nudge_bin() {
    echo "${REFOCUS_ROOT:-$HOME/.local/refocus}/focus-nudge"
}

_cron_validate_interval() {
    local iv="$1"
    if ! [[ "$iv" =~ ^[0-9]+$ ]]; then
        echo "NUDGE_INTERVAL must be numeric (got: $iv)" >&2; return 1
    fi
    if [[ $iv -lt 1 || $iv -gt 60 ]]; then
        echo "NUDGE_INTERVAL must be 1-60 (got: $iv)" >&2; return 1
    fi
}

cron_install() {
    local interval="${NUDGE_INTERVAL:-10}"
    _cron_validate_interval "$interval" || return 1

    local nudge_bin; nudge_bin=$(_cron_nudge_bin)
    local root="${REFOCUS_ROOT:-$HOME/.local/refocus}"

    local start_min; start_min=$(date +%M)
    local ones=$(( 10#$start_min % interval ))
    local pattern="${ones}-59/${interval}"

    local entry="$pattern * * * * REFOCUS_ROOT=$root DISPLAY=${DISPLAY:-} WAYLAND_DISPLAY=${WAYLAND_DISPLAY:-} DBUS_SESSION_BUS_ADDRESS=${DBUS_SESSION_BUS_ADDRESS:-} $nudge_bin"

    local tmp; tmp=$(mktemp)
    crontab -l 2>/dev/null | grep -vF "$nudge_bin" > "$tmp" || true
    echo "$entry" >> "$tmp"
    crontab "$tmp"
    rm -f "$tmp"
}

cron_remove() {
    local nudge_bin; nudge_bin=$(_cron_nudge_bin)
    local tmp; tmp=$(mktemp)
    crontab -l 2>/dev/null | grep -vF "$nudge_bin" > "$tmp" || true
    crontab "$tmp"
    rm -f "$tmp"
}
