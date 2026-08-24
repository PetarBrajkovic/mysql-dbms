# Chapter 3. Od SQL-a do plana izvrsavanja

Type: task
Status: resolved
Blocked by: 09, 11

## Question

Execution ticket - this map carries execution, so it resolves only when all four are done.

**Target length**: ~3.5 pages of `rad.md`.

**Scope**: Slide bullet: SQL to execution plan transformation. Parsing and resolution, logical rewrites, cost-based optimization, join-order search, and access-path selection. Needs a worked example where the optimizer visibly chooses between two access paths.

**Definition of done**:
1. The user has been taught this chapter via `/mattpocock-skills:teach` (they must invoke it
   themselves) and a lesson exists in `lessons/`.
2. Runnable SQL committed to `examples/`, and at least one captioned figure in `figures/`, per the
   strategy set in ticket 09.
3. Serbian prose appended to `rad.md` **using the `academic-research-writer` skill**, with IEEE
   citations added to `references.bib` as they are used.
4. A learning record written to `learning-records/`, and the work committed.

**Grounding**: research ticket 04, plus the lecture mapping from ticket 07 and the glossary
from ticket 08.

## Answer

Resolved 2026-08-24. All four Definition-of-Done items complete; Chapter 3 (Od SQL-a do plana
izvršavanja) written to `rad.md`.

1. **Taught.** Lesson `lessons/0003-od-sql-a-do-plana-izvrsavanja.html` ("Pet faza i jedna cena"),
   reference card `reference/02-od-sql-a-do-plana.html`, learning record
   `learning-records/0003-five-phases-and-one-cost.md` (status now "taught and written"). Grounded on
   research memo 04 and glossary §2b, which was locked during the teach session (~26 pipeline/optimizer
   terms).
2. **SQL + figures.** Five scripts in `examples/03-od-sql-a-do-plana/` (parser-vs-resolver;
   transformations in preparation; access-path choice; join-order search; cost model), all
   smoke-tested live against MySQL 8.4.11. Four figures exist; **two carried into the paper** to
   match `figures/README.md`'s budget of 2 for this chapter:
   - **Slika 3.1** `03-od-sql-a-do-plana-04-pet-faza-pregled.png`, the five-phase pipeline diagram.
     Hand-built conceptual SVG (no myflames), so it had no PNG twin; rasterized SVG→PNG via headless
     Edge (the make-figure.ps1 rasterize step). Two em dashes in the SVG text removed first, per
     WORKFLOW rule 8 (figure text included).
   - **Slika 3.2** `03-od-sql-a-do-plana-01-ukrstanje-cena.png`, the access-path cost crossover, which
     is the "optimizer visibly chooses between two access paths" worked example the ticket scope
     required.
   The two join-order figures (`...-02/03-redosled-spoja-dubina-62/1`) stayed lesson-only; the 150:1
   result is carried into §3.5 as cited prose.
3. **Serbian prose in `rad.md`** via `academic-research-writer` + `serbian-grammar`. ~3.5 pages,
   impersonal *se*-voice, glossary §2b terms verbatim (poluspoj/antispoj written solid; `optimizer_trace`
   keys in code font; cena never *trošak*); no em dash. Six subsections: 3.1 five phases and the
   three optimizer_trace steps; 3.2 parser/resolution and the transformation-vs-strategy line (with
   the WL#7082 memory-lifetime reason and the equality-propagation counterexample); 3.3 cost model as
   arithmetic over `server_cost`/`engine_cost`; 3.4 access-path choice and `cause: "cost"`; 3.5
   join-order search (`greedy_search` + `best_extension_by_limited_search`, depth 62 = MAX_TABLES+1);
   3.6 what is deferred (EXPLAIN→ch4, iterators→ch5, hypergraph optimizer as documented-not-demonstrated,
   pinned to 8.4). One new source added to `references.bib` and cited: **`mysqlwl7082`** (MySQL
   Worklog WL#7082, a published worklog, citable per rule 7). `mysql84refman`, `mysqlsource84`,
   `ramakrishnan2003` reused. Chapter closes with the bridge into ch. 4.
4. **Verified + committed.** `tools/make-docx.ps1` builds `rad.docx` clean, exit 0, no undefined
   citation keys; both chapter figures resolve.
