# 0001 — Query processing is a gap crossed on two levels

**Date:** 2026-08-22
**Chapter:** 1 (Uvod)
**Lesson:** `lessons/0001-uvod-the-gap-and-two-levels.html`
**Status:** taught

## What was learned

The conceptual spine of Chapter 1, kept deliberately free of the parser/optimizer/executor
mechanics (those are Chapter 2's job):

1. **Query processing = crossing a gap.** SQL is declarative (states *what* result), machines run
   only physical procedures (*how*: pages of 4–8 KB, B+ trees, heap scans, page I/O). The DBMS
   carries the burden of reconstructing the "how" — *teret efikasnih odgovaranja nosi DBMS*
   (03_Optimizacija p. 2; physical substrate on 02_Evaluacija p. 2).

2. **The gap is crossed on two levels of one problem** (03_Optimizacija p. 2):
   - *Logical (viši):* reformulate the relational-algebra expression into an equivalent, faster
     **shape** — result-preserving, still abstract.
   - *Physical (niži):* choose a concrete **algorithm + access path** per operator (scan vs. index;
     NL / sort-merge / hash join). "Nema univerzalno superiorne tehnike" (02_Evaluacija p. 4).
   - Both are steered by the same objective, **cena** (cost) — that shared objective is what makes
     them two *levels*, not two problems. Recipe: RA → lowest-cost algorithms → execute
     (03_Optimizacija p. 3).

3. **Why the paper exists:** one SQL statement → many equivalent plans of very different cost, so the
   DBMS must *search and choose*. Every later chapter zooms into how MySQL makes/runs that choice.

4. Intro closes with a one-sentence-per-chapter roadmap (chapters 2–9), taken from the locked
   skeleton in `GLOSSARY.md` §4.

## Non-obvious insight to revisit

The logical/physical split is the load-bearing frame for the *whole paper*, not just Chapter 1 —
chapters 3–5 are essentially "physical level, in MySQL detail," and chapter 4's EXPLAIN work is
reading the physical choices back out. When writing later chapters, reconnect to this frame rather
than re-introducing it.

## Grounding / sources

Primary: Prof. Stoimenov decks 03_Optimizacija p. 2–3, 02_Evaluacija p. 2–4 (extracted verbatim via
`pdftotext`, not paraphrase). External cross-check added to `RESOURCES.md`: R&G 3ed open-access
slides, Ch. 12 "Overview of Query Evaluation".

## Live run (2026-08-22) — the demo, corrected against the real server

Ran the §4 example live. The original prediction (free choice → table scan) was **wrong** and got
corrected in the lesson:

- Free choice **keeps the index** (`Index lookup … idx_country_code`, `cost≈513107`); forbidding it
  with `IGNORE INDEX` gives the **table scan** (`cost≈580134`). The scan is *dearer* because the row
  is wide (~2.1 GB table), so the index wins even at 70% selectivity. Clean "one statement, two plans,
  different cost, optimizer keeps the cheaper" — just with the index as winner, not loser.
- Estimate story (the Chapter-4 seed): **no histogram** on `country_code`; index **Cardinality = 14**
  ⇒ flat estimate 5M/14 ≈ **350,656** (used by `FORCE INDEX` and the scan's filter node); free plan
  estimates **2.45M** via **index dive**; **actual = 3.5M** (`EXPLAIN ANALYZE`). Estimates are
  approximate and disagree most on a skewed column — exactly Chapter 4's diagnostic.
- The §4 demo was switched from `FORCE INDEX` to `IGNORE INDEX` (the former just re-picks the same
  index with a skew-blind estimate — confusing; the latter reveals the genuine alternative plan).
- Insight worth carrying: this **contradicts** ticket 01 / `NOTES.md`, which predicted the
  non-covering `'US'` filter would flip to a scan. It doesn't. Correction filed in `NOTES.md`;
  ticket 01's Answer still needs updating.

## Next

Chapter 1 lesson done. Per WORKFLOW, next in the per-chapter loop: run an example in Workbench that
*shows* "many plans, different cost" (candidate: the wide_events covering-vs-non-covering pair in
`NOTES.md`), then write the Uvod prose with `academic-research-writer`. No follow-up teaching needed
unless the two-levels distinction is still blurry on recall.
