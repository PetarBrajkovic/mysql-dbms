# 0003 — The pipeline has five phases, and every decision with an alternative is settled by cost

**Date:** 2026-08-24
**Chapter:** 3 (Od SQL-a do plana izvršavanja)
**Lesson:** `lessons/0003-od-sql-a-do-plana-izvrsavanja.html`
**Reference card:** `reference/02-od-sql-a-do-plana.html`
**Status:** taught and written (Chapter 3 prose appended to `rad.md` 2026-08-24)

## What was taught

Chapter 3's spine, zooming into steps 3-5 of the path lesson 0002 laid out:

1. **Five named phases, each with a file and entry point in 8.4:** parser -> resolution (`Query_block::prepare()`) -> optimizer (`JOIN::optimize()`) -> planner (`Optimize_table_order`) -> executor (`sql/iterators/`).
2. **The server names its own phases.** `optimizer_trace` has three top-level steps; the planner has none because it is a sub-phase of the optimizer, the parser none because the trace starts after the tree exists.
3. **The parser/resolver boundary is measurable.** A doubly-broken statement always reports the parse error: 1064 first, 1054 only after the grammar is fixed. Cheapest defensible demo in the paper.
4. **Permanent transformations live in resolution, not optimization.** `SHOW WARNINGS` prints `semi join` for an `IN (SELECT ...)`; WL#7082's reason is memory lifetime.
5. **Transformation vs strategy is the chapter's sharpest line.** The semijoin transformation carries no cost; the semijoin *strategy* is costed.
6. **Cost is arithmetic over published constants**, with both cost decisions shown flipping live.

## Non-obvious insights to revisit

**(a) The cost model's compiled-in constants are now verified against the live server.** Research
memo `04-sql-to-plan-and-iterator.md` §2.3 marked the eight numbers `[UNVERIFIED]` at runtime because
that research had no server. They are confirmed via the `default_value` generated column:
`row_evaluate_cost` 0.1, `key_compare_cost` 0.05, `memory_temptable_create_cost` 1,
`memory_temptable_row_cost` 0.1, `disk_temptable_create_cost` 20, `disk_temptable_row_cost` 0.5,
`io_block_read_cost` 1, `memory_block_read_cost` 0.25. That flag in the memo can be cleared.

**(b) A table-scan cost can be reproduced exactly with a calculator, and its wobble explained.**
`0.1 × 4,909,177 rows + 1.0 × 89,216 clustered pages = 580,133.7`, which is precisely the
`580,134` Lesson 01 recorded. Today the server reports `578,220`; the 1,914 gap divided by
`(1.0 - 0.25)` implies ~2,552 pages already in the buffer pool, and
`information_schema.INNODB_BUFFER_PAGE` counts **2,651** for `wide_events` PRIMARY at that moment.
So the model is checkable end to end. **Consequence that matters for Chapter 4: the same cost is not
the same number between runs, because buffer-pool residency is one of its inputs.**

**(c) `optimizer_search_depth` is the most under-appreciated variable in the paper.** On the
six-table Sakila join, depth 62 (the default) plans at cost ~48 warm / ~131 cold; depth 1 plans the
same query at ~7,185 warm / ~20,807 cold, i.e. **~150x worse in both states**, and measured 5.76 ms
vs 21.28 ms. The bad plan opens with `Inner hash join (no condition)` (a Cartesian product on
`category`) and demotes `r.customer_id = c.customer_id` to a trailing `Filter`. This is a textbook
bad join order produced by MySQL's own optimizer on the user's own data, which is far stronger
evidence than any narrated example. Quote the **ratio**, not the absolute costs.

**(d) `optimizer_prune_level=1` costs nothing here.** 63 partial-plan nodes with pruning vs 89
without, same final plan and same total cost. Only 3 nodes were dropped by `pruned_by_heuristic`;
the `pruned_by_cost` entries appear with pruning *off* too, because that is the branch-and-bound
bound, not the heuristic. Do not conflate the two in the chapter.

**(e) Plan-search node counts are run-dependent.** An earlier measurement in the same session gave
88/118 instead of 63/89, because pruning depends on costs and costs depend on buffer-pool state. In
a fresh session the numbers are stable at 63/89/21. Any count quoted in the paper needs "izmereno u
svežoj sesiji" attached, or should be replaced by the direction.

**(f) Not every condition rewrite is permanent.** `condition_processing` (equality propagation,
constant propagation, trivial condition removal) runs in `join_optimization`, per execution, and does
not touch the statement tree. From `f.film_id = 42 AND fa.film_id = f.film_id` the optimizer derives
`multiple equal(42, f.film_id, fa.film_id)`, hence `fa.film_id = 42`, and the plan then shows
`Covering index lookup on fa using idx_fk_film_id (film_id=42)`. Writing "all transformations happen
in preparation" would be wrong; only **permanent** ones do.

**(g) The chosen access-path example is the one the ticket demanded, and it works.**
`SELECT notes FROM wide_events WHERE customer_id BETWEEN 1 AND N` with the *same* query text and only
`N` moving: the table-scan cost is a constant 578,220 while the range-scan cost grows linearly, so
the curves cross between N = 10,000 (545,590, taken) and N = 11,000 (585,722, rejected). The trace
spells out the rejection reason as `cause: "cost"`, which is the single most useful string in the
whole chapter: the index was not unusable, it was dearer. `usable: false` is the other, different
reason. The `notes` column is load-bearing (non-covering); a covering query never crosses.

## Next

Chapter 4 inherits three things from here: the estimated-vs-actual thread, the "cost varies between
runs" caveat, and the optimizer trace as a tool the user has already used once.

## Evidence

Measured numbers, artifacts and write-up notes for this session: `.scratch/obrada-upita/measurements/0003-five-phases-and-one-cost.md`.
