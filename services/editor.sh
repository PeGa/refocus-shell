#!/usr/bin/env bash
# Refocus Shell - Editor adapter (secondary adapter)
#
# Captures free-text notes for the one place the model allows them: the note
# focus off writes onto the session [INV-4]. past add/modify reuse the same
# capture so the editing experience is identical everywhere.
#
# Replaces `read -r notes`, which consumed exactly one line — pasting a block
# stored the first line and left the rest in the terminal, where the shell ran
# them as commands.
#
# Contract: always succeeds. Handlers run under `set -e` and a note is never
# worth aborting a session write over.

_NOTES_HEADER="# Lines starting with # are ignored. Save an empty file to skip."

_resolve_editor() {
    # $VISUAL/$EDITOR win when the user has set them. Otherwise find a real
    # terminal editor and use it locally — never exported; the user's
    # environment is not ours to write to.
    local ed="${VISUAL:-${EDITOR:-}}"
    if [[ -z "$ed" ]]; then
        local cand
        for cand in nano vim vi; do
            if command -v "$cand" >/dev/null 2>&1; then ed="$cand"; break; fi
        done
    fi
    # Last resort on macOS, if the box somehow has no vi: hand it to the GUI.
    # -W blocks until the editor quits — bare `open` returns immediately and we
    # would read the file back before anything was typed. -n forces a new
    # instance so -W still blocks when the editor is already running.
    if [[ -z "$ed" && "$(uname -s)" == "Darwin" ]] && command -v open >/dev/null 2>&1; then
        ed="open -W -n -t"
    fi
    printf '%s' "$ed"
}

capture_notes() {
    # capture_notes [initial-text] -> notes on stdout, newlines intact.
    local initial="${1:-}"

    # Not a terminal: cron, a pipeline, or `</dev/null`. Take the whole stream
    # as the note, so `echo "..." | focus off` still works — and now keeps
    # every line of it. Empty stdin falls back to what we were handed.
    if [[ ! -t 0 ]]; then
        local piped; piped=$(cat)
        printf '%s' "${piped:-$initial}"
        return 0
    fi

    local ed; ed=$(_resolve_editor)
    if [[ -z "$ed" ]]; then
        # No editor on the box at all (a stripped container image). Fall back to
        # the old single-line prompt rather than silently dropping the note.
        local line=""
        printf '📝 Notes (Enter to skip): ' >/dev/tty
        read -r line || true
        printf '%s' "$line"
        return 0
    fi

    local tmp; tmp=$(mktemp "${TMPDIR:-/tmp}/refocus-notes.XXXXXX")
    {
        [[ -n "$initial" ]] && printf '%s\n' "$initial"
        printf '%s\n' "$_NOTES_HEADER"
    } > "$tmp"

    # The editor must talk to the terminal, not to us: our stdout is a command
    # substitution pipe, and a full-screen editor would render straight into
    # the note. $ed is deliberately unquoted — it may carry flags.
    # shellcheck disable=SC2086
    $ed "$tmp" </dev/tty >/dev/tty 2>&1 || true

    # Drop comment lines; $( ) strips the trailing newlines for us.
    local out; out=$(sed '/^[[:space:]]*#/d' "$tmp")
    rm -f "$tmp"
    printf '%s' "$out"
}
