# Map: Obrada upita (query processing) u MySQL

Label: `wayfinder:map`

## Destination

A finished seminar paper in Serbian on query processing in MySQL, **≤25 rendered pages** — IEEE-cited,
illustrated with captioned figures of real query execution, exported to Word/PDF — built up chapter by
chapter, where each chapter is *first taught* to the user as a lesson and *then* written. Reached when
`rad.md` contains all **seven** chapters, the bibliography is complete, and the DOCX/PDF export is
verified.

**Revised 2026-08-31**: nine chapters became seven (old 6/7/8 merged), and the nominal "~20 pages"
became a hard ≤25 measured in the export. See [Fit the paper to a page ceiling](issues/20-page-budget-and-chapter-merge.md).

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
- **GitHub remote exists and is in use** (confirmed 2026-08-31): `origin` is
  `github.com/PetarBrajkovic/mysql-dbms.git`, `master` tracks `origin/master`, and the repo root is
  the **course** folder, so a push carries the shared layer and every topic together. This was listed
  as unspecified/low-priority fog for most of the effort; it is settled, so push as part of finishing
  a chapter rather than treating it as optional.
- Subagents run on **haiku** with narrow, specific briefs.
- Every substantive chapter needs runnable SQL plus at least one captioned figure.
- **Reference cards: one per lesson, no deliberation** (settled 2026-08-31). This was charted as fog
  ("which ones earn their place is unknown until several lessons exist"); six lessons produced six
  cards, `reference/00-`..`05-`, so the question answered itself. Write one with each lesson rather
  than curating a set afterwards. They are user-facing learning artifacts, so they are in Serbian and
  are **not** read by default when teaching (`../TEACHING.md`).
- Nominal timebox five weeks; no hard deadline. **Pacing settled 2026-08-31**, from the actual
  history rather than a guess: charting to a finished chapter 4 took **11 days** (2026-08-20 to
  08-31), sessions landing roughly **every two days**, one lesson *or* one chapter per session. The
  established rhythm is that **a lesson and its chapter are written in different sessions** (4a
  taught 08-24 / written 08-26; 4b 08-26 / 08-28; 4c 08-28 / 08-31), which is also why the map's
  one-ticket-per-session norm has held. Three chapters remain, so ~6 sessions, comfortably inside
  the five weeks. Do not plan a session that teaches *and* writes the same chapter.
- **Citation sourcing (set 2026-08-22):** the user's own university material — the lecture decks and
  PDFs in `../../Predavanja/` (Stoimenov SUBP slides) — is for *learning* only and is **never cited**
  in the paper. Deck-backed claims are cited to their published origin instead: Ramakrishnan & Gehrke
  for theory, the MySQL manual for MySQL-specifics. Applies to every chapter; see WORKFLOW.md rule 7.
- **Paper export**: `../tools/make-docx.ps1` (shared, at the course level) (title page `naslovna.md` + `rad.md`, IEEE citations) is the
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
  `references.bib`, `../ieee.csl` (shared), `examples/`, `figures/` and the full teach workspace
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
  PNG, `../tools/make-figure.ps1` / `../tools/make-table-figure.ps1` (shared) drive it end to end from
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

- [Chapter 4b. EXPLAIN ANALYZE: procenjeno naspram stvarnog](issues/13b-explain-analyze.md): the
  chapter's centrepiece written and closed. ~1.080 words of `rad.md` in three subsections (§4.5-4.7)
  on one spine: **`EXPLAIN` prints a number, `EXPLAIN ANALYZE` prints the same number beside the
  measurement, and only the pair is a diagnosis**. The divergence example is **4a's own query**, so
  the arithmetic 4a taught the reader (`16.500 × 33,33% = 5.499`) is revealed as a **48x** miss
  against 114 measured, with the table scan beside it at 1,03x to localise the miss to one node.
  The threshold question is answered as a **caveat, not a rule**: that same 48x leaves a five-table
  join order identical, so divergence means the decision used a wrong number, not that it is wrong.
  Histograms are shown failing twice on purpose (they close the gap on non-indexed `amount`,
  33,33 → 0,71, but change nothing on indexed `country_code`, and nothing at all in §4.7 where
  `LIMIT` caps the costed rows before corrected selectivity can act). §4.7 delivers the required
  bad-plan diagnosis: a plan whose every `EXPLAIN` column reads as ideal (`type: index`, `rows: 10`,
  cost 0,836) reads 31.621 rows in ~2.786 ms, while the `IGNORE INDEX` alternative that `EXPLAIN`
  costs ~686.000x higher runs ~1,5x faster. The reserved `wide_events`/`country_code` example was
  **demoted** to a 1,43x below-threshold illustration, per LR-0005 overriding the ticket's own scope.
  No new citations (all `mysql84refman`); the two places the live server outruns the manual are
  written as measured behaviour with the server and format version named. Fifth clean pass of the
  per-chapter loop, and it also corrected research memo `05-explain-semantics.md` §2.6.
  **Budget flag left open for 13c**: chapter 4 stands at ~5,6 of its 6 pages, so 13c either takes
  ~0,5 pages or the chapter goes slightly over. The user's call, and nothing gets trimmed for it.

- [Chapter 4c. Trag optimizatora](issues/13c-optimizer-trace.md): chapter 4 finished, §4.8-4.9,
  ~590 words plus one figure, and it did **not** fold into 4b. The spine is stronger than the ticket
  asked for: `EXPLAIN` printing the winner and not the losers is delivered (§4.2's
  `idx_fk_original_language_id` is now *shown* losing on `"cause": "cost"`, measured rather than
  inferred), but the centre of gravity is §4.7's bad plan. `considered_execution_plans` costs
  **exactly one** access path for `wide_events`, the table scan, and `idx_created_at` never appears
  there at all; the later `reconsidering_access_paths_for_index_ordering` step flips the plan with an
  **empty `"steps"` array**. So the plan `EXPLAIN` prices at 0,846 was **installed by a rule, not won
  in a comparison**, and that price is computed *after* the swap. `LIMIT` is the trigger, verified by
  removing it and by `LIMIT 10000`; this retroactively explains why §4.7's histogram corrected the
  estimate and changed nothing. Written honestly about the trace's limits (`"chosen": true` means
  "best so far"; pruned plans survive only as `"pruned_by_cost"`; session-scoped; truncates). §4.9
  gives `EXPLAIN FOR CONNECTION` the other half of the two-window framing, its error outcomes written
  as measured on 8.4.11 rather than as the manual's wording. No new citations. Sixth clean pass of the
  per-chapter loop.

- [Fit the paper to a page ceiling](issues/20-page-budget-and-chapter-merge.md): the user flagged the
  DOCX at 20 pages with chapters still to go. **Measuring first reframed it**: only ~1,5 pages are
  front/back matter (not the 4-5 assumed), figures are ~4,5, and since `rad.md` has **zero code
  fences** every SQL statement in the paper *is* a figure, so "remove a couple of pictures" deletes
  evidence and saves ~0,4 pages each against a projected 31-35. Decisions: ~20 is soft but **≤25
  rendered pages is hard**; the standing *"never trim written prose"* rule is **suspended** for this
  paper (scoped to redundancy, not to taught material); **old chapters 6/7/8 merge into chapter 6**
  with the conclusion becoming 7; the figure budget becomes a **firm cap** (ch5: 2, ch6: 1, ch7: 0);
  chapter 4 keeps its 6.6 and 4c keeps its full page. **Layout alone took 20 -> 18 with nothing
  removed** (explicit figure widths — Slika 2.1 was rendering 5,21 x 5,55 in off a 500 px PNG — plus
  10pt -> 6pt paragraph spacing). Also fixed a latent bug found on the way: neither the export nor the
  shared reference doc set `pgSz`/`pgMar`, so pagination depended on whose Word opened the file; now
  pinned to A4/2,5 cm. **The prose trim under-delivered** (~90 words, not ~2 pages — the prose is
  already dense), which is recorded so it is not budgeted as a lever again. The budget is now stated
  in **rendered DOCX pages** and re-measured every chapter; the old unit is why 13.6 budgeted pages
  rendered as ~17 unnoticed.

- [Chapter 5. Iterator model i pipeline operatora](issues/14-iterator-model.md): the chapter where
  the plan stops being a table of numbers and becomes running code, written and closed. §5.1-5.5,
  ~1.450 words plus two figures, **measured at exactly its 3-page budget** (export 19 -> 22). It
  opens on a puzzle rather than a definition: the same scan under the same `LIMIT 10` reads ten rows
  or five million, and the only difference is one `ORDER BY`. The answer runs in three moves plus a
  seam. **The interface**: `RowIterator` with `Init()`/`Read()`/`UnlockRow()`, where the row is *not*
  the return value but goes into `table->records[0]`, so Volcano supplied the control flow while
  MySQL kept its own record-buffer convention, and where an iterator reading from another iterator is
  why the plan is a tree. **The tree**: `FORMAT=TREE` nodes *are* iterators, and the printed-string →
  class mapping is mechanics, since `explain_access_path.cc` and `access_path.cc` branch on the same
  `path->type`; `-> Hash` is the one printed row that is not an iterator. **`loops`**: 4b's rule
  becomes a consequence of `GetNumInitCalls()`, giving inner `loops` = outer `rows` = 584 and
  `26.8 × 584 ≈ 15.651` against the join's 15.640. **Pipeline vs. blocking** discharges the opening
  puzzle: the scan is not "optimized to stop", it stops being called, and first-row-vs-last-row is a
  blocking detector the reader can apply without knowing any operator. **§5.5** ties `AccessPath` 1:1
  to iterators and retroactively answers 4c's empty `join_execution`: execution decides nothing.
  Two new citations, IEEE [6]-[7]: `graefe1994` (the chapter's one theory citation, since the decks
  cover none of this) and `mysqlwl11785`, whose page carries **no publication date**, so the entry
  claims none rather than inventing a year. Also carried LR-0007 (e)'s correction into the paper: the
  `IndexScanIterator` template parameter is `Reverse`, not covering-ness. Seventh clean pass of the
  per-chapter loop. **Budget flag for chapter 6**: 22 + 2.5 + 0.75 projects to ~25.25 against the
  hard ≤25, so there is no slack left and chapter 6 absorbs any overrun.

## Not yet specified

- **Whether the synthetic dataset needs to grow or change** for the parallel-execution chapter
  specifically — unknown until the MySQL install and the first EXPLAIN runs reveal what the optimizer
  does at what row counts.
- **A final Serbian proofreading / consistency pass** over the whole paper. Almost certainly needed,
  but its shape depends on how consistent the terminology glossary keeps things.

## Out of scope

- **The PowerPoint presentation for the defense.** A separate deliverable the user will handle
  separately; ruled out during charting.
- **The title page and faculty logo.** The user makes these themselves in Word after export.
- **Tema 2 and Tema 3.** Separate efforts, separate folders, separate maps.
- **Lecture decks `05_Oporavak` and `06_Sigurnost`.** Recovery and security are unrelated to query
  processing; they will not be mined or cited.
- **Building any application.** The professor asked for isolated examples, not a working app.
