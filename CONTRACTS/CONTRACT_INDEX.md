# CONTRACT_INDEX.md — refocus-shell

> Line-range index into `MAIN.md` (707 lines). Lets an agent load a single
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
| PORT   | Adapter surface (database.sh)            | 237–328 |
| CORE   | Domain-helper surface (core/*.sh)        | 330–367 |
| ENV    | Environment loader (env.sh)              | 369–386 |
| CRON   | Nudge scheduling (cron.sh)               | 388–409 |
| CMD    | Command surface (lib/)                   | 411–533 |
| NUDGE  | Nudge payload (focus-nudge)              | 535–553 |
| SM     | State machine                            | 555–574 |
| CONV   | Conventions                              | 576–634 |
| INT    | Install & shell integration              | 636–669 |
| BUILD  | Build guardrails                         | 671–688 |
| ACCEPT | Acceptance                               | 690–707 |

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
| CMD-ON       | focus on [project] | 415–423 |
| CMD-OFF      | focus off | 425–431 |
| CMD-PAUSE    | focus pause | 433–435 |
| CMD-CONTINUE | focus continue | 437–441 |
| CMD-STATUS   | focus status | 443–446 |
| CMD-PAST     | focus past <list\|add\|modify\|delete> | 448–472 |
| CMD-REPORT   | focus report <today\|week\|month\|custom N> | 474–479 |
| CMD-ENABLE   | focus enable | 481–483 |
| CMD-DISABLE  | focus disable | 485–487 |
| CMD-NUDGE    | focus nudge <status\|test> | 489–491 |
| CMD-CONFIG   | focus config <show\|set\|unset> | 493–504 |
| CMD-EXPORT   | focus export [basename] | 506–507 |
| CMD-IMPORT   | focus import <file> | 509–513 |
| CMD-INIT     | focus init | 515–516 |
| CMD-RESET    | focus reset | 518–520 |
| CMD-HELP     | focus help [cmd] | 522–533 |

---

## Component surfaces (for reproduction)

| Code | Surface | Lines |
|---|---|---|
| PORT | database.sh — full intent API | 237–328 |
| CORE | core/*.sh — time + text helpers | 330–367 |
| CORE-TIME | core/time.sh — duration/time parsing, GNU-BSD split | 335–355 |
| CORE-TEXT | core/text.sh — notes decode + block rendering | 357–367 |
| ENV  | env.sh — loader + exports + precedence | 369–386 |
| CRON | cron.sh — install/remove + entry format | 388–409 |
| NUDGE | focus-nudge — the cron payload | 535–553 |
| INT-INSTALL | setup.sh | 643–653 |
| INT-DESKTOP | refocus.desktop | 655–658 |
| INT-SHELL   | focus-function.sh | 660–669 |

Note: `services/help.sh` and `services/editor.sh` have no surface section of
their own — they are specified where they are used, at CMD-HELP (522–533) and
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
| PORT-PROJVALID         | project name validated in bash + a schema CHECK backstop (new DBs) | 245 | PORT |
| PORT-NOTES             | notes encode newlines on read | 305 | PORT |
| PORT-BASH32            | get_project_totals_in_range aggregates in SQL, not bash | 318 | PORT |
| CORE-DATE              | date(1) confined to core/time.sh | 348 | CORE-TIME |
| CMD-OFF-RECOVERY       | off ignores focus_disabled | 429 | CMD-OFF |
| CMD-PAST-ARGS          | optional leading project; don't eat --duration | 460 | CMD-PAST |
| CMD-PAST-ID            | numeric id guard before the adapter | 466 | CMD-PAST |
| CMD-PAST-NOOP          | a modify that changes nothing is exit 2 | 470 | CMD-PAST |
| CMD-HELP-INTERCEPT     | wants_help runs before parsing and db_ensure | 528 | CMD-HELP |
| NUDGE-HISTORY          | desktop-entry hint → logged in history | 549 | NUDGE |
| SM-INVARIANT           | disabled ⇒ idle; active+disabled illegal | 564 | SM |
| CONV-EXIT              | exit codes 0/1/2 | 578 | CONV |
| CONV-YES               | destructive ops need literal "yes" | 580 | CONV |
| CONV-REARM             | reset/import leave disabled | 582 | CONV |
| CONV-IDEMPOTENT-ENABLE | enable-when-enabled is a no-op | 585 | CONV |
| CONV-DURONLY           | duration-only rows have no timestamps | 588 | CONV |
| CONV-HELP              | help is data; no inline usage strings | 592 | CONV |
| CONV-ID                | session ids validated in the handler | 597 | CONV |
| CONV-NOTES             | encode/decode notes across the read boundary | 600 | CONV |
| CONV-NOTES-CLEAR       | clearing a note requires $EDITOR; never inferred from silence | 603 | CONV |
| CONV-PORTABLE          | GNU+BSD+bash-3.2; no date(1)/sed -i/sed t;/declare -A | 617 | CONV |
| CONV-ENVFILE           | ENV_FILE computed once in env.sh | 382 | ENV |
| CRON-BIN               | payload path resolved at call time | 396 | CRON |
| CRON-ENV               | entry embeds REFOCUS_ROOT + display env | 398 | CRON |
| CRON-STRIP             | fixed-string crontab strip, live only | 402 | CRON |
| CRON-INTERVAL          | validate 1–60 numeric | 406 | CRON |
| BUILD-NO-REGEN         | no whole-file regen through escaping | 676 | BUILD |
| BUILD-VERIFY           | run both test scripts after changes | 681 | BUILD |
| BUILD-UTF8             | shellcheck under LC_ALL=C.UTF-8 | 684 | BUILD |
| BUILD-SCOPE            | one concern per change | 686 | BUILD |

---

## Routing recipe (for an agent)

- Rebuilding a single component → load its surface row from *Component surfaces*
  plus every `INV-*` (124–179) and `NAME` (181–201). The invariants bind all of them.
- Implementing one command → load its `CMD-*` row + `PORT` (237–328) + `CONV` (576–634).
- Resolving an ambiguity → load the relevant rule's line ± its parent section, and
  decide by the WHY, never by local convenience (READ, 9–37).
- Checking your work → `ACCEPT` (690–707).
