# Chapter 6. Gde MySQL ne prati obrazac

Type: task
Status: closed 2026-08-31
Blocked by: 14 (closed)

## Question

Execution ticket - this map carries execution, so it resolves only when all four are done.
**Supersedes tickets 15, 16 and 17**, merged into one chapter on 2026-08-31 under the ≤25-page
target; see [Fit the paper to a page ceiling](20-page-budget-and-chapter-merge.md).

**Target length**: ~2.5 rendered pages, **one figure** (firm cap, `GLOSSARY.md` §4). If chapter 5
overruns its 3 pages, this chapter gives the page back.

**Scope**: three slide bullets under one thesis, as three subsections. The thesis is `MISSION.md`'s
own success criterion: *state precisely, with evidence, where MySQL does not match the pattern of
other systems, rather than assuming it matches by default.* Write the shared framing **once**, at
the chapter head; the three merged tickets each had their own intro, and dropping two of those is
part of what the merge buys.

- **§6.1 Vektorizovano izvršavanje** (was ticket 15): what vectorized execution is, why row-at-a-time
  MySQL does not do it, what that costs, and where HeatWave changes the picture.
- **§6.2 Paralelno izvršavanje upita** (was ticket 16): what is actually parallel in stock MySQL 8.4
  against Postgres and Oracle. Chapter 2 already planted the hook (`thread_handling` =
  `one-thread-per-connection`, and §2's forward reference now points *here*, at §6.2). Demonstrate
  InnoDB parallel read threads against the synthetic table, where the effect is measurable.
- **§6.3 Keširanje i ponovna upotreba planova** (was ticket 17): why MySQL has no shared plan cache,
  why the query cache was removed in 8.0, and what prepared statements actually reuse. **Hard
  constraint, `GLOSSARY.md` §3**: draw the plan-cache-vs-parse-tree-cache distinction precisely.
  MySQL caches prepared-statement *parse trees* per session; that is not a plan cache.

**Grounding**: research ticket 06 (which confirmed all three claims survive), plus the glossary from
ticket 08. **Zero lecture-deck coverage** for this chapter, so it rests entirely on external primary
sources: the MySQL manual and the MySQL Server Team blog. Its lesson has to work harder to ground
the material than chapters 1-5 did.

**Definition of done**:
1. The user has been taught this chapter via `/mattpocock-skills:teach` (they must invoke it
   themselves) and a lesson exists in `lessons/`. One lesson for all three subsections, per
   `MISSION.md`'s "chapters 6 and 7 share one lesson" budget.
2. Runnable SQL committed to `examples/`, and **one** captioned figure in `figures/`.
3. Serbian prose appended to `rad.md` **using the `academic-research-writer` skill**, with IEEE
   citations added to `references.bib` as they are used.
4. A learning record written to `learning-records/`, the paper re-exported and its page count
   measured against the ≤25 target, and the work committed.

## Answer

Written and closed 2026-08-31, resolving all four items of the definition of done. Sections 6.1-6.3,
~1.620 words plus one figure. The shared framing is written once at the chapter head, as the merge
intended: three claims of the form "MySQL does not do X", each carried to the boundary where the
"not" turns into "yes, but only under these conditions".

- **6.1** defines vectorized execution from its published origin (MonetDB/X100) with DuckDB's
  `STANDARD_VECTOR_SIZE` = 2.048 as the concrete contrast, then *derives* MySQL's row-at-a-time
  execution from chapter 5's `Read()` rather than asserting it as a separate fact. The measurable
  consequence is the ~20 ns per row per predicate that does not move with selectivity. Closes on the
  trade-off (OLTP against OLAP) and on HeatWave as a separate executor standing beside MySQL rather
  than as a change to it.
- **6.2** is the centre of gravity: three conditions, all of them necessary. The manual documents the
  feature only under `CHECK TABLE`; WL#11720's Scope names the single query shape it applies to; and
  measurement adds the two conditions the worklog omits, namely that the plan must really read the
  clustered index (hence `FORCE INDEX(PRIMARY)`, the trap from LR-0008 (b)) and that there must be no
  predicate. 2,9x against 1,01x, explained by chapter 2's `handler` seam and chapter 5's `Read()`
  jointly, with PostgreSQL's `Gather` node as the contrast that makes the boundary visible.
- **6.3** keeps the `GLOSSARY.md` section 3 hard constraint and sharpens it: Oracle's shared SQL area
  is shown as what a shared plan cache actually looks like; three `EXECUTE`s of one prepared statement
  produce three traces whose estimates are ~12x apart, so the plan is re-derived per execution against
  the actual parameter value; and `Com_stmt_reprepare` going 0 -> 1 after an `ALTER TABLE` shows what
  the manual's "internal structure" concretely is.

**Seven new citations, rendering as IEEE [8]-[14]**: `boncz2005`, `duckdbdocs`, `mysqlheatwave`,
`mysqlwl11720`, `postgresql18`, `mysqlblogqc`, `oracleconcepts`. This is the one chapter with zero
lecture-deck coverage, so every claim rests on a primary source or on this paper's own measurement,
which is why its citation count is the highest in the paper. Every quoted page was fetched at write
time (WORKFLOW.md rule 6); the `innodb_parallel_read_threads` prose paragraph that could not be
fetched during the lesson is still not quoted, and the claim it would have carried is carried by the
measurement instead.

**The synthetic dataset needed no change** for the parallel-execution material: 5.000.000 rows at
1394 MB against a 128 MB buffer pool made the effect both measurable and repeatable. That closes the
map's oldest fog entry.

**Budget: measured, partly fixed, and one decision left to the user.** The export after writing came
to **26 pages** against the hard <= 25, with chapter 7 (0.75) still to come, so chapter 6 rendered at
**4 pages against its 2.5 budget**. A redundancy-only trim of ~120 words moved the count by nothing,
exactly the under-delivery ticket 20 recorded. What did work is the lever `../WRITING.md` names as
the first one to reach for: figure widths 5.0in -> 4.3in (and 4.6in -> 4.1in) across all twelve
figures, which took the export **26 -> 25 with nothing removed**. A further shrink to 3.9in was
measured and buys **zero** further pages, so 4.3in is the floor worth having. The paper therefore
sits **exactly at 25 with chapter 7 unwritten**, and the ceiling now needs a call that is not this
ticket's to make: raise it by a page, or find ~1 page in chapters 1-4 under the suspended trim rule.
Flagged on [ticket 18](18-zakljucak.md).
