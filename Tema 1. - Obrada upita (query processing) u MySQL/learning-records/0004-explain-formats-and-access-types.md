# 0004 — EXPLAIN has two shapes, not three formats, and the access-type ladder is not a cost ranking

**Date:** 2026-08-24
**Chapter:** 4 (EXPLAIN i EXPLAIN ANALYZE), lesson 4a of three
**Lesson:** `lessons/0004-explain-formati-i-tipovi-pristupa.html`
**Reference card:** `reference/03-explain-formati-i-tipovi.html`
**Status:** taught and written (`rad.md` §4.1-4.4, ticket 13a closed 2026-08-26); 4b and 4c still to teach

## What was taught

Deliberately vocabulary only, per the chapter-4 split decided in `NOTES.md`: no `EXPLAIN ANALYZE`,
no `optimizer_trace`, no estimated-vs-actual. Four moves:

1. **Three formats, but only two shapes.** `EXPLAIN` (tabular) and `FORMAT=JSON` version 1 print
   **one row per table** — the MySQL 5.6 plan representation, in which a filter has no row of its
   own. `FORMAT=TREE` and `FORMAT=JSON` version 2 print **one node per iterator**, which is the
   structure that actually executes. Same query, same plan: 2 rows against 4 nodes.

2. **The bridge between the two shapes is arithmetic.** `rows × filtered / 100` in the table view
   is exactly the `Filter` node's row estimate in the iterator view: measured
   `16500 × 33.33% = 5499`, and JSON v1 hands you the same number outright as
   `rows_produced_per_join`. This turned "the formats differ" from an assertion into something the
   user could check with a calculator.

3. **Twelve access types, ranked by the manual, demonstrated on twelve live queries.**

4. **The four `Extra` values that carry the chapter-2 seam**: `Using index` (covering, table never
   touched), `Using index condition` (ICP, engine evaluates against the index record),
   `Using where` (server filters after the engine handed the row over). Three checks, three
   different places, one word each.

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

## Live run (2026-08-24, MySQL 8.4.11, `sakila`) — every number in the lesson is measured

| what | measured |
|---|---|
| `explain_json_format_version`, default / working | `1` / `2` |
| Same plan: tabular rows vs. tree nodes | `2` / `4` |
| `rows × filtered` = `Filter` node estimate | `16500 × 33.33% = 5499` |
| `film_actor` PRIMARY, leftmost prefix vs. whole key | `key_len 2` (`ref`, 19 rows) / `key_len 4` (`const`, 1 row) |
| `payment.rental_id`, `INT` nullable | `key_len 5` |
| Costed-but-rejected index | `film`: `possible_keys=idx_fk_original_language_id`, `key=NULL`, `type=ALL` |
| Same index, one extra predicate | `filtered` 100.00 → 33.33, `Extra` `Using index` → `Using where` |
| `IN (SELECT ...)`, defaults vs. `semijoin=off` | `SIMPLE` (`ref`+`eq_ref`) / `DEPENDENT SUBQUERY` (`unique_subquery`) |
| Access types reproduced live | **12 of 12** |

## Artifacts produced

- `examples/04-explain/01-tri-formata-jedan-plan.sql`,
  `02-lestvica-tipova-pristupa.sql`, `03-kolone-i-extra.sql` — all three smoke-tested against the
  live server, no errors or warnings.
- `figures/04-explain-01-tri-formata-jedan-plan.png` (+ `.svg`), via the new
  `tools/make-lesson04-three-formats.ps1`: the same query run through all three formats and laid
  out in three panels, with the three bridging numbers coloured wherever they appear.
- `figures/04-explain-02-lestvica-tipova-pristupa.png` (+ `.svg`), via the new
  `tools/make-lesson04-access-types.ps1`: twelve live `EXPLAIN` runs rendered as a ranked ladder.
  **The script is self-verifying** — each entry declares the access type it must produce and the
  script throws if the server produces anything else, so a stale query breaks the build instead of
  silently printing a wrong figure. Worth copying that pattern in later chapters.
- `assets/lesson.css`: `table.exp` unscoped from `.try` (lesson 04 needs the same two-column table
  in the body, for `EXPLAIN`'s columns and `Extra` values); body-level variant gets a wider first
  column.
- `GLOSSARY.md` §2c: 13 new terms plus four recorded non-choices.

## Terminology decisions worth remembering

**`tip pristupa`, not `tip spoja`, for the `type` column** — even though the manual's own
documentation calls it the "join type". The value describes how one table is reached, not how two
are joined, and `tip spoja` would collide with §1's join algorithms. The manual's name is a
historical artifact; carrying it into Serbian would import a confusion the English does not force
on a careful reader.

**`pretraga po indeksu` (index lookup) is kept distinct from §1's `sken preko indeksa` (index
scan).** A lookup is one targeted probe; a scan reads a run of entries. Chapter 4 turns on exactly
that difference (`ref`/`eq_ref` against `index`/`range`), so one shared Serbian word would erase
the chapter's point.

**`filesort` stays untranslated.** Every plausible rendering (`sortiranje u fajl`) asserts
something false: MySQL sorts in memory whenever the result fits. Same class of decision as
`handler` in §2a.

## Next

**Lesson 4b: `EXPLAIN ANALYZE`.** It inherits three things from here: the tree format (already
read fluently, since `EXPLAIN ANALYZE` only ever prints trees), the estimated-row vocabulary
(`rows`, `filtered`, and the fact that both are estimates), and the deliberately reserved
`wide_events` / `country_code` worked example — index dive estimating 2.45M against 3.5M actual,
with a histogram that does not close the gap. Lesson 4a did not touch that data, as planned.

**Lesson 4c: `optimizer_trace` + `EXPLAIN FOR CONNECTION`.** Still to be decided after 4b whether
it stands alone or folds in; the user has already used the trace twice (chapter 3, and once here
in passing), so it may be thinner than budgeted.
