# CONTRACT_INDEX.md — refocus-shell

> Line-range index into `MAIN.md` (locked, 574 lines). Lets an agent load a
> single section or rule by range instead of the whole spec — context budget for
> small-window models, precise citation for everyone else.
>
> Ranges are inclusive and were generated against the locked contract. If
> `MAIN.md` is edited, regenerate this file; a stale index is worse than none.
> Codes are stable handles: cite `INV-3` or `CONV-DURONLY`, not a line number, in
> prose — the number is only for loading.

---

## Sections (top level)

| Code | Section | Lines |
|---|---|---|
| READ   | How to read this                         | 9–37   |
| WHAT   | What refocus-shell is                    | 39–51  |
| DM     | Domain model                             | 53–122 |
| INV    | Invariants                               | 124–179 |
| NAME   | Naming contract                          | 181–201 |
| ARCH   | Architecture & layering                  | 203–235 |
| PORT   | Adapter surface (database.sh)            | 237–285 |
| CORE   | Domain-helper surface (core/time.sh)     | 287–303 |
| ENV    | Environment loader (env.sh)              | 305–322 |
| CRON   | Nudge scheduling (cron.sh)               | 324–345 |
| CMD    | Command surface (lib/)                   | 347–440 |
| NUDGE  | Nudge payload (focus-nudge)              | 442–460 |
| SM     | State machine                            | 462–481 |
| CONV   | Conventions                              | 483–501 |
| INT    | Install & shell integration (uncovered)  | 503–536 |
| BUILD  | Build guardrails (process)               | 538–555 |
| ACCEPT | Acceptance                               | 557–574 |

---

## Invariants (the five hard rules)

| Code  | Rule | Lines |
|---|---|---|
| INV-1 | No SQL outside the database adapter | 126–139 |
| INV-2 | Domain code names intent, never storage | 141–149 |
| INV-3 | Nudging is structural (cron), not a flag | 151–160 |
| INV-4 | Pause is silent | 162–168 |
| INV-5 | State is runtime; sessions are data | 170–179 |

---

## Domain model

| Code | Topic | Lines |
|---|---|---|
| DM-SESSION | Session is the entity (+ schema) | 55–75  |
| DM-PROJECT | Project is a label, not an entity | 77–85  |
| DM-STATE   | State is runtime (+ schema) | 87–105 |
| DM-DEAD    | Negative space — removed, never re-add | 107–122 |

---

## Commands (lib/)

| Code | Command | Lines |
|---|---|---|
| CMD-ON       | focus on [project] | 351–360 |
| CMD-OFF      | focus off (+ CMD-OFF-RECOVERY) | 361–368 |
| CMD-PAUSE    | focus pause | 369–372 |
| CMD-CONTINUE | focus continue | 373–378 |
| CMD-STATUS   | focus status | 379–383 |
| CMD-PAST     | focus past (+ CMD-PAST-ARGS) | 384–398 |
| CMD-REPORT   | focus report | 399–402 |
| CMD-ENABLE   | focus enable | 403–406 |
| CMD-DISABLE  | focus disable | 407–410 |
| CMD-NUDGE    | focus nudge | 411–414 |
| CMD-CONFIG   | focus config | 415–419 |
| CMD-EXPORT   | focus export | 420–422 |
| CMD-IMPORT   | focus import | 423–428 |
| CMD-INIT     | focus init | 429–431 |
| CMD-RESET    | focus reset | 432–435 |
| CMD-HELP     | focus help | 436–440 |

---

## Component surfaces (for reproduction)

| Code | Surface | Lines |
|---|---|---|
| PORT | database.sh — full intent API | 237–285 |
| CORE | core/time.sh — fmt/parse_duration/parse_time | 287–303 |
| ENV  | env.sh — loader + exports + precedence | 305–322 |
| CRON | cron.sh — install/remove + entry format | 324–345 |
| NUDGE | focus-nudge — the cron payload | 442–460 |
| INT-INSTALL | setup.sh | 510–521 |
| INT-DESKTOP | refocus.desktop | 522–526 |
| INT-SHELL   | focus-function.sh | 527–536 |

---

## Inline rules (defining line)

Single-line handles defined inside a section. Load the parent section for full
context; the line is where the rule itself is stated.

| Code | Rule | Line | Parent |
|---|---|---|---|
| ARCH-ROUTABLE          | dispatcher routes only to lib/ | 223 | ARCH |
| ARCH-ROOT              | REFOCUS_ROOT via realpath(BASH_SOURCE) | 227 | ARCH |
| ARCH-SOURCE            | handler source order | 232 | ARCH |
| CMD-OFF-RECOVERY       | off ignores focus_disabled | 365 | CMD-OFF |
| CMD-PAST-ARGS          | optional leading project; don't eat --duration | 393 | CMD-PAST |
| NUDGE-HISTORY          | desktop-entry hint → logged in history | 456 | NUDGE |
| SM-INVARIANT           | disabled ⇒ idle; active+disabled illegal | 471 | SM |
| CONV-EXIT              | exit codes 0/1/2 | 485 | CONV |
| CONV-YES               | destructive ops need literal "yes" | 425 | CMD-IMPORT |
| CONV-REARM             | reset/import leave disabled | 177 | INV-5 |
| CONV-IDEMPOTENT-ENABLE | enable-when-enabled is a no-op | 405 | CMD-ENABLE |
| CONV-DURONLY           | duration-only rows have no timestamps | 495 | CONV |
| CONV-ENVFILE           | ENV_FILE computed once in env.sh | 318 | ENV |
| CRON-INTERVAL          | validate 1–60 numeric | 328 | CRON |
| CRON-STRIP             | fixed-string crontab strip, live only | 338 | CRON |
| CRON-BIN               | payload path resolved at call time | 332 | CRON |
| CRON-ENV               | entry embeds REFOCUS_ROOT + display env | 334 | CRON |
| BUILD-NO-REGEN         | no whole-file regen through escaping | 543 | BUILD |
| BUILD-VERIFY           | run both test scripts after changes | 548 | BUILD |
| BUILD-UTF8             | shellcheck under LC_ALL=C.UTF-8 | 551 | BUILD |
| BUILD-SCOPE            | one concern per change | 553 | BUILD |

---

## Routing recipe (for an agent)

- Rebuilding a single component → load its surface row from *Component surfaces*
  plus every `INV-*` (124–179) and `NAME` (181–201). The invariants bind all of them.
- Implementing one command → load its `CMD-*` row + `PORT` (237–285) + `CONV` (483–501).
- Resolving an ambiguity → load the relevant rule's line ± its parent section, and
  decide by the WHY, never by local convenience (READ, 9–37).
- Checking your work → `ACCEPT` (557–574).
