#!/usr/bin/env bash
# Refocus Shell - Text utilities (domain helpers)
#
# Pure functions: string in, string out. No SQL, no state, no side effects.
# Sourced by any layer that renders stored text — not routable as a command.
#
# Notes may contain newlines, but session reads are one pipe-separated line per
# row [PORT]. The adapter encodes newlines on the way out; these decode them
# again for display.

notes_decode() {
    # Encoded note -> raw text. printf %b makes a single left-to-right pass, so
    # an escaped backslash ("\\") can never be re-read as the start of an
    # escape — which is exactly what a naive two-pass sed would get wrong.
    printf '%b' "${1:-}"
}

notes_block() {
    # <first-prefix> <cont-prefix> <decoded-notes> -> the note printed one line
    # at a time, so a multi-line note cannot wreck a listing's alignment.
    # Takes raw text: callers that read from the adapter run it through
    # notes_decode first. Decoding here too would turn a backslash-n the user
    # actually typed into a line break.
    local first="$1" cont="$2" notes="${3:-}" n=0 line
    # Strip ALL trailing newlines before re-adding exactly one below: without
    # this, a note that already ends in \n (or several) gets one more
    # appended, and the read loop sees an extra empty final "line" — a
    # spurious blank continuation row after the real content.
    while [[ "$notes" == *$'\n' ]]; do notes="${notes%$'\n'}"; done
    while IFS= read -r line; do
        if [[ $n -eq 0 ]]; then
            printf '%s%s\n' "$first" "$line"
        else
            printf '%s%s\n' "$cont" "$line"
        fi
        n=$(( n + 1 ))
    done < <(printf '%s\n' "$notes")
}

notes_merge_trail() {
    # <note> <orig-start> <orig-stop> <new-start> <new-stop> -> the note with
    # the timestamps a merge is about to destroy appended to it [#36].
    #
    # Folding a second session into an existing row turns it duration-only, so
    # its start/end are dropped. Recording them in the note keeps the merge
    # non-lossy. Empty arguments are skipped, which is what makes the second
    # merge onto the same row read the way it should: the row is already
    # duration-only by then, so it has no "Original" pair left to contribute
    # and only the incoming session's pair gets appended.
    local note="${1:-}" ofrom="${2:-}" oto="${3:-}" nfrom="${4:-}" nto="${5:-}"
    local trail=""
    [[ -n "$ofrom" ]] && trail="${trail}Original start time: $ofrom"$'\n'
    [[ -n "$oto"   ]] && trail="${trail}Original stop time: $oto"$'\n'
    [[ -n "$nfrom" ]] && trail="${trail}New start time: $nfrom"$'\n'
    [[ -n "$nto"   ]] && trail="${trail}New stop time: $nto"$'\n'

    if [[ -z "$trail" ]]; then
        printf '%s' "$note"
        return 0
    fi
    trail="${trail%$'\n'}"

    # Same trailing-newline discipline notes_block uses: strip what's there so
    # the blank line between the note and the trail is exactly one, however
    # many newlines $EDITOR left behind.
    while [[ "$note" == *$'\n' ]]; do note="${note%$'\n'}"; done
    if [[ -n "$note" ]]; then
        printf '%s\n\n%s' "$note" "$trail"
    else
        printf '%s' "$trail"
    fi
}
