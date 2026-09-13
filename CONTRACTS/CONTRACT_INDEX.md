# CONTRACT_INDEX.md — refocus-shell

> Line-range index into `MAIN.md` (934 lines). Lets an agent load a single
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
| READ| How to read this                            | 9–37    |
| WHAT| What refocus-shell is                       | 39–51   |
| DM| Domain model                                | 53–122  |
| INV| Invariants                                  | 124–187 |
| NAME| Naming contract                             | 189–222 |
| ARCH| Architecture & layering                     | 224–256 |
| PORT| Adapter surface (database.sh)               | 258–397 |
| CORE| Domain-helper surface (core/*.sh)           | 399–447 |
| ENV| Environment loader (env.sh)                 | 449–466 |
| CRON| Nudge and check-in scheduling (cron.sh)     | 468–513 |
| CMD| Command surface (lib/)                      | 515–662 |
| NUDGE| Nudge payload (focus-nudge)                 | 664–682 |
| CHECKIN| Check-in payload (focus-checkin)            | 684–731 |
| SM| State machine                               | 733–752 |
| CONV| Conventions                                 | 754–859 |
| INT| Install & shell integration                 | 861–896 |
| BUILD| Build guardrails                            | 898–915 |
| ACCEPT| Acceptance                                  | 917–934 |

---

## Domain model (DM)

| Code | Rule | Lines |
|---|---|---|
| DM-SESSION| Session is the entity                     | 55–75   |
| DM-PROJECT| Project is a label, not an entity         | 77–85   |
| DM-STATE| State is runtime, not data                | 87–105  |
| DM-DEAD| Negative space — never re-add             | 107–122 |

---

## Invariants (INV)

| Code | Rule | Lines |
|---|---|---|
| INV-1| No SQL outside the database adapter                          | 126–139 |
| INV-2| Domain code names intent, never storage                      | 141–149 |
| INV-3| Nudging and check-in are structural (cron), not a flag       | 151–168 |
| INV-4| Pause is silent                                               | 170–176 |
| INV-5| State is runtime; sessions are data                           | 178–187 |

---

## Commands (CMD)

| Code | Command | Lines |
|---|---|---|
| CMD-ON| focus on [project] | 519–527 |
| CMD-OFF| focus off | 529–535 |
| CMD-PAUSE| focus pause | 537–539 |
| CMD-CONTINUE| focus continue | 541–545 |
| CMD-STATUS| focus status | 547–550 |
| CMD-PAST     | focus past <list\|add\|modify\|delete> | 548–572 |
| CMD-REPORT   | focus report <today\|week\|month\|custom N> | 574–579 |
| CMD-ENABLE| focus enable | 585–590 |
| CMD-DISABLE| focus disable | 592–594 |
| CMD-NUDGE    | focus nudge <status\|test> | 592–594 |
| CMD-CHECKIN  | focus checkin <status\|test> | 596–605 |
| CMD-CONFIG   | focus config <show\|set\|unset> | 607–618 |
| CMD-EXPORT| focus export [basename] | 624–625 |
| CMD-IMPORT| focus import <file> | 627–641 |
| CMD-INIT| focus init | 643–644 |
| CMD-RESET| focus reset | 646–649 |
| CMD-HELP| focus help [cmd] | 651–662 |

---

## Component surfaces (for reproduction)

| Code | Surface | Lines |
|---|---|---|
| PORT| database.sh — full intent API | 258–397 |
| CORE| core/*.sh — time + text helpers | 399–447 |
| CORE-TIME| core/time.sh — duration/time parsing, GNU-BSD split | 404–428 |
| CORE-TEXT| core/text.sh — notes decode + block rendering | 430–447 |
| ENV| env.sh — loader + exports + precedence | 449–466 |
| CRON| cron.sh — nudge + check-in install/remove + entry format | 468–513 |
| NUDGE| focus-nudge — the cron payload | 664–682 |
| CHECKIN| focus-checkin — the check-in cron payload | 684–731 |
| INT-INSTALL| setup.sh | 868–880 |
| INT-DESKTOP| refocus.desktop | 882–885 |
| INT-SHELL| focus-function.sh | 887–896 |

Note: `services/help.sh` and `services/editor.sh` have no surface section of
their own — they are specified where they are used, at CMD-HELP (651–662) and
CMD-OFF / CMD-PAST respectively.

---

## Inline rules (defining line)

Single-line handles defined inside a section. Load the parent section for full
context; the line is where the rule itself is stated. Every `CONV-*` is defined
by its bullet in [CONV] and referenced from the commands it governs.

| Code | Rule | Line | Parent |
|---|---|---|---|
| NAME-UNDERSCORE| underscore marks file-private scope; never a license for cryptic names | 201 | NAME |
| NAME-BREVITY| identifiers state intent; short-name allowlist id/rc/n/lo/hi, oracle-enforced | 207 | NAME |
| ARCH-ROUTABLE| dispatcher routes only to lib/ | 249 | ARCH |
| ARCH-ROOT| REFOCUS_ROOT via realpath(BASH_SOURCE) | 253 | ARCH |
| ARCH-SOURCE| handler source order | 258 | ARCH |
| ARCH-COMPOSER| shared domain rule → composer service, not copy | 260 | ARCH |
| PORT-VOCAB| adapter never hardcodes domain vocabulary; literals arrive as arguments | 268 | PORT |
| PORT-PROJVALID| project names sanitize (¦); notes encode (\x7c); CHECK backstops both | 278 | PORT |
| PORT-NOTES| notes encode newlines/pipe on read | 374 | PORT |
| PORT-BASH32| get_project_totals_in_range aggregates in SQL, not bash | 387 | PORT |
| CORE-DATE| date(1) confined to core/time.sh | 417 | CORE-TIME |
| CORE-LITERAL| domain literals defined once in core/text.sh, handed out by functions | 439 | CORE-TEXT |
| CMD-OFF-RECOVERY| off ignores focus_disabled | 533 | CMD-OFF |
| CMD-PAST-ARGS| optional leading project; don't eat --duration | 564 | CMD-PAST |
| CMD-PAST-ID| numeric id guard before the adapter | 570 | CMD-PAST |
| CMD-PAST-NOOP| a modify that changes nothing is exit 2 | 574 | CMD-PAST |
| CMD-HELP-INTERCEPT| wants_help runs before parsing and db_ensure | 657 | CMD-HELP |
| NUDGE-HISTORY| desktop-entry hint → logged in history | 678 | NUDGE |
| CHECKIN-GUARDS| four silent early exits: no DB, disabled, active, paused, interval=0 | 693 | CHECKIN |
| CHECKIN-DURONLY| logs via record_duration_session, never a timestamped session | 700 | CHECKIN |
| CHECKIN-CASCADE| kdialog → zenity → terminal+dialog → terminal+read → silent | 708 | CHECKIN |
| CHECKIN-RETRY| project prompt loops on blank; note prompt does not | 715 | CHECKIN |
| CHECKIN-TIER3-HANDOFF| terminal tier hands back two bare lines, never pipe-delimited | 723 | CHECKIN |
| SM-INVARIANT| disabled ⇒ idle; active+disabled illegal | 742 | SM |
| CONV-EXIT| exit codes 0/1/2 | 756 | CONV |
| CONV-YES| two-tier: app-wide destructive needs "yes", simple ops use y/N | 764 | CONV |
| CONV-REARM| reset/import leave disabled | 766 | CONV |
| CONV-IDEMPOTENT-ENABLE| enable-when-enabled is a no-op | 769 | CONV |
| CONV-DURONLY| duration-only rows have no timestamps | 772 | CONV |
| CONV-ABSENT| absence branched at boundaries, named by renderers, never parsed, never repaired in-app | 777 | CONV |
| CONV-HELP| help is data; no inline usage strings | 801 | CONV |
| CONV-ID| session ids validated in the handler | 806 | CONV |
| CONV-NOTES| encode/decode notes (incl. pipe) across the read boundary | 821 | CONV |
| CONV-NOTES-CLEAR| clearing a note requires $EDITOR; never inferred from silence | 828 | CONV |
| CONV-PORTABLE| GNU+BSD+bash-3.2; no date(1)/sed -i/sed t;/declare -A | 842 | CONV |
| CONV-ENVFILE| ENV_FILE computed once in env.sh | 462 | ENV |
| CONV-DEADKNOB| every config key has a live reader; dead keys removed | 475 | ENV |
| CRON-BIN| payload paths resolved at call time (nudge + checkin) | 482 | CRON |
| CRON-ENV| entry embeds REFOCUS_ROOT + display env | 485 | CRON |
| CRON-STRIP| fixed-string crontab strip, live only | 489 | CRON |
| CRON-INTERVAL| nudge: validate 1–60 numeric | 493 | CRON |
| CRON-CHECKIN-INTERVAL| checkin: 0 disables, 1–60 minute-stepped, >60 whole hours only | 495 | CRON |
| CRON-CHECKIN-FAILCLOSED| invalid checkin interval fails closed, no stale entry left | 505 | CRON |
| BUILD-NO-REGEN| no whole-file regen through escaping | 903 | BUILD |
| BUILD-VERIFY| run both test scripts after changes | 908 | BUILD |
| BUILD-UTF8| shellcheck under LC_ALL=C.UTF-8 | 911 | BUILD |
| BUILD-SCOPE| one concern per change | 913 | BUILD |

---

## Routing recipe (for an agent)

- Rebuilding a single component → load its surface row from *Component surfaces*
  plus every `INV-*` (124–187) and `NAME` (189–222). The invariants bind all of them.
- Implementing one command → load its `CMD-*` row + `PORT` (258–397) + `CONV` (754–847).
- Resolving an ambiguity → load the relevant rule's line ± its parent section, and
  decide by the WHY, never by local convenience (READ, 9–37).
- Checking your work → `ACCEPT` (905–922).
