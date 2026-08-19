# CONTRACT_INDEX.md — refocus-shell

> Line-range index into `MAIN.md` (748 lines). Lets an agent load a single
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
| PORT   | Adapter surface (database.sh)            | 237–365 |
| CORE   | Domain-helper surface (core/*.sh)        | 367–404 |
| ENV    | Environment loader (env.sh)              | 406–423 |
| CRON   | Nudge scheduling (cron.sh)               | 425–446 |
| CMD    | Command surface (lib/)                   | 448–570 |
| NUDGE  | Nudge payload (focus-nudge)              | 572–590 |
| SM     | State machine                            | 592–611 |
| CONV   | Conventions                              | 613–675 |
| INT    | Install & shell integration              | 677–710 |
| BUILD  | Build guardrails                         | 712–729 |
| ACCEPT | Acceptance                               | 731–748 |

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
| CMD-ON       | focus on [project] | 452–460 |
| CMD-OFF      | focus off | 462–468 |
| CMD-PAUSE    | focus pause | 470–472 |
| CMD-CONTINUE | focus continue | 474–478 |
| CMD-STATUS   | focus status | 480–483 |
| CMD-PAST     | focus past <list\|add\|modify\|delete> | 485–509 |
| CMD-REPORT   | focus report <today\|week\|month\|custom N> | 511–516 |
| CMD-ENABLE   | focus enable | 518–520 |
| CMD-DISABLE  | focus disable | 522–524 |
| CMD-NUDGE    | focus nudge <status\|test> | 526–528 |
| CMD-CONFIG   | focus config <show\|set\|unset> | 530–541 |
| CMD-EXPORT   | focus export [basename] | 543–544 |
| CMD-IMPORT   | focus import <file> | 546–550 |
| CMD-INIT     | focus init | 552–553 |
| CMD-RESET    | focus reset | 555–557 |
| CMD-HELP     | focus help [cmd] | 559–570 |

---

## Component surfaces (for reproduction)

| Code | Surface | Lines |
|---|---|---|
| PORT | database.sh — full intent API | 237–365 |
| CORE | core/*.sh — time + text helpers | 367–404 |
| CORE-TIME | core/time.sh — duration/time parsing, GNU-BSD split | 372–392 |
| CORE-TEXT | core/text.sh — notes decode + block rendering | 394–404 |
| ENV  | env.sh — loader + exports + precedence | 406–423 |
| CRON | cron.sh — install/remove + entry format | 425–446 |
| NUDGE | focus-nudge — the cron payload | 572–590 |
| INT-INSTALL | setup.sh | 684–694 |
| INT-DESKTOP | refocus.desktop | 696–699 |
| INT-SHELL   | focus-function.sh | 701–710 |

Note: `services/help.sh` and `services/editor.sh` have no surface section of
their own — they are specified where they are used, at CMD-HELP (559–570) and
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
| PORT-PROJVALID         | project names sanitize (¦); notes encode (\x7c); CHECK backstops both | 246 | PORT |
| PORT-NOTES             | notes encode newlines/pipe on read | 342 | PORT |
| PORT-BASH32            | get_project_totals_in_range aggregates in SQL, not bash | 355 | PORT |
| CORE-DATE              | date(1) confined to core/time.sh | 385 | CORE-TIME |
| CMD-OFF-RECOVERY       | off ignores focus_disabled | 466 | CMD-OFF |
| CMD-PAST-ARGS          | optional leading project; don't eat --duration | 497 | CMD-PAST |
| CMD-PAST-ID            | numeric id guard before the adapter | 503 | CMD-PAST |
| CMD-PAST-NOOP          | a modify that changes nothing is exit 2 | 507 | CMD-PAST |
| CMD-HELP-INTERCEPT     | wants_help runs before parsing and db_ensure | 565 | CMD-HELP |
| NUDGE-HISTORY          | desktop-entry hint → logged in history | 586 | NUDGE |
| SM-INVARIANT           | disabled ⇒ idle; active+disabled illegal | 601 | SM |
| CONV-EXIT              | exit codes 0/1/2 | 615 | CONV |
| CONV-YES               | destructive ops need literal "yes" | 617 | CONV |
| CONV-REARM             | reset/import leave disabled | 619 | CONV |
| CONV-IDEMPOTENT-ENABLE | enable-when-enabled is a no-op | 622 | CONV |
| CONV-DURONLY           | duration-only rows have no timestamps | 625 | CONV |
| CONV-HELP              | help is data; no inline usage strings | 629 | CONV |
| CONV-ID                | session ids validated in the handler | 634 | CONV |
| CONV-NOTES             | encode/decode notes (incl. pipe) across the read boundary | 637 | CONV |
| CONV-NOTES-CLEAR       | clearing a note requires $EDITOR; never inferred from silence | 644 | CONV |
| CONV-PORTABLE          | GNU+BSD+bash-3.2; no date(1)/sed -i/sed t;/declare -A | 658 | CONV |
| CONV-ENVFILE           | ENV_FILE computed once in env.sh | 419 | ENV |
| CRON-BIN               | payload path resolved at call time | 433 | CRON |
| CRON-ENV               | entry embeds REFOCUS_ROOT + display env | 435 | CRON |
| CRON-STRIP             | fixed-string crontab strip, live only | 439 | CRON |
| CRON-INTERVAL          | validate 1–60 numeric | 443 | CRON |
| BUILD-NO-REGEN         | no whole-file regen through escaping | 717 | BUILD |
| BUILD-VERIFY           | run both test scripts after changes | 722 | BUILD |
| BUILD-UTF8             | shellcheck under LC_ALL=C.UTF-8 | 725 | BUILD |
| BUILD-SCOPE            | one concern per change | 727 | BUILD |

---

## Routing recipe (for an agent)

- Rebuilding a single component → load its surface row from *Component surfaces*
  plus every `INV-*` (124–179) and `NAME` (181–201). The invariants bind all of them.
- Implementing one command → load its `CMD-*` row + `PORT` (237–365) + `CONV` (613–675).
- Resolving an ambiguity → load the relevant rule's line ± its parent section, and
  decide by the WHY, never by local convenience (READ, 9–37).
- Checking your work → `ACCEPT` (731–748).
