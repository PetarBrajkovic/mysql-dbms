# figures/

Captioned figures for `rad.md`, named `NN-<chapter-slug>-MM-<what-it-shows>.png` where `NN` is the
chapter number and `MM` numbers figures within that chapter (e.g.
`04-explain-01-visual-explain.png`).

Because pandoc does not auto-number figure captions in the DOCX export, the figure number also
belongs in the caption text itself wherever the image is referenced from `rad.md`, e.g.
`![Slika 4.1: ...](figures/04-explain-01-visual-explain.png)`.

**The pipeline is shared and documented in [`../../tools/FIGURES.md`](../../tools/FIGURES.md)** — how
figures are generated, when a dedicated script is warranted, the self-verifying pattern, the capture
standard, captions and sourcing, reproducibility, and the traps already hit. None of that is repeated
here. This file holds only what is specific to this paper.

Decision record: [`../.scratch/obrada-upita/issues/09-figure-and-example-strategy.md`](../.scratch/obrada-upita/issues/09-figure-and-example-strategy.md)
(reopened 2026-08-22, when Workbench's Visual Explain stopped rendering and the whole pipeline was
switched to an automated, agent-run one).

## Per-chapter budget (soft guidance, not a hard cap)

| Chapter | Expected | What it's for |
|---|---|---|
| 1 Uvod | 0 | no SQL runs here |
| 2 Arhitektura | 3 | official reused architecture diagram, plus an ICP-on/ICP-off flame graph pair |
| 3 Od SQL-a do plana | 2 | parse/resolve stage, then optimized plan |
| 4 EXPLAIN i EXPLAIN ANALYZE | 4 (lekcije su napravile 9) | access-type ladder, estimated-vs-actual divergence, JSON/TREE formats, trace excerpt |
| 5 Iterator model | 2 | iterator/pipeline diagram, one EXPLAIN ANALYZE tree read as an iterator chain |
| 6 Vektorizovano | 1 | row-at-a-time evidence |
| 7 Paralelno | 1 | `innodb_parallel_read_threads` non-effect on ordinary SELECT |
| 8 Plan cache | 2 | prepared-statement parse-tree reuse vs. "no shared plan cache" |
| 9 Zaključak | 0 | no SQL runs here |

~13 figures total. A chapter may go over if it genuinely needs both a diagram and a live example —
this guards against chapter 4 swallowing every figure, it is not a quota to hit exactly.

## Dedicated scripts written for this paper

All live in this topic's own `tools/`. The two generic entry points (`make-figure.ps1`,
`make-table-figure.ps1`) are shared and live in `../../tools/`.

| Script | Builds | The claim it asserts |
|---|---|---|
| `make-lesson01-comparison.ps1` | index vs table scan, hand-built comparison page | myflames' runtime-based `compare` view would mislead here |
| `make-lesson02-icp-comparison.ps1` | ICP on/off flame-graph pair | the "off" state needs a session-scoped `SET` in the same connection |
| `make-lesson03-cost-crossing.ps1` | access-path cost crossover, 15-point sweep | two cost curves crossing; myflames cannot draw this at all |
| `make-lesson03-joinorder-comparison.ps1` | join-order comparison | two plans, not one plan's shape |
| `make-lesson04-access-types.ps1` | ranked access-type ladder, 12 queries | each row must produce its declared access type |
| `make-lesson04-three-formats.ps1` | same query in all three formats | two formats are table-shaped, one is iterator-shaped |
| `make-lesson05-explain-analyze.ps1` | chapter 4b's three figures | divergence holds, histogram closes the gap on the non-indexed column but not the indexed one, per-loop count stays fractional, the alternative plan still wins. `-SkipBadPlan` while iterating on layout |
| `make-lesson06-optimizer-trace.ps1` | chapter 4c's four figures | the load-bearing **negative** assertion: `idx_created_at` must **not** appear in `considered_execution_plans`. Figure 09 starts two real background clients. `-SkipForConnection` while iterating |

## Non-SQL figures in this paper

`02-arhitektura-00-mysql-architecture-official.png` is Figure 18.3 from the 8.4 Reference Manual's
Pluggable Storage Engine Architecture page, fetched verbatim (no re-drawing, no relabeling) and cited
by name and link. It is the only reused external diagram so far.
