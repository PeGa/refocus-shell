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
chmod +x focus focus-nudge focus-checkin lib/*.sh services/*.sh core/*.sh 2>/dev/null || true

export REFOCUS_ROOT="$ROOT"
SANDBOX=$(mktemp -d)
export REFOCUS_DB_PATH="$SANDBOX/refocus.db"
trap 'rm -rf "$SANDBOX"' EXIT

# This suite calls `focus enable`, which arms real cron entries via
# services/cron.sh — without a shim, every run of this file writes into the
# machine's actual crontab. Fake `crontab` backed by a file in $SANDBOX,
# prepended to PATH so `focus enable`'s own subprocess picks it up too.
mkdir -p "$SANDBOX/bin"
cat > "$SANDBOX/bin/crontab" <<'CRONSHIM'
#!/usr/bin/env bash
store="${SANDBOX_CRONTAB:-/tmp/state-matrix-fake-crontab}"
if [[ "$1" == "-l" ]]; then
    [[ -f "$store" ]] && cat "$store" || exit 1
else
    cat "$1" > "$store"
fi
CRONSHIM
chmod +x "$SANDBOX/bin/crontab"
export SANDBOX_CRONTAB="$SANDBOX/fake-crontab"
export PATH="$SANDBOX/bin:$PATH"

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
./focus on fyc/guard >/dev/null 2>&1
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
# Two rows under one project name: `past add` now folds a same-named session
# into the original instead [#36], so the second row is seeded directly. The
# aggregation still has to work for rows that arrived before the rule, or
# through import.
sqlite3 "$REFOCUS_DB_PATH" "INSERT INTO sessions (project, start_time, end_time, duration_seconds, notes, duration_only)
    VALUES ('rep/x', '2026-06-12T10:00:00-03:00', '2026-06-12T12:00:00-03:00', 7200, 'r2', 0);"
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
chk "config show renders override"   "0" "$([[ "$out" == *"NUDGE_INTERVAL='11'"* ]]; echo $?)"

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

# ── checkin: cron interval validation ─────────────────────────────────────────
echo "── checkin: interval validation ──"
_ci_valid() { bash -c "source env.sh; source services/cron.sh; _cron_validate_checkin_interval '$1'" >/dev/null 2>&1; echo $?; }
chk "checkin interval 0 valid"       "0" "$(_ci_valid 0)"
chk "checkin interval 60 valid"      "0" "$(_ci_valid 60)"
chk "checkin interval 120 valid"     "0" "$(_ci_valid 120)"
chk "checkin interval 1440 valid"    "0" "$(_ci_valid 1440)"
chk "checkin interval 90 rejected"   "1" "$(_ci_valid 90)"
chk "checkin interval 1500 rejected" "1" "$(_ci_valid 1500)"
chk "checkin interval abc rejected"  "1" "$(_ci_valid abc)"

# ── checkin: cron install/remove ──────────────────────────────────────────────
# Exercises the actual crontab lines cron_checkin_install writes (via the
# shim above), not just the exit codes — a wrong minute/hour pattern would
# still return 0.
echo "── checkin: cron install/remove ──"
_ci_reinstall() {
    ./focus config set CHECKIN_INTERVAL "$1" >/dev/null 2>&1
    ./focus disable >/dev/null 2>&1
    ./focus enable  >/dev/null 2>&1
}
_ci_entry() { grep 'focus-checkin' "$SANDBOX_CRONTAB" 2>/dev/null; }

_ci_reinstall 60
chk "checkin@60: one cron entry" "1" "$(_ci_entry | wc -l)"
chk "checkin@60: minute-stepped" "0" "$(_ci_entry | grep -qE '^[0-9]+-59/60 \* \* \* \*'; echo $?)"

_ci_reinstall 120
chk "checkin@120: hour-stepped" "0" "$(_ci_entry | grep -qE '^[0-9]+ [0-9]+-23/2 \* \* \*'; echo $?)"

_ci_reinstall 1440
chk "checkin@1440: once-daily hour-stepped" "0" "$(_ci_entry | grep -qE '^[0-9]+ [0-9]+-23/24 \* \* \*'; echo $?)"

_ci_reinstall 0
chk "checkin@0: no cron entry" "0" "$(_ci_entry | wc -l)"
chk "checkin@0: nudge entry untouched" "1" "$(grep -c 'focus-nudge' "$SANDBOX_CRONTAB")"

# An invalid interval must fail closed: disable already removed the old
# entry, and the failed install must not leave anything stale in its place.
_ci_reinstall 120
./focus config set CHECKIN_INTERVAL 90 >/dev/null 2>&1
./focus disable >/dev/null 2>&1
out=$(./focus enable 2>&1)
chk "checkin@90 (invalid): enable still succeeds, warns" "0" \
    "$([[ "$out" == *"Could not install check-in cron"* ]]; echo $?)"
chk "checkin@90 (invalid): no stale/bad entry left" "0" "$(_ci_entry | wc -l)"
chk "checkin@90 (invalid): nudge entry unaffected" "1" "$(grep -c 'focus-nudge' "$SANDBOX_CRONTAB")"

# ── checkin: guard clauses ─────────────────────────────────────────────────────
# focus-checkin runs standalone (as cron would invoke it) — every guard must
# be a silent no-op: zero DB writes, no popup attempted.
echo "── checkin: guard clauses ──"
./focus config set CHECKIN_INTERVAL 60 >/dev/null 2>&1

before=$(cnt)
./focus disable >/dev/null 2>&1
bash focus-checkin >/dev/null 2>&1
chk "checkin@disabled: silent no-op" "$before" "$(cnt)"
./focus enable >/dev/null 2>&1

./focus on checkin/guard >/dev/null 2>&1
before=$(cnt)
bash focus-checkin >/dev/null 2>&1
chk "checkin@active: silent no-op" "$before" "$(cnt)"
printf 'n\n' | ./focus off >/dev/null 2>&1

./focus on checkin/guard-paused >/dev/null 2>&1
./focus pause >/dev/null 2>&1
before=$(cnt)
bash focus-checkin >/dev/null 2>&1
chk "checkin@paused: silent no-op" "$before" "$(cnt)"
printf '\n' | ./focus continue >/dev/null 2>&1
printf 'n\n' | ./focus off >/dev/null 2>&1

./focus config set CHECKIN_INTERVAL 0 >/dev/null 2>&1
before=$(cnt)
bash focus-checkin >/dev/null 2>&1
chk "checkin@interval=0: silent no-op" "$before" "$(cnt)"

# No dialog tool anywhere on PATH (kdialog/zenity/terminal all absent) —
# must fall all the way through and exit 0 without ever spawning anything.
./focus config set CHECKIN_INTERVAL 60 >/dev/null 2>&1
mkdir -p "$SANDBOX/notool-bin"
for b in bash env awk cat column date dirname grep id mktemp sed sqlite3 tr; do
    ln -sf "$(command -v "$b")" "$SANDBOX/notool-bin/$b" 2>/dev/null
done
before=$(cnt)
PATH="$SANDBOX/notool-bin" bash focus-checkin >/dev/null 2>&1
chk "checkin@no-dialog-tool: silent no-op" "$before" "$(cnt)"

# ── config: leading-zero interval values (bash reads them as octal) ────────────
# "090"/"008" aren't valid octal digits — an unguarded `[[ $iv -gt N ]]` throws
# "value too great for base", and because that's an if-condition, set -e never
# sees it as a failure: the bad value used to sail through as "valid", and
# cron_checkin_install would then silently write nothing while `enable` still
# reported success.
echo "── config: leading-zero intervals ──"
_iv_valid()  { bash -c "source env.sh; source services/cron.sh; _cron_validate_interval '$1'"         >/dev/null 2>&1; echo $?; }
_civ_valid() { bash -c "source env.sh; source services/cron.sh; _cron_validate_checkin_interval '$1'" >/dev/null 2>&1; echo $?; }
chk "nudge interval '008' -> valid (normalizes to 8)"     "0" "$(_iv_valid 008)"
chk "nudge interval '090' -> rejected (normalizes to 90)" "1" "$(_iv_valid 090)"
chk "checkin interval '090' -> rejected, not an hour multiple" "1" "$(_civ_valid 090)"
chk "checkin interval '0120' -> valid (normalizes to 120)"     "0" "$(_civ_valid 0120)"

./focus config set NUDGE_INTERVAL 008 >/dev/null 2>&1
./focus disable >/dev/null 2>&1
./focus enable  >/dev/null 2>&1
chk "nudge@008: actually installs, minute-stepped by 8" "0" \
    "$(grep 'focus-nudge' "$SANDBOX_CRONTAB" | grep -qE '^[0-9]+-59/8 \* \* \* \*'; echo $?)"
./focus config unset NUDGE_INTERVAL >/dev/null 2>&1

# focus-checkin re-reads CHECKIN_INTERVAL fresh from env.sh on every cron
# fire, independent of whatever cron.sh normalized at install time — so a
# leading zero broke the `interval * 60` arithmetic there too, even though
# the interval itself was already validated as legal. Exercise it with no
# dialog tool on PATH so this can never pop a real window: the arithmetic
# runs before the tool cascade is even reached, so a clean silent exit here
# proves the fix without any popup risk.
./focus config set CHECKIN_INTERVAL 008 >/dev/null 2>&1
err=$(PATH="$SANDBOX/notool-bin" bash focus-checkin < /dev/null 2>&1)
chk "focus-checkin@008: no octal-parse crash" "0" \
    "$([[ "$err" != *"value too great for base"* ]]; echo $?)"
./focus config set CHECKIN_INTERVAL 60 >/dev/null 2>&1

# ── status: "Last:" must surface duration-only sessions too ────────────────────
# get_last_session used to filter WHERE end_time IS NOT NULL, so a check-in-
# logged (or `past add --duration`) session — which never has an end_time —
# was invisible to `focus status` even though `focus report` showed it fine.
echo "── status: last session includes duration-only ──"
# A bare session_date sorts as a string, so a same-day duration-only row can
# lose to an earlier-today timestamped fixture from elsewhere in this suite
# (their end_time has extra trailing chars: "2026-08-19T..." > "2026-08-19").
# Use a far-future date so this assertion is deterministic regardless of what
# else ran today, without changing what the fix actually does.
bash -c "source env.sh; source services/database.sh; record_duration_session 'status-check-in' 3600 '2099-01-01' ''" >/dev/null
out=$(./focus status 2>&1)
chk "status shows Last: for a duration-only session" "0" \
    "$([[ "$out" == *"Last: status-check-in"* ]]; echo $?)"

# ── config: values with spaces/shell-metacharacters must round-trip safely ─────
# ENV_FILE is sourced verbatim as shell — an unquoted value with a space
# split into two words on source, so setting DATE_SHORT_FORMAT to its own
# documented default ("%Y-%m-%d %H:%M") broke every subsequent command
# ("%H:%M: command not found", or "fg: no job control" — bash read the bare
# %-word as a job-control spec).
echo "── config: value quoting ──"
./focus config set DATE_SHORT_FORMAT '%Y-%m-%d %H:%M' >/dev/null 2>&1
out=$(./focus status 2>&1)
chk "config set with a space doesn't break subsequent commands" "0" \
    "$([[ "$out" != *"command not found"* && "$out" != *"job control"* ]]; echo $?)"
./focus config set DATE_SHORT_FORMAT '%Y-%m-%d | %H:%M & extra' >/dev/null 2>&1
chk "config set with '|' and '&' round-trips exactly" \
    "REFOCUS_DATE_SHORT_FORMAT='%Y-%m-%d | %H:%M & extra'" \
    "$(grep '^REFOCUS_DATE_SHORT_FORMAT=' "$SANDBOX/.env")"
./focus config unset DATE_SHORT_FORMAT >/dev/null 2>&1

# ── JSON import: newline in a project name must not abort the rest ─────────────
# db_import_session_row deliberately skips _validate_project_name (a bad row
# must not kill the import loop) — but the DB's own CHECK constraint still
# rejected a bare newline, which did exactly that under set -e. Sanitize it
# the same way '|' already is.
echo "── JSON import: newline in project name ──"
cat > "$SANDBOX/newline-import.json" <<'EOF'
{"sessions": [
  {"project": "Good", "start_time": "2026-06-11T10:00:00-03:00", "end_time": "2026-06-11T11:00:00-03:00", "duration_seconds": 3600, "notes": "", "duration_only": 0, "session_date": ""},
  {"project": "bad\nname", "start_time": "2026-06-11T12:00:00-03:00", "end_time": "2026-06-11T13:00:00-03:00", "duration_seconds": 3600, "notes": "", "duration_only": 0, "session_date": ""},
  {"project": "GoodTwo", "start_time": "2026-06-11T14:00:00-03:00", "end_time": "2026-06-11T15:00:00-03:00", "duration_seconds": 3600, "notes": "", "duration_only": 0, "session_date": ""}
]}
EOF
printf 'yes\n' | ./focus import "$SANDBOX/newline-import.json" >/dev/null 2>&1
chk "JSON import: newline in project doesn't abort the rest" "3" "$(cnt)"
chk "JSON import: newline sanitized to a space, not dropped" "1" \
    "$(sqlite3 "$REFOCUS_DB_PATH" "SELECT COUNT(*) FROM sessions WHERE project='bad name';")"

# ── report range: session_date boundary, positive UTC offset ───────────────────
# _range_where used to wrap session_date in sqlite's date(), which converts
# its argument to UTC first. For a timezone ahead of UTC, local midnight
# ("...T00:00:00+10:00") becomes UTC the PREVIOUS day ("...T14:00:00Z"), so
# date() returned yesterday — shifting the whole "today" boundary back a day
# and leaking yesterday's duration-only session into it. substr just reads
# the date already written in the string; no timezone interpretation.
echo "── report range: session_date boundary (positive UTC offset) ──"
bash -c "source env.sh; source services/database.sh; record_duration_session 'range-today' 3600 '2026-08-19' ''" >/dev/null
bash -c "source env.sh; source services/database.sh; record_duration_session 'range-yesterday' 3600 '2026-08-18' ''" >/dev/null
out=$(bash -c "
    source env.sh; source services/database.sh
    _query \"SELECT project FROM sessions WHERE \$(_range_where '2026-08-19T00:00:00+10:00' '2026-08-19T23:59:59+10:00');\"
")
chk "range@+10:00: today's session included"    "0" "$([[ "$out" == *"range-today"*     ]]; echo $?)"
chk "range@+10:00: yesterday's session excluded" "0" "$([[ "$out" != *"range-yesterday"* ]]; echo $?)"

# ── duplicate sessions: one project name, one row [#36] ───────────────────────
# Two rows with the same project name and overlapping clock times are
# indistinguishable in a report. Every write path now offers to fold the new
# time into the row that already holds the name instead of adding a second one.
echo "── duplicates: fold into the original [#36] ──"
./focus enable >/dev/null 2>&1 || true

_notes_of() { sqlite3 "$REFOCUS_DB_PATH" "SELECT notes FROM sessions WHERE project='$1';"; }
_rows_of()  { sqlite3 "$REFOCUS_DB_PATH" "SELECT COUNT(*) FROM sessions WHERE project='$1';"; }

printf 'first\n' | ./focus past add dup/add 2026/06/20-10:00 2026/06/20-11:00 >/dev/null 2>&1

# Declining writes nothing at all.
printf 'n\n' | ./focus past add dup/add 2026/06/20-12:00 2026/06/20-13:00 >/dev/null 2>&1
chk "add@dup declined: rc=0"        "0"    "$?"
chk "add@dup declined: no new row"  "1"    "$(_rows_of dup/add)"
chk "add@dup declined: dur untouched" "3600" "$(dur dup/add)"

# Accepting folds: one row, summed duration, and the timestamps the fold drops
# are written into the note instead.
printf 'y\nsecond\n' | ./focus past add dup/add 2026/06/20-12:00 2026/06/20-13:00 >/dev/null 2>&1
chk "add@dup folded: still one row"  "1"    "$(_rows_of dup/add)"
chk "add@dup folded: durations sum"  "7200" "$(dur dup/add)"
chk "add@dup folded: now duration-only" "1" \
    "$(sqlite3 "$REFOCUS_DB_PATH" "SELECT duration_only FROM sessions WHERE project='dup/add';")"
chk "add@dup folded: note carries both spans" "second

Original start time: 2026-06-20 10:00
Original stop time: 2026-06-20 11:00
New start time: 2026-06-20 12:00
New stop time: 2026-06-20 13:00" "$(_notes_of dup/add)"

# A second fold has no "Original" pair left to preserve — that row gave its
# timestamps up on the first one — so only the incoming span is appended.
printf 'y\nthird\n' | ./focus past add dup/add 2026/06/21-08:00 2026/06/21-09:30 >/dev/null 2>&1
chk "add@dup refolded: durations sum" "12600" "$(dur dup/add)"
chk "add@dup refolded: only the new span appended" "third

New start time: 2026-06-21 08:00
New stop time: 2026-06-21 09:30" "$(_notes_of dup/add)"

# `past add --duration` has no timestamps to contribute; it folds its length in
# and leaves the trail alone.
printf 'dur-first\n' | ./focus past add dup/duronly --duration 1h --date 2026/06/20 >/dev/null 2>&1
printf 'y\ndur-second\n' | ./focus past add dup/duronly --duration 30m --date 2026/06/21 >/dev/null 2>&1
chk "add --duration@dup: one row"       "1"    "$(_rows_of dup/duronly)"
chk "add --duration@dup: durations sum" "5400" "$(dur dup/duronly)"
chk "add --duration@dup: no timestamp trail" "dur-second" "$(_notes_of dup/duronly)"

# focus off: declining leaves the clock running — the name was fixed at
# `focus on`, so there is nothing else to correct here.
./focus on dup/live >/dev/null 2>&1
printf 'live one\n' | ./focus off >/dev/null 2>&1
./focus on dup/live >/dev/null 2>&1
printf 'n\n' | ./focus off >/dev/null 2>&1
chk "off@dup declined: rc=0"           "0" "$?"
chk "off@dup declined: still active"   "1|0|0|dup/live" "$(st)"
chk "off@dup declined: no second row"  "1" "$(_rows_of dup/live)"

printf 'y\nlive two\n' | ./focus off >/dev/null 2>&1
chk "off@dup accepted: idle"           "0|0|0|-" "$(st)"
chk "off@dup accepted: still one row"  "1" "$(_rows_of dup/live)"

# past modify renaming onto a name another row holds folds the two together
# and removes the row being edited.
printf 'to-merge\n' | ./focus past add dup/source 2026/06/22-10:00 2026/06/22-12:00 >/dev/null 2>&1
sid=$(sqlite3 "$REFOCUS_DB_PATH" "SELECT id FROM sessions WHERE project='dup/source';")
printf 'y\nmerged\n' | ./focus past modify "$sid" dup/add >/dev/null 2>&1
chk "modify@dup: rc=0"                "0" "$?"
chk "modify@dup: source row removed"  "0" "$(_rows_of dup/source)"
chk "modify@dup: target absorbed it"  "19800" "$(dur dup/add)"

printf 'keep-me\n' | ./focus past add dup/keep 2026/06/22-14:00 2026/06/22-15:00 >/dev/null 2>&1
kid=$(sqlite3 "$REFOCUS_DB_PATH" "SELECT id FROM sessions WHERE project='dup/keep';")
printf 'n\n' | ./focus past modify "$kid" dup/add >/dev/null 2>&1
chk "modify@dup declined: rc=0"       "0" "$?"
chk "modify@dup declined: row intact" "1" "$(_rows_of dup/keep)"
chk "modify@dup declined: target untouched" "19800" "$(dur dup/add)"

# A bare `modify <id> --notes` changes neither name nor timing, so it must not
# ask about duplicates — even when the name really is duplicated (rows that
# predate the rule, or arrived by import).
sqlite3 "$REFOCUS_DB_PATH" "INSERT INTO sessions (project, start_time, end_time, duration_seconds, notes, duration_only)
    VALUES ('dup/legacy', '2026-06-23T10:00:00-03:00', '2026-06-23T11:00:00-03:00', 3600, 'a', 0),
           ('dup/legacy', '2026-06-23T12:00:00-03:00', '2026-06-23T13:00:00-03:00', 3600, 'b', 0);"
lid=$(sqlite3 "$REFOCUS_DB_PATH" "SELECT MIN(id) FROM sessions WHERE project='dup/legacy';")
printf 'rewritten\n' | ./focus past modify "$lid" --notes >/dev/null 2>&1
chk "modify --notes@dup: rc=0"          "0" "$?"
chk "modify --notes@dup: no fold"       "2" "$(_rows_of dup/legacy)"
chk "modify --notes@dup: note rewritten" "rewritten" \
    "$(sqlite3 "$REFOCUS_DB_PATH" "SELECT notes FROM sessions WHERE id=$lid;")"

# notes_merge_trail is pure string work: empty timestamps drop out entirely, so
# a fold with nothing to preserve returns the note untouched.
chk "notes_merge_trail: no timestamps, note unchanged" "just a note" \
    "$(bash -c "source core/text.sh; notes_merge_trail 'just a note' '' '' '' ''")"
chk "notes_merge_trail: empty note keeps no leading blank line" "New start time: A
New stop time: B" \
    "$(bash -c "source core/text.sh; notes_merge_trail '' '' '' 'A' 'B'")"

# ── result ───────────────────────────────────────────────────────────────────
echo
total=$(( pass + fail ))
echo "RESULT: $pass/$total passed"
[[ $fail -eq 0 ]]
