#!/usr/bin/env bash
# Refocus Shell - Cron management

NUDGE_BIN="$HOME/.local/refocus/focus-nudge"
CRON_BACKUP="$HOME/.local/refocus/.cron_backup"

cron_install() {
    local project="$1" start_time="$2"
    local interval="${NUDGE_INTERVAL:-10}"

    local start_min
    start_min=$(date --date="$start_time" +%M 2>/dev/null || date +%M)
    local ones=$(( 10#$start_min % interval ))
    local pattern="${ones}-59/${interval}"
    local entry="$pattern * * * * DISPLAY=${DISPLAY:-} WAYLAND_DISPLAY=${WAYLAND_DISPLAY:-} DBUS_SESSION_BUS_ADDRESS=${DBUS_SESSION_BUS_ADDRESS:-} $NUDGE_BIN"

    # Backup everything except our own entry (skip if backup already exists)
    if [[ ! -f "$CRON_BACKUP" ]]; then
        crontab -l 2>/dev/null | grep -v "$NUDGE_BIN" > "$CRON_BACKUP" || true
    fi

    local tmp
    tmp=$(mktemp)
    cat "$CRON_BACKUP" > "$tmp"
    echo "$entry" >> "$tmp"
    crontab "$tmp"
    rm -f "$tmp"
}

cron_remove() {
    if [[ -f "$CRON_BACKUP" ]]; then
        crontab "$CRON_BACKUP"
        rm -f "$CRON_BACKUP"
    else
        # No backup — just strip our entry
        local tmp
        tmp=$(mktemp)
        crontab -l 2>/dev/null | grep -v "$NUDGE_BIN" > "$tmp" || true
        crontab "$tmp"
        rm -f "$tmp"
    fi
}
