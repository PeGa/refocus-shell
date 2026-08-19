#!/usr/bin/env bash
# Refocus Shell - State machine regression matrix
#
# Usage: tests/state-matrix.sh [root-dir]
#   root-dir defaults to the repo root (one level up from this script)
#
# Covers:
#   - disable guard: active session, paused session, idle
#   - focus on: disabled, already active
#   - full on/pause/continue/off cycle
#   - past add/modify duration-only: correct storage, rename, re-duration, ts-rejection
#   - import SQL: sessions preserved, state normalised to idle+disabled
#   - config set/show round-trip (ENV_FILE split-brain fix)
#   - focus help <cmd> dispatch and <bad-cmd> exit code
#
# Keys: row lookups use project name, never row id, so session ordering
# between test steps cannot corrupt assertions.
#
# Exit 0 = all passed. Exit 1 = failures. Printed to stdout.

set -uo pipefail

ROOT="${1:-$(dirname "$(realpath "${BASH_SOURCE[0]}")")/../}"
cd "$ROOT"
chmod +x focus focus-nudge lib/*.sh services/*.sh core/*.sh 2>/dev/null || true

export REFOCUS_ROOT="$ROOT"
SANDBOX=$(mktemp -d)
export REFOCUS_DB_PATH="$SANDBOX/refocus.db"
trap 'rm -rf "$SANDBOX"' EXIT

pass=0; fail=0

chk() {
    local desc="$1" expected="$2" actual="$3"
    if [[ "$expected" == "$actual" ]]; then
        pass=$(( pass + 1 ))
        echo "  ✓  $desc"
    else
        fail=$(( fail + 1 ))
        echo "  ✗  $desc"
        echo "       expected: $expected"
        echo "       actual:   $actual"
    fi
}

st()  { sqlite3 -separator '|' "$REFOCUS_DB_PATH" \
          "SELECT active,paused,focus_disabled,COALESCE(project,'-') FROM state;" 2>/dev/null; }
dur() { sqlite3 "$REFOCUS_DB_PATH" \
          "SELECT duration_seconds FROM sessions WHERE project='$1' ORDER BY id DESC LIMIT 1;" 2>/dev/null; }
cnt() { sqlite3 "$REFOCUS_DB_PATH" "SELECT count(*) FROM sessions;" 2>/dev/null; }

# ── setup ────────────────────────────────────────────────────────────────────
echo "── setup ──"
./focus init >/dev/null
./focus enable >/dev/null 2>&1 || true
chk "init: idle enabled" "0|0|0|-" "$(st)"

# ── on guard: disabled ───────────────────────────────────────────────────────
echo "── on guard: disabled ──"
./focus disable >/dev/null 2>&1
./focus on whatever >/dev/null 2>&1; chk "on@disabled rc=1" "1" "$?"
./focus enable >/dev/null 2>&1 || true

# ── on / pause / continue / off cycle ───────────────────────────────────────
echo "── lifecycle ──"
./focus on fyc/work >/dev/null 2>&1
chk "on: active"           "1|0|0|fyc/work" "$(st)"

./focus disable >/dev/null 2>&1; chk "disable@active rc=1" "1" "$?"
chk "disable@active: state held" "1|0|0|fyc/work" "$(st)"

./focus pause >/dev/null 2>&1
chk "pause: paused"        "0|1|0|fyc/work" "$(st)"

./focus disable >/dev/null 2>&1; chk "disable@paused rc=1" "1" "$?"

printf '\n' | ./focus continue >/dev/null 2>&1
chk "continue: active"     "1|0|0|fyc/work" "$(st)"

printf 'context note\n' | ./focus off >/dev/null 2>&1
chk "off: idle"            "0|0|0|-" "$(st)"

# ── disable/enable cycle ─────────────────────────────────────────────────────
echo "── disable/enable ──"
./focus disable >/dev/null 2>&1; chk "disable@idle rc=0" "0" "$?"
chk "disabled state"       "0|0|1|-" "$(st)"

out=$(./focus status 2>&1)
[[ "$out" == *"disabled"* ]]; chk "status surfaces disabled" "0" "$?"

./focus enable >/dev/null 2>&1 || true
chk "enable: not disabled" "0" "$(sqlite3 "$REFOCUS_DB_PATH" "SELECT focus_disabled FROM state;")"

# ── on guard: already active ─────────────────────────────────────────────────
echo "── on guard: already active ──"
./focus on fyc/work >/dev/null 2>&1
./focus on fyc/other >/dev/null 2>&1; chk "on@active rc=1" "1" "$?"
printf 'done\n' | ./focus off >/dev/null 2>&1

# ── past add duration-only ───────────────────────────────────────────────────
echo "── past: duration-only ──"
printf 'invoicing\n' | ./focus past add fyc/billing --duration 2h30m --date 2026/06/11 >/dev/null 2>&1
chk "dur-only 9000s"       "9000" "$(dur fyc/billing)"

./focus past modify \
    "$(sqlite3 "$REFOCUS_DB_PATH" "SELECT id FROM sessions WHERE project='fyc/billing';")" \
    fyc/billing-v2 >/dev/null 2>&1
chk "rename preserves dur" "9000" "$(sqlite3 "$REFOCUS_DB_PATH" "SELECT duration_seconds FROM sessions WHERE project='fyc/billing-v2';")"

./focus past modify \
    "$(sqlite3 "$REFOCUS_DB_PATH" "SELECT id FROM sessions WHERE project='fyc/billing-v2';")" \
    fyc/billing-v2 --duration 3h >/dev/null 2>&1
chk "re-duration 10800"    "10800" "$(dur fyc/billing-v2)"
bash lib/past.sh modify "$(sqlite3 "$REFOCUS_DB_PATH" "SELECT id FROM sessions WHERE project='fyc/billing-v2';")" --duration 90m >/dev/null 2>&1
chk "modify --duration only: dur"  "5400"          "$(dur fyc/billing-v2)"
chk "modify --duration only: proj" "fyc/billing-v2" "$(sqlite3 "$REFOCUS_DB_PATH" "SELECT project FROM sessions WHERE project='fyc/billing-v2';")"

./focus past modify \
    "$(sqlite3 "$REFOCUS_DB_PATH" "SELECT id FROM sessions WHERE project='fyc/billing-v2';")" \
    x 2026/06/11-09:00 2026/06/11-10:00 >/dev/null 2>&1
chk "ts-edit on dur-only rc=2" "2" "$?"

# ── import: state normalisation ──────────────────────────────────────────────
echo "── import: SQL state normalisation ──"
./focus on fyc/active >/dev/null 2>&1
sessions_before=$(cnt)
( cd "$SANDBOX" && "$REFOCUS_ROOT/focus" export snap >/dev/null )
printf 'done\n' | ./focus off >/dev/null 2>&1
printf 'yes\n' | ./focus import "$SANDBOX/snap.sql" >/dev/null 2>&1
chk "import: state idle+disabled" "0|0|1|-" "$(st)"
chk "import: sessions preserved"  "$sessions_before" "$(cnt)"

# ── config round-trip ────────────────────────────────────────────────────────
echo "── config round-trip ──"
./focus enable >/dev/null 2>&1 || true
./focus config set NUDGE_INTERVAL 7 >/dev/null 2>&1
actual=$(./focus config show 2>/dev/null | awk '/NUDGE_INTERVAL/ {print $3; exit}')
chk "config set/show same .env"  "7" "$actual"

# ── help dispatch ────────────────────────────────────────────────────────────
echo "── help dispatch ──"
out=$(./focus help disable 2>&1)
[[ "$out" == *"disable"* ]]; chk "help <cmd>: dispatches to docs/" "0" "$?"
./focus help nonexistent >/dev/null 2>&1; chk "help <bad>: rc=2" "2" "$?"

# ── help consistency [#24] ───────────────────────────────────────────────────
# One text per command, whether you ask for it or get the arguments wrong.
# These three printed three different strings before.
echo "── help consistency [#24] ──"
h_sub=$(./focus past --help 2>&1);      chk "past --help rc=0"      "0" "$?"
h_add=$(./focus past add --help 2>&1);  chk "past add --help rc=0"  "0" "$?"
h_err=$(./focus past add 2>&1);         chk "past add: usage rc=2"  "2" "$?"
chk "past --help == past add --help" "$h_sub" "$h_add"
chk "past --help == usage on error"  "$h_sub" "$h_err"
chk "help text comes from docs/"     "0" \
    "$([[ "$h_sub" == "$(cat docs/help/past.txt)" ]]; echo $?)"

# ── past modify: argument guards [#25] ───────────────────────────────────────
echo "── past modify guards [#25] ──"
printf 'note\n' | ./focus past add guard/proj 2026/06/11-10:00 2026/06/11-11:00 >/dev/null 2>&1
gid=$(sqlite3 "$REFOCUS_DB_PATH" "SELECT id FROM sessions WHERE project='guard/proj';")

# The bug: --help was taken for a new project name and silently renamed the row.
./focus past modify "$gid" --help >/dev/null 2>&1; chk "modify <id> --help rc=0" "0" "$?"
chk "modify <id> --help does not rename" "guard/proj" \
    "$(sqlite3 "$REFOCUS_DB_PATH" "SELECT project FROM sessions WHERE id=$gid;")"

# The bug: --help reached SQL as `WHERE id=--help`, where -- opens a comment.
./focus past modify --help >/dev/null 2>&1; chk "modify --help rc=0" "0" "$?"
err=$(./focus past modify --help 2>&1)
chk "modify --help: no SQL error" "0" \
    "$([[ "$err" != *"in prepare"* ]]; echo $?)"

# A modify that changes nothing used to report success after a no-op UPDATE.
./focus past modify "$gid" >/dev/null 2>&1;    chk "modify <id> no fields rc=2" "2" "$?"
./focus past delete abc  >/dev/null 2>&1;      chk "delete <non-numeric> rc=2"  "2" "$?"
err=$(./focus past delete abc 2>&1)
chk "delete <non-numeric>: no SQL error" "0" \
    "$([[ "$err" != *"in prepare"* ]]; echo $?)"

# ── notes: multi-line [#23] ──────────────────────────────────────────────────
# A newline in the note must survive storage and must not break the
# pipe-separated read contract [PORT].
echo "── multi-line notes [#23] ──"
printf 'first line\nsecond line\n' | ./focus past add note/multi 2026/06/11-12:00 2026/06/11-13:00 >/dev/null 2>&1
nid=$(sqlite3 "$REFOCUS_DB_PATH" "SELECT id FROM sessions WHERE project='note/multi';")
chk "note keeps both lines" "first line
second line" "$(sqlite3 "$REFOCUS_DB_PATH" "SELECT notes FROM sessions WHERE id=$nid;")"
chk "encoded read stays one row" "1" \
    "$(bash -c 'source env.sh; source services/database.sh; get_session '"$nid"' | wc -l' | tr -d ' ')"
chk "encoded read stays 8 fields" "8" \
    "$(bash -c 'source env.sh; source services/database.sh; get_session '"$nid"' | awk -F"|" "{print NF}"')"
chk "past list renders both lines" "0" \
    "$(out=$(./focus past list 2>&1); [[ "$out" == *"first line"* && "$out" == *"second line"* ]]; echo $?)"

# --notes rewrites the note without touching timing.
dur_before=$(sqlite3 "$REFOCUS_DB_PATH" "SELECT duration_seconds FROM sessions WHERE id=$nid;")
printf 'replaced\n' | ./focus past modify "$nid" --notes >/dev/null 2>&1
chk "--notes rewrites note"      "replaced"     "$(sqlite3 "$REFOCUS_DB_PATH" "SELECT notes FROM sessions WHERE id=$nid;")"
chk "--notes preserves duration" "$dur_before"  "$(sqlite3 "$REFOCUS_DB_PATH" "SELECT duration_seconds FROM sessions WHERE id=$nid;")"

# --notes piped with nothing on stdin, against an existing note, is a usage
# error rather than a silent guess at "keep" or "clear" — clearing is only
# ever a deliberate act done through $EDITOR.
printf '' | ./focus past modify "$nid" --notes >/dev/null 2>&1
chk "--notes empty pipe on existing note rc=2" "2" "$?"
chk "--notes empty pipe leaves note unchanged" "replaced" \
    "$(sqlite3 "$REFOCUS_DB_PATH" "SELECT notes FROM sessions WHERE id=$nid;")"

# A fresh note (no existing content — off/add) keeps meaning "no note" on
# empty input; the usage-error path above only applies to re-editing.
printf '' | ./focus past add note/fresh 2026/06/11-16:00 2026/06/11-16:30 >/dev/null 2>&1
chk "empty pipe on a fresh note rc=0" "0" "$?"

# notes_block must not render a spurious blank line for a note that already
# ends in a newline (printf '%s\n' would otherwise double it up).
chk "notes_block: no spurious blank on trailing newline" "2" \
    "$(bash -c "source core/text.sh; notes_block '' '' \$'a\nb\n'" | wc -l | tr -d ' ')"
chk "notes_block: no spurious blank on multiple trailing newlines" "2" \
    "$(bash -c "source core/text.sh; notes_block '' '' \$'a\nb\n\n\n'" | wc -l | tr -d ' ')"

# ── report: empty period ─────────────────────────────────────────────────────
# `declare -A` left the array unset, so ${#arr[@]} tripped set -u and any
# period with no sessions exited 1.
echo "── report: empty period ──"
./focus report custom 1 >/dev/null 2>&1; chk "report on empty period rc=0" "0" "$?"

# ── report: bash-3.2 compat (macOS ships bash 3.2, no associative arrays) ────
# report.sh previously kept per-project totals in `declare -A`, which macOS's
# shipped /bin/bash cannot parse at all -- every `focus report` call aborted
# on macOS. Aggregation now happens in SQL (get_project_totals_in_range);
# this checks the construct is gone and the breakdown is still correct.
echo "── report: bash-3.2 compat ──"
if grep -q '^[^#]*declare -A' lib/report.sh; then assoc_array_found=yes; else assoc_array_found=no; fi
chk "report.sh has no associative array" "no" "$assoc_array_found"
printf 'r1\n' | ./focus past add rep/x 2026/06/12-09:00 2026/06/12-10:00 >/dev/null 2>&1
printf 'r2\n' | ./focus past add rep/x 2026/06/12-10:00 2026/06/12-12:00 >/dev/null 2>&1
printf 'r3\n' | ./focus past add rep/y 2026/06/12-13:00 2026/06/12-13:30 >/dev/null 2>&1
out=$(./focus report custom 90000 2>&1)
chk "report: multi-session project total" "0" \
    "$([[ "$out" == *"rep/x"*"3h 0m"*"2 session"* ]]; echo $?)"
chk "report: single-session project total" "0" \
    "$([[ "$out" == *"rep/y"*"30m"*"1 session"* ]]; echo $?)"

# ── config show: BSD sed t-label ─────────────────────────────────────────────
# BSD sed reads a `;`-terminated `t` label as part of the label name and
# errors "undefined label"; GNU accepts it inline. Split into -e clauses.
# This only exercises the GNU path here, but guards against reintroducing the
# single-expression form.
echo "── config show ──"
./focus config set NUDGE_INTERVAL 11 >/dev/null 2>&1
out=$(./focus config show 2>&1); rc=$?
chk "config show rc=0 with overrides" "0" "$rc"
chk "config show renders override"   "0" "$([[ "$out" == *"NUDGE_INTERVAL=11"* ]]; echo $?)"

# ── config set/unset: file mode survives the rewrite ─────────────────────────
# `mv` over a mktemp file drops ENV_FILE from its real mode to mktemp's
# default 0600. Writing back into the original file instead of replacing it
# must leave the mode untouched.
echo "── config: file mode preserved ──"
env_file="$SANDBOX/.env"
./focus config set REPORT_LIMIT 6 >/dev/null 2>&1
chmod 644 "$env_file"
./focus config set REPORT_LIMIT 7 >/dev/null 2>&1
chk "config set preserves 644"   "-rw-r--r--" "$(ls -l "$env_file" | cut -c1-10)"
./focus config unset REPORT_LIMIT >/dev/null 2>&1
chk "config unset preserves 644" "-rw-r--r--" "$(ls -l "$env_file" | cut -c1-10)"

# ── project name sanitization: '|' desyncs every pipe-separated read ────────
# _query uses `sqlite3 -separator '|'` and every caller splits on IFS='|'; a
# project name containing the separator corrupts every field after it.
# Rather than rejecting it, every input path transliterates '|' -> '¦'
# (U+00A6) before it ever reaches storage, so the character that breaks the
# format never gets there in the first place.
echo "── project name sanitization ──"
printf 'n\n' | ./focus past add 'evil|project' 2026/06/11-10:00 2026/06/11-11:00 >/dev/null 2>&1
chk "past add '|' name rc=0"      "0" "$?"
chk "past add '|' name stored as ¦" "1" \
    "$(sqlite3 "$REFOCUS_DB_PATH" "SELECT COUNT(*) FROM sessions WHERE project='evil¦project';")"

./focus on 'a|b' >/dev/null 2>&1; chk "on '|' name rc=0" "0" "$?"
chk "on '|' name active, stored as ¦" "1|0|0|a¦b" "$(st)"
printf 'n\n' | ./focus off >/dev/null 2>&1

# A second 'on' with the same raw name must find the total the first one
# logged under the sanitized name, not 0m under a key nothing was stored as.
sqlite3 "$REFOCUS_DB_PATH" "UPDATE sessions SET duration_seconds=7200 WHERE project='a¦b';"
out=$(printf 'n\n' | ./focus on 'a|b' 2>&1)
chk "on '|' name: total-time lookup matches sanitized key" "0" \
    "$([[ "$out" == *"120m logged"* ]]; echo $?)"

# The bash-side guard is a friendly front door; the schema CHECK is the
# actual backstop for anything that bypasses it (db_import_session_row is
# deliberately exempt from the bash guard, per its own comment).
sessions_before_check=$(cnt)
bash -c 'source env.sh; source services/database.sh; db_import_session_row "bad|import" "" "" 3600 "" 0 "2026-06-11"' >/dev/null 2>&1
chk "DB-level CHECK blocks '|' bypassing the bash guard" "$sessions_before_check" "$(cnt)"

# A '|' in a NOTE must round-trip as the exact original byte, not get
# transliterated (notes are free text; encode-on-read via _NOTES_ENCODED
# preserves it, unlike project names which are short identifiers).
printf 'Fixed the a|b parser bug\n' | ./focus past add note/pipe 2026/06/11-16:00 2026/06/11-17:00 >/dev/null 2>&1
out=$(./focus past list 2>&1)
chk "note with '|' round-trips exactly, not transliterated" "0" \
    "$([[ "$out" == *"Fixed the a|b parser bug"* ]]; echo $?)"

# JSON import: a '|' in one row's project must not abort the rest of the
# import (the earlier bash-side rejection + schema CHECK both used to kill
# the while-loop under set -e partway through; sanitizing at capture removes
# the trigger, so every row after the bad one still lands).
cat > "$SANDBOX/pipe-import.json" <<EOF
{"sessions": [
  {"project": "GoodOne", "start_time": "2026-06-11T10:00:00-03:00", "end_time": "2026-06-11T11:00:00-03:00", "duration_seconds": 3600, "notes": "", "duration_only": 0, "session_date": ""},
  {"project": "bad|name", "start_time": "2026-06-11T12:00:00-03:00", "end_time": "2026-06-11T13:00:00-03:00", "duration_seconds": 3600, "notes": "", "duration_only": 0, "session_date": ""},
  {"project": "GoodTwo", "start_time": "2026-06-11T14:00:00-03:00", "end_time": "2026-06-11T15:00:00-03:00", "duration_seconds": 3600, "notes": "", "duration_only": 0, "session_date": ""}
]}
EOF
printf 'yes\n' | ./focus import "$SANDBOX/pipe-import.json" >/dev/null 2>&1
chk "JSON import: '|' row doesn't abort the rest" "0" \
    "$([[ "$(cnt)" -eq 3 ]]; echo $?)"
chk "JSON import: bad row sanitized, not dropped" "1" \
    "$(sqlite3 "$REFOCUS_DB_PATH" "SELECT COUNT(*) FROM sessions WHERE project='bad¦name';")"
chk "JSON import: normalizes state per INV-5" "0|0|1|-" "$(st)"

# ── result ───────────────────────────────────────────────────────────────────
echo
total=$(( pass + fail ))
echo "RESULT: $pass/$total passed"
[[ $fail -eq 0 ]]
