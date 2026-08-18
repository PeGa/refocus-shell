#!/usr/bin/env bash
# Refocus Shell - Time layer portability probe
#
# Usage: tests/time-portability.sh [root-dir]
#
# core/time.sh has a GNU branch and a BSD branch, and CI only ever exercises
# one of them. This runs the public time API against whichever date(1) is on
# the box and checks the results agree with each other.
#
# On macOS run it TWICE — once with `gdate` on PATH (brew install coreutils)
# and once without — because time.sh prefers gdate when it exists, so a green
# run with coreutils installed says nothing about the BSD branch.
#
# Exit 0 = all passed. Exit 1 = failures.

set -uo pipefail

ROOT="${1:-$(dirname "$(realpath "${BASH_SOURCE[0]}")")/../}"
cd "$ROOT" || exit 1
source core/time.sh

pass=0; fail=0
chk() {
    local desc="$1" expected="$2" actual="$3"
    if [[ "$expected" == "$actual" ]]; then
        pass=$(( pass + 1 )); echo "  ✓  $desc"
    else
        fail=$(( fail + 1 )); echo "  ✗  $desc"
        echo "       expected: $expected"
        echo "       actual:   $actual"
    fi
}
ok() {  # ok <desc> <command...> — passes if the command succeeds
    local desc="$1"; shift
    if "$@" >/dev/null 2>&1; then
        pass=$(( pass + 1 )); echo "  ✓  $desc"
    else
        fail=$(( fail + 1 )); echo "  ✗  $desc  (exit $?)"
    fi
}

echo "── environment ──"
echo "  uname:        $(uname -s)"
if [[ "$_DATE_IS_GNU" == "1" ]]; then impl="GNU"; else impl="BSD"; fi
echo "  date impl:    $impl"
echo "  gdate:        $(command -v gdate || echo '(absent)')"
echo "  bash:         $BASH_VERSION"

echo "── round-trips ──"
now_e=$(now_epoch)
chk "now_epoch is an integer" "0" "$([[ "$now_e" =~ ^[0-9]+$ ]]; echo $?)"

iso=$(now_iso)
chk "now_iso parses back"     "0" "$([[ "$(iso_to_epoch "$iso")" =~ ^[0-9]+$ ]]; echo $?)"

# The stored format is whatever now_iso emits; epoch -> iso -> epoch must be
# lossless to the second, or durations drift.
rt=$(iso_to_epoch "$(epoch_to_iso "$now_e")")
chk "epoch -> iso -> epoch"   "$now_e" "$rt"

chk "epoch_format Y-m-d"      "$(epoch_format "$now_e" '%Y-%m-%d')" "$(ts_format "$(epoch_to_iso "$now_e")" '%Y-%m-%d')"

echo "── documented input formats (docs/help/past.txt) ──"
ok  "YYYY/MM/DD-HH:MM"        parse_time "2026/06/11-14:30"
ok  "YYYY-MM-DD HH:MM"        parse_time "2026-06-11 14:30"
ok  "bare HH:MM"              parse_time "14:30"
chk "YYYY/MM/DD-HH:MM is 14:30" "14:30" "$(ts_format "$(parse_time '2026/06/11-14:30')" '%H:%M')"
chk "same instant either way"   "$(iso_to_epoch "$(parse_time '2026/06/11-14:30')")" \
                                "$(iso_to_epoch "$(parse_time '2026-06-11 14:30')")"

echo "── relative forms (GNU only; must fail cleanly on BSD) ──"
if [[ "$_DATE_IS_GNU" == "1" ]]; then
    ok  "'2 hours ago'"       parse_time "2 hours ago"
    ok  "'yesterday 14:00'"   parse_time "yesterday 14:00"
else
    parse_time "2 hours ago" >/dev/null 2>&1
    chk "'2 hours ago' exits 1, not garbage" "1" "$?"
    msg=$(parse_time "2 hours ago" 2>&1 >/dev/null)
    chk "error names coreutils" "0" "$([[ "$msg" == *coreutils* ]]; echo $?)"
fi

echo "── period boundaries (used by focus report) ──"
ok  "iso_days_ago 0"          iso_days_ago 0
ok  "iso_days_ago 7"          iso_days_ago 7
ok  "iso_month_start"         iso_month_start
chk "days_ago 0 is midnight"  "00:00:00" "$(ts_format "$(iso_days_ago 0)" '%H:%M:%S')"
chk "days_ago 7 is 7 days before days_ago 0" "604800" \
    "$(( $(iso_to_epoch "$(iso_days_ago 0)") - $(iso_to_epoch "$(iso_days_ago 7)") ))"
chk "month_start is day 01"   "01" "$(ts_format "$(iso_month_start)" '%d')"

echo "── past add --date parsing ──"
ok  "parse_date_to_fmt today"       parse_date_to_fmt "today"      "%Y-%m-%d"
ok  "parse_date_to_fmt YYYY/MM/DD"  parse_date_to_fmt "2026/06/11" "%Y-%m-%d"
chk "YYYY/MM/DD -> ISO date" "2026-06-11" "$(parse_date_to_fmt '2026/06/11' '%Y-%m-%d')"

echo
total=$(( pass + fail ))
echo "RESULT: $pass/$total passed"
[[ $fail -eq 0 ]]
