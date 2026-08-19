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
# Contract: succeeds unless invoked non-interactively to re-edit an existing
# note with nothing piped in (see capture_notes below) — that case is a usage
# error, not a silent guess at "keep" or "clear". Handlers run under `set -e`,
# so a non-zero return aborts the command; callers don't need to check it.

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
    # every line of it.
    #
    # Empty stdin: for a fresh note (initial is empty — off/add) that just
    # means "no note", same as always. For a re-edit (initial is an existing
    # note — past modify --notes) it's ambiguous whether nothing-piped means
    # "leave it alone" or "clear it", and guessing either way is how this
    # bug existed in the first place. Refuse instead: clearing a note is only
    # ever a deliberate act done through $EDITOR (delete everything, save).
    if [[ ! -t 0 ]]; then
        local piped; piped=$(cat)
        if [[ -z "$piped" && -n "$initial" ]]; then
            echo "❌ --notes needs input when run non-interactively (stdin was empty)." >&2
            echo "   To clear a note, edit it in \$EDITOR and save an empty file." >&2
            return 2
        fi
        printf '%s' "$piped"
        return 0
    fi

    local ed; ed=$(_resolve_editor)
    if [[ -z "$ed" ]]; then
        # No editor on the box at all (a stripped container image). Degraded
        # single-line prompt: Enter means skip — leave initial untouched,
        # same as it would be if there were nothing to type. Typing text
        # replaces it. There's no way to clear an existing note from this
        # fallback: that needs $EDITOR (delete everything, save), same as
        # the non-interactive path above.
        local line=""
        printf '📝 Notes (Enter to skip): ' >/dev/tty
        read -r line || true
        printf '%s' "${line:-$initial}"
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
