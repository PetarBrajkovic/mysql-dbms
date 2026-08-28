# Chapter 4b. EXPLAIN ANALYZE: procenjeno naspram stvarnog

Type: task
Status: closed
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

### Resolved 2026-08-28 — written into `rad.md`, ticket closed

Chapter 4's middle third is written: `rad.md` §4.5-4.7, ~1.080 words, three figures, no new
citations needed. The section runs on one spine: **`EXPLAIN` prints a number, `EXPLAIN ANALYZE`
prints the same number beside the measurement, and only the pair is a diagnosis.**

**§4.5 Merenje umesto procene.** The second bracket (`actual time`, `rows`, `loops`) and the fact
that `rows` now appears twice in one line meaning two different things, disambiguated in Serbian as
*procena* against *stvarni broj torki* (`GLOSSARY.md` §2d) and never by renaming the key. Two limits
stated up front: the tree-only rule, written as the manual's claim with the measured 8.4.11
exception named (`explain_json_format_version = 2` returns `actual_rows`/`actual_loops`), and the
no-modification fact, so the reader is never told to wrap a measurement in a rollback. Then the
divergence itself, on **4a's own query**: 4a taught the reader to compute 5.499 from
`rows × filtered`, and 4b measures 114, a **48x** miss, with the `payment` table scan beside it at
1,03x to show the miss is one node's, not the plan's. Cause named: `amount` has no index and no
histogram, so 33,33% is an assumption and the truth is 0,711%. The histogram pair follows
(non-indexed `amount`: 33,33 → 0,71, estimate 117 against 114 actual, 19 of 32 buckets, type
`singleton`; indexed `country_code`: byte-identical 2,45 M before and after, because the optimizer
prefers range-optimizer estimates to histogram statistics). Closes on the threshold question with
the answer being a caveat: the 48x case leaves the five-table join order **identical**, so
divergence says the decision used a wrong number, not that the decision is wrong.

**§4.6 Prosek po ponavljanju.** Short, and deliberately placed between the diagnostic and the bad
plan, because §4.7 leans on reading a measured bracket correctly: `rows=5.48 loops=178`, the
fractional row count as the giveaway, 178 × 5,48 = 975 against the join's 976, and the consequence
that the node with the smallest reported time can be the most expensive.

**§4.7 Plan koji ispis prikazuje kao savršen.** The chapter's centrepiece and the required
bad-plan diagnosis. `EXPLAIN` reports `type: index`, `key: idx_created_at`, `rows: 10`, no
`filesort`, cost 0,836, and **every column reads as ideal**; `EXPLAIN ANALYZE` measures 31.621 rows
(3.162x) and ~2.786 ms. Proven genuinely bad rather than merely slow by the `IGNORE INDEX`
alternative that `EXPLAIN` costs at 574.087 (~686.000x more) and that measures ~1.861 ms. Then the
histogram's second failure: 64 and 1024 buckets improve the estimate (33,33 → 0,50) and change
neither plan nor runtime, because `LIMIT` caps the costed rows at ten before the corrected
selectivity can act. Ends on the question the section cannot answer, which is 13c's hook: the ispis
measures the winner and never names the alternatives or their costs.

**Every number in the section is measured**, from LR-0005's live-run table, not from the research
memo. Three of this ticket's own scope statements were overridden by that table and the prose
follows the corrections, not the original ticket: the reserved `wide_events`/`country_code` example
is demoted to the 1,43x below-threshold illustration it actually is, `sakila.payment.amount` carries
the divergence and the histogram demo, and the `ORDER BY` + `LIMIT` trap carries the bad plan.

**Citations.** No new `references.bib` entry. Everything cited is `mysql84refman` (the measured
bracket's fields, statement types, `filtered`'s hardcoded assumption, histograms, and the
range-optimizer-over-histogram preference); the two places where the live server contradicts or
outruns the manual are written as measured behaviour with the server version and the format version
named, per WORKFLOW rule 6.

**Artifacts** (all pre-existing from the lesson session, verified in place, nothing regenerated):
`lessons/0005-explain-analyze-procena-naspram-stvarnog.html`,
`learning-records/0005-explain-analyze-estimate-vs-actual.md`,
`reference/04-explain-analyze.html`, `examples/04-explain/04..07-*.sql`,
`figures/04-explain-03-procena-naspram-stvarnog`, `-04-loops-i-prosek`, `-05-los-plan` (PNG + SVG),
built by `tools/make-lesson05-explain-analyze.ps1`.

**Also corrected here**, because LR-0005 (g) and (h) asked for it: research memo
`research/05-explain-semantics.md` §2.6 now carries a dated correction block on two of its four
bullets (statement types are **multi-table** UPDATE/DELETE and nothing is modified; "TREE format
only" holds only at `explain_json_format_version = 1`).

**Verified**: `tools/make-docx.ps1` builds clean. 11 inline figures in the DOCX (was 8, +3 here),
`Slika 4.3`/`4.4`/`4.5` captions all present, citations render IEEE [1]-[5] with the reference list
intact, Serbian diacritics intact, zero em dashes in `rad.md` (rule 8).

**Budget flag for 13c, raised not resolved.** At this paper's measured density (~450 words/page)
chapter 4 now stands at ~2.520 words, so 4a ≈ 3,2 pages and 4b ≈ 2,4 pages, which is ~5,6 of the
6-page budget. 13c's ~1 page would put chapter 4 at ≈6,6 and the paper at ≈23,5. Nothing here is
padding and nothing was trimmed to make room (the user's standing instruction from the 4a budget
call). **13c should either take ~0,5 pages instead of ~1, or chapter 4 goes slightly over**; that
is the user's call at the start of the 13c session, not a decision made here.

