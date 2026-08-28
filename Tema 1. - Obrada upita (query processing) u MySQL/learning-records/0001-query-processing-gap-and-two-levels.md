# 0001 — Query processing is a gap crossed on two levels

**Date:** 2026-08-22
**Chapter:** 1 (Uvod)
**Lesson:** `lessons/0001-uvod-the-gap-and-two-levels.html`
**Status:** taught

## What was learned

Chapter 1's spine, deliberately free of parser/optimizer/executor mechanics (chapter 2's job):

1. **Query processing = crossing a gap.** SQL states *what*; machines run only *how* (pages, B+ trees, scans). The DBMS carries the burden.
2. **The gap is crossed on two levels of one problem:** logical (reshape the relational-algebra expression) and physical (pick algorithm + access path). Both steered by the same objective, **cena**, which is what makes them two levels rather than two problems.
3. **Why the paper exists:** one statement, many equivalent plans of very different cost, so the DBMS must search and choose.
4. Closes with a one-sentence-per-chapter roadmap from `GLOSSARY.md` §4.

## Non-obvious insight to revisit

The logical/physical split is the load-bearing frame for the *whole paper*, not just Chapter 1 —
chapters 3–5 are essentially "physical level, in MySQL detail," and chapter 4's EXPLAIN work is
reading the physical choices back out. When writing later chapters, reconnect to this frame rather
than re-introducing it.

## Next

Chapter 1 lesson done. Per WORKFLOW, next in the per-chapter loop: run an example in Workbench that
*shows* "many plans, different cost" (candidate: the wide_events covering-vs-non-covering pair in
`NOTES.md`), then write the Uvod prose with `academic-research-writer`. No follow-up teaching needed
unless the two-levels distinction is still blurry on recall.

## Evidence

Measured numbers, artifacts and write-up notes for this session: `.scratch/obrada-upita/measurements/0001-query-processing-gap-and-two-levels.md`.
