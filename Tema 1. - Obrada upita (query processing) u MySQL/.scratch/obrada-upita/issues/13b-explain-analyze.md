# Chapter 4b. EXPLAIN ANALYZE: procenjeno naspram stvarnog

Type: task
Status: open
Blocked by: 13a

## Question

Execution ticket, second of the three that deliver chapter 4. Split from the original ticket 13; see
13a for why.

**Target length**: see the budget flag in 13a's Answer before writing a word. The written half took
~3 of chapter 4's ~4 budgeted pages, so this ticket either fits into ~1 page together with 13c, or
it raises chapter 4's budget deliberately and moves the total in `GLOSSARY.md` §4 with it. Decide
that first, in the open, rather than discovering it at the end.

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
