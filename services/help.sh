#!/usr/bin/env bash
# Refocus Shell - Help adapter (secondary adapter)
#
# One text per command, in docs/help/<cmd>.txt, rendered by both paths that
# ever show usage: an explicit --help, and a usage error. Handlers must not
# carry their own usage strings — that is how `focus past --help`,
# `focus past add --help` and `focus past add` came to print three different
# things. [#24] [#25]
#
# lib/help.sh is the routable wrapper over show_help; every other handler
# sources this file for the -h/--help intercept and for usage_error.

_help_doc() {
    printf '%s' "$REFOCUS_ROOT/docs/help/${1}.txt"
}

show_help() {
    # show_help <cmd> -> doc on stdout, exit 0. Asking for help is not an error.
    local doc; doc=$(_help_doc "$1")
    if [[ -f "$doc" ]]; then
        cat "$doc"
        exit 0
    fi
    echo "No help for: $1" >&2
    echo "Run 'focus help' for the command list." >&2
    exit 2
}

usage_error() {
    # usage_error <cmd> -> same doc, on stderr, exit 2 [CONV-EXIT].
    local doc; doc=$(_help_doc "$1")
    if [[ -f "$doc" ]]; then
        cat "$doc" >&2
    else
        echo "Usage: focus $1" >&2
    fi
    exit 2
}

wants_help() {
    # wants_help "$@" -> true if -h/--help appears anywhere in the arguments.
    # Handlers call this before parsing or touching the DB, so `past modify 5
    # --help` cannot reach the code that treated --help as a new project name.
    local a
    for a in "$@"; do
        [[ "$a" == "-h" || "$a" == "--help" ]] && return 0
    done
    return 1
}
