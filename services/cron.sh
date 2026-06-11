#!/usr/bin/env bash
# Refocus Shell - Cron management
# Installs and removes the per-session nudge cron job.

NUDGE_BIN="$HOME/.local/refocus/focus-nudge"

cron_install() {
    local project="$1" start_time="$2"

    # Align nudge to session start: fire at :X1, :X1+10, :X1+20 ...
    local start_min
    start_min=$(date --date="$start_time" +%M 2>/dev/null || date +%M)
    local ones=$(( 10#$start_min % 10 ))
    local pattern="${ones}-59/10"

    local entry="$pattern * * * * DISPLAY=${DISPLAY:-} WAYLAND_DISPLAY=${WAYLAND_DISPLAY:-} DBUS_SESSION_BUS_ADDRESS=${DBUS_SESSION_BUS_ADDRESS:-} $NUDGE_BIN"

    local tmp
    tmp=$(mktemp)
    crontab -l 2>/dev/null | grep -v "$NUDGE_BIN" > "$tmp" || true
    echo "$entry" >> "$tmp"
    crontab "$tmp"
    rm -f "$tmp"
}

cron_remove() {
    local tmp
    tmp=$(mktemp)
    crontab -l 2>/dev/null | grep -v "$NUDGE_BIN" > "$tmp" || true
    crontab "$tmp"
    rm -f "$tmp"
}
