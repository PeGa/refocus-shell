#!/usr/bin/env bash
# Refocus Shell - Period resolution (secondary adapter)
#
# Turns a cycle selector into the id window it names. `focus past cycles show`
# and `focus report cycle` take the same selector, so the rule for reading one
# lives here rather than being spelled twice — handlers are self-contained and
# cannot source each other.
#
# A period runs from the cycle break that opens it up to, but not including,
# the next one. Windows are id ranges rather than time ranges: ids record the
# order things were logged, while a duration-only row carries a date and no
# clock time, so a boundary falling inside its day would put it on both sides.
#
# Sourced by handlers; assumes env.sh, services/database.sh and core/text.sh
# are already in scope.

is_period_selector() {
    # <selector> -> 0 when it is even the right shape. Anything else is a
    # malformed argument, which is a usage error rather than a lookup miss.
    [[ "${1:-}" =~ ^-?[0-9]+$ ]]
}

get_period_window() {
    # <selector> -> "lo|hi" on stdout, where lo is inclusive and hi exclusive;
    # either may be empty for unbounded. Returns 1 and says why when the
    # selector names no period.
    #
    #   0 / empty   the current period — from the newest break onward
    #   -N          N periods back; N may equal the number of breaks, which
    #               reaches the span before the first one (there is no break
    #               opening it, so lo is unbounded)
    #   <id>        the period opened by that break
    local sel="${1:-0}" ids lo hi count
    ids=$(list_cycles "$(cycle_prefix)" | cut -d'|' -f1)
    count=0
    [[ -n "$ids" ]] && count=$(printf '%s\n' "$ids" | wc -l | tr -d ' ')

    if [[ "$sel" == -* || "$sel" == "0" ]]; then
        # 10# forces base-10: a leading-zero selector ("-08") would otherwise
        # be read as octal and abort with "value too great for base".
        local back=$(( 10#${sel#-} ))
        if [[ "$back" -gt "$count" ]]; then
            echo "❌ Cycle not found: only $count cycle break(s) recorded." >&2
            return 1
        fi
        # Newest-first, so stepping back N is reading N rows down the list.
        lo=$(printf '%s\n' "$ids" | sed -n "$(( back + 1 ))p")
        hi=""
        [[ "$back" -gt 0 ]] && hi=$(printf '%s\n' "$ids" | sed -n "${back}p")
    else
        # A positive selector is a row id, and it has to be a break — pointing
        # it at an ordinary session would silently report someone else's window.
        if ! printf '%s\n' "$ids" | grep -qx "$sel"; then
            echo "❌ Cycle not found: $sel is not a cycle break." >&2
            return 1
        fi
        lo="$sel"
        # The next break above it, if any, closes the period.
        hi=$(printf '%s\n' "$ids" | awk -v want="$sel" '$1 > want' | sort -n | head -1)
    fi
    printf '%s|%s' "$lo" "$hi"
}
