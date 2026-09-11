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
    is_session_id "$1" || { echo "❌ Not a session id: $1" >&2; usage_error cycle; }
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

_note_placeholder="$(cycle_note_placeholder)"

# Both branches below keep the same derived-data invariant: a break's receipt
# must agree with its neighbours' instants. Editing regenerates the next
# receipt; deleting regenerates it too, re-anchored to the nearest survivor.
# One walk and one writer, shared, so the invariant has a single implementation.
_cycle_neighbours() {
    # <break-id> -> "prev_end|next_id|next_end" over the live break list:
    # nearest break by id below (its end) and nearest above. Empty fields
    # mean none. Neighbours by id, not by time: ids record the order the
    # markers were drawn, and every period view is an id window.
    local target="$1" found_prev=0 prev_end="" next_id="" next_end=""
    local cid _cproj _cstart cend _cdur _cnotes _cdonly _csdate
    while IFS='|' read -r cid _cproj _cstart cend _cdur _cnotes _cdonly _csdate; do
        if [[ "$cid" -lt "$target" && $found_prev -eq 0 ]]; then
            prev_end="$cend"; found_prev=1
        elif [[ "$cid" -gt "$target" ]]; then
            next_id="$cid"; next_end="$cend"
        fi
    done < <(list_cycles "$(cycle_prefix)")
    printf '%s|%s|%s' "$prev_end" "$next_id" "$next_end"
}

_relabel_break() {
    # <break-id> <from-text> -> rewrite that break's receipt so its period
    # opens at the given moment; prints the one-line confirmation on success.
    # A row with no end_time (import damage) is skipped, not rewritten: it
    # has no instant to name, and feeding date(1) an empty date answers
    # today-midnight instead of failing.
    local break_id="$1" from_text="$2" nrow nstart nend ndur nto nlabel
    nrow=$(get_session "$break_id")
    [[ -z "$nrow" ]] && return 0
    IFS='|' read -r _ _ nstart nend ndur _ _ _ <<< "$nrow"
    [[ -z "$nend" ]] && return 0
    nto=$(ts_format "$nend" "$DATE_SHORT_FORMAT" 2>/dev/null || echo "$nend")
    nlabel=$(cycle_label "$from_text" "$nto")
    nlabel="${nlabel//|/¦}"
    update_session "$break_id" "$nlabel" "$nstart" "$nend" "$ndur"
    echo "   Break $break_id re-labelled: $nlabel"
}

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
        case "${1:-}" in
        --edit-notes)
            id="${2:-}"; [[ -z "$id" || $# -gt 2 ]] && usage_error cycle
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

        --edit-time)
            # Moves the marker to a chosen instant [#50]. A break is a point in
            # time — start == end == the moment — and the label is a receipt
            # derived from it, so moving the instant regenerates the receipt.
            # The next break's receipt names this one's instant as its `from`,
            # so it is regenerated too, from its own untouched timestamps.
            id="${2:-}"; raw="${3:-}"
            [[ -z "$id" || -z "$raw" || $# -gt 3 ]] && usage_error cycle
            _require_id "$id"
            # Normalise before the id is compared as a string (the duplicate
            # check greps the adapter's ids) or fed to [[ -lt ]], which reads
            # a leading zero as octal: "08" would crash the walk, "02" would
            # fail to exclude its own row from the duplicate check.
            id=$((10#$id))

            row=$(get_session "$id")
            [[ -z "$row" ]] && { echo "❌ Session $id not found." >&2; exit 1; }
            IFS='|' read -r _ proj _ _ _ _ _ _ <<< "$row"
            _reject_non_cycle "$id" "$proj"

            new_ts=$(parse_time "$raw") || exit 2
            new_epoch=$(iso_to_epoch "$new_ts")
            new_label_ts=$(ts_format "$new_ts" "$DATE_SHORT_FORMAT" 2>/dev/null || echo "$new_ts")

            # A break closes a period: one landing in the future would close a
            # period that hasn't happened, and the next `cycle add` would date
            # its receipt backwards from there.
            if [[ "$new_epoch" -gt "$(now_epoch)" ]]; then
                echo "❌ That is in the future — a break can only close a period that already happened." >&2
                exit 1
            fi

            neighbours=$(_cycle_neighbours "$id")
            prev_end="${neighbours%%|*}"
            next_id="${neighbours#*|}"; next_id="${next_id%%|*}"
            next_end="${neighbours##*|}"

            # A marker cannot cross its neighbours: that would invert the
            # period both receipts describe, and the id windows would disagree
            # with the timeline the labels claim.
            if [[ -n "$prev_end" && "$new_epoch" -le "$(iso_to_epoch "$prev_end")" ]]; then
                echo "❌ At or before the previous break ($(ts_format "$prev_end" "$DATE_SHORT_FORMAT" 2>/dev/null || echo "$prev_end")) — a marker cannot cross its neighbours." >&2
                exit 1
            fi
            if [[ -n "$next_end" && "$new_epoch" -ge "$(iso_to_epoch "$next_end")" ]]; then
                echo "❌ At or after the next break (id $next_id, $(ts_format "$next_end" "$DATE_SHORT_FORMAT" 2>/dev/null || echo "$next_end")) — a marker cannot cross its neighbours." >&2
                exit 1
            fi

            if [[ -n "$prev_end" ]]; then
                from=$(ts_format "$prev_end" "$DATE_SHORT_FORMAT" 2>/dev/null || echo "$prev_end")
            else
                from="Beginning"
            fi
            new_label=$(cycle_label "$from" "$new_label_ts")
            # Storage transliterates '|' (it is the read separator) — same
            # discipline as add: what is echoed must match what is stored.
            new_label="${new_label//|/¦}"

            # With the ordering guard holding, a CLI edit cannot duplicate a
            # label — but an import can pre-seed one, and two identical
            # receipts are indistinguishable markers.
            dup=$(list_session_ids_by_project "$new_label" | grep -vx "$id" || true)
            if [[ -n "$dup" ]]; then
                echo "❌ Another break (id $(printf '%s' "$dup" | tr '\n' ' ' | sed 's/ $//')) already reads: $new_label" >&2
                exit 1
            fi

            update_session "$id" "$new_label" "$new_ts" "$new_ts" 0

            echo "✅ Cycle break $id moved to $new_label_ts."
            echo "   was: $proj"
            echo "   now: $new_label"
            # The cascade ends in if/fi, never a trailing `&& echo`: a false
            # test as the branch's last command would exit the handler 1 on a
            # fully successful move — which is exactly what the no-cascade
            # path (newest break) used to do.
            if [[ -n "$next_id" ]]; then
                reline=$(_relabel_break "$next_id" "$new_label_ts")
                if [[ -n "$reline" ]]; then echo "$reline"; fi
            fi
            ;;

        *)
            usage_error cycle
            ;;
        esac
        ;;

    delete|del|rm)
        id="${1:-}"; [[ -z "$id" ]] && usage_error cycle
        _require_id "$id"
        id=$((10#$id))   # same normalisation as --edit-time: the walk below compares ids

        row=$(get_session "$id")
        [[ -z "$row" ]] && { echo "❌ Session $id not found." >&2; exit 1; }
        IFS='|' read -r _ proj _ _ _ _ _ _ <<< "$row"
        _reject_non_cycle "$id" "$proj"

        echo -n "🗑  Delete cycle break $id ($proj)? (y/N): "
        ans=""
        read -r ans || true
        [[ "$ans" =~ ^[Yy]$ ]] || { echo "Cancelled."; exit 0; }

        # Neighbours are captured while the row still exists: the next break's
        # receipt opens at THIS break's instant, and after the delete it must
        # re-anchor to the nearest survivor — otherwise it names a boundary
        # that no longer exists, forever.
        neighbours=$(_cycle_neighbours "$id")
        prev_end="${neighbours%%|*}"
        next_id="${neighbours#*|}"; next_id="${next_id%%|*}"

        delete_session "$id"

        if [[ -n "$next_id" ]]; then
            if [[ -n "$prev_end" ]]; then
                from_text=$(ts_format "$prev_end" "$DATE_SHORT_FORMAT" 2>/dev/null || echo "$prev_end")
            else
                from_text="Beginning"
            fi
            reline=$(_relabel_break "$next_id" "$from_text")
            if [[ -n "$reline" ]]; then echo "$reline"; fi
        fi
        echo "✅ Deleted."
        ;;

    *)
        usage_error cycle
        ;;
esac
