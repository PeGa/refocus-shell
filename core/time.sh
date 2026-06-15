#!/usr/bin/env bash
# Refocus Shell - Time and duration utilities (domain helpers)
#
# Pure functions: string in, string or integer out.
# No SQL, no cron, no state. No side effects.
# Sourced by any layer that needs time representation — not routable as a command.

# --- Portable date layer (GNU + BSD/macOS) --------------------------------
# The rest of the codebase only ever asks for a few well-defined conversions.
# GNU `date` (Linux) and BSD `date` (macOS) speak different flags, so every
# date(1) call routes through the helpers below, which branch once on platform.
# GNU coreutils `gdate`, if installed on macOS, is preferred transparently.

if command -v gdate >/dev/null 2>&1; then
    _date() { gdate "$@"; }
else
    _date() { date "$@"; }
fi

# GNU `date` understands --version; BSD errors out. Detect once.
if _date --version >/dev/null 2>&1; then
    _DATE_IS_GNU=1
else
    _DATE_IS_GNU=0
fi

_epoch_to_iso() {
    # epoch seconds -> ISO-8601 timestamp
    local e="$1"
    if [[ "$_DATE_IS_GNU" == "1" ]]; then
        _date --date="@$e" -Iseconds
    else
        _date -r "$e" -Iseconds
    fi
}

_epoch_format() {
    # epoch seconds + strftime format -> formatted string
    local e="$1" fmt="$2"
    if [[ "$_DATE_IS_GNU" == "1" ]]; then
        _date --date="@$e" +"$fmt"
    else
        _date -r "$e" +"$fmt"
    fi
}

_iso_to_epoch() {
    # stored ISO (-Iseconds output) or normalised "YYYY-MM-DD HH:MM" -> epoch.
    # Returns non-zero on failure so callers' `|| ...` guards still fire.
    local s="$1"
    if [[ "$_DATE_IS_GNU" == "1" ]]; then
        _date --date="$s" +%s
        return
    fi
    # BSD strptime rejects the colon in a "-03:00" offset; strip it.
    local norm="${s}"
    if [[ "$norm" =~ ^(.*[T\ ][0-9]{2}:[0-9]{2}:[0-9]{2})([+-][0-9]{2}):([0-9]{2})$ ]]; then
        norm="${BASH_REMATCH[1]}${BASH_REMATCH[2]}${BASH_REMATCH[3]}"
    fi
    _date -j -f "%Y-%m-%dT%H:%M:%S%z" "$norm" +%s 2>/dev/null \
        || _date -j -f "%Y-%m-%d %H:%M" "$s" +%s 2>/dev/null
}

_ts_format() {
    # stored ISO -> formatted for display. Non-zero if the timestamp won't parse.
    local iso="$1" fmt="$2" e
    e=$(_iso_to_epoch "$iso") || return 1
    _epoch_format "$e" "$fmt"
}

_iso_days_ago() {
    # n days ago at 00:00 -> ISO (n=0 => today 00:00)
    local n="$1"
    if [[ "$_DATE_IS_GNU" == "1" ]]; then
        _date --date="$n days ago 00:00" -Iseconds
    else
        _date -v-"${n}"d -v0H -v0M -v0S -Iseconds
    fi
}

_iso_month_start() {
    # 00:00 on the 1st of the current month -> ISO
    if [[ "$_DATE_IS_GNU" == "1" ]]; then
        _date --date="$(_date +%Y-%m-01) 00:00" -Iseconds
    else
        _date -v1d -v0H -v0M -v0S -Iseconds
    fi
}

_parse_date_to_fmt() {
    # `past add --date` value (today | YYYY/MM/DD | YYYY-MM-DD) -> formatted.
    # Non-zero on unparseable input.
    local str="$1" fmt="$2"
    if [[ "$_DATE_IS_GNU" == "1" ]]; then
        _date --date="$str" +"$fmt"
        return
    fi
    if [[ "$str" == "today" ]]; then
        _date +"$fmt"
        return
    fi
    local norm="${str//\//-}"
    _date -j -f "%Y-%m-%d" "$norm" +"$fmt" 2>/dev/null
}
# --------------------------------------------------------------------------

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
    local epoch
    epoch=$(_iso_to_epoch "$raw") || {
        echo "❌ Cannot parse time: $1" >&2
        return 1
    }
    _epoch_to_iso "$epoch"
}
