# 0002 — MySQL's architecture is a seam, and the seam is the `handler` class — evidence

Detail split out of `learning-records/0002-server-engine-seam.md` so the record itself stays short.
Measured numbers, produced artifacts and write-up notes for that session. Read this only when writing or checking the chapter it belongs to, not when planning a lesson.

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

