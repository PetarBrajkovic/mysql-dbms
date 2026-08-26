# Chapter 4b. EXPLAIN ANALYZE: procenjeno naspram stvarnog

Type: task
Status: open
Blocked by: 13a

## Question

Execution ticket, second of the three that deliver chapter 4. Split from the original ticket 13; see
13a for why.

**Target length**: ~2 pages of `rad.md`. Chapter 4's budget was raised from 4 to 6 pages on
2026-08-26 (the user's call, recorded in 13a's Answer and `GLOSSARY.md` §4) precisely so this
ticket would not be squeezed: 13a took ~3, leaving **~3 for 13b and 13c together**. This is the
chapter's centrepiece, so it takes the larger share. At this paper's measured density that is
roughly 850-900 words.

**Scope**: `EXPLAIN ANALYZE` as the counterpart to everything 13a wrote. It executes the query, and
it only ever prints trees, so the tree reading is already paid for. The vocabulary is
`actual time=...`, `rows=`, `loops=`, read against the `rows` and `filtered` estimates 13a
introduced. The chapter's centre of gravity is **estimated against actual row divergence** as the
core diagnostic (research ticket 05), which is also where the original ticket 13's requirement to
**end by diagnosing one genuinely bad plan** belongs.

**The worked example is already captured live and reserved for this ticket** (`NOTES.md`, chapter-4
entries, and ticket 01's Answer): `wide_events` filtered on the skewed `country_code`. The index
dive estimates **2,45 M** against **3,5 M** actual, engine cardinality is 14 so the flat estimate
would be 5.000.000/14 ≈ 350.656, and the two disagree with each other as well as with reality.
Two traps recorded from live runs, both of which the prose must respect:

- **A histogram does not close that gap.** Verified: building one on `country_code` leaves the
  estimate byte-identical, because the optimizer prefers range-optimizer estimates to histogram
  statistics when the column is indexed. Never let the reader infer that histograms fix this. A
  genuine "histograms fix skew" example needs a **non-indexed** skewed column.
- **Selectivity alone does not flip this plan**, covering or not: the index-lookup plan (cost ≈
  513.107) still beats the `IGNORE INDEX` table scan (cost ≈ 580.134) because the row is wide. The
  rare `'JP'` side may flip; **verify before using it**.

Also 13b's business: the "estimates off by 3x" rule of thumb, the last item `WORKFLOW.md` lists as
still needing a check against the live server (the other, `explain_json_format_version = 2`, was
closed by 13a).

**Definition of done**: the same four as 13a (lesson taught via `/teach`, SQL in `examples/`, at
least one captioned figure, Serbian prose into `rad.md` via `academic-research-writer` with
citations, learning record plus commit).

**Next action for the user**: `/teach EXPLAIN ANALYZE in MySQL`, then run
`/mattpocock-skills:wayfinder .scratch/obrada-upita/map.md` in the same session.

## Answer

### Progress 2026-08-26 — taught, not yet written

Lesson done via `/teach`: `lessons/0005-explain-analyze-procena-naspram-stvarnog.html`, reference
card `reference/04-explain-analyze.html`, four SQL files `examples/04-explain/04…07-*.sql`, three
figures via `tools/make-lesson05-explain-analyze.ps1`. Full findings in **LR-0005**. Remaining DoD
for this ticket: the Serbian prose into `rad.md` via `academic-research-writer`, plus citations.

**Four things above that revise this ticket's own scope statement, so read LR-0005 before writing:**

1. **The reserved worked example is the wrong centrepiece.** `wide_events`/`country_code` measures
   at only **1.43x** divergence, below the 3x threshold, and its plan is fine. Demote it to an
   illustration of where an estimate comes from (index dive vs. flat cardinality 14).
2. **Use `sakila.payment.amount` instead**, which is already in the chapter: 4a's own
   `16500 × 33,33% = 5499` is **48x** off the measured 114, because the column has no index and no
   histogram so `filtered` is the hardcoded guess. It doubles as the non-indexed histogram demo the
   ticket asks for (33.33 → 0.71, est 117 vs 114 actual), with `country_code` as the indexed
   counter-case beside it.
3. **The "off by 3x" item is answered, and the answer is a caveat.** It is a screening threshold,
   not a verdict: the 48x case leaves a five-table join order unchanged. The bad-plan requirement is
   met separately by the `ORDER BY` + `LIMIT` trap (est 10 vs actual 31.621, 3.162x; chosen plan
   ~2.700 ms against an alternative `EXPLAIN` costs ~686.000x higher that runs in ~1.860 ms).
4. **Do not write that `EXPLAIN ANALYZE` modifies data.** It does not; see LR-0005 (g). The research
   memo is wrong on this and the manual's wording is narrower ("multi-table").

**13c is no longer a fold-in candidate.** 4b ends on a plan proven worse than an alternative, with
no way to see which alternatives were costed. That is the trace's hook, so 13c stands alone.
