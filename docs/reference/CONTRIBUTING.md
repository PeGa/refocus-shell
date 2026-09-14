# Contributing

Refocus is contract-driven. The contract (`CONTRACTS/MAIN.md`) is the authority; the tests are the verifier. Contributors are executors — when the contract, the tests, and local judgment disagree, the contract wins.

Read `CONTRACTS/START_HERE.md` before your first change. It's the digest.

---

## Build order

Dependencies run bottom-up. Don't implement step N before step N−1 exists and passes the test suite.

```
 1. tests/audit.sh                  shellcheck wrapper; the oracle exists first
 2. env.sh                          no deps; exports DB_PATH, NUDGE_INTERVAL, etc.
 3. services/database.sh            deps: env.sh; the ONLY file that speaks SQL
 4. core/time.sh                    pure functions; owns the GNU/BSD date(1) split
 4b. core/text.sh                   pure functions; decodes/indents stored notes
 4c. services/help.sh               renders docs/help/<cmd>.txt
 4d. services/editor.sh             captures notes through $EDITOR
 5. services/cron.sh                deps: env.sh
 6. focus (dispatcher)              skeleton: set REFOCUS_ROOT, exec lib/$1.sh
 7–21. lib/*.sh                     handlers, one per command (see order in AGENTS.md)
22. focus-nudge                     self-contained; sources env+db+time independently
23. focus-checkin                   self-contained; sources env+db+time independently
24. services/focus-function.sh      prompt hook + focus() wrapper
25. setup.sh                        install/uninstall; arms cron on fresh install
26. tests/state-matrix.sh           full behavioural oracle
27. tests/time-portability.sh       GNU/BSD date(1) portability probe
```

---

## Naming conventions

| Prefix       | Meaning                                                       |
|--------------|---------------------------------------------------------------|
| `db_*`       | schema lifecycle and serialization only (`db_init`, `db_dump_sql`) — not for domain work |
| `is_*`       | boolean predicates, exit status (0 = true)                    |
| `get_*` / `list_*` | reads, output to stdout                                 |
| verbs        | mutations (`start_session`, `pause_session`, `set_focus_disabled`) |
| `_name`      | private to the file; never called externally                  |

Do not shadow shell builtins. (`enable`, `reset`, `type`, `test` are builtins — domain concepts live in `lib/enable.sh` etc., not as functions named `enable`.)

---

## Test-authoring norms

- **Capture-then-match.** Never pipe into `grep -q` under `pipefail` — the upstream command gets SIGPIPE when `grep -q` exits early. Capture output first, then match:
  ```bash
  # Bad: SIGPIPE risk
  chk "description" "0" "$(command | grep -q 'pattern'; echo $?)"

  # Good: capture first
  local output
  output="$(command)"
  chk "description" "0" "$([[ "$output" == *pattern* ]]; echo $?)"
  ```

- **Fixtures through the app's gears.** Use `parse_time`, `cycle_label`, etc. to build test data. Hand-crafted timestamps may not match what the app actually stores.

- **Determinism by config-coarsening.** Match on coarse keys (year, project name), not exact timestamps. Tests that match `"2025-09-05 14:30"` fail when run at 14:31. Set `DATE_SHORT_FORMAT='%Y'` or match on stable identifiers.

---

## One concern per change

One file per task. One concern per change. Do not touch files not named in the current task, even if they look like they need updating.

---

## Drift detection

Run at session start and every 5 commits:

```bash
# INV-1: only the adapter speaks SQL
grep -rl sqlite3 lib/ core/ focus focus-nudge focus-checkin services/cron.sh \
     services/focus-function.sh env.sh 2>/dev/null

# DM-DEAD: dead symbols must not reappear
grep -rn '^[^#]*\(nudging_enabled\|pause_notes\|\bprojects\b\|focus describe\|nudge enable\|nudge disable\|db_flip_flag\|db_nudging_on\|db_is_active\|db_is_paused\|db_is_disabled\)' \
     lib/ services/ core/ focus focus-nudge focus-checkin 2>/dev/null

# CONV-HELP: help text lives in docs/, never inline in a handler
grep -rn '"Usage:' lib/ focus focus-nudge focus-checkin 2>/dev/null

# CONV-PORTABLE: only core/time.sh calls date(1), nobody uses GNU-only flags,
# nobody uses sed -i, nobody uses declare -A (macOS ships bash 3.2)
grep -rn '^[^#]*\(date --date\|date -d \|date +%s\|date -Iseconds\)' \
     lib/ services/ focus focus-nudge focus-checkin env.sh 2>/dev/null
grep -rn '^[^#]*sed -i' lib/ services/ core/ focus focus-nudge focus-checkin setup.sh 2>/dev/null
grep -rn '^[^#]*declare -A' lib/ services/ core/ focus focus-nudge focus-checkin 2>/dev/null
```

All four must return no output. If any returns output, fix the violation before proceeding.

---

## Commit discipline

- Commit after every task that passes the oracle. Not before. Not in batches.
- Commit message format: `feat(lib): implement pause.sh [INV-4]` — scope in parens, one-line summary, cite the governing invariant if relevant.
- If a file is corrupt or a test regresses: `git diff`, `git checkout -- <file>`, re-implement from scratch with the spec. Do not patch a broken file into shape.

---

## Conflict resolution

If the contract and the acceptance oracle cannot be satisfied simultaneously:

1. Stop.
2. State the exact conflict: which rule, which file, which test assertion.
3. Do not pick one silently.
4. Do not work around it with a local hack.
5. Wait for the human to resolve the conflict in the contract or the test.

The contract is the authority. The oracle is the verifier. You are the executor. When those three disagree, the executor defers — always.
