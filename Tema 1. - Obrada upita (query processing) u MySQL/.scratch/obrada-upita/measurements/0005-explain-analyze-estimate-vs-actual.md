# 0005 — A bad estimate is not a bad plan, and the plan that IS bad looks perfect in EXPLAIN — evidence

Detail split out of `learning-records/0005-explain-analyze-estimate-vs-actual.md` so the record itself stays short.
Measured numbers, produced artifacts and write-up notes for that session. Read this only when writing or checking the chapter it belongs to, not when planning a lesson.

## Live run (2026-08-26, MySQL 8.4.11) — every number in the lesson is measured

| what | measured |
|---|---|
| `payment` table scan: est / actual | 16,500 / 16,044 = **1.03x** |
| `Filter (amount > 10)`: est / actual | 5,499 / **114** = **48x** |
| truth behind it | 114 of 16,044 = **0.711%** against the hardcoded 33.33% |
| histogram on `payment.amount` (non-indexed) | `filtered` 33.33 → **0.71**; est 5,499 → **117** vs 114 actual; cost 3,672 → 1,715 |
| buckets requested / built / type | 32 / **19** / `singleton` |
| histogram on `wide_events.country_code` (indexed) | estimate **`2.45e+6` before and after**, unchanged |
| `wide_events` `'US'`: est / actual | 2,454,588 / 3,500,177 = **1.43x**, ~4,475 ms |
| flat estimate that was *not* used | 5,000,000 / cardinality 14 = 350,656 |
| five-table join, with vs without histogram | **identical join order**; cost 9,373 vs 1,926 |
| `loops` demo: `fa` node | `rows=5.48 loops=178` → 178 × 5.48 = 975 ≈ join's 976 |
| bad plan: est / actual rows | **10 / 31,621 = 3,162x** |
| bad plan: chosen vs alternative | cost 0.836 → ~2,700 ms; cost 574,128 → **~1,860 ms** |
| histogram on `amount` (64 and 1024 buckets) | `filtered` → 0.50, **plan and runtime unchanged** |
| `EXPLAIN ANALYZE FOR CONNECTION` | `ERROR 1235` |
| single- vs multi-table `UPDATE` | no plan / full measured plan, **data unchanged in both** |

Server left with `COLUMN_STATISTICS` back to 0 rows; every script that builds a histogram drops it.

## Artifacts produced

- `examples/04-explain/04-procena-naspram-stvarnog.sql`, `05-loops-i-prosek.sql`,
  `06-histogram-i-njegove-granice.sql`, `07-los-plan-koji-explain-ne-vidi.sql` — all four
  smoke-tested against the live server, no errors, no leftover histograms or probe tables.
- `figures/04-explain-03-procena-naspram-stvarnog.png`, `-04-loops-i-prosek.png`,
  `-05-los-plan.png` (+ `.svg` twins), via the new `tools/make-lesson05-explain-analyze.ps1`.
  Self-verifying in the lesson-04 style, and then some: it throws if the Filter divergence drops
  below 10x, if the table-scan estimate stops being accurate, if the histogram stops closing the
  gap, if the indexed-column histogram *starts* moving the estimate, if `fa`'s actual row count
  stops being fractional, if the dominant node stops being a looped one, or if the alternative plan
  fails to beat the chosen one on that run. Any of those means a claim in the lesson has gone
  stale, and the build breaks instead of rendering it.
- `GLOSSARY.md` §2d: 9 new terms plus five recorded non-choices.

## Terminology decisions worth remembering

Full reasoning is in `GLOSSARY.md` §2d. The two that took actual checking:

**`korpa`, not `razred` or `interval`, for a histogram bucket.** The statistics words both assert a
class *interval*, which is false for MySQL's `singleton` histograms where one bucket holds one
value. This lesson uses a singleton histogram as its worked example, so the wrong word would have
contradicted the figure beside it.

**`optimizator opsega`, not `opsežni optimizator`, for the range optimizer.** `Opsežan` means
extensive, so the adjective form says "the thorough optimizer", which is a different claim. The
genitive keeps it visibly tied to §2b's `sken opsega`, which is what the component plans.

