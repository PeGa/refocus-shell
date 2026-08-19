# CONTRACT_INDEX.md — refocus-shell

> Line-range index into `MAIN.md` (847 lines). Lets an agent load a single
> section or rule by range instead of the whole spec — context budget for small-
> window models, precise citation for everyone else.
>
> Ranges are inclusive and were generated against the current contract. If
> `MAIN.md` is edited, regenerate this file; a stale index is worse than none.
> Codes are stable handles: cite `INV-3` or `CONV-DURONLY`, not a line number, in
> prose — the number is only for loading.

---

## Sections (top level)

| Code    | Section                                     | Lines   |
|---|---|---|
| READ    | How to read this                            | 9–37    |
| WHAT    | What refocus-shell is                       | 39–51   |
| DM      | Domain model                                | 53–122  |
| INV     | Invariants                                  | 124–187 |
| NAME    | Naming contract                             | 189–209 |
| ARCH    | Architecture & layering                     | 211–243 |
| PORT    | Adapter surface (database.sh)               | 245–373 |
| CORE    | Domain-helper surface (core/*.sh)           | 375–412 |
| ENV     | Environment loader (env.sh)                 | 414–431 |
| CRON    | Nudge and check-in scheduling (cron.sh)     | 433–478 |
| CMD     | Command surface (lib/)                      | 480–618 |
| NUDGE   | Nudge payload (focus-nudge)                 | 620–638 |
| CHECKIN | Check-in payload (focus-checkin)            | 640–687 |
| SM      | State machine                               | 689–708 |
| CONV    | Conventions                                 | 710–772 |
| INT     | Install & shell integration                 | 774–809 |
| BUILD   | Build guardrails                            | 811–828 |
| ACCEPT  | Acceptance                                  | 830–847 |

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
| INV-1 | No SQL outside the database adapter                          | 126–139 |
| INV-2 | Domain code names intent, never storage                      | 141–149 |
| INV-3 | Nudging and check-in are structural (cron), not a flag       | 151–168 |
| INV-4 | Pause is silent                                               | 170–176 |
| INV-5 | State is runtime; sessions are data                           | 178–187 |

---

## Commands (CMD)

| Code | Command | Lines |
|---|---|---|
| CMD-ON       | focus on [project] | 484–492 |
| CMD-OFF      | focus off | 494–500 |
| CMD-PAUSE    | focus pause | 502–504 |
| CMD-CONTINUE | focus continue | 506–510 |
| CMD-STATUS   | focus status | 512–515 |
| CMD-PAST     | focus past <list\|add\|modify\|delete> | 517–541 |
| CMD-REPORT   | focus report <today\|week\|month\|custom N> | 543–548 |
| CMD-ENABLE   | focus enable | 550–555 |
| CMD-DISABLE  | focus disable | 557–559 |
| CMD-NUDGE    | focus nudge <status\|test> | 561–563 |
| CMD-CHECKIN  | focus checkin <status\|test> | 565–574 |
| CMD-CONFIG   | focus config <show\|set\|unset> | 576–587 |
| CMD-EXPORT   | focus export [basename] | 589–590 |
| CMD-IMPORT   | focus import <file> | 592–597 |
| CMD-INIT     | focus init | 599–600 |
| CMD-RESET    | focus reset | 602–605 |
| CMD-HELP     | focus help [cmd] | 607–618 |

---

## Component surfaces (for reproduction)

| Code | Surface | Lines |
|---|---|---|
| PORT | database.sh — full intent API | 245–373 |
| CORE | core/*.sh — time + text helpers | 375–412 |
| CORE-TIME | core/time.sh — duration/time parsing, GNU-BSD split | 380–400 |
| CORE-TEXT | core/text.sh — notes decode + block rendering | 402–412 |
| ENV  | env.sh — loader + exports + precedence | 414–431 |
| CRON | cron.sh — nudge + check-in install/remove + entry format | 433–478 |
| NUDGE | focus-nudge — the cron payload | 620–638 |
| CHECKIN | focus-checkin — the check-in cron payload | 640–687 |
| INT-INSTALL | setup.sh | 781–793 |
| INT-DESKTOP | refocus.desktop | 795–798 |
| INT-SHELL   | focus-function.sh | 800–809 |

Note: `services/help.sh` and `services/editor.sh` have no surface section of
their own — they are specified where they are used, at CMD-HELP (607–618) and
CMD-OFF / CMD-PAST respectively.

---

## Inline rules (defining line)

Single-line handles defined inside a section. Load the parent section for full
context; the line is where the rule itself is stated. Every `CONV-*` is defined
by its bullet in [CONV] and referenced from the commands it governs.

| Code | Rule | Line | Parent |
|---|---|---|---|
| ARCH-ROUTABLE          | dispatcher routes only to lib/ | 231 | ARCH |
| ARCH-ROOT              | REFOCUS_ROOT via realpath(BASH_SOURCE) | 235 | ARCH |
| ARCH-SOURCE            | handler source order | 240 | ARCH |
| PORT-PROJVALID         | project names sanitize (¦); notes encode (\x7c); CHECK backstops both | 254 | PORT |
| PORT-NOTES             | notes encode newlines/pipe on read | 350 | PORT |
| PORT-BASH32            | get_project_totals_in_range aggregates in SQL, not bash | 363 | PORT |
| CORE-DATE              | date(1) confined to core/time.sh | 393 | CORE-TIME |
| CMD-OFF-RECOVERY       | off ignores focus_disabled | 498 | CMD-OFF |
| CMD-PAST-ARGS          | optional leading project; don't eat --duration | 529 | CMD-PAST |
| CMD-PAST-ID            | numeric id guard before the adapter | 535 | CMD-PAST |
| CMD-PAST-NOOP          | a modify that changes nothing is exit 2 | 539 | CMD-PAST |
| CMD-HELP-INTERCEPT     | wants_help runs before parsing and db_ensure | 613 | CMD-HELP |
| NUDGE-HISTORY          | desktop-entry hint → logged in history | 634 | NUDGE |
| CHECKIN-GUARDS         | four silent early exits: no DB, disabled, active, paused, interval=0 | 649 | CHECKIN |
| CHECKIN-DURONLY        | logs via record_duration_session, never a timestamped session | 656 | CHECKIN |
| CHECKIN-CASCADE        | kdialog → zenity → terminal+dialog → terminal+read → silent | 664 | CHECKIN |
| CHECKIN-RETRY          | project prompt loops on blank; note prompt does not | 671 | CHECKIN |
| CHECKIN-TIER3-HANDOFF  | terminal tier hands back two bare lines, never pipe-delimited | 679 | CHECKIN |
| SM-INVARIANT           | disabled ⇒ idle; active+disabled illegal | 698 | SM |
| CONV-EXIT              | exit codes 0/1/2 | 712 | CONV |
| CONV-YES               | destructive ops need literal "yes" | 714 | CONV |
| CONV-REARM             | reset/import leave disabled | 716 | CONV |
| CONV-IDEMPOTENT-ENABLE | enable-when-enabled is a no-op | 719 | CONV |
| CONV-DURONLY           | duration-only rows have no timestamps | 722 | CONV |
| CONV-HELP              | help is data; no inline usage strings | 726 | CONV |
| CONV-ID                | session ids validated in the handler | 731 | CONV |
| CONV-NOTES             | encode/decode notes (incl. pipe) across the read boundary | 734 | CONV |
| CONV-NOTES-CLEAR       | clearing a note requires $EDITOR; never inferred from silence | 741 | CONV |
| CONV-PORTABLE          | GNU+BSD+bash-3.2; no date(1)/sed -i/sed t;/declare -A | 755 | CONV |
| CONV-ENVFILE           | ENV_FILE computed once in env.sh | 427 | ENV |
| CRON-BIN               | payload paths resolved at call time (nudge + checkin) | 447 | CRON |
| CRON-ENV               | entry embeds REFOCUS_ROOT + display env | 450 | CRON |
| CRON-STRIP             | fixed-string crontab strip, live only | 454 | CRON |
| CRON-INTERVAL          | nudge: validate 1–60 numeric | 458 | CRON |
| CRON-CHECKIN-INTERVAL  | checkin: 0 disables, 1–60 minute-stepped, >60 whole hours only | 460 | CRON |
| CRON-CHECKIN-FAILCLOSED| invalid checkin interval fails closed, no stale entry left | 470 | CRON |
| BUILD-NO-REGEN         | no whole-file regen through escaping | 816 | BUILD |
| BUILD-VERIFY           | run both test scripts after changes | 821 | BUILD |
| BUILD-UTF8             | shellcheck under LC_ALL=C.UTF-8 | 824 | BUILD |
| BUILD-SCOPE            | one concern per change | 826 | BUILD |

---

## Routing recipe (for an agent)

- Rebuilding a single component → load its surface row from *Component surfaces*
  plus every `INV-*` (124–187) and `NAME` (189–209). The invariants bind all of them.
- Implementing one command → load its `CMD-*` row + `PORT` (245–373) + `CONV` (710–772).
- Resolving an ambiguity → load the relevant rule's line ± its parent section, and
  decide by the WHY, never by local convenience (READ, 9–37).
- Checking your work → `ACCEPT` (830–847).
