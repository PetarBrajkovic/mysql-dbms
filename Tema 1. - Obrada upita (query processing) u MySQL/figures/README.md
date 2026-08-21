# figures/

Captioned screenshots and diagrams for `rad.md`, named `NN-<chapter-slug>-MM-<what-it-shows>.png`
where `NN` is the chapter number and `MM` numbers figures within that chapter (e.g.
`04-explain-01-visual-explain.png`).

Because Pandoc does not auto-number figure captions in the DOCX export (see ticket 02), the
sequential figure number also belongs in the caption text itself wherever the image is referenced
from `rad.md`, e.g. `![Slika 4.1: ...](figures/04-explain-01-visual-explain.png)`.

Full decision record: [`../.scratch/obrada-upita/issues/09-figure-and-example-strategy.md`](../.scratch/obrada-upita/issues/09-figure-and-example-strategy.md).

## What gets photographed

Assigned per purpose, not one medium for the whole paper - whichever is most accurate and
readable for the specific example:

- **Visual Explain** (Workbench) for anything showing an access path or plan shape.
- **EXPLAIN ANALYZE / FORMAT=TREE text**, captured inside Workbench (monospaced), wherever the
  tree text itself is the teaching point (ch. 4, ch. 8).
- **Result grid** only when the data itself is the point (e.g. the `country_code` skew).
- No raw CLI screenshots - one tool (Workbench), one visual style throughout.
- **Non-SQL diagrams** (architecture, conceptual comparisons): search first for a suitable
  official/existing diagram (MySQL reference manual, a citable paper) to reuse; fall back to an
  original diagram made for this paper only if nothing suitable turns up.

## Per-chapter budget (soft guidance, not a hard cap)

| Chapter | Expected | What it's for |
|---|---|---|
| 1 Uvod | 0 | no SQL runs here |
| 2 Arhitektura | 1 | pipeline diagram (official reused, or original) |
| 3 Od SQL-a do plana | 2 | parse/resolve stage, then optimized plan |
| 4 EXPLAIN i EXPLAIN ANALYZE | 4 | ranked access-type showcase, estimated-vs-actual divergence, JSON/TREE format, optimizer_trace rejected-plan excerpt |
| 5 Iterator model | 2 | iterator/pipeline diagram, one EXPLAIN ANALYZE tree read as an iterator chain |
| 6 Vektorizovano | 1 | row-at-a-time evidence |
| 7 Paralelno | 1 | `innodb_parallel_read_threads` non-effect on ordinary SELECT |
| 8 Plan cache | 2 | prepared-statement parse-tree reuse evidence vs. "no shared plan cache" |
| 9 Zaključak | 0 | no SQL runs here |

~13 figures total. A chapter may go over if it genuinely needs both a diagram and a live
example - this guards against chapter 4 swallowing every figure, it's not a quota to hit exactly.

## Capture standard

- **Light** theme (Workbench default) - prints cleanly on a white page.
- Bump the Workbench UI/result-grid font a notch or two before capturing - every screenshot
  shrinks to fit a page margin.
- Tight crop: content only, no window chrome, menus, or OS taskbar.
- Target width ~1200-1600px, native PNG (no JPEG artifacts on text).

## Captions and sourcing

`Slika N: <opis>`, hand-typed (Pandoc won't number them). **No source note** for the author's own
live captures or the author's own original diagrams - authorship is implicit and constant.
A source note **is** required, as an IEEE numbered citation in the caption text
(`Slika N: ... [k]`), whenever a figure is a reused official/external diagram - add that source to
`references.bib` like any other reference.

## Reproducibility

Every SQL-driven figure's script lives in `examples/`, its filename mirroring the figure's
filename (e.g. `figures/04-explain-01-visual-explain.png` <->
`examples/04-explain/01-visual-explain.sql`), with a one-line comment at the top of the SQL file
naming the figure it produces. **Non-SQL diagrams** (architecture, reused-official, or original)
are exempt - there is nothing to run behind them.
