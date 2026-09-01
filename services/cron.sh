#!/usr/bin/env bash
# Refocus Shell - Cron management
#
# NUDGE_BIN is resolved at call time from REFOCUS_ROOT, not hardcoded.
# The cron entry embeds REFOCUS_ROOT so focus-nudge resolves config/db
# correctly under cron stripped environment (no HOME, no PATH).

_cron_nudge_bin() {
    echo "${REFOCUS_ROOT:-$HOME/.local/refocus}/focus-nudge"
}

_cron_checkin_bin() {
    echo "${REFOCUS_ROOT:-$HOME/.local/refocus}/focus-checkin"
}

_cron_env_prefix() {
    # cron strips the environment; the payloads need enough of it back to
    # reach the desktop session. Two rules, both learned from #35:
    #
    #   - XDG_RUNTIME_DIR goes in. WAYLAND_DISPLAY is a socket NAME resolved
    #     against it, so an entry carrying "WAYLAND_DISPLAY=wayland-0" and
    #     nothing else points Qt at a compositor it cannot locate — kdialog
    #     aborts on SIGABRT and dumps core instead of failing politely.
    #   - Empty variables are omitted entirely. "DISPLAY=" is not a harmless
    #     no-op: it names a display server called "", which suppresses every
    #     fallback the tool would otherwise have.
    local root="${REFOCUS_ROOT:-$HOME/.local/refocus}"
    local prefix="REFOCUS_ROOT=$root" v
    for v in DISPLAY WAYLAND_DISPLAY XDG_RUNTIME_DIR DBUS_SESSION_BUS_ADDRESS; do
        [[ -n "${!v:-}" ]] && prefix="$prefix $v=${!v}"
    done
    printf '%s' "$prefix"
}

_cron_validate_interval() {
    local iv="$1"
    if ! [[ "$iv" =~ ^[0-9]+$ ]]; then
        echo "NUDGE_INTERVAL must be numeric (got: $iv)" >&2; return 1
    fi
    # Force base-10: a leading zero ("090") is otherwise read as octal, and
    # "090"/"008" aren't valid octal digits — bash throws "value too great
    # for base" on the comparison below, and since that comparison is an
    # if-condition, set -e never sees it as a failure, so the bad value
    # silently sails through as "valid".
    iv=$((10#$iv))
    if [[ $iv -lt 1 || $iv -gt 60 ]]; then
        echo "NUDGE_INTERVAL must be 1-60 (got: $1)" >&2; return 1
    fi
}

_cron_validate_checkin_interval() {
    # Unlike the nudge, 0 (disabled) and intervals over an hour are both
    # legitimate here — a check-in every 10 minutes would be noise, and
    # "once a day" is a reasonable ask. Anything past 60 must be a whole
    # number of hours: the minute field can only step within one hour
    # (0-59), so a hop that doesn't divide evenly into hours needs the hour
    # field to step instead (see cron_checkin_install), and that only
    # produces an even cadence for whole-hour intervals.
    local iv="$1"
    if ! [[ "$iv" =~ ^[0-9]+$ ]]; then
        echo "CHECKIN_INTERVAL must be numeric (got: $iv)" >&2; return 1
    fi
    # Base-10, same reason as _cron_validate_interval above.
    iv=$((10#$iv))
    if [[ $iv -gt 1440 ]]; then
        echo "CHECKIN_INTERVAL must be 0-1440 (got: $1)" >&2; return 1
    fi
    if [[ $iv -gt 60 && $(( iv % 60 )) -ne 0 ]]; then
        echo "CHECKIN_INTERVAL over 60 must be a whole number of hours (got: $1)" >&2; return 1
    fi
}

cron_install() {
    local interval="${NUDGE_INTERVAL:-10}"
    _cron_validate_interval "$interval" || return 1
    interval=$((10#$interval))

    local nudge_bin; nudge_bin=$(_cron_nudge_bin)
    local env_prefix; env_prefix=$(_cron_env_prefix)

    local start_min; start_min=$(date +%M)
    local ones=$(( 10#$start_min % interval ))
    local pattern="${ones}-59/${interval}"

    local entry="$pattern * * * * $env_prefix $nudge_bin"

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

cron_checkin_install() {
    local interval="${CHECKIN_INTERVAL:-60}"
    # 0 means "off" — make sure nothing's installed and stop, no error.
    [[ "$interval" == "0" ]] && { cron_checkin_remove; return 0; }
    _cron_validate_checkin_interval "$interval" || return 1
    interval=$((10#$interval))

    local checkin_bin; checkin_bin=$(_cron_checkin_bin)
    local env_prefix; env_prefix=$(_cron_env_prefix)
    local entry

    if [[ $interval -le 60 ]]; then
        # Same shape as the nudge: step within the minute field, offset from
        # whatever minute this was installed at.
        local start_min; start_min=$(date +%M)
        local ones=$(( 10#$start_min % interval ))
        entry="${ones}-59/${interval} * * * * $env_prefix $checkin_bin"
    else
        # A whole number of hours (enforced by the validator above): step
        # the hour field instead, fire once at the current minute within
        # each selected hour.
        local hours=$(( interval / 60 ))
        local start_hour; start_hour=$(date +%H)
        local start_min; start_min=$(date +%M)
        local hour_offset=$(( 10#$start_hour % hours ))
        entry="${start_min} ${hour_offset}-23/${hours} * * * $env_prefix $checkin_bin"
    fi

    local tmp; tmp=$(mktemp)
    crontab -l 2>/dev/null | grep -vF "$checkin_bin" > "$tmp" || true
    echo "$entry" >> "$tmp"
    crontab "$tmp"
    rm -f "$tmp"
}

cron_checkin_remove() {
    local checkin_bin; checkin_bin=$(_cron_checkin_bin)
    local tmp; tmp=$(mktemp)
    crontab -l 2>/dev/null | grep -vF "$checkin_bin" > "$tmp" || true
    crontab "$tmp"
    rm -f "$tmp"
}
