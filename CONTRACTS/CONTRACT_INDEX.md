# CONTRACT_INDEX.md — refocus-shell

> Line-range index into `MAIN.md` (1213 lines). Lets an agent load a single
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
| ARCH| Architecture & layering                     | 247–298   |
| PORT| Adapter surface (database.sh)               | 299–492   |
| CORE| Domain-helper surface (core/*.sh)           | 493–558   |
| ENV| Environment loader (env.sh)                 | 559–592   |
| CRON| Nudge and check-in scheduling (cron.sh)     | 593–644   |
| CMD| Command surface (lib/)                      | 645–894   |
| NUDGE| Nudge payload (focus-nudge)                 | 895–914   |
| CHECKIN| Check-in payload (focus-checkin)            | 915–963   |
| SM| State machine                               | 964–984   |
| CONV| Conventions                                 | 985–1116  |
| INT| Install & shell integration                 | 1117–1153 |
| BUILD| Build guardrails                            | 1154–1193 |
| ACCEPT| Acceptance                                  | 1194–1213 |

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
| CMD-ON| focus on [project] | 649–660 |
| CMD-OFF| focus off | 661–672 |
| CMD-PAUSE| focus pause | 673–676 |
| CMD-CONTINUE| focus continue | 677–682 |
| CMD-STATUS| focus status | 683–690 |
| CMD-PAST     | focus past <list\|add\|modify\|delete> | 691–729 |
| CMD-REPORT   | focus report <today\|week\|month\|custom N\|cycle [selector]> | 730–746 |
| CMD-ENABLE| focus enable | 747–753 |
| CMD-DISABLE| focus disable | 754–757 |
| CMD-NUDGE    | focus nudge <status\|test> | 758–761 |
| CMD-CHECKIN  | focus checkin <status\|test> | 762–777 |
| CMD-CONFIG   | focus config <show\|set\|unset> | 778–791 |
| CMD-EXPORT| focus export [basename] | 792–794 |
| CMD-IMPORT| focus import <file> | 795–810 |
| CMD-CYCLE| focus cycle <add\|list\|show\|modify\|delete> | 811–844 |
| CMD-PERIOD| Period resolution (services/period.sh) | 845–864 |
| CMD-INIT| focus init | 865–867 |
| CMD-RESET| focus reset | 868–872 |
| CMD-HELP| focus help [cmd] | 873–894 |

---

## Component surfaces (for reproduction)

| Code | Surface | Lines |
|---|---|---|
| PORT| database.sh — full intent API | 299–492 |
| CORE| core/*.sh — time + text helpers | 493–558 |
| CORE-TIME| core/time.sh — duration/time parsing, GNU-BSD split | 498–523 |
| CORE-TEXT| core/text.sh — notes decode + block rendering | 524–558 |
| ENV| env.sh — loader + exports + precedence | 559–592 |
| CRON| cron.sh — nudge + check-in install/remove + entry format | 593–644 |
| NUDGE| focus-nudge — the cron payload | 895–914 |
| CHECKIN| focus-checkin — the check-in cron payload | 915–963 |
| INT-INSTALL| setup.sh | 1124–1137 |
| INT-DESKTOP| refocus.desktop | 1138–1142 |
| INT-SHELL| focus-function.sh | 1143–1153 |

Note: `services/help.sh`, `services/editor.sh` and `services/listing.sh` have
no surface section of their own — `listing.sh` (the shared row renderer for
`past list` / `cycle list` / `cycle show`) is specified at CMD-PAST and
CMD-CYCLE where it's used; `help.sh`/`editor.sh` at CMD-HELP (873–894) and
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
| ARCH-ROUTABLE| dispatcher routes only to lib/ | 276 | ARCH |
| ARCH-ROOT| REFOCUS_ROOT via realpath(BASH_SOURCE) | 280 | ARCH |
| ARCH-SOURCE| handler source order | 285 | ARCH |
| ARCH-COMPOSER| shared domain rule → composer service, not copy; presentation-only sharing counts too | 287 | ARCH |
| PORT-VOCAB| adapter never hardcodes domain vocabulary; literals arrive as arguments | 319 | PORT |
| PORT-PROJVALID| project names sanitize (¦); notes encode (\x7c); CHECK backstops both | 329 | PORT |
| PORT-NOTES| notes encode newlines/pipe on read (six full-row reads) | 471 | PORT |
| PORT-BASH32| get_project_totals_in_range aggregates in SQL, not bash | 452 | PORT |
| CORE-DATE| date(1) confined to core/time.sh | 511 | CORE-TIME |
| CORE-LITERAL| domain literals defined once in core/text.sh, handed out by functions | 549 | CORE-TEXT |
| CMD-OFF-RECOVERY| off ignores focus_disabled | 669 | CMD-OFF |
| CMD-PAST-ARGS| optional leading project; don't eat --duration/--date | 709 | CMD-PAST |
| CMD-PAST-ID| numeric id guard before the adapter | 716 | CMD-PAST |
| CMD-PAST-NOOP| a modify that changes nothing is exit 2 | 720 | CMD-PAST |
| CMD-HELP-INTERCEPT| wants_help runs before parsing and db_ensure; lib/help.sh is the deliberate exception | 879 | CMD-HELP |
| NUDGE-HISTORY| desktop-entry hint → logged in history | 909 | NUDGE |
| CHECKIN-GUARDS| five silent early exits: no DB, disabled, active, paused, interval=0 | 924 | CHECKIN |
| CHECKIN-DURONLY| logs via record_duration_session, never a timestamped session | 931 | CHECKIN |
| CHECKIN-CASCADE| kdialog → zenity → terminal+dialog → terminal+read → silent | 939 | CHECKIN |
| CHECKIN-RETRY| project prompt loops on blank; note prompt does not | 946 | CHECKIN |
| CHECKIN-TIER3-HANDOFF| terminal tier hands back two bare lines, never pipe-delimited | 954 | CHECKIN |
| SM-INVARIANT| disabled ⇒ idle; active+disabled illegal | 973 | SM |
| CONV-EXIT| exit codes 0/1/2 | 987 | CONV |
| CONV-YES| three-tier confirmation: literal yes / y-N / Y-n, EOF covered per-tier | 995 | CONV |
| CONV-REARM| reset/import leave disabled | 1006 | CONV |
| CONV-IDEMPOTENT-ENABLE| enable-when-enabled is a no-op | 1009 | CONV |
| CONV-DURONLY| duration-only rows have no timestamps | 1014 | CONV |
| CONV-ABSENT| absence branched at boundaries, named by renderers, never parsed, never repaired in-app | 1019 | CONV |
| CONV-HELP| help is data; no inline usage strings | 1043 | CONV |
| CONV-ID| session ids validated in the handler | 1048 | CONV |
| CONV-NOTES| encode/decode notes (incl. pipe) across the read boundary | 1063 | CONV |
| CONV-NOTES-CLEAR| clearing a note requires $EDITOR; never inferred from silence | 1070 | CONV |
| CONV-PORTABLE| GNU+BSD+bash-3.2; no date(1)/sed -i/sed t;/declare -A | 1084 | CONV |
| CONV-SURFACE| removing/renaming a user-facing command needs explicit sign-off + default deprecation shim | 1104 | CONV |
| CONV-ENVFILE| ENV_FILE computed once in env.sh; DB_PATH-change split-brain confirmed live, not fixed | 572 | ENV |
| CONV-DEADKNOB| every config key has a live reader; dead keys removed | 586 | ENV |
| CRON-BIN| payload paths resolved at call time (nudge + checkin) | 607 | CRON |
| CRON-ENV| entry embeds REFOCUS_ROOT + display env | 610 | CRON |
| CRON-STRIP| fixed-string crontab strip, live only | 614 | CRON |
| CRON-INTERVAL| nudge: validate 1–60 numeric | 621 | CRON |
| CRON-CHECKIN-INTERVAL| checkin: 0 disables, 1–60 minute-stepped, >60 whole hours only | 623 | CRON |
| CRON-CHECKIN-FAILCLOSED| invalid checkin interval fails closed, no stale entry left | 635 | CRON |
| BUILD-NO-REGEN| no whole-file regen through escaping | 1159 | BUILD |
| BUILD-VERIFY| run all three test scripts after changes | 1164 | BUILD |
| BUILD-UTF8| shellcheck under LC_ALL=C.UTF-8 | 1170 | BUILD |
| BUILD-SCOPE| one concern per change; found-but-out-of-scope is logged, never folded in | 1172 | BUILD |
| BUILD-RELOCATE| grep full repo before AND after relocating/renaming a cross-file symbol or surface | 1182 | BUILD |

---

## Routing recipe (for an agent)

- Rebuilding a single component → load its surface row from *Component surfaces*
  plus every `INV-*` (147–211) and `NAME` (212–246). The invariants bind all of them.
- Implementing one command → load its `CMD-*` row + `PORT` (299–492) + `CONV` (985–1116).
- Resolving an ambiguity → load the relevant rule's line ± its parent section, and
  decide by the WHY, never by local convenience (READ, 9–39).
- Checking your work → `ACCEPT` (1194–1213).
