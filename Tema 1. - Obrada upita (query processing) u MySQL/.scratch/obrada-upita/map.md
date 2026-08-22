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

- [Install MySQL 8.4, Workbench, and the sample datasets](issues/01-install-mysql-workbench-and-datasets.md):
  MySQL 8.4.11 + Workbench 8.0.47 verified live; Sakila loaded (1000 films); the synthetic
  `obrada_upita.wide_events` table built by `examples/00-setup/` - 5,000,000 rows, 2.1 GB,
  country_code skewed exactly to the designed 70/30 split. One prediction corrected by the live
  server: a skewed secondary index still gets chosen by the optimizer when the query is
  covering (`COUNT(*)`) - selectivity only decides the access path once the query needs
  uncovered columns, a sharper lesson for chapter 4 than originally assumed.
- [Scaffold the Tema 1 workspace and initialise git](issues/03-scaffold-workspace.md): `rad.md`,
  `references.bib`, `ieee.csl`, `examples/`, `figures/` and the full teach workspace
  (`MISSION.md`, `RESOURCES.md`, `NOTES.md`, `lessons/`, `reference/`, `learning-records/`) all
  created at the Tema 1 root.
- [Prove the Markdown to DOCX pipeline with IEEE citations](issues/02-pandoc-export-pipeline.md):
  Pandoc 3.10.2 + the Zotero IEEE CSL file produce a clean, editable `.docx` with correct in-text
  citations, a properly formatted reference list, and intact Serbian diacritics - but only if
  `lang` stays unset (Serbian locale forces the bibliography into Cyrillic), and figure captions
  need their number written into the caption text by hand since Pandoc doesn't auto-number them.
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
- [Research: how MySQL turns SQL into an executing plan](issues/04-research-sql-to-plan-and-iterator.md):
  MySQL has **five** stages, with transformations living inside **resolution**, not a separate rewrite
  stage. The **hypergraph optimizer is compile-gated to debug builds and cannot be demonstrated** on a
  stock 8.4 install. `optimizer_search_depth` defaults to 62. Two items are explicitly uncitable.
- **Destination and paper structure fixed** (this charting session): Serbian, ~20 pages, IEEE, nine
  chapters mapping onto the six slide bullets plus an architecture bridge chapter, an intro and a
  conclusion.
- [Decide the Serbian terminology glossary and lock the paper skeleton](issues/08-terminology-and-skeleton.md):
  full glossary written to `GLOSSARY.md` at the workspace root, binding on every chapter from here on.
  ~30 deck-derived terms adopted verbatim; six terms with no deck precedent (iterator model, plan
  cache, vectorized execution, parallel query execution, prepared statement, cost-based optimizer)
  locked to "Serbian term, English in parentheses on first use only." Chapter skeleton locked at the
  top level (list, order, ~21-page budget - accepted over the nominal ~20, no trimming); subheadings
  deliberately left open per-chapter. Chapter 8 confirmed unchanged by research ticket 06, with the
  plan-cache-vs-parse-tree-cache distinction written in as a hard constraint. Voice: impersonal
  *se*-construction. Citation density: per-paragraph wherever a factual claim appears.
- [Decide the figure and example strategy](issues/09-figure-and-example-strategy.md): full detail
  in `figures/README.md`, binding on every chapter from here on. Non-SQL diagrams (chapter 2
  architecture, and any other conceptual figure) prefer a reused official/existing diagram first,
  original artwork as fallback - the only case needing a source note and a `references.bib` entry.
  Per-chapter budget (~13 figures total, table in `figures/README.md`) is soft guidance against
  chapter 4 swallowing every figure, not a hard quota. Captions hand-typed `Slika N: ...` (Pandoc
  doesn't auto-number). Every SQL-driven figure's script lives in `examples/` under a mirrored
  filename with a back-reference comment; non-SQL diagrams are exempt.
  **Reopened 2026-08-22**: Workbench's Visual Explain broke on the user's machine and manual
  capture/naming/filing didn't scale, so the medium changed from Workbench (Visual Explain,
  in-app TREE text, result grid) to a fully automated agent-run pipeline - `myflames` renders
  `EXPLAIN ANALYZE FORMAT=JSON` to SVG (flame graph/tree/diagram), headless Edge rasterizes it to
  PNG, `tools/make-figure.ps1` / `tools/make-table-figure.ps1` drive it end to end from
  `mysql-credentials.cnf` (gitignored). Naming, budget, captions, and the examples/-as-source-of-
  truth rule are unchanged; see ticket 09's "Reopened" section and `figures/README.md` for the
  mechanics.

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
