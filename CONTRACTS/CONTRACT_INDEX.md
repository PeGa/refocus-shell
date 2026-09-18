# CONTRACT_INDEX.md — refocus-shell

> Line-range index into `MAIN.md` (1238 lines). Lets an agent load a single
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
| PORT| Adapter surface (database.sh)               | 299–493   |
| CORE| Domain-helper surface (core/*.sh)           | 494–559   |
| ENV| Environment loader (env.sh)                 | 560–593   |
| CRON| Nudge and check-in scheduling (cron.sh)     | 594–647   |
| CMD| Command surface (lib/)                      | 648–904   |
| NUDGE| Nudge payload (focus-nudge)                 | 905–924   |
| CHECKIN| Check-in payload (focus-checkin)            | 925–973   |
| SM| State machine                               | 974–994   |
| CONV| Conventions                                 | 995–1131  |
| INT| Install & shell integration                 | 1132–1178 |
| BUILD| Build guardrails                            | 1179–1218 |
| ACCEPT| Acceptance                                  | 1219–1238 |

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
| CMD-ON| focus on [project] | 652–663 |
| CMD-OFF| focus off | 664–675 |
| CMD-PAUSE| focus pause | 676–679 |
| CMD-CONTINUE| focus continue | 680–685 |
| CMD-STATUS| focus status | 686–693 |
| CMD-PAST     | focus past <list\|add\|modify\|delete> | 694–733 |
| CMD-REPORT   | focus report <today\|week\|month\|custom N\|cycle [selector]> | 734–753 |
| CMD-ENABLE| focus enable | 754–760 |
| CMD-DISABLE| focus disable | 761–764 |
| CMD-NUDGE    | focus nudge <status\|test> | 765–768 |
| CMD-CHECKIN  | focus checkin <status\|test> | 769–787 |
| CMD-CONFIG   | focus config <show\|set\|unset> | 788–801 |
| CMD-EXPORT| focus export [basename] | 802–804 |
| CMD-IMPORT| focus import <file> | 805–820 |
| CMD-CYCLE| focus cycle <add\|list\|show\|modify\|delete> | 821–854 |
| CMD-PERIOD| Period resolution (services/period.sh) | 855–874 |
| CMD-INIT| focus init | 875–877 |
| CMD-RESET| focus reset | 878–882 |
| CMD-HELP| focus help [cmd] | 883–904 |

---

## Component surfaces (for reproduction)

| Code | Surface | Lines |
|---|---|---|
| PORT| database.sh — full intent API | 299–493 |
| CORE| core/*.sh — time + text helpers | 494–559 |
| CORE-TIME| core/time.sh — duration/time parsing, GNU-BSD split | 499–524 |
| CORE-TEXT| core/text.sh — notes decode + block rendering | 525–559 |
| ENV| env.sh — loader + exports + precedence | 560–593 |
| CRON| cron.sh — nudge + check-in install/remove + entry format | 594–647 |
| NUDGE| focus-nudge — the cron payload | 905–924 |
| CHECKIN| focus-checkin — the check-in cron payload | 925–973 |
| INT-INSTALL| setup.sh | 1139–1162 |
| INT-DESKTOP| refocus.desktop | 1163–1167 |
| INT-SHELL| focus-function.sh | 1168–1178 |

Note: `services/help.sh` and `services/editor.sh` have no surface section of
their own — specified where they're used, at CMD-HELP (883–904) and
CMD-OFF / CMD-PAST respectively. `services/listing.sh` (the shared row
renderer) is named explicitly at both CMD-PAST (`list --show-cycles`) and
CMD-CYCLE (`list`/`show`), where it's used.

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
| PORT-VOCAB| adapter never hardcodes domain vocabulary; literals arrive as arguments | 320 | PORT |
| PORT-PROJVALID| project names sanitize (¦); notes encode (\x7c); CHECK backstops both | 330 | PORT |
| PORT-NOTES| notes encode newlines/pipe on read (six full-row reads) | 472 | PORT |
| PORT-BASH32| get_project_totals_in_range aggregates in SQL, not bash | 453 | PORT |
| CORE-DATE| date(1) confined to core/time.sh | 512 | CORE-TIME |
| CORE-LITERAL| domain literals defined once in core/text.sh, handed out by functions | 550 | CORE-TEXT |
| CMD-OFF-RECOVERY| off ignores focus_disabled | 672 | CMD-OFF |
| CMD-PAST-ARGS| optional leading project; don't eat --duration/--date | 712 | CMD-PAST |
| CMD-PAST-ID| numeric id guard before the adapter | 719 | CMD-PAST |
| CMD-PAST-NOOP| a modify that changes nothing is exit 2 | 723 | CMD-PAST |
| CMD-HELP-INTERCEPT| wants_help runs before parsing and db_ensure; lib/help.sh is the deliberate exception | 889 | CMD-HELP |
| NUDGE-HISTORY| desktop-entry hint → logged in history | 919 | NUDGE |
| CHECKIN-GUARDS| five silent early exits: no DB, disabled, active, paused, interval=0 | 934 | CHECKIN |
| CHECKIN-DURONLY| logs via record_duration_session, never a timestamped session | 941 | CHECKIN |
| CHECKIN-CASCADE| kdialog → zenity → terminal+dialog → terminal+read → silent | 949 | CHECKIN |
| CHECKIN-RETRY| project prompt loops on blank; note prompt does not | 956 | CHECKIN |
| CHECKIN-TIER3-HANDOFF| terminal tier hands back two bare lines, never pipe-delimited | 964 | CHECKIN |
| SM-INVARIANT| disabled ⇒ idle; active+disabled illegal | 983 | SM |
| CONV-EXIT| exit codes 0/1/2 | 997 | CONV |
| CONV-YES| three-tier confirmation: literal yes / y-N / Y-n, EOF covered per-tier | 1005 | CONV |
| CONV-REARM| reset/import leave disabled | 1016 | CONV |
| CONV-IDEMPOTENT-ENABLE| enable-when-enabled is a no-op | 1019 | CONV |
| CONV-DURONLY| duration-only rows have no timestamps | 1024 | CONV |
| CONV-ABSENT| absence branched at boundaries, named by renderers, never parsed, never repaired in-app | 1029 | CONV |
| CONV-HELP| help is data; no inline usage strings | 1053 | CONV |
| CONV-ID| session ids validated in the handler | 1058 | CONV |
| CONV-NOTES| encode/decode notes (incl. pipe) across the read boundary; report.sh is the deliberate notes_block exception | 1073 | CONV |
| CONV-NOTES-CLEAR| clearing a note requires $EDITOR; never inferred from silence | 1085 | CONV |
| CONV-PORTABLE| GNU+BSD+bash-3.2; no date(1)/sed -i/sed t;/declare -A | 1099 | CONV |
| CONV-SURFACE| removing/renaming a user-facing command needs explicit sign-off + default deprecation shim | 1119 | CONV |
| CONV-ENVFILE| ENV_FILE computed once in env.sh; DB_PATH-change split-brain confirmed live, not fixed | 573 | ENV |
| CONV-DEADKNOB| every config key has a live reader; dead keys removed | 587 | ENV |
| CRON-BIN| payload paths resolved at call time (nudge + checkin) | 608 | CRON |
| CRON-ENV| entry embeds REFOCUS_ROOT + display env (incl. XDG_RUNTIME_DIR) | 611 | CRON |
| CRON-STRIP| fixed-string crontab strip, live only | 617 | CRON |
| CRON-INTERVAL| nudge: validate 1–60 numeric | 624 | CRON |
| CRON-CHECKIN-INTERVAL| checkin: 0 disables, 1–60 minute-stepped, >60 whole hours only | 626 | CRON |
| CRON-CHECKIN-FAILCLOSED| invalid checkin interval fails closed, no stale entry left | 638 | CRON |
| BUILD-NO-REGEN| no whole-file regen through escaping | 1184 | BUILD |
| BUILD-VERIFY| run all three test scripts after changes | 1189 | BUILD |
| BUILD-UTF8| shellcheck under LC_ALL=C.UTF-8 | 1195 | BUILD |
| BUILD-SCOPE| one concern per change; found-but-out-of-scope is logged, never folded in | 1197 | BUILD |
| BUILD-RELOCATE| grep full repo before AND after relocating/renaming a cross-file symbol or surface | 1207 | BUILD |

---

## Routing recipe (for an agent)

- Rebuilding a single component → load its surface row from *Component surfaces*
  plus every `INV-*` (147–211) and `NAME` (212–246). The invariants bind all of them.
- Implementing one command → load its `CMD-*` row + `PORT` (299–493) + `CONV` (995–1131).
- Resolving an ambiguity → load the relevant rule's line ± its parent section, and
  decide by the WHY, never by local convenience (READ, 9–39).
- Checking your work → `ACCEPT` (1219–1238).
