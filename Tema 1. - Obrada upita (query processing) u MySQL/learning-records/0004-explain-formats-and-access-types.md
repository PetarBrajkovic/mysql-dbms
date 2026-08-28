# 0004 — EXPLAIN has two shapes, not three formats, and the access-type ladder is not a cost ranking

**Date:** 2026-08-24
**Chapter:** 4 (EXPLAIN i EXPLAIN ANALYZE), lesson 4a of three
**Lesson:** `lessons/0004-explain-formati-i-tipovi-pristupa.html`
**Reference card:** `reference/03-explain-formati-i-tipovi.html`
**Status:** taught and written (`rad.md` §4.1-4.4, ticket 13a closed 2026-08-26); 4b and 4c still to teach

## What was taught

Vocabulary only, per the chapter-4 split: no `EXPLAIN ANALYZE`, no `optimizer_trace`, no estimated-vs-actual. Four moves:

1. **Three formats, but only two shapes.** Tabular and JSON v1 print one row per table; `FORMAT=TREE` and JSON v2 print one node per iterator. Same query, same plan: 2 rows against 4 nodes.
2. **The bridge between the shapes is arithmetic.** `rows x filtered / 100` equals the `Filter` node's estimate; JSON v1 hands the same number over as `rows_produced_per_join`.
3. **Twelve access types, ranked by the manual, demonstrated on twelve live queries.**
4. **The four `Extra` values that carry the chapter-2 seam**: `Using index`, `Using index condition`, `Using where` - three checks in three different places.

## Non-obvious insights to revisit

**(a) All twelve access types are reproducible on stock Sakila, including the two "legacy" ones.**
This was not obvious going in. `unique_subquery` and `index_subquery` need
`optimizer_switch='semijoin=off,materialization=off'`, and the reason is chapter 3's finding seen
from the other side: the semijoin transformation runs in **preparation**, so it rewrites the
subquery away **before an access type is ever chosen**. With defaults, the same `IN (SELECT ...)`
query reports two `SIMPLE` rows (`ref` + `eq_ref`) and no subquery at all; with semijoin off it
reports `id: 2`, `DEPENDENT SUBQUERY`, `unique_subquery`. This is the strongest continuity link
between chapters 3 and 4 and should be written up as such.

**(b) The `access_type` key means two different things in the two JSON versions.** In v1 it holds
the traditional access type (`ALL`, `eq_ref`). In v2 it holds the **iterator kind** (`table`,
`filter`, `join`, `index`), and the traditional value moves to `index_access_type`
(`index_lookup`). Any JSON output quoted in the paper must name its version, or the claim is
ambiguous. Verified live on both versions of the same query.

**(c) `explain_json_format_version = 2` works on 8.4.11.** This closes one of the two open
questions `WORKFLOW.md` left after ticket 01 ("still needs checking against your live server").
Default is `1`; setting `2` is accepted and produces the iterator-shaped JSON. Session-scoped.

**(d) The manual's ranking is a ranking of shapes, not of costs, and the figure proves it is not
even a smooth gradient.** Rank 8 (`unique_subquery`) returns at most one row, the same as rank 3
(`eq_ref`), yet sits five places lower. Grouping the twelve by "how many rows can one access
return" produces four bands that are **not contiguous** in the manual's order. That visual is the
argument: the order is practical guidance, and the price is computed by chapter 3's cost model.
Defence line: `range` over 50 rows beats `ref` over five million; `ALL` over a three-row table is
the cheapest thing there is.

**(e) `key` and `key_len` answer different questions, and only together.** Two plans both say
`key: PRIMARY` on `film_actor`, whose primary key is `(actor_id, film_id)`, 2 + 2 bytes. `key_len:
2` means only the leftmost column is in play, so one lookup returns 19 rows (`ref`); `key_len: 4`
means the whole key, so at most one (`const`). A nullable column costs one byte more than its type
(`payment.rental_id`, `INT NULL`, `key_len: 5`). This is the cheapest diagnostic in the whole
chapter and the paper should carry it.

**(f) `possible_keys` naming an index while `key` is `NULL` is chapter 3's `cause: "cost"`, seen
from the output side.** Not a missing or unusable index: a candidate that was costed and lost.
Live case: `film` with `original_language_id`, index present in `possible_keys`, `key: NULL`,
`type: ALL`.

**(g) `filtered` is not decoration.** Same index, same `rows: 32`, `filtered` 100.00 against 33.33
purely because of one extra predicate, and `Extra` flips from `Using index` to `Using where` at the
same time. That pair is the compact demonstration that the number flowing into the next table of
the plan is the product, not `rows`.

## Next

**Lesson 4b: `EXPLAIN ANALYZE`.** It inherits three things from here: the tree format (already
read fluently, since `EXPLAIN ANALYZE` only ever prints trees), the estimated-row vocabulary
(`rows`, `filtered`, and the fact that both are estimates), and the deliberately reserved
`wide_events` / `country_code` worked example — index dive estimating 2.45M against 3.5M actual,
with a histogram that does not close the gap. Lesson 4a did not touch that data, as planned.

**Lesson 4c: `optimizer_trace` + `EXPLAIN FOR CONNECTION`.** Still to be decided after 4b whether
it stands alone or folds in; the user has already used the trace twice (chapter 3, and once here
in passing), so it may be thinner than budgeted.

## Evidence

Measured numbers, artifacts and write-up notes for this session: `.scratch/obrada-upita/measurements/0004-explain-formats-and-access-types.md`.
