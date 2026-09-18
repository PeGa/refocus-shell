# CONTRACT_INDEX.md — refocus-shell

> Line-range index into `MAIN.md` (1145 lines). Lets an agent load a single
> section or rule by range instead of the whole spec — context budget for small-
> window models, precise citation for everyone else.
>
> Ranges are inclusive and were generated against the current contract. If
> `MAIN.md` is edited, regenerate this file; a stale index is worse than none.
> Codes are stable handles: cite `INV-3` or `CONV-DURONLY`, not a line number, in
> prose — the number is only for loading.

---

## Sections (top level)

| Code    | Section                                     | Lines     |
|---|---|---|
| READ| How to read this                            | 9–39      |
| WHAT| What refocus-shell is                       | 40–53     |
| DM| Domain model                                | 54–146    |
| INV| Invariants                                  | 147–211   |
| NAME| Naming contract                             | 212–246   |
| ARCH| Architecture & layering                     | 247–297   |
| PORT| Adapter surface (database.sh)               | 298–450   |
| CORE| Domain-helper surface (core/*.sh)           | 451–516   |
| ENV| Environment loader (env.sh)                 | 517–539   |
| CRON| Nudge and check-in scheduling (cron.sh)     | 540–591   |
| CMD| Command surface (lib/)                      | 592–826   |
| NUDGE| Nudge payload (focus-nudge)                 | 827–846   |
| CHECKIN| Check-in payload (focus-checkin)            | 847–895   |
| SM| State machine                               | 896–916   |
| CONV| Conventions                                 | 917–1048  |
| INT| Install & shell integration                 | 1049–1085 |
| BUILD| Build guardrails                            | 1086–1125 |
| ACCEPT| Acceptance                                  | 1126–1145 |

---

## Domain model (DM)

| Code | Rule | Lines |
|---|---|---|
| DM-SESSION| Session is the entity                     | 56–77   |
| DM-PROJECT| Project is a label, not an entity         | 78–87   |
| DM-STATE| State is runtime, not data                | 88–107  |
| DM-DEAD| Negative space — never re-add             | 108–122 |
| DM-CYCLE| Cycle breaks are informational delimiters, not periods | 123–146 |

---

## Invariants (INV)

| Code | Rule | Lines |
|---|---|---|
| INV-1| No SQL outside the database adapter                          | 149–163 |
| INV-2| Domain code names intent, never storage                      | 164–173 |
| INV-3| Nudging and check-in are structural (cron), not a flag       | 174–192 |
| INV-4| Pause is silent                                               | 193–200 |
| INV-5| State is runtime; sessions are data                           | 201–211 |

---

## Commands (CMD)

| Code | Command | Lines |
|---|---|---|
| CMD-ON| focus on [project] | 596–607 |
| CMD-OFF| focus off | 608–619 |
| CMD-PAUSE| focus pause | 620–623 |
| CMD-CONTINUE| focus continue | 624–629 |
| CMD-STATUS| focus status | 630–637 |
| CMD-PAST     | focus past <list\|add\|modify\|delete\|cycles> | 638–680 |
| CMD-REPORT   | focus report <today\|week\|month\|custom N\|cycle [selector]> | 681–697 |
| CMD-ENABLE| focus enable | 698–704 |
| CMD-DISABLE| focus disable | 705–708 |
| CMD-NUDGE    | focus nudge <status\|test> | 709–712 |
| CMD-CHECKIN  | focus checkin <status\|test> | 713–728 |
| CMD-CONFIG   | focus config <show\|set\|unset> | 729–742 |
| CMD-EXPORT| focus export [basename] | 743–745 |
| CMD-IMPORT| focus import <file> | 746–761 |
| CMD-CYCLE| focus cycle <add\|modify\|delete> | 762–785 |
| CMD-PERIOD| Period resolution (services/period.sh) | 786–805 |
| CMD-INIT| focus init | 806–808 |
| CMD-RESET| focus reset | 809–813 |
| CMD-HELP| focus help [cmd] | 814–826 |

---

## Component surfaces (for reproduction)

| Code | Surface | Lines |
|---|---|---|
| PORT| database.sh — full intent API | 298–450 |
| CORE| core/*.sh — time + text helpers | 451–516 |
| CORE-TIME| core/time.sh — duration/time parsing, GNU-BSD split | 456–481 |
| CORE-TEXT| core/text.sh — notes decode + block rendering | 482–516 |
| ENV| env.sh — loader + exports + precedence | 517–539 |
| CRON| cron.sh — nudge + check-in install/remove + entry format | 540–591 |
| NUDGE| focus-nudge — the cron payload | 827–846 |
| CHECKIN| focus-checkin — the check-in cron payload | 847–895 |
| INT-INSTALL| setup.sh | 1056–1069 |
| INT-DESKTOP| refocus.desktop | 1070–1074 |
| INT-SHELL| focus-function.sh | 1075–1085 |

Note: `services/help.sh` and `services/editor.sh` have no surface section of
their own — they are specified where they are used, at CMD-HELP (814–826) and
CMD-OFF / CMD-PAST respectively.

---

## Inline rules (defining line)

Single-line handles defined inside a section. Load the parent section for full
context; the line is where the rule itself is stated. Every `CONV-*` is defined
by its bullet in [CONV] and referenced from the commands it governs.

| Code | Rule | Line | Parent |
|---|---|---|---|
| NAME-UNDERSCORE| underscore marks file-private scope; never a license for cryptic names | 224 | NAME |
| NAME-BREVITY| identifiers state intent; short-name allowlist id/rc/n/lo/hi, oracle-enforced | 230 | NAME |
| ARCH-ROUTABLE| dispatcher routes only to lib/ | 275 | ARCH |
| ARCH-ROOT| REFOCUS_ROOT via realpath(BASH_SOURCE) | 279 | ARCH |
| ARCH-SOURCE| handler source order | 284 | ARCH |
| ARCH-COMPOSER| shared domain rule → composer service, not copy; presentation-only sharing counts too | 286 | ARCH |
| PORT-VOCAB| adapter never hardcodes domain vocabulary; literals arrive as arguments | 308 | PORT |
| PORT-PROJVALID| project names sanitize (¦); notes encode (\x7c); CHECK backstops both | 318 | PORT |
| PORT-NOTES| notes encode newlines/pipe on read | 432 | PORT |
| PORT-BASH32| get_project_totals_in_range aggregates in SQL, not bash | 419 | PORT |
| CORE-DATE| date(1) confined to core/time.sh | 469 | CORE-TIME |
| CORE-LITERAL| domain literals defined once in core/text.sh, handed out by functions | 507 | CORE-TEXT |
| CMD-OFF-RECOVERY| off ignores focus_disabled | 616 | CMD-OFF |
| CMD-PAST-ARGS| optional leading project; don't eat --duration/--date | 656 | CMD-PAST |
| CMD-PAST-ID| numeric id guard before the adapter | 663 | CMD-PAST |
| CMD-PAST-NOOP| a modify that changes nothing is exit 2 | 667 | CMD-PAST |
| CMD-HELP-INTERCEPT| wants_help runs before parsing and db_ensure | 820 | CMD-HELP |
| NUDGE-HISTORY| desktop-entry hint → logged in history | 841 | NUDGE |
| CHECKIN-GUARDS| five silent early exits: no DB, disabled, active, paused, interval=0 | 856 | CHECKIN |
| CHECKIN-DURONLY| logs via record_duration_session, never a timestamped session | 863 | CHECKIN |
| CHECKIN-CASCADE| kdialog → zenity → terminal+dialog → terminal+read → silent | 871 | CHECKIN |
| CHECKIN-RETRY| project prompt loops on blank; note prompt does not | 878 | CHECKIN |
| CHECKIN-TIER3-HANDOFF| terminal tier hands back two bare lines, never pipe-delimited | 886 | CHECKIN |
| SM-INVARIANT| disabled ⇒ idle; active+disabled illegal | 905 | SM |
| CONV-EXIT| exit codes 0/1/2 | 919 | CONV |
| CONV-YES| three-tier confirmation: literal yes / y-N / Y-n, EOF covered per-tier | 927 | CONV |
| CONV-REARM| reset/import leave disabled | 938 | CONV |
| CONV-IDEMPOTENT-ENABLE| enable-when-enabled is a no-op | 941 | CONV |
| CONV-DURONLY| duration-only rows have no timestamps | 946 | CONV |
| CONV-ABSENT| absence branched at boundaries, named by renderers, never parsed, never repaired in-app | 951 | CONV |
| CONV-HELP| help is data; no inline usage strings | 975 | CONV |
| CONV-ID| session ids validated in the handler | 980 | CONV |
| CONV-NOTES| encode/decode notes (incl. pipe) across the read boundary | 995 | CONV |
| CONV-NOTES-CLEAR| clearing a note requires $EDITOR; never inferred from silence | 1002 | CONV |
| CONV-PORTABLE| GNU+BSD+bash-3.2; no date(1)/sed -i/sed t;/declare -A | 1016 | CONV |
| CONV-SURFACE| removing/renaming a user-facing command needs explicit sign-off + default deprecation shim | 1036 | CONV |
| CONV-ENVFILE| ENV_FILE computed once in env.sh | 530 | ENV |
| CONV-DEADKNOB| every config key has a live reader; dead keys removed | 533 | ENV |
| CRON-BIN| payload paths resolved at call time (nudge + checkin) | 554 | CRON |
| CRON-ENV| entry embeds REFOCUS_ROOT + display env | 557 | CRON |
| CRON-STRIP| fixed-string crontab strip, live only | 561 | CRON |
| CRON-INTERVAL| nudge: validate 1–60 numeric | 568 | CRON |
| CRON-CHECKIN-INTERVAL| checkin: 0 disables, 1–60 minute-stepped, >60 whole hours only | 570 | CRON |
| CRON-CHECKIN-FAILCLOSED| invalid checkin interval fails closed, no stale entry left | 582 | CRON |
| BUILD-NO-REGEN| no whole-file regen through escaping | 1091 | BUILD |
| BUILD-VERIFY| run all three test scripts after changes | 1096 | BUILD |
| BUILD-UTF8| shellcheck under LC_ALL=C.UTF-8 | 1102 | BUILD |
| BUILD-SCOPE| one concern per change; found-but-out-of-scope is logged, never folded in | 1104 | BUILD |
| BUILD-RELOCATE| grep full repo before AND after relocating/renaming a cross-file symbol or surface | 1114 | BUILD |

---

## Routing recipe (for an agent)

- Rebuilding a single component → load its surface row from *Component surfaces*
  plus every `INV-*` (147–211) and `NAME` (212–246). The invariants bind all of them.
- Implementing one command → load its `CMD-*` row + `PORT` (298–450) + `CONV` (917–1048).
- Resolving an ambiguity → load the relevant rule's line ± its parent section, and
  decide by the WHY, never by local convenience (READ, 9–39).
- Checking your work → `ACCEPT` (1126–1145).
