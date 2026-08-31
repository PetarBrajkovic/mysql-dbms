# 0007 — The plan is a tree of objects, and a row exists only because someone above asked for it

**Date:** 2026-08-31
**Chapter:** 5 (Model iteratora i pipeline operatora)
**Lesson:** `lessons/0007-model-iteratora-i-pipeline.html`
**Reference card:** `reference/06-model-iteratora.html`
**Status:** taught (lesson delivered; quiz not yet taken at time of writing); ticket 14 still open on
steps 2-4

## What was taught

Chapter 5's spine, closing the question 4b and 4c both deferred — what actually runs. Five moves:

1. **`RowIterator` and its three methods** (`Init()`, `Read()`, `UnlockRow()`), with the Volcano
   lineage from WL#11785 and the six abstractions it replaced.
2. **Every node of `FORMAT=TREE` is one iterator**, with the printed-string → `AccessPath` type →
   C++ class mapping, read out of the 8.4.6 source.
3. **`loops` is the number of `Init()` calls** — see insight (b). This retro-explains lesson 4b.
4. **Pipelined vs. blocking operators**, and the fact that first-row-vs-last-row time is a readable
   signature of which one a node is.
5. **`AccessPath` is the plan, the iterator is the runtime**, 1:1 — which is why 4c's
   `join_execution` phase was empty.

## Non-obvious insights to revisit

**(a) The headline: the same scan reads 10 rows or 5,000,000, and the only difference is one
clause.** `WHERE amount > 100 LIMIT 10` against `wide_events` makes the table scan report `rows=10`;
adding `ORDER BY amount` makes the identical scan report `rows=5e+6` and the query ~600× slower. The
scan is not "optimized to stop" — it simply stops being called. This is the shortest complete proof
of demand-driven execution the paper has, and chapter 5 should lead with it.

**(b) `loops` is not a metaphor: it is literally the count of `Init()` calls, stated in the source.**
`IteratorProfiler::GetNumInitCalls()` carries the comment "The number of loops (i.e number of
iterator->Init() calls." Two things that were rules in 4b become consequences of that: `loops` on a
join's inner input equals the outer input's row count (measured: 584 both ways, and 584 active
customers), and `rows` on an inner node is a **per-loop average**, so `26.8 × 584 = 15651`
reconstructs the join's own `15640`. LR-0005 taught the per-loop rule; this is the reason for it.

**(c) First row versus last row is a blocking detector, and both signatures appear in one plan.**
In the `ORDER BY` plan, `Sort` reports `actual time=2173..2173` — nothing came out until everything
went in — while the `Filter` directly beneath it reports `0.127..1845`. Same plan, one blocking node
and one pipelined node, distinguishable without knowing anything about either operator.

**(d) `-> Hash` is the one printed row that is not an iterator.** In
`explain_access_path.cc` it is `children->push_back({path->hash_join().inner, "Hash"})` — a label on
the edge to the build input, not an `AccessPath` of its own. It is also identifiable **without** the
source: it is the only row in a tree that carries no numbers at all, because there is no cost to
estimate and no iterator to time.

**(e) Research memo 04 §3.4 has an error in its mapping table.** It reads
`Index scan` → `IndexScanIterator<true>` and `Covering index scan` → `IndexScanIterator<false>`.
The template parameter is **`Reverse`**, not "covering": `access_path.cc` branches on
`param.reverse`, and covering-ness is a `read_set` property that does not change the class. Same
shape for `RefIterator<true>`/`<false>`. Corrected in the lesson and the reference card.

**(f) WL#11785's Volcano sentence is not worded the way memo 04 paraphrases it.** The worklog says
the abstraction is "borrowed from the classic Volcano database system", not "based on the classic
Volcano database system architecture". Quote the former. Same discipline as LR-0006 (i): fetch the
page, do not write the quotation from memory.

**(g) Volcano's shape, not Volcano's plumbing.** `row_iterator.h` states the row "is not actually
returned from the function; it is put in the table's … record buffer, ie., `table->records[0]`"
(that spelling is the source's own, and `records[0]` is what it says). So MySQL took the
open/next/close control flow and layered it over its pre-existing record-buffer convention. The
header concedes the seam itself: "The abstraction is not completely tight." Good material for the
defense — it is not a textbook Volcano executor.

## Next

Chapter 5 is taught. Ticket 14 remains open on steps 2-4 of its definition of done: run the two
scripts in `examples/05-model-iteratora/` (WORKFLOW step 2), then write §5 with
`academic-research-writer` (step 3) using the two figures already built, then close the record.

Budget is **3 rendered pages** and the figure cap of **2** is fully spent. The export stood at 19
pages with chapters 1-4 written, so re-measure with `..\tools\make-docx.ps1` right after §5 lands —
if it comes in over 3, chapter 6 gives the page back (GLOSSARY §4).

Lesson 08 belongs to **chapter 6 (Gde MySQL ne prati obrazac)**, the merged 6.1/6.2/6.3. It is the
one chapter with **zero lecture-deck coverage**, so its lesson has to carry its own sources — and
this chapter hands it a ready-made hook: now that the executor is known to be one row at a time
through `Read()`, "MySQL does not vectorize" stops being a bare fact and becomes a consequence of
the interface the reader has just seen.

## Evidence

Measured numbers, artifacts and write-up notes for this session: `.scratch/obrada-upita/measurements/0007-iterator-model-and-pipeline.md`.
