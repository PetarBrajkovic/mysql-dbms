# Chapter 6. Gde MySQL ne prati obrazac

Type: task
Status: open
Blocked by: 14

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
