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
