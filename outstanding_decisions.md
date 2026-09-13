# outstanding_decisions.md — decisions parked, not yet executed

> This file records decisions made in conversation that are not yet committed
> to the contract or the code. It is a staging ground; items graduate into
> CONTRACTS/ (or are dropped) when the work executes. Not the authority —
> MAIN.md is.

---

## Decided (pending execution)

### A6 — dissolved, with corrected vocabulary

A6 is **not** a new contract clause. The ontology "measurement vs projection,"
"recompute," "window" — all fabricated. The domain is:

- A cycle break is a single point in time.
- Its label is a note written at creation: the previous point's date (read
  from there) + `now()`.
- When a point moves or is deleted, the notes that name it are rewritten from
  the points; no code ever reads a date out of a note.

A6's entire contract content is two sentences that join the *deferred* cycle
clauses (DM-CYCLE / CMD-CYCLE) when they are written. No new handle, no
taxonomy, no meta-rule about future denormalized fields.

The two known edges (past-modify re-times a break with no note rewrite — the
declined guard; replace-on-collision re-inserts with a new id) record as
known-gap lines in the same deferred clause.

The behavior already conforms — the code was built from this model. Nothing
to undo.

### Vocabulary discipline queued for #47

- One shipped phrase to fix: "id-window period views" in CONV-ABSENT
  (MAIN.md:785) → "the period listings".
- CMD-PERIOD, when written, uses the spec language ("the events between that
  break and the next"). The id-ordering mechanism appears once, as an
  implementation note carrying the duration-only WHY — never as a domain noun.
- Ledger entries (A6, A7, A8 in CONTRACT_RECONCILE.md) get the same
  vocabulary pass.
- Code identifiers (`get_period_window`) stay — implementation vocabulary,
  renaming for metaphor is churn.

### A7 — dissolved, ordering is enhancement

Session date is authoritative for when work happened. Id-based ordering is a
valid before/after signal; time-based ordering also works. The choice is about
presentation neatness, not correctness. Enhancement issue #57 for `--order`
parameter or config entry. No contract clause needed.

### A9 — landed, CONV-YES gains a tier

Two-tier confirmation: app-wide destructive ops (`reset`, `import`) require
literal `yes`; simple/recoverable ops (cycle delete, cycle add replace-prompt)
use `y/N` default-no. Landed in MAIN.md CONV-YES definition. App already
matches — no code changes needed.

### A10 — landed, services taxonomy settled

Three-tier taxonomy: **infrastructure** (database, cron — essential), **integration**
(desktop, editor, help — optional), **composer** (merge, period — domain logic, no
mechanism). ARCH-COMPOSER added: when two handlers need the same domain rule, it
becomes a composer service, not a copy. Landed in START_HERE §3 and MAIN.md ARCH.

---

## Pending (still to be decided)

### A11 — Dead-knob rule

Every config key has a live reader; a knob controlling nothing gets removed,
not left lying. Material: REPORT_LIMIT removal (`b14d669`); adjacent debt #40.

### A12 — Three oracles + oracle-as-enforcer

`tests/time-portability.sh` absent from BUILD-VERIFY/ACCEPT/ARCH (both say
"both test scripts"). Principle behind the naming guard: a convention the
oracle can grep belongs in the oracle, not prose alone.

### A13 — Test-authoring norms

Capture-then-match (never pipe into `grep -q` under pipefail — SIGPIPE→141);
fixtures built through the app's own gears (`parse_time`/`cycle_label`) so
stored shape matches reality; determinism by config-coarsening
(DATE_SHORT_FORMAT→`%Y`) instead of racing clocks.

---

## Deferred #47 scope (not yet written)

- DM-CYCLE + CMD-CYCLE + CMD-PERIOD clauses (cycle vocabulary in spec terms
  per the vocabulary discipline; A6's two sentences fold into DM-CYCLE /
  CMD-CYCLE).
- Stale-text inventory: [PORT] reads (`list_cycles`,
  `list_sessions_by_id_range`, `get_project_totals_by_id_range`,
  `get_last_cycle_end`, `list_session_ids_by_project`; exclude params on
  `get_last_*`/totals; `list_sessions` signature), [ENV] exports
  (CHECKIN_INTERVAL in, REPORT_LIMIT out), [CORE-TEXT] surface
  (`is_session_id`, cycle vocabulary, `notes_merge_trail`), [ARCH] layer map
  (+merge/desktop/period, tests line), CMD-OFF/CMD-PAST (#36 fold), CMD-PAST
  (full-history bare list, #51 validation, `cycles` subcommands, boundary
  rendering, cycle-row truth: past modify/delete DO operate on breaks —
  rename is the exit mechanism), CMD-REPORT (markdown #39, cycle mode,
  exclusions, `unknown` bound), CMD-ON/CMD-STATUS (marker exclusion #46),
  CMD-CHECKIN/[CHECKIN] (desktop guard #35, "four exits" that are five),
  CMD-CONFIG (valid keys), CONV-PORTABLE (narrow to divergent invocations —
  7 POSIX `date +FMT` sites), [CRON] vs `4c609f8`/leading-zero fixes,
  CMD-IMPORT vs `0f91ecb`, BUILD-VERIFY/ACCEPT (three oracles).
- #45 folds into the above (its 5 items are all listed).
- START_HERE.md sync: §1 DM rows (cycles table/kind column; period-as-time-cut
  phrasing per the vocabulary discipline), §3 map (+3 services), §5
  CONV-PORTABLE narrowing, §7 third oracle, naming-line digest.
- AGENTS.md: §5 DM-DEAD grep comment-skip (`^[^#]*`), §2 build-order
  additions, oracle wording.
- App-debt clauses (#40, #41, #42, #43, #44, #28): contract states intent +
  `(app debt: #NN)` marker, issues stay open.
- Not contractualized, deliberately: message voice/emoji, boundary glyph,
  "Current cycle" label wording, note prose — UI texture lives in help docs.
  Exception: the `Cycle break. Period:` prefix (identification mechanism).

## Process rules carried over (from CONTRACT_RECONCILE.md)

- Every MAIN.md edit ships with a rebuilt CONTRACT_INDEX in the same commit;
  rebuild is anchor-based (script), then machine-validated — every row must
  resolve.
- No clause written from memory: every claim re-verified against code at
  write time.
- Commits land in reviewable slices.
