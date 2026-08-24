# 0003 — The pipeline has five phases, and every decision with an alternative is settled by cost

**Date:** 2026-08-24
**Chapter:** 3 (Od SQL-a do plana izvršavanja)
**Lesson:** `lessons/0003-od-sql-a-do-plana-izvrsavanja.html`
**Reference card:** `reference/02-od-sql-a-do-plana.html`
**Status:** taught (lesson delivered; quiz not yet taken by the user at time of writing)

## What was taught

The conceptual spine of Chapter 3, zooming into steps 3-5 of the path Lesson 0002 laid out, exactly
as LR-0002 recommended:

1. **Five named phases, each with a file and an entry point in 8.4:** parser → resolution
   (`Query_block::prepare()`, `sql_resolver.cc`) → optimizer (`JOIN::optimize()`,
   `sql_optimizer.cc`) → planner (`Optimize_table_order`, `sql_planner.cc`) → executor
   (`sql_executor.cc`, `sql/iterators/`).

2. **The server names its own phases.** `optimizer_trace` has exactly three top-level steps:
   `join_preparation`, `join_optimization`, `join_execution`. The planner has no step of its own
   because it is a sub-phase of the optimizer; the parser has none because the trace starts once the
   tree already exists. This turned the phase list from an assertion into an observation, and the
   trace then carried the rest of the lesson.

3. **The parser/resolver boundary is measurable, not interpretive.** A statement that is broken in
   both ways at once always reports the parse error. `SELECT nepostojeca FROM wide_events WHERE;`
   gives 1064; fix only the grammar and the same statement gives 1054. This is the cheapest
   defensible demo in the whole paper.

4. **Permanent transformations live in resolution, not optimization** (the research memo's headline
   finding, now demonstrated). `SHOW WARNINGS` after `EXPLAIN` prints the statement as
   `customer c semi join (rental r)` although the query says `IN (SELECT ...)`; the trace shows the
   same rewrite inside `join_preparation`, with `decorrelated_predicates`. WL#7082's stated reason is
   memory lifetime: optimization runs per execution and its memory is freed, preparation runs once
   per statement.

5. **Transformation vs strategy is the chapter's sharpest line.** The semijoin transformation carries
   no cost at all (`chosen: true`, no number). The semijoin *strategy* is costed:
   FirstMatch 18124.9, MaterializeLookup 2027.95 (chosen), DuplicatesWeedout 18350. Same
   logical/physical split Chapter 1 opened with.

6. **Cost is arithmetic over published constants**, and both cost decisions (access path, join order)
   were shown flipping live.

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

## Live run (2026-08-24, MySQL 8.4.11) — every number in the lesson is measured

| what | measured |
|---|---|
| Parse error precedes name resolution | `1064` before `1054` |
| Table-scan cost, `wide_events` | `578,220` (cold-pool arithmetic: `580,134`) |
| Range scan, `customer_id` ≤ 9,000 | `462,848`, `chosen: true` |
| Range scan, `customer_id` ≤ 12,000 | `660,854`, `chosen: false`, `cause: "cost"` |
| Access-path crossover | between N = 10,000 and N = 11,000 |
| Semijoin strategies costed | FirstMatch 18,124.9 / MaterializeLookup 2,027.95 / DuplicatesWeedout 18,350 |
| Six-table join, depth 62 vs depth 1 | ~150x cost, 5.76 ms vs 21.28 ms |
| Partial plans considered, prune 1 / 0 / depth 1 | 63 / 89 / 21 |
| `wide_events` PRIMARY pages in buffer pool | 2,651 (predicted ~2,552) |

## Artifacts produced

- `examples/03-od-sql-a-do-plana/01..05-*.sql`, all five smoke-tested against the live server.
- `figures/03-od-sql-a-do-plana-01-ukrstanje-cena.png` (+ `.svg`), a two-curve cost chart built from
  a 15-point sweep of the trace, by the new `tools/make-lesson03-cost-crossing.ps1`. This is the
  first figure in the workspace that myflames cannot produce: the teaching point is a pair of cost
  *curves*, and one plan tree is only ever one point on them.
- `figures/03-od-sql-a-do-plana-02/03-redosled-spoja-dubina-62/1.png` (+ `.svg`), via the new
  `tools/make-lesson03-joinorder-comparison.ps1` (same shape as the lesson-02 ICP script, because the
  "after" state needs a session-scoped `SET` alongside the `EXPLAIN ANALYZE`).
- `GLOSSARY.md` §2b: ~26 new terms, plus four recorded non-choices.

## Terminology decision worth remembering

**`poluspoj` / `antispoj`, written solid, not `polu-spoj` / `anti-spoj`.** Checked against the
orthography norm rather than guessed: the prefixoid `polu-` is written joined to its base
(`poluvreme`, `poluostrvo`, `polufinale`, `polukrug`), with a hyphen only before a capitalised proper
noun (`polu-Nemac`). `anti-` behaves the same way. `rad.md` never used the term. The two chapter-2
learning artifacts that said `semi-spoj` in a parenthetical (`lessons/0002-*.html`,
`reference/01-*.html`) were flagged rather than silently edited, and the user asked for them to be
corrected the same day, so the workspace is consistent with no grandfathered exceptions.

## Next

Per WORKFLOW's per-chapter loop: the user runs the five scripts in `examples/03-od-sql-a-do-plana/`
himself (step 2), then Chapter 3's prose is written with `academic-research-writer` (step 3). The
figure budget for the chapter is 2; three exist, so the write-up should pick the two that carry the
most argument (the cost-crossing chart is almost certainly one of them). Chapter 4 inherits three
things from here: the estimated-vs-actual thread, the "cost varies between runs" caveat, and the
optimizer trace as a tool the user has already used once.
