#!/usr/bin/env bash
# Refocus Shell - Time and duration utilities (domain helpers)
#
# Pure functions: string in, string or integer out.
# No SQL, no cron, no state. No side effects.
# Sourced by any layer that needs time representation — not routable as a command.

fmt_duration() {
    # seconds -> human string: "2h 15m" or "45m"
    local secs="$1"
    local h=$(( secs / 3600 )) m=$(( (secs % 3600) / 60 ))
    if [[ $h -gt 0 ]]; then echo "${h}h ${m}m"; else echo "${m}m"; fi
}

parse_duration() {
    # XhYm | Xh | Xm -> seconds, or exit 1 on bad input
    # Caller supplies the raw string; this function owns the regex.
    local raw="$1"
    if [[ "$raw" =~ ^([0-9]+)h([0-9]+)m$ ]]; then
        echo $(( BASH_REMATCH[1]*3600 + BASH_REMATCH[2]*60 ))
    elif [[ "$raw" =~ ^([0-9]+)h$ ]]; then
        echo $(( BASH_REMATCH[1]*3600 ))
    elif [[ "$raw" =~ ^([0-9]+)m$ ]]; then
        echo $(( BASH_REMATCH[1]*60 ))
    else
        echo "❌ Invalid duration: $raw (use 1h30m, 2h, 45m)" >&2
        return 1
    fi
}

parse_time() {
    # YYYY/MM/DD-HH:MM | any date(1)-compatible string -> ISO-8601 timestamp
    # or exit 1 on failure.
    local raw="$1"
    # Normalise our preferred YYYY/MM/DD-HH:MM format to something date(1) accepts
    if [[ "$raw" =~ ^([0-9]{4})/([0-9]{2})/([0-9]{2})-([0-9]{2}:[0-9]{2})$ ]]; then
        raw="${BASH_REMATCH[1]}-${BASH_REMATCH[2]}-${BASH_REMATCH[3]} ${BASH_REMATCH[4]}"
    fi
    date --date="$raw" -Iseconds 2>/dev/null || {
        echo "❌ Cannot parse time: $1" >&2
        return 1
    }
}
