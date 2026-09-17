# CONTRACT_INDEX.md — refocus-shell

> Line-range index into `MAIN.md` (1107 lines). Lets an agent load a single
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
| ARCH| Architecture & layering                     | 247–293   |
| PORT| Adapter surface (database.sh)               | 294–446   |
| CORE| Domain-helper surface (core/*.sh)           | 447–512   |
| ENV| Environment loader (env.sh)                 | 513–535   |
| CRON| Nudge and check-in scheduling (cron.sh)     | 536–586   |
| CMD| Command surface (lib/)                      | 587–821   |
| NUDGE| Nudge payload (focus-nudge)                 | 822–841   |
| CHECKIN| Check-in payload (focus-checkin)            | 842–890   |
| SM| State machine                               | 891–911   |
| CONV| Conventions                                 | 912–1029  |
| INT| Install & shell integration                 | 1030–1066 |
| BUILD| Build guardrails                            | 1067–1087 |
| ACCEPT| Acceptance                                  | 1088–1107 |

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
| CMD-ON| focus on [project] | 591–602 |
| CMD-OFF| focus off | 603–614 |
| CMD-PAUSE| focus pause | 615–618 |
| CMD-CONTINUE| focus continue | 619–624 |
| CMD-STATUS| focus status | 625–632 |
| CMD-PAST     | focus past <list\|add\|modify\|delete\|cycles> | 633–675 |
| CMD-REPORT   | focus report <today\|week\|month\|custom N\|cycle [selector]> | 676–692 |
| CMD-ENABLE| focus enable | 693–699 |
| CMD-DISABLE| focus disable | 700–703 |
| CMD-NUDGE    | focus nudge <status\|test> | 704–707 |
| CMD-CHECKIN  | focus checkin <status\|test> | 708–723 |
| CMD-CONFIG   | focus config <show\|set\|unset> | 724–738 |
| CMD-EXPORT| focus export [basename] | 739–741 |
| CMD-IMPORT| focus import <file> | 742–757 |
| CMD-CYCLE| focus cycle <add\|modify\|delete> | 758–780 |
| CMD-PERIOD| Period resolution (services/period.sh) | 781–800 |
| CMD-INIT| focus init | 801–803 |
| CMD-RESET| focus reset | 804–808 |
| CMD-HELP| focus help [cmd] | 809–821 |

---

## Component surfaces (for reproduction)

| Code | Surface | Lines |
|---|---|---|
| PORT| database.sh — full intent API | 294–446 |
| CORE| core/*.sh — time + text helpers | 447–512 |
| CORE-TIME| core/time.sh — duration/time parsing, GNU-BSD split | 452–477 |
| CORE-TEXT| core/text.sh — notes decode + block rendering | 478–512 |
| ENV| env.sh — loader + exports + precedence | 513–535 |
| CRON| cron.sh — nudge + check-in install/remove + entry format | 536–586 |
| NUDGE| focus-nudge — the cron payload | 822–841 |
| CHECKIN| focus-checkin — the check-in cron payload | 842–890 |
| INT-INSTALL| setup.sh | 1037–1050 |
| INT-DESKTOP| refocus.desktop | 1051–1055 |
| INT-SHELL| focus-function.sh | 1056–1066 |

Note: `services/help.sh` and `services/editor.sh` have no surface section of
their own — they are specified where they are used, at CMD-HELP (809–821) and
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
| ARCH-COMPOSER| shared domain rule → composer service, not copy | 286 | ARCH |
| PORT-VOCAB| adapter never hardcodes domain vocabulary; literals arrive as arguments | 304 | PORT |
| PORT-PROJVALID| project names sanitize (¦); notes encode (\x7c); CHECK backstops both | 314 | PORT |
| PORT-NOTES| notes encode newlines/pipe on read | 428 | PORT |
| PORT-BASH32| get_project_totals_in_range aggregates in SQL, not bash | 415 | PORT |
| CORE-DATE| date(1) confined to core/time.sh | 465 | CORE-TIME |
| CORE-LITERAL| domain literals defined once in core/text.sh, handed out by functions | 503 | CORE-TEXT |
| CMD-OFF-RECOVERY| off ignores focus_disabled | 611 | CMD-OFF |
| CMD-PAST-ARGS| optional leading project; don't eat --duration/--date | 651 | CMD-PAST |
| CMD-PAST-ID| numeric id guard before the adapter | 658 | CMD-PAST |
| CMD-PAST-NOOP| a modify that changes nothing is exit 2 | 662 | CMD-PAST |
| CMD-HELP-INTERCEPT| wants_help runs before parsing and db_ensure | 815 | CMD-HELP |
| NUDGE-HISTORY| desktop-entry hint → logged in history | 836 | NUDGE |
| CHECKIN-GUARDS| five silent early exits: no DB, disabled, active, paused, interval=0 | 851 | CHECKIN |
| CHECKIN-DURONLY| logs via record_duration_session, never a timestamped session | 858 | CHECKIN |
| CHECKIN-CASCADE| kdialog → zenity → terminal+dialog → terminal+read → silent | 866 | CHECKIN |
| CHECKIN-RETRY| project prompt loops on blank; note prompt does not | 873 | CHECKIN |
| CHECKIN-TIER3-HANDOFF| terminal tier hands back two bare lines, never pipe-delimited | 881 | CHECKIN |
| SM-INVARIANT| disabled ⇒ idle; active+disabled illegal | 900 | SM |
| CONV-EXIT| exit codes 0/1/2 | 914 | CONV |
| CONV-YES| destructive confirmation tiers (see MAIN.md — code and text currently disagree on tier count, unresolved) | 922 | CONV |
| CONV-REARM| reset/import leave disabled | 928 | CONV |
| CONV-IDEMPOTENT-ENABLE| enable-when-enabled is a no-op | 931 | CONV |
| CONV-DURONLY| duration-only rows have no timestamps | 936 | CONV |
| CONV-ABSENT| absence branched at boundaries, named by renderers, never parsed, never repaired in-app | 941 | CONV |
| CONV-HELP| help is data; no inline usage strings | 965 | CONV |
| CONV-ID| session ids validated in the handler | 970 | CONV |
| CONV-NOTES| encode/decode notes (incl. pipe) across the read boundary | 985 | CONV |
| CONV-NOTES-CLEAR| clearing a note requires $EDITOR; never inferred from silence | 992 | CONV |
| CONV-PORTABLE| GNU+BSD+bash-3.2; no date(1)/sed -i/sed t;/declare -A | 1006 | CONV |
| CONV-ENVFILE| ENV_FILE computed once in env.sh | 526 | ENV |
| CONV-DEADKNOB| every config key has a live reader; dead keys removed | 529 | ENV |
| CRON-BIN| payload paths resolved at call time (nudge + checkin) | 550 | CRON |
| CRON-ENV| entry embeds REFOCUS_ROOT + display env | 553 | CRON |
| CRON-STRIP| fixed-string crontab strip, live only | 557 | CRON |
| CRON-INTERVAL| nudge: validate 1–60 numeric | 563 | CRON |
| CRON-CHECKIN-INTERVAL| checkin: 0 disables, 1–60 minute-stepped, >60 whole hours only | 565 | CRON |
| CRON-CHECKIN-FAILCLOSED| invalid checkin interval fails closed, no stale entry left | 577 | CRON |
| BUILD-NO-REGEN| no whole-file regen through escaping | 1072 | BUILD |
| BUILD-VERIFY| run all three test scripts after changes | 1077 | BUILD |
| BUILD-UTF8| shellcheck under LC_ALL=C.UTF-8 | 1082 | BUILD |
| BUILD-SCOPE| one concern per change | 1084 | BUILD |

---

## Routing recipe (for an agent)

- Rebuilding a single component → load its surface row from *Component surfaces*
  plus every `INV-*` (147–211) and `NAME` (212–246). The invariants bind all of them.
- Implementing one command → load its `CMD-*` row + `PORT` (294–446) + `CONV` (912–1029).
- Resolving an ambiguity → load the relevant rule's line ± its parent section, and
  decide by the WHY, never by local convenience (READ, 9–39).
- Checking your work → `ACCEPT` (1088–1107).
