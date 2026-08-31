# 0006 — The bad plan was never costed against anything, and the trace is the only place that says so

**Date:** 2026-08-28
**Chapter:** 4 (EXPLAIN i EXPLAIN ANALYZE), lesson 4c of three
**Lesson:** `lessons/0006-optimizer-trace-i-explain-for-connection.html`
**Reference card:** `reference/05-optimizer-trace.html`
**Status:** taught and written (`rad.md` §4.8-4.9, 2026-08-31); ticket 13c closed

## What was taught

`optimizer_trace` and `EXPLAIN FOR CONNECTION` as the two windows `EXPLAIN` does not open: the trace goes deeper but stays inside one session, `FOR CONNECTION` crosses the session boundary but stays shallow. Six moves:

1. The four-tool table (`EXPLAIN` / `EXPLAIN ANALYZE` / trace / `FOR CONNECTION`), and the point that the last two do not overlap.
2. The four-step procedure, the `OPTIMIZER_TRACE` table's four columns, and the trace's three phases.
3. Rejected plans with their costs; 4a's `key: NULL` case finally explained by `"cause": "cost"`.
4. **The answer to 4b's cliffhanger** - see insight (a).
5. What the trace still does not show: pruning, memory truncation, no measurements.
6. `EXPLAIN FOR CONNECTION` and its five documented outcomes.

## Non-obvious insights to revisit

**(a) The headline finding: the bad plan from lesson 4b was never chosen by the cost model at all.**
LR-0005 (e) left the question open — `EXPLAIN ANALYZE` proves the plan is worse than an alternative
but says nothing about what was considered. The trace answers it, and the answer is stronger than
"the optimizer costed it wrong":

- `considered_execution_plans` contains **exactly one** costed access path for `wide_events`, and it
  is the **table scan**, at cost ≈ 574.800, marked `"chosen": true`. `idx_created_at` **does not
  appear anywhere in that step.** It was never a candidate, because there is no index on `amount`.
- A *later* step, `reconsidering_access_paths_for_index_ordering`, then reports
  `"index_provides_order": true`, `"index": "idx_created_at"`, `"plan_changed": true` — and its own
  `"steps"` array is **empty**, meaning **no cost was computed in that step at all**.

So the plan `EXPLAIN` reports at cost `0,838` was installed by a rule, not won in a comparison, and
the `0,838` is a **consequence computed after the swap**, not the reason for it. This is the single
best thing in chapter 4 and the paper should lead §4c with it.

**(b) `LIMIT` is the trigger, and this is verifiable by removing it.** Same query without `LIMIT`:
`"index_provides_order": false`, `"plan_changed": false`, and `EXPLAIN` reports `type: ALL` with
`Using filesort` — i.e. exactly the plan the cost search picked. With `LIMIT 10000` the swap happens
again, so it is not the size of the limit but its **existence**. This also explains, retroactively,
LR-0005 (f): a histogram on `amount` improved the estimate but changed nothing, because the decision
was never made from an estimate.

**(c) The trace is obtainable without running the query — trace `EXPLAIN` instead.** The third phase
is then called `join_explain` rather than `join_execution`, and `join_optimization` is identical,
with every cost. Verified on both. This is a real advantage over `EXPLAIN ANALYZE`, which must
execute to completion: the whole 4c investigation of a five-million-row table ran instantly.

**(d) `"chosen": true` means "best so far", not "the winner".** Both completed join orders in the
two-table example carry it, because the first complete plan has nothing to beat. The winner is the
smaller `cost_for_plan`. A reader who takes `chosen` at face value will read the trace backwards.

**(e) Reading the trace closes lesson 4a's open question exactly.** `film` /
`idx_fk_original_language_id`: `possible_keys` names it, `key` is `NULL`, and the trace shows it
entered `range_scan_alternatives`, got a cost, and was dropped with `"chosen": false`,
`"cause": "cost"` against the table scan. LR-0004 (f) called this "a candidate that was costed and
lost"; that is now a measured statement rather than an inference.

**(f) The trace does not contain every rejected plan.** Partial plans are abandoned as soon as they
exceed the best found, and appear only as `"pruned_by_cost": true` without a completed plan. On the
six-table Sakila join: ~170 partial plans considered, roughly half abandoned (measured 195/97 and
169/85 on two runs). Counts are run-dependent for the reason chapter 3 already recorded. So "that
plan was never considered" usually means "considered partially, then abandoned".

**(g) `EXPLAIN FOR CONNECTION` has five outcomes, not four, and two of them are easy to conflate.**
All measured on 8.4.11:
- working call → the plan, in `TRADITIONAL`, `TREE` or `JSON`; `Com_explain_other` increments
  (**global** status only — each `mysql -e` is a fresh session, so session-scoped `SHOW STATUS`
  always reads 0);
- `EXPLAIN ANALYZE FOR CONNECTION` → **`ERROR 1235`** (confirms LR-0005's measurement);
- connection **busy with a non-explainable statement** (`DO SLEEP(...)`) → **`ERROR 3012`**;
- connection **idle** (`COMMAND: Sleep`) → **empty result, no error**, exactly as the manual says.
  The lesson originally conflated this with 3012 and was corrected;
- unknown/finished id → **`ERROR 1094`**; via `PREPARE`/`EXECUTE` → **`ERROR 1295`**.

**(h) The 1295 case is measured, and is NOT the manual's claim.** The manual documents the opposite
direction — `EXPLAIN FOR CONNECTION` does not work when the *target* is a prepared statement. That
you also cannot *issue* it through the prepared-statement protocol (so the connection id must be
typed literally, and cannot come from a subquery) is a live finding. Same handling rule as LR-0005
(h): cite it as measured behaviour, never as the manual's wording.

**(i) Two claims in the lesson had to be corrected against the primary source before it shipped.**
Worth remembering as a pattern, not just as two facts. (1) A quotation attributed to the manual's
tracing page was written from memory and did **not** match; the real opening sentence is dry
("the interface is provided by a set of `optimizer_trace_xxx` system variables and the
`INFORMATION_SCHEMA.OPTIMIZER_TRACE` table"), so the lesson now quotes that and makes the teaching
claim in its own voice instead. (2) The lesson said the trace's three phases "are the same ones
chapter 3 named" — false: the pipeline has **five** stages, parsing finishes before the trace
starts, and optimization and planning are one block in it.

## Next

Chapter 4 is **written** end to end (4a, 4b, 4c): §4.1-4.9, with insight (a) as §4.8's spine, exactly
as this record recommended. Chapter 4 kept its 6.6 pages and 4c kept its full page.

**The paper is now seven chapters, not nine** (old 6/7/8 merged into chapter 6), under a hard ≤25
rendered-page target set on 2026-08-31 when the export hit 20 pages with four chapters written. The
figure budget is now a firm cap. See `GLOSSARY.md` §4 and
`.scratch/obrada-upita/issues/20-page-budget-and-chapter-merge.md` before planning lesson 07's
figures.

Lesson 07 belongs to **chapter 5 (iterator model)**, and it inherits a ready-made hook: this lesson
established that the trace stops at `join_optimization` and that `join_execution` is empty, so
"what actually runs" has been deferred twice now — once by 4b (which measures iterators without
explaining them) and once here. Chapter 5 is where the iterators themselves get named.

## Evidence

Measured numbers, artifacts and write-up notes for this session: `.scratch/obrada-upita/measurements/0006-optimizer-trace-and-for-connection.md`.
