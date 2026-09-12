# CONTRACT_RECONCILE.md — working ledger for the app↔contract reconciliation (#47)

> **Not the authority.** MAIN.md is. This file stages the reconciliation: norms
> the app grew that the contract has not sanctioned yet, each with its status
> and the material needed to settle it. Items graduate into MAIN.md (+
> CONTRACT_INDEX regeneration, same commit) as they are settled, and are struck
> from here. When this file is empty, #47 is closable.

---

## Settled and landed

| Item | Rule as landed | Where |
|---|---|---|
| A1 — adapter ignorance | `PORT-VOCAB`: the adapter never hardcodes domain vocabulary; literals arrive as arguments | MAIN.md [PORT] |
| A2 — the naming line | `NAME-UNDERSCORE` (the `_` is a tool with a place: file-private functions, module constants, throwaway single-use vars inside private scope; never a license for cryptic names) + `NAME-BREVITY` (intent at length budget; allowlist `id rc n lo hi`; oracle-enforced; test helpers intent-named without the prefix) | MAIN.md [NAME] |
| A3 — one literal, one file | `CORE-LITERAL`: domain literals live once in core/text.sh, handed out by functions | MAIN.md [CORE-TEXT] |
| A5 — error taxonomy | CONV-EXIT refined: malformed shape → 2; well-formed but absent → 1; decline → 0. Verified pre-existing since the initial release (`75ed4d5`) — names practice, makes no new law | MAIN.md [CONV] |
| A8 — damaged-data quarantine | `CONV-ABSENT`, matured through challenge: three boundaries, one law — the time layer refuses empty identically on both platforms (CORE-DATE amended); renderers name the absence (`(no timestamps)`, `unknown`, no fabricated recency) while unbounded/id-window views keep the row listed and its duration counted; JSON import rejects shapes no write path can produce (loud, atomic, pre-swap) and sanitises representable oddities per row. The app **repairs nothing** — a migrator, if it ever exists, is external. Boundary taxonomy (settled via the `\|` challenge, citing MAIN.md's existing import ruling): conflictive-but-representable → transform at the boundary (`\|`→`¦`); impossible-and-unrepresentable → refuse; already-resident → render honestly. App batch shipped: `iso_to_epoch` empty refusal, renderer markers (past/report/status), import shape validation; +8 matrix, +2 tp | MAIN.md [CONV]/[CORE-TIME]/[CMD-IMPORT] |
| A4 — two-face validation | CONV-ID amended: handler face = UX (shape-check before parse/render, rc=2, human message); adapter face = structural (`_require_uint` at every bare-number interpolation site). WHY both: INV-1's chokepoint must defend itself; handler-only outsources integrity to every caller forever (#51), adapter-only answers typos in a storage-layer voice. Sweep shipped: 10 adapter functions guarded — including `get_session_by_project`'s `id<>$exclude`, found during the sweep; +4 matrix abuse checks (non-destructive payloads: a vanished guard fails as rc≠2, never as eaten fixtures) | MAIN.md [CONV] |

---

## Pending brainstorm

### A6 — Derived-data discipline (receipts)
The cycle label is a receipt derived from timestamps: regenerated at *write*
time, never recomputed at read time; every mutation path regenerates dependents
(`--edit-time` cascades into the next break; `delete` re-anchors to the nearest
survivor); the invariant has exactly one implementation (`_cycle_neighbours` +
`_relabel_break`). Must be stated *against* DM-SESSION (stored duration is
authoritative, never recomputed) so derived-vs-recorded reads as one coherent
rule, not a contradiction. Material: `8344189` (five-bug crawl), `lib/cycle.sh`.
Status: no pushback — full understanding requested first.

### A7 — Provenance ordering (id windows)
Challenge to answer: "there isn't any mixed-kind windowing." The mixed kinds
are timestamped sessions vs duration-only rows (date, no clock time): a
*timestamp* boundary falling inside a duration-only row's day put it on both
sides — the double-count periods were built to kill. Id windows make
membership total because every row has exactly one id. Material:
`services/period.sh` header; matrix "boundary-day manual row" checks.

### A9 — Two-tier confirmation  ⟵ PUSHBACK
Literal `yes` for irreversible (CONV-YES: reset/import); `y/N` default-no for
recoverable replacement (cycle add replace-prompt, cycle delete). **User
position: app drift — CONV-YES as written was violated.** The honest fork:
either CONV-YES gains a tier (destructive-to-the-database vs
destructive-to-one-row) or `cycle delete` must demand the literal `yes`.
Material: CONV-YES text and rationale (blast radius); `lib/cycle.sh` prompts.

### A10 — Service-promotion rule
Two handlers needing one rule ⇒ a service, not a copy (`merge.sh`,
`period.sh`); duplication reserved for trivial guards; services don't source —
they document scope assumptions. Status: understood-in-principle, full picture
requested. Material: `services/period.sh` + `services/merge.sh` headers; #48's
history (guard duplicated → predicate shared, refusal stays local).

### A11 — Dead-knob rule
Every config key has a live reader; a knob controlling nothing gets removed,
not left lying. Material: `b14d669` (REPORT_LIMIT removal); adjacent debt #40.

### A12 — Three oracles + oracle-as-enforcer
`tests/time-portability.sh` is absent from BUILD-VERIFY/ACCEPT/ARCH (both say
"both test scripts"). Principle behind the naming guard: a convention the
oracle can grep belongs in the oracle, not prose alone. Material: BUILD-VERIFY,
ACCEPT 1–2, ARCH tests line, AGENTS.md §1/§5.

### A13 — Test-authoring norms
Capture-then-match, never pipe into `grep -q` (SIGPIPE→141 under pipefail);
fixtures built through the app's own gears (`parse_time`/`cycle_label`) so
stored shape matches reality; determinism by config-coarsening
(DATE_SHORT_FORMAT→`%Y`) instead of racing clocks. Material: BUILD-VERIFY
("stable keys" only, today); the periods-batch SIGPIPE incident.

---

## B. Taxonomy gap the contract must settle (this is the "guide in spirit" part)

services/ now holds two different species: mechanism adapters (database, cron,
editor, desktop, help — each talks to one external thing) and domain composers
(merge.sh, period.sh — compose adapter reads + domain rules, touch no
mechanism, assume the caller's source scope). START_HERE §3 labels all
five-plus "SECONDARY adapter," which is why period.sh's placement was a
judgment call instead of a rule application. Recommendation: define the
subcategory in ARCH (composer: no mechanism of its own, documents scope
assumptions, never sourced by another service) rather than move files — the
next shared-rule file should land by rule, not by precedent.
*(Overlaps A10 — settle together.)*

## C. Where the app is behind and the contract must NOT deform

For these, the reconciliation writes the *mature* rule and leaves the issue
open as app debt — contract leads, app follows:

- #40 config unset false success → contract states: unset of an unknown key is
  a usage error
- #43 MAX_PROJECT_LENGTH on one write path of three → contract states:
  enforced on every path that takes a project name
- #42 prompts abort at EOF → contract states: EOF at a prompt is a decline
  (exit 0), never an abort
- #41 crontab read ambiguity → CRON-STRIP gains the fail-closed intent
  (unreadable ≠ empty)
- #44 enable's idempotent message on stderr → contract states: stdout is the
  success channel
- #28 report tests match substrings across lines → already covered by
  BUILD-VERIFY's spirit; stays test debt

Writing these as-is will make ACCEPT temporarily describe behavior the app
doesn't have — that's deliberate, and each gets a `(app debt: #NN)` marker so
the contract doesn't lie about *verification* while telling the truth about
*intent*.

## D. Deliberately NOT contractualized

Message voice and emoji vocabulary, boundary-glyph aesthetics, "Current cycle"
label wording, receipt prose — UI texture lives in help docs. One exception:
the `Cycle break. Period:` prefix *is* contract (it's the identification
mechanism, DM-CYCLE).

---

## Deferred non-A scope (direction settled elsewhere, not yet written)

- **The #47 core**: `DM-CYCLE` + `CMD-CYCLE` + `CMD-PERIOD` clauses; the
  stale-text inventory — [PORT] reads (`list_cycles`,
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
- **#45** folds into the above (its 5 items are all listed).
- **START_HERE.md sync**: §1 DM rows (cycles table/kind column;
  period-as-time-window), §3 map (+3 services), §5 CONV-PORTABLE narrowing,
  §7 third oracle, naming-line digest.
- **AGENTS.md**: §5 DM-DEAD grep comment-skip (`^[^#]*`), §2 build-order
  additions, oracle wording.

## Process rules for this workstream

- Every MAIN.md edit ships with a regenerated CONTRACT_INDEX **in the same
  commit** (the index's own header rule). Regeneration is script-assisted
  (band-shift + grep anchors), then machine-validated: every row must resolve
  (validator pattern: 94 rows, 0 failures as of this writing).
- No clause written from memory: every claim re-verified against code at write
  time (Phase 0 discipline).
- Commits land in reviewable slices, not one 250-line prose bomb.
