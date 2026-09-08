#!/usr/bin/env bash
set -euo pipefail
source "$REFOCUS_ROOT/env.sh"
source "$REFOCUS_ROOT/services/database.sh"
source "$REFOCUS_ROOT/services/editor.sh"
source "$REFOCUS_ROOT/services/help.sh"
source "$REFOCUS_ROOT/core/time.sh"
source "$REFOCUS_ROOT/core/text.sh"

# A shortcut for marking where one period of work ends and the next begins —
# the same row `focus on "Cycle break…"` + `focus off` would produce, minus the
# editor, with the label filled in for you.
#
# The marker is an ordinary session: zero duration, start and end both now.
# Nothing in the schema says "cycle"; the project string is the whole of it
# (core/text.sh), so a marker renamed out of that shape simply stops being one.

wants_help "$@" && show_help cycle

db_ensure

sub="${1:-}"; shift || true
[[ -z "$sub" ]] && usage_error cycle

# Ids reach the adapter as raw SQL, so they are checked here [CONV-ID].
_require_id() {
    [[ "$1" =~ ^[0-9]+$ ]] || { echo "❌ Not a session id: $1" >&2; usage_error cycle; }
}

# Called directly, never through $( ) — a subshell would swallow the exit and
# let the caller carry on with an empty row.
_reject_non_cycle() {
    # <id> <project> -> returns only when that row really is a cycle break.
    is_cycle_label "$2" && return 0
    echo "❌ Session $1 is not a cycle break." >&2
    echo "   Use 'focus past modify|delete' for ordinary sessions." >&2
    exit 1
}

_note_placeholder="Period cycle. Edit with \`focus cycle modify --edit-notes\` and the \`id\` of this cycle."

case "$sub" in
    add)
        [[ $# -gt 0 ]] && usage_error cycle

        # A break marks a boundary *between* periods. Mid-session the boundary
        # would be ambiguous, so it waits for the session to end. Idle or
        # disabled are both fine — this touches no state either way.
        if is_session_active; then
            IFS='|' read -r _ project _ <<< "$(get_state)"
            echo "❌ Focusing on: $project — run 'focus off' before marking a cycle break." >&2; exit 1
        fi
        if is_session_paused; then
            IFS='|' read -r _ project _ <<< "$(get_state)"
            echo "❌ Session paused: $project — run 'focus off' before marking a cycle break." >&2; exit 1
        fi

        now=$(now_iso)
        now_label=$(ts_format "$now" "$DATE_SHORT_FORMAT" 2>/dev/null || echo "$now")

        # Where the period being closed started: the last break, or the
        # beginning of the record if this is the first one.
        prev=$(get_last_cycle_end "$(cycle_prefix)")
        if [[ -n "$prev" ]]; then
            from=$(ts_format "$prev" "$DATE_SHORT_FORMAT" 2>/dev/null || echo "$prev")
        else
            from="Beginning"
        fi

        label=$(cycle_label "$from" "$now_label")
        # Storage transliterates '|' (it is the read separator), so do it here
        # too: the label is echoed back below and used to find the row again,
        # and both must match what actually lands in the database.
        label="${label//|/¦}"

        # Two breaks inside the same minute render the same label. Rather than
        # leave markers nothing can tell apart, offer to replace — all of them,
        # since an import can leave more than one under a single name.
        existing=$(list_session_ids_by_project "$label")
        if [[ -n "$existing" ]]; then
            echo "⚠  A cycle break for this period already exists (id $(printf '%s' "$existing" | tr '\n' ' ' | sed 's/ $//'))."
            printf '   Replace it? (y/N): '
            ans=""
            read -r ans || true
            [[ "$ans" =~ ^[Yy]$ ]] || { echo "Cancelled — nothing was added."; exit 0; }
            # Replaced, not edited: the new marker is a fresh row, so a note
            # typed onto the old one does not survive.
            while read -r old_id; do
                [[ -n "$old_id" ]] && delete_session "$old_id"
            done <<< "$existing"
        fi

        record_session "$label" "$now" "$now" 0 "$_note_placeholder"

        # The note tells the user to edit by id, so hand them the id — the
        # newest row under this name, which is the one just written.
        new_id=$(list_session_ids_by_project "$label" | head -1)
        echo "✅ Cycle break $new_id: $label"
        echo "   Add your own note with 'focus cycle modify --edit-notes $new_id'."
        ;;

    modify)
        [[ "${1:-}" == "--edit-notes" ]] || usage_error cycle
        id="${2:-}"; [[ -z "$id" ]] && usage_error cycle
        _require_id "$id"

        row=$(get_session "$id")
        [[ -z "$row" ]] && { echo "❌ Session $id not found." >&2; exit 1; }
        IFS='|' read -r _ proj _ _ _ cur_notes _ _ <<< "$row"
        _reject_non_cycle "$id" "$proj"

        # Notes come back encoded, one line per row [CONV-NOTES] — decode
        # before the editor sees them, or a stored newline arrives as \n.
        echo "📝 Notes (edit; delete everything and save to clear)"
        new_notes=$(capture_notes "$(notes_decode "$cur_notes")")
        update_session_notes "$id" "$new_notes"
        echo "✅ Cycle break $id updated."
        ;;

    delete|del|rm)
        id="${1:-}"; [[ -z "$id" ]] && usage_error cycle
        _require_id "$id"

        row=$(get_session "$id")
        [[ -z "$row" ]] && { echo "❌ Session $id not found." >&2; exit 1; }
        IFS='|' read -r _ proj _ _ _ _ _ _ <<< "$row"
        _reject_non_cycle "$id" "$proj"

        echo -n "🗑  Delete cycle break $id ($proj)? (y/N): "
        ans=""
        read -r ans || true
        [[ "$ans" =~ ^[Yy]$ ]] || { echo "Cancelled."; exit 0; }
        delete_session "$id"
        echo "✅ Deleted."
        ;;

    *)
        usage_error cycle
        ;;
esac
