# CONTRACT_INDEX.md — refocus-shell

> Line-range index into `MAIN.md` (637 lines). Lets an agent load a single
> section or rule by range instead of the whole spec — context budget for small-
> window models, precise citation for everyone else.
>
> Ranges are inclusive and were generated against the current contract. If
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
| PORT   | Adapter surface (database.sh)            | 237–295 |
| CORE   | Domain-helper surface (core/*.sh)        | 297–334 |
| ENV    | Environment loader (env.sh)              | 336–353 |
| CRON   | Nudge scheduling (cron.sh)               | 355–376 |
| CMD    | Command surface (lib/)                   | 378–489 |
| NUDGE  | Nudge payload (focus-nudge)              | 491–509 |
| SM     | State machine                            | 511–530 |
| CONV   | Conventions                              | 532–564 |
| INT    | Install & shell integration              | 566–599 |
| BUILD  | Build guardrails                         | 601–618 |
| ACCEPT | Acceptance                               | 620–637 |

---

## Domain model (DM)

| Code | Rule | Lines |
|---|---|---|
| DM-SESSION | Session is the entity                     | 55–75   |
| DM-PROJECT | Project is a label, not an entity         | 77–85   |
| DM-STATE   | State is runtime, not data                | 87–105  |
| DM-DEAD    | Negative space — never re-add             | 107–122 |

---

## Invariants (INV)

| Code | Rule | Lines |
|---|---|---|
| INV-1 | No SQL outside the database adapter        | 126–139 |
| INV-2 | Domain code names intent, never storage    | 141–149 |
| INV-3 | Nudging is structural (cron), not a flag   | 151–160 |
| INV-4 | Pause is silent                            | 162–168 |
| INV-5 | State is runtime; sessions are data        | 170–179 |

---

## Commands (CMD)

| Code | Command | Lines |
|---|---|---|
| CMD-ON       | focus on [project] | 382–390 |
| CMD-OFF      | focus off | 392–398 |
| CMD-PAUSE    | focus pause | 400–402 |
| CMD-CONTINUE | focus continue | 404–408 |
| CMD-STATUS   | focus status | 410–413 |
| CMD-PAST     | focus past <list\|add\|modify\|delete> | 415–439 |
| CMD-REPORT   | focus report <today\|week\|month\|custom N> | 441–443 |
| CMD-ENABLE   | focus enable | 445–447 |
| CMD-DISABLE  | focus disable | 449–451 |
| CMD-NUDGE    | focus nudge <status\|test> | 453–455 |
| CMD-CONFIG   | focus config <show\|set\|unset> | 457–460 |
| CMD-EXPORT   | focus export [basename] | 462–463 |
| CMD-IMPORT   | focus import <file> | 465–469 |
| CMD-INIT     | focus init | 471–472 |
| CMD-RESET    | focus reset | 474–476 |
| CMD-HELP     | focus help [cmd] | 478–489 |

---

## Component surfaces (for reproduction)

| Code | Surface | Lines |
|---|---|---|
| PORT | database.sh — full intent API | 237–295 |
| CORE | core/*.sh — time + text helpers | 297–334 |
| CORE-TIME | core/time.sh — duration/time parsing, GNU-BSD split | 302–322 |
| CORE-TEXT | core/text.sh — notes decode + block rendering | 324–334 |
| ENV  | env.sh — loader + exports + precedence | 336–353 |
| CRON | cron.sh — install/remove + entry format | 355–376 |
| NUDGE | focus-nudge — the cron payload | 491–509 |
| INT-INSTALL | setup.sh | 573–583 |
| INT-DESKTOP | refocus.desktop | 585–588 |
| INT-SHELL   | focus-function.sh | 590–599 |

Note: `services/help.sh` and `services/editor.sh` have no surface section of
their own — they are specified where they are used, at CMD-HELP (478–489) and
CMD-OFF / CMD-PAST respectively.

---

## Inline rules (defining line)

Single-line handles defined inside a section. Load the parent section for full
context; the line is where the rule itself is stated. Every `CONV-*` is defined
by its bullet in [CONV] and referenced from the commands it governs.

| Code | Rule | Line | Parent |
|---|---|---|---|
| ARCH-ROUTABLE          | dispatcher routes only to lib/ | 223 | ARCH |
| ARCH-ROOT              | REFOCUS_ROOT via realpath(BASH_SOURCE) | 227 | ARCH |
| ARCH-SOURCE            | handler source order | 232 | ARCH |
| PORT-NOTES             | notes encode newlines on read | 278 | PORT |
| CORE-DATE              | date(1) confined to core/time.sh | 315 | CORE-TIME |
| CMD-OFF-RECOVERY       | off ignores focus_disabled | 396 | CMD-OFF |
| CMD-PAST-ARGS          | optional leading project; don't eat --duration | 427 | CMD-PAST |
| CMD-PAST-ID            | numeric id guard before the adapter | 433 | CMD-PAST |
| CMD-PAST-NOOP          | a modify that changes nothing is exit 2 | 437 | CMD-PAST |
| CMD-HELP-INTERCEPT     | wants_help runs before parsing and db_ensure | 484 | CMD-HELP |
| NUDGE-HISTORY          | desktop-entry hint → logged in history | 505 | NUDGE |
| SM-INVARIANT           | disabled ⇒ idle; active+disabled illegal | 520 | SM |
| CONV-EXIT              | exit codes 0/1/2 | 534 | CONV |
| CONV-YES               | destructive ops need literal "yes" | 536 | CONV |
| CONV-REARM             | reset/import leave disabled | 538 | CONV |
| CONV-IDEMPOTENT-ENABLE | enable-when-enabled is a no-op | 541 | CONV |
| CONV-DURONLY           | duration-only rows have no timestamps | 544 | CONV |
| CONV-HELP              | help is data; no inline usage strings | 548 | CONV |
| CONV-ID                | session ids validated in the handler | 553 | CONV |
| CONV-NOTES             | encode/decode notes across the read boundary | 556 | CONV |
| CONV-PORTABLE          | GNU+BSD userland; no date(1), no sed -i | 559 | CONV |
| CONV-ENVFILE           | ENV_FILE computed once in env.sh | 349 | ENV |
| CRON-BIN               | payload path resolved at call time | 363 | CRON |
| CRON-ENV               | entry embeds REFOCUS_ROOT + display env | 365 | CRON |
| CRON-STRIP             | fixed-string crontab strip, live only | 369 | CRON |
| CRON-INTERVAL          | validate 1–60 numeric | 373 | CRON |
| BUILD-NO-REGEN         | no whole-file regen through escaping | 606 | BUILD |
| BUILD-VERIFY           | run both test scripts after changes | 611 | BUILD |
| BUILD-UTF8             | shellcheck under LC_ALL=C.UTF-8 | 614 | BUILD |
| BUILD-SCOPE            | one concern per change | 616 | BUILD |

---

## Routing recipe (for an agent)

- Rebuilding a single component → load its surface row from *Component surfaces*
  plus every `INV-*` (124–179) and `NAME` (181–201). The invariants bind all of them.
- Implementing one command → load its `CMD-*` row + `PORT` (237–295) + `CONV` (532–564).
- Resolving an ambiguity → load the relevant rule's line ± its parent section, and
  decide by the WHY, never by local convenience (READ, 9–37).
- Checking your work → `ACCEPT` (620–637).
