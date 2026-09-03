# figures/

Captioned figures for `rad.md`, named `NN-<chapter-slug>-MM-<what-it-shows>.png` where `NN` is the
chapter number and `MM` numbers figures within that chapter.

Because pandoc does not auto-number figure captions in the DOCX export, the figure number also
belongs in the caption text itself wherever the image is referenced from `rad.md`, e.g.
`![Slika 3.1: ...](figures/03-privilegije-01-role-graph.png)`.

**The pipeline is shared and documented in [`../../tools/FIGURES.md`](../../tools/FIGURES.md)** — how
figures are generated, the self-verifying pattern, the capture standard, sourcing rules, and the
traps already hit. This file holds only what is specific to this paper.

Decision record: [`../.scratch/kontrola-pristupa/issues/12-figure-and-example-strategy.md`](../.scratch/kontrola-pristupa/issues/12-figure-and-example-strategy.md).

## What a figure is, in a security paper

Tema 1's figure pipeline was built around one shape: `EXPLAIN ANALYZE` rendered as a flame graph.
None of that applies here — there is no plan to draw. This paper's figure types instead:

- **result-and-error pair** — the same statement run as two accounts, one succeeding and one
  throwing `ERROR 1142`/`1143`. The paper's workhorse: it shows *enforcement*, not configuration.
  Built by a new shared, topic-local script, **`tools/make-pair-figure.ps1`**: runs a statement as
  two named accounts in one script, captures the success grid and the error text, stitches both
  into one image. Reused across chs. 3–5 rather than re-derived per chapter.
- **table figure** — a result grid where the data itself is the point (e.g. a `SHOW GRANTS` or
  grant-table extract). `../../tools/make-table-figure.ps1`, already shared and topic-agnostic.
  Used sparingly here — most grant-table detail is carried in prose, not a figure.
- **drawn diagram** (role graph, privilege-check flow, RLS/tenancy pattern comparisons) — the
  `visualize` skill (Mermaid, rendered and verified in-session) is the default, replacing Tema 1's
  hand-built-SVG approach. An official reused diagram (vendor manual, citable paper) is still tried
  first per `../../tools/FIGURES.md`'s existing rule; Mermaid is the fallback when nothing suitable
  exists to reuse, which is expected to be the common case here since MySQL's own manual has no
  privilege-check-path or role-graph diagram.
- **log extract** (ch. 6 only) — plain text, not a result grid, so `make-table-figure.ps1` doesn't
  fit as-is. Rendered via a small monospace-styled HTML→PNG using the same rasterization step, either
  a tiny shared `tools/make-log-figure.ps1` or a `-Raw` mode added to `make-table-figure.ps1` (decide
  the exact shape when ch. 6 is written — the source text already exists in
  `examples/11-audit/captured-general-log.txt`).

**No screenshots anywhere in this paper.** Carried forward unchanged from `../../tools/FIGURES.md` and
Tema 1's own trap note: every figure is agent-generated end to end via CLI/rasterization, including
error dialogs — never a hand-captured Workbench screenshot.

## Per-chapter budget (soft guidance, not a hard cap)

Kept deliberately lean — Tema 1's own scar is that figures ran to ~25% of page count before a cap
had to be retroactively imposed. One figure carries each chapter's sharpest point rather than
illustrating everything illustrable.

| Chapter | Expected | What it's for |
|---|---|---|
| 1 Uvod | 0 | no SQL runs here |
| 2 Klasični modeli | 1 | Bell–LaPadula levels diagram — the sharpest DAC/MAC contrast, carried by one figure |
| 3 Privilegije i uloge | 2 | role graph (Mermaid); privilege-check two-stage flow (Mermaid) |
| 4 FGAC i RLS | 2 | result/error pair for column-privilege enforcement; RLS emulation pattern comparison (Mermaid) |
| 5 Sprovođenje politika | 1 | one result/error pair — the strongest of memo 05's candidates, not several |
| 6 Audit logging | 1 | log extract, from the capture already in `examples/11-audit/` |
| 7 Multi-tenant | 1 | tenancy pattern comparison diagram (Mermaid), the closing synthesis |
| 8 Zaključak | 0 | no SQL runs here |

**~8 figures total.** A chapter may go over if it genuinely needs both a diagram and a live example;
this guards against one chapter swallowing every figure, it is not a quota to hit exactly — but the
lean side is the default to reach for, not the generous one.

## Dedicated scripts written for this paper

| Script | Figures it builds | What it asserts |
|---|---|---|
| `tools/make-pair-figure.ps1` | result/error pairs, chs. 3–5 | *(written at first use — asserts the success account's statement actually succeeds and the restricted account's actually throws the declared error, not a different one)* |
| `tools/make-log-figure.ps1` (or `make-table-figure.ps1 -Raw`) | ch. 6 log extract | *(decided at ch. 6, shape TBD between the two options above)* |
