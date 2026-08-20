# Map: Obrada upita (query processing) u MySQL

Label: `wayfinder:map`

## Destination

A finished ~20-page seminar paper in Serbian on query processing in MySQL — IEEE-cited, illustrated
with captioned figures of real query execution, exported to Word/PDF — built up chapter by chapter,
where each chapter is *first taught* to the user as a lesson and *then* written. Reached when
`rad.md` contains all nine chapters, the bibliography is complete, and the DOCX/PDF export is
verified.

## Notes

**Domain**: MySQL 8.4 query processing — parsing, optimization, the iterator executor, EXPLAIN /
EXPLAIN ANALYZE, plan caching, and where MySQL sits relative to systems that vectorize and
parallelize.

**Execution override**: this map is *not* planning-only. Wayfinder's default is to stop once the
decisions are made; here the chapter tickets deliberately carry execution — a chapter ticket is
resolved only when the lesson has been taught, the examples run, and the Serbian prose is appended to
`rad.md`.

**Skills every session must consult**:
- `academic-research-writer` — **mandatory** for all prose that lands in the paper. Non-negotiable;
  the user has restated it emphatically.
- `/mattpocock-skills:teach` — drives the lesson half of each chapter ticket. It cannot be invoked by
  the agent (`disable-model-invocation: true`); ask the user to type the slash command.
- `pdf-reader` — for every PDF, including the lecture decks in `../../../Predavanja/`.
- `mattpocock-skills:grilling` + `domain-modeling` — for the two decision tickets.

**Standing preferences**:
- Paper in Serbian, written Serbian-first per chapter. Everything else (lessons, notes, commits,
  these files) in English.
- All artifacts stay inside the `Tema 1. ...` folder. Tema 2 and Tema 3 will get their own.
- Subagents run on **haiku** with narrow, specific briefs.
- Every substantive chapter needs runnable SQL plus at least one captioned figure.
- Nominal timebox five weeks; no hard deadline.

## Decisions so far

- [Research: mine the lecture decks for required content and terminology](issues/07-research-mine-lecture-decks.md):
  the decks are **general theory from Ramakrishnan & Gehrke, not MySQL-specific**. They back chapters
  1-5 with citable slide numbers and yield a ~40-term Serbian glossary, but give **zero** coverage of
  chapters 6-8, which must come entirely from external sources.
- [Research: vectorized execution, parallel execution, and plan caching in MySQL](issues/06-research-vectorized-parallel-plancache.md):
  chapters 6, 7 and 8 all survive. MySQL is row-at-a-time (no vectorization), its parallelism excludes
  ordinary `SELECT`s, and it has no shared plan cache - though it does cache prepared-statement
  **parse trees** per session, a distinction chapter 8 must draw precisely.
- [Research: EXPLAIN, EXPLAIN ANALYZE, and optimizer trace](issues/05-research-explain-semantics.md):
  ample material for chapter 4, organised around the ranked access `type` values and around
  **estimated vs actual row divergence** as the core diagnostic. Two claims flagged for empirical
  check against the live server: the "3x divergence" heuristic and JSON format version 2.
- **Destination and paper structure fixed** (this charting session): Serbian, ~20 pages, IEEE, nine
  chapters mapping onto the six slide bullets plus an architecture bridge chapter, an intro and a
  conclusion.

## Not yet specified

- **Lesson-to-chapter cadence.** One teach lesson per chapter is the assumption, but the thin
  chapters (6 and 7, both comparative) may deserve a single shared lesson. Revisit once the first two
  lessons show how long one actually takes.
- **Session pacing across the five weeks.** Depends on how heavy the first chapter turns out.
- **Whether the synthetic dataset needs to grow or change** for the parallel-execution chapter
  specifically — unknown until the MySQL install and the first EXPLAIN runs reveal what the optimizer
  does at what row counts.
- **A final Serbian proofreading / consistency pass** over the whole paper. Almost certainly needed,
  but its shape depends on how consistent the terminology glossary keeps things.
- **GitHub remote.** The user wants it eventually; explicitly low priority. Local git only for now.
- **Whether chapters 6-8 need rebalancing.** With no lecture backing at all, they rest entirely on
  external sources; if research ticket 06 finds thin material, their combined 6-page budget may be
  better spent on chapters 3 to 5. Decide in ticket 08.
- **Reference documents / cheat sheets** in the teach workspace (`reference/*.html`) — which ones
  earn their place is unknown until several lessons exist.

## Out of scope

- **The PowerPoint presentation for the defense.** A separate deliverable the user will handle
  separately; ruled out during charting.
- **The title page and faculty logo.** The user makes these themselves in Word after export.
- **Tema 2 and Tema 3.** Separate efforts, separate folders, separate maps.
- **Lecture decks `05_Oporavak` and `06_Sigurnost`.** Recovery and security are unrelated to query
  processing; they will not be mined or cited.
- **Building any application.** The professor asked for isolated examples, not a working app.
