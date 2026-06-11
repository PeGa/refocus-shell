#!/usr/bin/env bash
# Refocus Shell - Shell integration
# Source this in ~/.bashrc:
#   source ~/.local/refocus/services/focus-function.sh

_REFOCUS_INSTALL="${_REFOCUS_INSTALL:-$HOME/.local/refocus}"
_REFOCUS_DB="${REFOCUS_DB_PATH:-$HOME/.local/refocus/refocus.db}"

# Save original PS1 once
[[ -z "${_REFOCUS_ORIGINAL_PS1:-}" ]] && export _REFOCUS_ORIGINAL_PS1="$PS1"

# Prompt hook — reads state from DB, updates PS1
_refocus_prompt() {
    [[ -f "$_REFOCUS_DB" ]] || return

    local row
    row=$(sqlite3 -separator '|' "$_REFOCUS_DB" \
        "SELECT active, project, paused FROM state WHERE id=1;" 2>/dev/null) || return

    local active project paused
    IFS='|' read -r active project paused <<< "$row"

    if [[ "$active" == "1" && -n "$project" ]]; then
        PS1="⏳ [$project] $_REFOCUS_ORIGINAL_PS1"
    elif [[ "$paused" == "1" && -n "$project" ]]; then
        PS1="⏸  [$project] $_REFOCUS_ORIGINAL_PS1"
    else
        PS1="$_REFOCUS_ORIGINAL_PS1"
    fi
}

# Prepend to PROMPT_COMMAND (preserve existing hooks)
if [[ -z "${PROMPT_COMMAND:-}" ]]; then
    PROMPT_COMMAND="_refocus_prompt"
elif [[ "$PROMPT_COMMAND" != *"_refocus_prompt"* ]]; then
    PROMPT_COMMAND="_refocus_prompt;$PROMPT_COMMAND"
fi

# focus() function — wraps the installed script so the prompt updates immediately
focus() {
    local script="$_REFOCUS_INSTALL/focus"
    if [[ ! -x "$script" ]]; then
        echo "❌ Refocus not installed at $_REFOCUS_INSTALL" >&2
        return 1
    fi
    REFOCUS_ROOT="$_REFOCUS_INSTALL" bash "$script" "$@"
    local rc=$?
    _refocus_prompt   # immediate feedback, don't wait for next prompt
    return $rc
}
