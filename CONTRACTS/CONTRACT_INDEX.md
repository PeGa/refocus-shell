# CONTRACT_INDEX.md — refocus-shell

> Line-range index into `MAIN.md` (676 lines). Lets an agent load a single
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
| PORT   | Adapter surface (database.sh)            | 237–311 |
| CORE   | Domain-helper surface (core/*.sh)        | 313–350 |
| ENV    | Environment loader (env.sh)              | 352–369 |
| CRON   | Nudge scheduling (cron.sh)               | 371–392 |
| CMD    | Command surface (lib/)                   | 394–516 |
| NUDGE  | Nudge payload (focus-nudge)              | 518–536 |
| SM     | State machine                            | 538–557 |
| CONV   | Conventions                              | 559–603 |
| INT    | Install & shell integration              | 605–638 |
| BUILD  | Build guardrails                         | 640–657 |
| ACCEPT | Acceptance                               | 659–676 |

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
| CMD-ON       | focus on [project] | 398–406 |
| CMD-OFF      | focus off | 408–414 |
| CMD-PAUSE    | focus pause | 416–418 |
| CMD-CONTINUE | focus continue | 420–424 |
| CMD-STATUS   | focus status | 426–429 |
| CMD-PAST     | focus past <list\|add\|modify\|delete> | 431–455 |
| CMD-REPORT   | focus report <today\|week\|month\|custom N> | 457–462 |
| CMD-ENABLE   | focus enable | 464–466 |
| CMD-DISABLE  | focus disable | 468–470 |
| CMD-NUDGE    | focus nudge <status\|test> | 472–474 |
| CMD-CONFIG   | focus config <show\|set\|unset> | 476–487 |
| CMD-EXPORT   | focus export [basename] | 489–490 |
| CMD-IMPORT   | focus import <file> | 492–496 |
| CMD-INIT     | focus init | 498–499 |
| CMD-RESET    | focus reset | 501–503 |
| CMD-HELP     | focus help [cmd] | 505–516 |

---

## Component surfaces (for reproduction)

| Code | Surface | Lines |
|---|---|---|
| PORT | database.sh — full intent API | 237–311 |
| CORE | core/*.sh — time + text helpers | 313–350 |
| CORE-TIME | core/time.sh — duration/time parsing, GNU-BSD split | 318–338 |
| CORE-TEXT | core/text.sh — notes decode + block rendering | 340–350 |
| ENV  | env.sh — loader + exports + precedence | 352–369 |
| CRON | cron.sh — install/remove + entry format | 371–392 |
| NUDGE | focus-nudge — the cron payload | 518–536 |
| INT-INSTALL | setup.sh | 612–622 |
| INT-DESKTOP | refocus.desktop | 624–627 |
| INT-SHELL   | focus-function.sh | 629–638 |

Note: `services/help.sh` and `services/editor.sh` have no surface section of
their own — they are specified where they are used, at CMD-HELP (505–516) and
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
| PORT-PROJVALID         | project name validated before every DB write | 245 | PORT |
| PORT-NOTES             | notes encode newlines on read | 288 | PORT |
| PORT-BASH32            | get_project_totals_in_range aggregates in SQL, not bash | 301 | PORT |
| CORE-DATE              | date(1) confined to core/time.sh | 331 | CORE-TIME |
| CMD-OFF-RECOVERY       | off ignores focus_disabled | 412 | CMD-OFF |
| CMD-PAST-ARGS          | optional leading project; don't eat --duration | 443 | CMD-PAST |
| CMD-PAST-ID            | numeric id guard before the adapter | 449 | CMD-PAST |
| CMD-PAST-NOOP          | a modify that changes nothing is exit 2 | 453 | CMD-PAST |
| CMD-HELP-INTERCEPT     | wants_help runs before parsing and db_ensure | 511 | CMD-HELP |
| NUDGE-HISTORY          | desktop-entry hint → logged in history | 532 | NUDGE |
| SM-INVARIANT           | disabled ⇒ idle; active+disabled illegal | 547 | SM |
| CONV-EXIT              | exit codes 0/1/2 | 561 | CONV |
| CONV-YES               | destructive ops need literal "yes" | 563 | CONV |
| CONV-REARM             | reset/import leave disabled | 565 | CONV |
| CONV-IDEMPOTENT-ENABLE | enable-when-enabled is a no-op | 568 | CONV |
| CONV-DURONLY           | duration-only rows have no timestamps | 571 | CONV |
| CONV-HELP              | help is data; no inline usage strings | 575 | CONV |
| CONV-ID                | session ids validated in the handler | 580 | CONV |
| CONV-NOTES             | encode/decode notes across the read boundary | 583 | CONV |
| CONV-PORTABLE          | GNU+BSD+bash-3.2; no date(1)/sed -i/sed t;/declare -A | 586 | CONV |
| CONV-ENVFILE           | ENV_FILE computed once in env.sh | 365 | ENV |
| CRON-BIN               | payload path resolved at call time | 379 | CRON |
| CRON-ENV               | entry embeds REFOCUS_ROOT + display env | 381 | CRON |
| CRON-STRIP             | fixed-string crontab strip, live only | 385 | CRON |
| CRON-INTERVAL          | validate 1–60 numeric | 389 | CRON |
| BUILD-NO-REGEN         | no whole-file regen through escaping | 645 | BUILD |
| BUILD-VERIFY           | run both test scripts after changes | 650 | BUILD |
| BUILD-UTF8             | shellcheck under LC_ALL=C.UTF-8 | 653 | BUILD |
| BUILD-SCOPE            | one concern per change | 655 | BUILD |

---

## Routing recipe (for an agent)

- Rebuilding a single component → load its surface row from *Component surfaces*
  plus every `INV-*` (124–179) and `NAME` (181–201). The invariants bind all of them.
- Implementing one command → load its `CMD-*` row + `PORT` (237–311) + `CONV` (559–603).
- Resolving an ambiguity → load the relevant rule's line ± its parent section, and
  decide by the WHY, never by local convenience (READ, 9–37).
- Checking your work → `ACCEPT` (659–676).
