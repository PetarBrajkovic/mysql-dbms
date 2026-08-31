# 0008 — A negative claim is only defensible once you have found its boundary

**Date:** 2026-08-31
**Chapter:** 6 (Gde MySQL ne prati obrazac — merged 6.1 vektorizacija / 6.2 paralelizam / 6.3 keširanje)
**Lesson:** `lessons/0008-gde-mysql-ne-prati-obrazac.html`
**Reference card:** `reference/07-ne-prati-obrazac.html`
**Status:** taught 2026-08-31; chapter written and ticket 21 closed the same day.

## What was taught

The chapter's three claims all have the form "MySQL does not do X", which is a shape none of
chapters 1-5 used. The lesson's organising move is that such a claim is only defensible once its
boundary is found, so each of the three sections ends at a measured boundary rather than at "no":

1. **§6.1 no vectorization** — `Read()` returns one row by definition (WL#11785), and the measurable
   consequence is a per-row, per-expression cost that is independent of selectivity.
2. **§6.2 parallelism exists, but below `handler`** — three conditions, all three necessary, and the
   third one is a single `WHERE` clause.
3. **§6.3 no shared plan cache, but a per-session statement cache** — with the sharper version:
   the plan is not merely un-shared, it is re-derived on every `EXECUTE`.

## Non-obvious insights to revisit

**(a) The headline: the boundary of MySQL's parallelism is exactly the `handler` seam from chapter 2.**
The same clustered scan of 5,000,000 rows goes 1483 ms → 508 ms as `innodb_parallel_read_threads`
goes 1 → 16 (**2.9×**). Add `WHERE amount > 100` and the identical sweep is **1.01×** — nothing.
The reason is structural, not a heuristic: with no predicate and no projection InnoDB can count
subtrees itself and hand the server layer a total, so rows never cross the seam; with a predicate the
decision belongs to a server-layer iterator, so every row crosses `handler` one at a time in one
thread. Chapter 2's seam and chapter 5's `Read()` jointly *predict* this result — that is the
strongest cross-chapter link the paper has, and §6.2 should be written around it.

**(b) `FORCE INDEX(PRIMARY)` is load-bearing, and the reason is a trap worth teaching.**
`SELECT COUNT(*) FROM wide_events` does **not** read the clustered index: every index is covering for
`COUNT(*)`, so the optimizer picks the narrowest secondary one (`idx_is_flagged` here, `Extra: Using
index`). Parallel read applies to clustered-index reads, so the default plan never gets it — measured
440 ms flat across every thread count, which reads like "parallelism does nothing" and is the wrong
conclusion. Anyone re-running this without `FORCE INDEX(PRIMARY)` will conclude the opposite of the
truth.

**(c) Research memo 06 overstates the parallelism claim in one direction and invents it in another.**
The memo says parallelism applies to "index creation, bulk insert operations (LOAD DATA INFILE),
full table scans" and that it does "NOT parallelize ordinary SELECT queries". WL#11720's own Scope
says the opposite of the second half: *"Read the sub trees of an index in parallel only if the
request is a non-locking SELECT COUNT(*)."* So a `SELECT` **is** the named case. And DDL/bulk-load
parallelism is `innodb_ddl_threads`, a different variable — the memo has merged two features.
Do not quote memo 06 §2 without checking; see the corrections list in `README.md`.

**(d) The `optimizer_trace` is a plan-cache detector, and this is the cleanest proof in the chapter.**
Three `EXECUTE`s of one prepared statement produce **three separate traces** (7889 / 7403 / 7889
bytes) with **three different row estimates** (203730 / 2454590 / 213948) and costs (213078 / 494949
/ 221109). A cached plan would leave the second and third with nothing to trace. This upgrades the
chapter's claim from "the plan is not shared" to "the plan is re-derived per execution against the
actual parameter value" — MySQL does not build a generic plan, so PostgreSQL's custom-vs-generic
plan machinery has no MySQL counterpart at all.

**(e) `Com_stmt_reprepare` shows what "internal structure" means, concretely.** `SELECT * FROM t`
prepared, then `ALTER TABLE ... ADD COLUMN`: the same unchanged statement text returns **three**
columns instead of two, and the counter goes 0 → 1. So the `*` had been resolved to a column list and
remembered. That is a better explanation of the manual's vague "internal structure" than any
paraphrase of it.

**(f) The chapter's real risk is rhetorical, not factual.** Three sentences are easy to write and all
false: "MySQL doesn't cache anything", "MySQL has no parallelism", "MySQL is slow because it doesn't
vectorize". Each has a precise true counterpart. The lesson ends on that table deliberately, and the
reference card repeats it, because this is what a defense question will target.

## Next

Chapter 6 is **written**: §6.1-6.3, ~1.620 words, one figure
(`06-...-01-paralelni-sken-granica.png`), with `02-cena-po-torki.png` left lesson-only, the same
arrangement as chapter 5's third figure. All of the insights above landed in the prose, (a) as
§6.2's spine and (b) as the stated reason `FORCE INDEX(PRIMARY)` is in the example.

**The page prediction above was wrong, and how it was wrong is the useful part.** Chapter 6 did not
absorb the overrun, it *was* the overrun: 4 rendered pages against 2.5, taking the export to 26
against the hard ≤25. Tightening §6.1 was tried first, as this record advised, and a ~120-word
redundancy trim moved the page count by **zero**. Figure widths did it instead: 5.0in → 4.3in across
all twelve figures gave back a full page with nothing removed, and 3.9in gives back nothing further.
The lesson for chapter 7, and for Tema 2: on a paper this dense, **layout is the lever and prose is
not**, which is now the second measurement saying so.

Only chapter 7 (Zaključak) remains, and it has **no page allowance left** at 25 of 25. That
decision is flagged on its ticket.

## Evidence

Measured numbers, artifacts and write-up notes for this session:
`.scratch/obrada-upita/measurements/0008-ne-prati-obrazac-three-boundaries.md`.
