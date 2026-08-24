# 0002 — MySQL's architecture is a seam, and the seam is the `handler` class

**Date:** 2026-08-24
**Chapter:** 2 (Arhitektura obrade upita u MySQL-u)
**Lesson:** `lessons/0002-arhitektura-serverski-sloj-i-motor.html`
**Reference card:** `reference/01-arhitektura-serverski-sloj-i-motor.html`
**Status:** taught (lesson delivered; quiz not yet taken by the user at time of writing)

## What was taught

The conceptual spine of Chapter 2, built to sit directly on Chapter 1's logical/physical frame:

1. **MySQL is split into two layers with a documented interface between them.** Server layer
   understands SQL; storage engine understands rows and pages. The manual states it plainly:
   the pluggable architecture "provides a standard set of management and support services that are
   common among all underlying storage engines", while the engines "actually perform actions on the
   underlying data"
   (<https://dev.mysql.com/doc/refman/8.4/en/pluggable-storage-overview.html>).

2. **The membership test is falsifiable, not a matter of taste:** does the feature change if you
   swap the engine? Table 18.1's footnote 1 marks *only* replication and backup/PITR as
   "Implemented in the server, rather than in the storage engine"; everything else in that table
   (transactions, MVCC, locking granularity, clustered indexes, data caches, foreign keys) varies
   per engine, so it cannot be server-layer
   (<https://dev.mysql.com/doc/refman/8.4/en/storage-engines.html>).

3. **The seam is a C++ class, not a metaphor.** `handler` is "the interface for dynamically loadable
   storage engines"; `handlerton` is "a singleton structure - one instance per storage engine"
   (`sql/handler.h`, tag `mysql-8.4.6`). The load-bearing teaching sentence, verified in code:
   **executor iterators never read pages, they call handler methods.**
   `TableScanIterator::Read()` is literally
   `while ((tmp = table()->file->ha_rnd_next(m_record))) { ... }`
   (`sql/iterators/basic_row_iterators.cc`), where `TABLE::file` is a `handler *`.

4. **The path, with names that exist in 8.4:** `do_command()` → `dispatch_command()` (protocol) →
   `dispatch_sql_command()` (SQL entry) → parser → resolver → optimizer/planner → executor →
   `handler` → InnoDB. `THD` carries session state through all of it;
   `thread_handling` defaults to `one-thread-per-connection`.

5. **Two places where the abstraction deliberately leaks** — this is the chapter's most defensible
   material, because both are demonstrable live:
   - **ICP**: the server hands an `Item*` (a server-layer expression node) into the engine via
     `idx_cond_push(uint keyno, Item *idx_cond)`.
   - **Statistics**: index cardinality is the engine's, column histograms are the server's.

## Non-obvious insights to revisit

**(a) `mysql_parse()` no longer exists in 8.4.** It is `dispatch_sql_command()`. Verified absent from
both `sql/sql_parse.h` and `sql/sql_parse.cc` at tag `mysql-8.4.6`. Older blog posts and lecture
material still name it, so this is an easy citation error to inherit. Do not write it.

**(b) The 8.4 Reference Manual never mentions `handler`, `handlerton`, or "handler API" anywhere.**
Every handler-level claim in Chapter 2 must cite the **source tree**, not the manual. This is a real
constraint on how the chapter is written, not a stylistic preference.

**(c) There is no official MySQL 8.4 figure of the query-processing pipeline.** Figure 18.3
("MySQL Architecture with Pluggable Storage Engines",
<https://dev.mysql.com/doc/refman/8.4/en/images/mysql-architecture.png>, verified reachable) is a
layered *component* diagram only. So Chapter 2 either reuses Figure 18.3 with an IEEE citation, or
uses an original diagram. The lesson's `.arch` component is that original diagram and can be
rasterized for `figures/`.

**(d) The statistics split is the sharpest single teaching point in the chapter.** Mnemonic:
*index statistics belong to the engine; column histograms belong to the server.* Histograms exist
precisely to give selectivity for columns that are **not** indexed.

## Live run (2026-08-24, MySQL 8.4.11) — every number in the lesson is measured, not predicted

The MySQL84 service was started by the user mid-session, so all three examples were verified.

**ICP, `wide_events`, `FORCE INDEX (idx_customer_created)`, `customer_id BETWEEN 1 AND 20000 AND
created_at >= '2025-01-01'`:**

| | plan shape | rows out of the scan | rows out of the node above |
|---|---|---|---|
| ICP on | one node, `with index condition: (...)` | 165,707 | — |
| ICP off | `Filter:` **above** `Index range scan` | 499,297 | 165,707 |

333,590 rows crossed the seam only to be discarded; ~15.3 s vs ~45.8 s on this machine. The
`Filter` node appearing and disappearing is the seam made visible in the plan tree — a much better
demonstration than the `Extra` column, which was the original plan for this example.

**A first attempt at this example was wrong and got corrected.** Without `FORCE INDEX` the optimizer
picks `idx_customer_id`, so what gets pushed is the `customer_id` range itself, not `created_at`,
and the plan also picks up `Using MRR`. The lesson and `examples/02-arhitektura/02-*.sql` both
document why the composite index is forced.

**Statistics, `country_code`:**

| source | layer | value |
|---|---|---|
| `mysql.innodb_index_stats.n_diff_pfx01` | engine | **14** distinct, from `sample_size` = **16** of **5,082** leaf pages |
| `information_schema.COLUMN_STATISTICS` before | server | empty — no histograms at all |
| histogram after `UPDATE HISTOGRAM ... WITH 16 BUCKETS` | server | `singleton`, **15** buckets, sampling-rate ≈ 0.03 |
| bucket[14] / bucket[13] | server | `VVM=`(`US`) at 1.0; `U0U=`(`SE`) at 0.29915 ⇒ **US ≈ 70.1%** |

So the engine's sampled estimate (14) and the server's histogram (15) disagree, and the server is
right. More importantly, cardinality can only imply a *uniform* 5M/14 ≈ 357k per value, while the
histogram carries the real ~70% skew. Same question, two layers, two answers.

**Histogram state was restored** (`DROP HISTOGRAM`, verified `COUNT(*) = 0`), because Chapter 4's
planned worked example depends on there being no histogram.

## Correction filed against Chapter 4's plan

Creating the histogram on `country_code` **did not change the estimate**: `EXPLAIN FORMAT=TREE` for
the Lesson-01 query still reported `rows=2.45e+6`, identical to the no-histogram run. The manual
gives the reason: "The optimizer prefers range optimizer row estimates to those obtained from
histogram statistics" (<https://dev.mysql.com/doc/refman/8.4/en/optimizer-statistics.html>) — with
an index present, the index dive wins. Recorded in `NOTES.md`. Chapter 4 must not claim or imply
that adding a histogram fixes the 2.45M-vs-3.5M gap on this column.

## Grounding / sources

New research memo: `.scratch/obrada-upita/research/11-server-engine-architecture.md` (first-party
only: 8.4 manual, `mysql-8.4.6` source tree; no blogs, no Doxygen). Prior memo
`04-sql-to-plan-and-iterator.md` supplied the pipeline-stage names. Glossary terms added in
`GLOSSARY.md` §2a.

## Next

Per WORKFLOW's per-chapter loop: the user runs the three scripts in `examples/02-arhitektura/`
himself (step 2), then Chapter 2's prose is written with `academic-research-writer` (step 3),
with one figure — either Figure 18.3 reused under an IEEE citation, or the lesson's `.arch` diagram
rasterized. Chapter 3 ("Od SQL-a do plana izvršavanja") reuses the `ol.stages` component and should
zoom into stages 3–5 rather than re-introducing them.
