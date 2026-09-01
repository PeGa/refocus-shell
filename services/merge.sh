#!/usr/bin/env bash
# Refocus Shell - Duplicate-session merge (secondary adapter)
#
# One project name, one session row. `focus off`, `past add` and `past modify`
# each route through merge_duplicate_session before writing: if a row already
# carries the name, the new time is folded into that original row instead of
# landing beside it as a second entry. Two rows named the same thing, with
# overlapping clock times, are indistinguishable in a report — which is what
# issue #36 was. [#36]
#
# Sourced by handlers, never routable — a file under services/ is not a
# command. Assumes the caller already sourced env.sh, services/database.sh,
# services/editor.sh, core/time.sh and core/text.sh; every handler that writes
# a session already sources all five.

_merge_ts() {
    # stored ISO -> display string, or nothing when there is no timestamp.
    # Never fails: an unparseable stored value prints as-is rather than
    # aborting a merge that is already half-decided.
    local iso="${1:-}"
    [[ -z "$iso" ]] || ts_format "$iso" "$DATE_SHORT_FORMAT" 2>/dev/null || printf '%s' "$iso"
}

_merge_date() {
    # <iso>... -> the calendar date the merged row should carry, from the first
    # timestamp that parses; today if the original row has none to offer.
    local iso
    for iso in "$@"; do
        [[ -z "$iso" ]] && continue
        ts_format "$iso" "$DATE_FORMAT" 2>/dev/null && return 0
    done
    parse_date_to_fmt "today" "$DATE_FORMAT"
}

merge_duplicate_session() {
    # <project> <seconds> <start-iso> <end-iso> [exclude-id] -> offer to fold
    # this session into the row that already holds <project>. start/end may be
    # empty (a duration-only session has no timestamps). exclude-id keeps
    # `past modify` from matching the very row it is editing.
    #
    # Returns:
    #   0  folded — the caller must NOT write a row of its own
    #   1  nothing else holds the name — the caller proceeds normally
    #   2  declined — the caller must cancel without writing anything
    #
    # Fatal errors exit the handler outright rather than returning: callers
    # invoke this in a `|| rc=$?` list, which suspends set -e for the whole
    # function body, so a failed note capture or a failed write would
    # otherwise sail on and overwrite the original note with nothing.
    local project="$1" seconds="$2" new_start="${3:-}" new_end="${4:-}" exclude="${5:-}"

    local row; row=$(get_session_by_project "$project" "$exclude")
    [[ -z "$row" ]] && return 1

    local oid ostart oend odur onotes odonly odate
    IFS='|' read -r oid _ ostart oend odur onotes odonly odate <<< "$row"

    local total=$(( odur + seconds ))
    echo "⚠  Session $oid is already named '$project' ($(fmt_duration "$odur") logged)."
    printf '   A session with the same name exists, append to original note? (y/N): '
    local ans=""
    read -r ans || true
    [[ "$ans" =~ ^[Yy]$ ]] || return 2

    echo "📝 Notes — this is the original session's note; add to it (empty to keep as is)"
    local notes
    notes=$(capture_notes "$(notes_decode "$onotes")") || exit 2

    # The row only kept its timestamps while it described one span. Write them
    # into the note before dropping them; a row that is already duration-only
    # has none left to preserve and contributes nothing here.
    local ofrom="" oto=""
    if [[ "$odonly" != "1" ]]; then
        ofrom=$(_merge_ts "$ostart")
        oto=$(_merge_ts "$oend")
    fi
    local nfrom nto
    nfrom=$(_merge_ts "$new_start")
    nto=$(_merge_ts "$new_end")
    notes=$(notes_merge_trail "$notes" "$ofrom" "$oto" "$nfrom" "$nto")

    local date="$odate"
    [[ -z "$date" ]] && date=$(_merge_date "$ostart" "$oend")

    fold_session_into "$oid" "$total" "$date" "$notes" || exit 1
    echo "✅ Appended to session $oid: $project is now $(fmt_duration "$total") on $date."
    return 0
}
