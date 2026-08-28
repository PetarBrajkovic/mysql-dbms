# 0006 — The bad plan was never costed against anything, and the trace is the only place that says so — evidence

Detail split out of `learning-records/0006-optimizer-trace-and-for-connection.md` so the record itself stays short.
Measured numbers, produced artifacts and write-up notes for that session. Read this only when writing or checking the chapter it belongs to, not when planning a lesson.

## Live run (2026-08-28, MySQL 8.4.11) — every number in the lesson is measured

| what | measured |
|---|---|
| trace phases, tracing a `SELECT` | `join_preparation`, `join_optimization`, `join_execution` |
| trace phases, tracing an `EXPLAIN` | `join_preparation`, `join_optimization`, **`join_explain`** |
| steps inside `join_optimization` (2-table query) | 9 |
| trace size, 2-table query / 6-table join | ≈ 9,6 KB / ≈ 274–318 KB |
| truncation at `max_mem_size=16384` | `MISSING_BYTES` ≈ 257.000–294.000, `LENGTH(TRACE)` ≈ 16.000 |
| default `optimizer_trace_max_mem_size` | **1048576**, not the 16 KB the research memo claims |
| two costed join orders (`payment`/`customer`) | both present; winner is the smaller `cost_for_plan` |
| same two orders, three separate runs | 3.599/5.836, 4.657/10.337, 7.796/18.215 — **run-dependent** |
| `film` rejected index | `"chosen": false`, `"cause": "cost"`; range 350–1.101 vs scan 105–114 |
| bad plan: costed access paths | **1**, `access_type: "scan"`, cost ≈ 574.800 |
| bad plan: `EXPLAIN`'s reported cost | **0,838** |
| the override step | `plan_changed: true`, `index: idx_created_at`, `"steps": []` |
| same query without `LIMIT` | `plan_changed: false`; `EXPLAIN` → `type=ALL`, `Using filesort` |
| same query with `LIMIT 10000` | `plan_changed: true` — size of the limit is irrelevant |
| six-table join: partial plans / abandoned | 195/97 and 169/85 on two runs |
| traces visible from another session | **0** |
| `FOR CONNECTION` outcomes | plan · 1235 · 3012 · empty · 1094 · 1295 |

## Artifacts produced

- `examples/04-explain/08-anatomija-traga.sql`, `09-odbijeni-planovi-i-cene.sql`,
  `10-zasto-bas-ovaj-plan.sql` — all three smoke-tested end to end against the live server, no
  errors, and their `JSON_TABLE`/`JSON_EXTRACT` paths verified to return real values rather than
  `NULL`. `11-explain-for-connection.sql` is the exception: it needs two Workbench tabs and cannot
  be run as one script, which is stated at the top of the file.
- `figures/04-explain-06-anatomija-traga.png`, `-07-odbijeni-planovi.png`,
  `-08-zasto-bas-ovaj-plan.png`, `-09-explain-for-connection.png` (+ `.svg` twins), via the new
  `tools/make-lesson06-optimizer-trace.ps1`. Self-verifying in the lesson-05 style: it throws if the
  trace stops having three phases, if the two join orders stop differing in cost, if the rejected
  index stops being rejected **for cost**, if the bad plan's index **starts** being costed (which
  would falsify the whole lesson), if the override stops firing with `LIMIT` or **starts** firing
  without it, or if any of the four `FOR CONNECTION` error numbers changes. Figure 09 starts two
  real background `mysql` clients so there is a genuine second session to read a plan out of.
- `GLOSSARY.md` §2e: 9 new terms plus five recorded non-choices.
- `reference/05-optimizer-trace.html`.

## Three PowerShell traps this script hit, worth not re-learning

Beside the two already in `NOTES.md` from lesson 4b (case-insensitive variable names, `č` vs `ć`):

- **`$args` is an automatic variable.** Assigning to it and passing it to `Start-Process` silently
  produced a client that never connected. Renamed to `$mysqlArgs`.
- **`Start-Process -ArgumentList` splits on spaces**, so a path containing spaces (this repo's own
  folder) must carry its own embedded quotes — unlike the `&` call operator used everywhere else in
  these scripts.
- **`2>&1` on a native command throws under `$ErrorActionPreference = 'Stop'`** (NativeCommandError).
  The helper that deliberately captures MySQL's `ERROR` lines has to relax the preference around the
  call, or measuring an expected error crashes the build.

And one MySQL trap that is a teaching point in its own right: **the sentinel `SELECT` used to split
the script's output was itself traced**, and with `optimizer_trace_limit = 1` it overwrote the trace
being fetched. The fix — turn tracing off before reading — is exactly the rule the lesson teaches.

## Terminology decisions worth remembering

Full reasoning is in `GLOSSARY.md` §2e. The one that took actual checking:

**`pristupni put`, not `put pristupa`.** §1 already locked `pristupni put` from the decks. The lesson
was written throughout with `put pristupa`, by false analogy with §2c's `tip pristupa`, and had to be
reverted across the lesson, the reference card, the figure script and two example files. The analogy
is genuinely tempting and will be tempting again in chapter 5.

