# 0005 — A bad estimate is not a bad plan, and the plan that IS bad looks perfect in EXPLAIN

**Date:** 2026-08-26
**Chapter:** 4 (EXPLAIN i EXPLAIN ANALYZE), lesson 4b of three
**Lesson:** `lessons/0005-explain-analyze-procena-naspram-stvarnog.html`
**Reference card:** `reference/04-explain-analyze.html`
**Status:** taught; ticket 13b's write-up still to run

## What was taught

`EXPLAIN ANALYZE` as the counterpart to 4a's vocabulary. Six moves:

1. **What executing adds, and what it costs.** Same plan, same costs, one extra bracket per node. Tree format only; JSON only in version 2.
2. **`actual time` / `rows` / `loops` are per-loop averages, not totals.** Shown on a join where the node with the smallest reported time is the most expensive.
3. **Estimated-vs-actual divergence as the diagnostic**, on the same query as 4a, revealing 4a's arithmetic as a 48x miss.
4. **Histograms fix skew only on a non-indexed column**, with the indexed counter-case beside it.
5. **One genuinely bad plan**, proven bad by comparison with an alternative.
6. What `EXPLAIN ANALYZE` still does not say (hands off to 4c).

## Non-obvious insights to revisit

**(a) The workspace's own reserved worked example turned out to be the weaker one.** `NOTES.md`
reserved `wide_events.country_code` (2.45M est vs 3.5M actual) for this lesson. Measured, that is
only a **1.43x** divergence, *below* the 3x rule-of-thumb threshold, and the plan it produces is
genuinely reasonable. It is a fine illustration of where an estimate comes from (index dive beating
flat cardinality 14), but it is **not** a divergence example and definitely not a bad-plan example.
The lesson keeps it, demoted, as the "below threshold" row of the divergence table.

**(b) The strong divergence example was hiding in lesson 4a's own query.** `sakila`'s
`payment.amount` has no index and no histogram, so `filtered` is the hardcoded 33.33% guess for a
`>` comparison. Truth is 0.711% (114 of 16,044). So 4a's `Filter` estimate of 5,499 is **48x** off,
and the continuity is exact: 4a taught the reader to compute 5,499, and 4b shows it was wrong.
This is worth far more than a fresh example, and the paper should use it the same way.

**(c) `payment.amount` is the "histograms fix skew" example `NOTES.md` said was still needed.**
`NOTES.md` recorded that a genuine histogram demo needs a **non-indexed** skewed column and that
`country_code` (indexed) is not one. `payment.amount` is exactly that column, and it is already in
the chapter. Measured: `filtered` 33.33 → 0.71, estimate 5,499 → 117 against 114 actual, plan cost
3,672 → 1,715. 32 buckets requested, **19** built, type `singleton`. The two cases now sit side by
side in one figure, which is a much better teaching object than either alone.

**(d) A 48x divergence did not change the plan at all.** Five-table Sakila join on the same
predicate, run with and without the histogram: **identical join order** both ways, only the costs
differ (9,373 vs 1,926). This directly answers the "estimates off by 3x" rule of thumb that
`WORKFLOW.md` listed as unverified: **the rule is a screening threshold, not a verdict.** Divergence
means the optimizer chose using a wrong number, so it *could* have erred; whether it did is only
visible by comparing the chosen plan against another one. The paper must not let the reader infer
"big divergence ⇒ bad plan".

**(e) The genuinely bad plan is the `ORDER BY` + `LIMIT` + rare-non-indexed-predicate trap, and it
is the single best argument for the whole chapter.** `wide_events WHERE amount > 504.9 ORDER BY
created_at LIMIT 10`: `EXPLAIN` reports `type: index`, `key: idx_created_at`, `rows: 10`,
`cost=0.836`. **Every column looks perfect** — index chosen, no `filesort`, no table scan, cost
below 1. `EXPLAIN ANALYZE` shows the index scan actually returned **31,621** rows (3,162x) and took
~2,700 ms for ten rows. Proof it is genuinely bad, not merely slow: `IGNORE INDEX` forces a table
scan plus sort, which `EXPLAIN` costs at **574,128** (≈686,000x more expensive), and it measures
**~1,860 ms**, about 1.5x faster. So: the plan `EXPLAIN` calls ~686,000x cheaper is the slower one.

**(f) A histogram does NOT rescue (e), and the reason is worth knowing.** Built on `amount` with 64
and then 1024 buckets: `filtered` drops 33.33 → 0.50 and the tree estimate 3.33 → 0.05, so the
*estimate* improves, but the **plan, the 31,621 rows and the runtime are unchanged**. `LIMIT` caps
the index-order scan's costed rows at 10 before the corrected selectivity can raise it. Good
statistics helped the *estimate* without touching the *decision*. Do not present histograms as the
general cure.

**(g) `EXPLAIN ANALYZE` never modifies data, which contradicts the research memo.**
`.scratch/obrada-upita/research/05-explain-semantics.md` §2.5–2.6 says it "works with SELECT,
UPDATE, DELETE, and TABLE statements", which invites the inference that running it on an `UPDATE`
changes rows. Verified live on 8.4.11, in three separate connections:
- **single-table** `UPDATE`/`DELETE` → `-> <not executable by iterator executor>`, no plan at all;
- **multi-table** `UPDATE`/`DELETE` → full measured plan (`Update a (immediate)`), the read side
  runs and is measured (join reports `rows=3`), and the write node reports `rows=0`;
- in both cases the data is **unchanged**, confirmed from a third connection.
The manual's actual wording is narrower than the memo's: "EXPLAIN ANALYZE can be used with SELECT
statements, **multi-table** UPDATE and DELETE statements, and TABLE statements." The memo should be
corrected, and the paper must not tell the reader to wrap `EXPLAIN ANALYZE` in a rollback
transaction: it would be guarding against a consequence that does not occur.

**(h) The 8.4 manual is wrong (or stale) about `EXPLAIN ANALYZE FORMAT=JSON`.** The `EXPLAIN
Statement` page says "Using FORMAT=TRADITIONAL or FORMAT=JSON with EXPLAIN ANALYZE always raises an
error, regardless of the value of explain_format." On 8.4.11 that holds only while
`explain_json_format_version = 1`; set it to `2` and `EXPLAIN ANALYZE FORMAT=JSON` **succeeds**,
returning `actual_rows`, `actual_loops`, `actual_first_row_ms`, `actual_last_row_ms` alongside
`estimated_rows` and `estimated_total_cost`. If this goes into `rad.md`, it is cited as **measured
behaviour with the format version named**, not as the manual's claim.

## Next

**Lesson 4c: `optimizer_trace` + `EXPLAIN FOR CONNECTION`.** It now has a sharper hook than when it
was budgeted. Insight (e) ends with a question this lesson cannot answer: the chosen plan is
demonstrably worse than one alternative, but nothing in `EXPLAIN ANALYZE` says which alternatives
the optimizer considered or what it costed them. That is exactly the trace's job, and it makes 4c a
genuine continuation rather than the thin add-on `NOTES.md` feared. The "fold 4c into 4b" option
should be dropped.

## Evidence

Measured numbers, artifacts and write-up notes for this session: `.scratch/obrada-upita/measurements/0005-explain-analyze-estimate-vs-actual.md`.
