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

**Superseded for chapters 5-7 by the firm cap in `../GLOSSARY.md` §4** (set 2026-08-31 under the hard
≤25-page ceiling): chapter 5 gets **2**, chapter 6 gets **1**, chapter 7 gets **0**, and those are
caps, not guidance. The table below is the original nine-chapter plan, kept for chapters 1-4 which
were budgeted under it.

| Chapter | Expected | What it's for |
|---|---|---|
| 1 Uvod | 0 | no SQL runs here |
| 2 Arhitektura | 3 | official reused architecture diagram, plus an ICP-on/ICP-off flame graph pair |
| 3 Od SQL-a do plana | 2 | parse/resolve stage, then optimized plan |
| 4 EXPLAIN i EXPLAIN ANALYZE | 4 (lekcije su napravile 9) | access-type ladder, estimated-vs-actual divergence, JSON/TREE formats, trace excerpt |
| 5 Iterator model | **2** (lekcija je napravila 3) | iterator/pipeline diagram, one EXPLAIN ANALYZE tree read as an iterator chain |
| 6 Gde MySQL ne prati obrazac | **1** (lekcija je napravila 2) | the parallel-read boundary: 2.9× without `WHERE`, 1.01× with it |
| 7 Zaključak | **0** | no SQL runs here |

A chapter may **not** go over the §4 cap any more — figures are ~25% of the page count, which is
where the paper grew unnoticed. A lesson may still build extra figures for itself; they simply do not
enter `rad.md` (chapters 5 and 6 each did this once).

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
| `make-lesson07-iterator.ps1` | chapter 5's three figures (the third is lesson-only) | every printed TREE node must resolve to a known iterator class (an unmapped node throws); inner `loops` == outer `rows`; `rows × loops` reconstructs the join's row count. The **negative** assertion: the `LIMIT`-only plan must contain **no** `Sort` node, or the whole pipeline/blocking contrast is a lie. Figure 3 redraws figure 1's run as a real node-and-edge tree off the same `Get-TreeData` call, and adds its own negative assertion: the plan must actually branch, or a figure captioned "stablo, ne spisak" would be a lie. `-Only 1` / `-Only 2` / `-Only 3` while iterating |
| `make-lesson08-ne-prati-obrazac.ps1` | chapter 6's two figures (the second is lesson-only) | asserts the figure's whole argument in **both** directions: the clustered `COUNT(*)` sweep must speed up ≥ 2× from 1 to 16 threads, and the **negative** half — the same scan plus one `WHERE` must stay ≤ 1.20×, or the claim "one predicate kills it" is a lie. Also asserts the premise: the *default* `COUNT(*)` plan must use a **secondary** index and `FORCE INDEX(PRIMARY)` must use `PRIMARY`, since without that the sweep silently measures the wrong plan. Figure 2 asserts monotonic growth with predicate count |

## Non-SQL figures in this paper

`02-arhitektura-00-mysql-architecture-official.png` is Figure 18.3 from the 8.4 Reference Manual's
Pluggable Storage Engine Architecture page, fetched verbatim (no re-drawing, no relabeling) and cited
by name and link. It is the only reused external diagram so far.
