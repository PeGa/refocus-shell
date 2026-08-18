# AGENTS.md — refocus-shell agentic build protocol

> Process layer for agentic tooling. Auto-loaded by opencode and compatible agents.
> Covers HOW to build — task discipline, build order, verification, drift detection.
> Domain constraints live in `CONTRACTS/START_HERE.md`. Load both before acting.

---

## 0 · Session start (mandatory)

Before any action in a session:

1. Read `CONTRACTS/START_HERE.md` in full — the digest.
2. Read this file in full.
3. Read only the files named in the current task — not the whole repo.

`CONTRACTS/MAIN.md` is the authority; `CONTRACTS/CONTRACT_INDEX.md` indexes it by
handle. Expand a handle there when the digest is not enough.

If any of these files is missing, stop and say so. Do not infer their content.

---

## 1 · Prime directives

- **One file per task.** One concern per change. Do not touch files not named in
  the current task, even if you think they need updating.
- **Run the oracle before declaring done.** Every task ends with
  `bash tests/audit.sh`. Report its exit code and stderr. A task is not done
  until the oracle exits 0.
- **Read before writing.** Use the file-read tool on any file you are about to
  edit. Your in-context version may be stale.
- **No whole-file regeneration through escaping layers.** No heredoc inside
  `python -c`, no `echo`-assembled scripts. Surgical edits to exact strings, or
  direct file writes. Mangled backslashes and dropped UTF-8 glyphs pass shellcheck
  and break at runtime. `[BUILD-NO-REGEN]`

---

## 2 · Build order

Dependencies run bottom-up. Do not implement step N before step N−1 exists and
passes `tests/audit.sh`.

```
 1. tests/audit.sh                  shellcheck wrapper; the oracle exists first
 2. env.sh                          no deps; exports DB_PATH, NUDGE_INTERVAL, etc.
 3. services/database.sh            deps: env.sh; the ONLY file that speaks SQL [INV-1]
 4. core/time.sh                    pure functions; no deps; fmt/parse duration+time
                                    owns the GNU/BSD date(1) split [CONV-PORTABLE]
 4b. core/text.sh                   pure functions; decodes/indents stored notes
 4c. services/help.sh               renders docs/help/<cmd>.txt [CONV-HELP]
 4d. services/editor.sh             captures notes through $EDITOR
 5. services/cron.sh                deps: env.sh
 6. focus (dispatcher)              skeleton: set REFOCUS_ROOT, exec lib/$1.sh $@
 7. lib/enable.sh                   first handler; exercises cron + db boundary
 8. lib/disable.sh
 9. lib/on.sh                       most logic-dense handler; typo guard, last project
10. lib/off.sh                      note capture + record_session; first full cycle
11. lib/pause.sh                    INV-4 enforced: silent, no prompt, no notes
12. lib/continue.sh                 previous_elapsed math; common arithmetic failure point
13. lib/status.sh
14. lib/past.sh                     most complex arg parsing; CONV-DURONLY strictly
15. lib/report.sh
16. lib/config.sh
17. lib/reset.sh
18. lib/import.sh
19. lib/export.sh
20. lib/init.sh
21. lib/help.sh + docs/help/*.txt   thin wrapper over services/help.sh
22. focus-nudge                     self-contained; sources env+db+time independently
23. services/focus-function.sh      prompt hook + focus() wrapper
24. setup.sh                        install/uninstall; arms cron on fresh install
25. tests/state-matrix.sh           full behavioral oracle; written after all lib/ exists
```

---

## 3 · Per-task format

The human provides tasks in this shape. Honour every field:

```
Task: implement lib/<name>.sh

Constraints:
- Read CONTRACTS/START_HERE.md §N for relevant invariants.
- Source order: env.sh → services/database.sh → [core/time.sh if needed] → db_ensure.
- Calls permitted: [explicit list of intent functions]
- No sqlite3 calls. No db_* domain calls. [INV-1] [INV-2]
- Exit codes: 0 success / 1 state error / 2 usage error. [CONV-EXIT]
- After writing, run: bash tests/audit.sh
  Report exit code and full stderr before responding.

Do not touch any other file.
```

If the task spec is ambiguous, ask for clarification before writing a single line.
Do not infer unstated scope.

---

## 4 · Naming rules (summary — full spec in CONTRACTS/START_HERE.md §3 and [NAME])

- `db_*` — schema lifecycle and serialization only (`db_init`, `db_dump_sql`, etc.).
  Not for domain work.
- `is_*` — boolean predicates, exit status (0 = true).
- `get_*` / `list_*` — reads, output to stdout.
- Verbs (`start_session`, `pause_session`, `set_focus_disabled`) — mutations.
- `_name` — private to the file; never called externally.
- Do not shadow shell builtins. (`enable`, `reset`, `type`, `test` are builtins —
  domain concepts live in `lib/enable.sh` etc., not as functions named `enable`.)

---

## 5 · Drift detection (run at session start and every 5 commits)

```bash
# INV-1: only the adapter speaks SQL
grep -rl sqlite3 lib/ core/ focus focus-nudge services/cron.sh \
     services/focus-function.sh env.sh 2>/dev/null
# Expected: no output

# DM-DEAD: dead symbols must not reappear
grep -rn "nudging_enabled\|pause_notes\|\bprojects\b\|focus describe\|nudge enable\|nudge disable\|db_flip_flag\|db_nudging_on\|db_is_active\|db_is_paused\|db_is_disabled" \
     lib/ services/ core/ focus focus-nudge 2>/dev/null
# Expected: no output

# CONV-HELP: help text lives in docs/, never inline in a handler.
# services/help.sh is exempt — it owns the no-doc-found fallback.
grep -rn '"Usage:' lib/ focus focus-nudge 2>/dev/null
# Expected: no output

# CONV-PORTABLE: only core/time.sh calls date(1), nobody uses GNU-only `sed -i`
# or a `;`-terminated `t` label, and nobody uses `declare -A` — macOS ships
# bash 3.2, which has no associative arrays; `focus report` had zero working
# subcommands on macOS until this was enforced. All three skip comment lines,
# so the notes explaining a rule don't trip the check that enforces it.
grep -rn '^[^#]*\(date --date\|date -d \|date +%s\|date -Iseconds\)' \
     lib/ services/ focus focus-nudge env.sh 2>/dev/null
grep -rn '^[^#]*sed -i' lib/ services/ core/ focus focus-nudge setup.sh 2>/dev/null
grep -rn '^[^#]*declare -A' lib/ services/ core/ focus focus-nudge 2>/dev/null
# Expected: no output for all three
```

If either returns output, stop, fix the violation, rerun before proceeding.
Do not carry drift forward into the next task.

---

## 6 · Commit discipline

- Commit after every task that passes the oracle. Not before. Not in batches.
- Commit message format: `feat(lib): implement pause.sh [INV-4]`
  — scope in parens, one-line summary, cite the governing invariant if relevant.
- If a file is corrupt or a test regresses: `git diff`, `git checkout -- <file>`,
  re-implement from scratch with the spec. Do not patch a broken file into shape.

---

## 7 · Conflict resolution

If you cannot satisfy `CONTRACTS/START_HERE.md` and the acceptance oracle simultaneously:

1. Stop.
2. State the exact conflict: which rule, which file, which test assertion.
3. Do not pick one silently.
4. Do not work around it with a local hack.
5. Wait for the human to resolve the conflict in the contract or the test.

The contract is the authority. The oracle is the verifier. You are the executor.
When those three disagree, the executor defers — always.
