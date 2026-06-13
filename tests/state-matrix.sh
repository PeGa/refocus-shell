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

# ── result ───────────────────────────────────────────────────────────────────
echo
total=$(( pass + fail ))
echo "RESULT: $pass/$total passed"
[[ $fail -eq 0 ]]
