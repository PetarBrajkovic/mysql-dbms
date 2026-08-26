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
- **Citation sourcing (set 2026-08-22):** the user's own university material — the lecture decks and
  PDFs in `../../Predavanja/` (Stoimenov SUBP slides) — is for *learning* only and is **never cited**
  in the paper. Deck-backed claims are cited to their published origin instead: Ramakrishnan & Gehrke
  for theory, the MySQL manual for MySQL-specifics. Applies to every chapter; see WORKFLOW.md rule 7.
- **Paper export**: `tools/make-docx.ps1` (title page `naslovna.md` + `rad.md`, IEEE citations) is the
  one canonical way to build `rad.docx`; never run bare `pandoc rad.md ...`, which drops the title page.

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
  top level (list, order, ~21-page budget - accepted over the nominal ~20, no trimming; **revised to
  ~23 on 2026-08-26** when chapter 4 went from 4 to 6 pages); subheadings
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

- [Chapter 1. Uvod](issues/10-uvod.md): first chapter written and closed. ~1.5 pages of `rad.md`
  frame query processing as *crossing a gap* (declarative SQL → physical procedures), optimized on
  *two levels of one problem* (logical shape-rewrite; physical algorithm + access path) unified by
  **cena**, motivating the paper via "one query → many plans of very different cost." Cited to R&G
  3ed (theory) + MySQL 8.4 manual (MySQL-specifics), rendering as IEEE [1]–[2] — the university
  lecture decks are used for grounding but never cited, per the sourcing rule in Notes; illustrated
  by the reused lesson-01 side-by-side figure
  (`figures/01-uvod-01-jedan-upit-dva-plana.png`); ends with the ch. 2–9 roadmap. First proof that
  the per-chapter loop (teach → run → write with `academic-research-writer` + `serbian-grammar` →
  cite → verify with pandoc) works end to end. Flagged for the revisit-after-conclusion pass the
  ticket called for.

- [Chapter 2. Arhitektura obrade upita u MySQL-u](issues/11-arhitektura.md): bridge chapter written
  and closed. ~2 pages of `rad.md` frame MySQL as **two layers with a documented seam**: the server
  layer that understands SQL, the storage engine (motor) that understands rows and pages, and the
  falsifiable membership test (*does the feature change if you swap the engine?* — Table 18.1 fn 1).
  Traces the statement path (`do_command` → `dispatch_command` → `dispatch_sql_command`, `THD`,
  thread-per-connection), identifies the seam as the `handler` class (iterators call `ha_rnd_next`,
  never touch a page), and shows the two deliberate **leaks** live: ICP (`idx_cond_push(Item*)`,
  Slike 2.2/2.3) and the engine-cardinality-vs-server-histogram statistics split. New citation
  `mysqlsource84` (the **`mysql-8.4.6` source tree**) added and cited for every `handler`-level
  claim, since the manual never documents that C++ interface; renders IEEE [3]. Three figures at
  budget (reused official Figure 18.3 + ICP flame-graph pair). `mysql_parse()` deliberately not
  written (gone in 8.4). Second clean pass of the per-chapter loop.

- [Chapter 3. Od SQL-a do plana izvršavanja](issues/12-sql-u-plan.md): the chapter where *how the
  system chooses* becomes visible, written and closed. ~3.5 pages of `rad.md` in six subsections
  built on one spine: **five named phases (parser, razrešavanje, optimizator, planer, izvršilac),
  one cost line**. Everything above the line (parsing, and the *permanent* tree transformations that
  live in **resolution**, not a separate rewrite pass, per WL#7082's memory-lifetime reason) changes
  the statement's shape once; everything below (access path, join order) is chosen by **cena**, a sum
  of published `server_cost`/`engine_cost` constants times measured quantities. Two cost decisions
  shown flipping live: the access-path crossover (`cause: "cost"`, the ticket's required two-path
  example, Slika 3.2) and join-order search (depth 62 = MAX_TABLES+1, the 150:1 depth-1 result). New
  citation `mysqlwl7082` (WL#7082, a citable published worklog) added, alongside the manual and source
  tree. Two of four lesson figures carried at the 2-figure budget; Slika 3.1 (pipeline diagram) was a
  hand-built SVG rasterized to PNG, with two em dashes stripped from the figure text first (rule 8).
  Third clean pass of the per-chapter loop; the transformation-vs-strategy line and the "cost varies
  between runs" caveat hand off to chapter 4.

- [Chapter 4a. EXPLAIN: formati ispisa i tipovi pristupa](issues/13a-explain-formati-i-tipovi.md):
  the vocabulary half of chapter 4 written and closed. **Chapter 4 is now three tickets, not one**
  (13a here, [13b `EXPLAIN ANALYZE`](issues/13b-explain-analyze.md),
  [13c trag optimizatora](issues/13c-optimizer-trace.md)), matching the 3-lesson split `NOTES.md`
  decided on 2026-08-24, so each taught lesson has a ticket it can close; ticket 14 now waits on 13c.
  Visual Explain dropped from scope for good (ticket 09's reopening). ~3 pages of `rad.md` in four
  subsections on one spine: **`EXPLAIN` prints an estimate, and the estimate has a shape**. Three
  formats are only **two shapes**, one row per *table* (tabular, JSON v1) against one node per
  *iterator* (TREE, JSON v2), bridged by arithmetic the manual prescribes (`rows × filtered / 100` =
  16.500 × 33,33% = 5.499, the `Filter` node's own estimate). Four of twelve columns carry the
  decision; `key` and `key_len` only answer together; `possible_keys` with `key: NULL` is chapter 3's
  `cause: "cost"` seen from the output side. The access-type ladder is **not a cost ranking**
  (`unique_subquery` at rank 8 returns one row, like `eq_ref` at rank 3), and its two subquery types
  are invisible by default because the semijoin transformation runs in *preparation*, before an
  access type exists: chapter 3's finding from the other side. `Extra` closes it by showing chapter
  2's seam in one word (`Using index` / `Using index condition` / `Using where`). New citation
  `mysqlblogjson` (Brevik, MySQL Server Team Blog, 2024) for JSON v2's field semantics, which the
  manual doesn't document; renders IEEE [5]. Two figures at budget. Fourth clean pass of the
  per-chapter loop, and it also **closed one of `WORKFLOW.md`'s two open live-server questions**
  (`explain_json_format_version = 2` works on 8.4.11). **Raised chapter 4's page budget**: this half alone ate ~3
  of chapter 4's ~4 pages with nothing padded, so on 2026-08-26 the user raised chapter 4 from 4 to
  **6 pages** (paper total ≈21 -> ≈23, `GLOSSARY.md` §4) rather than squeeze `EXPLAIN ANALYZE` and
  the optimizer trace into ~1 shared page and gut the chapter's centrepiece. 13b now targets ~2
  pages, 13c ~1, and 13c folds into 13b only if thin on its own merits.

## Not yet specified

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
