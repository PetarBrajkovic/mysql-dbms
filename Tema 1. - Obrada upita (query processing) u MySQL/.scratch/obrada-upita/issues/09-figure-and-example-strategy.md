# Decide the figure and example strategy

Type: grilling
Status: resolved
Blocked by: 01

## Question

The professor explicitly asked for examples and **pictures of SQL queries**, so figures are a graded
requirement, not decoration. Decide once, apply to all nine chapters.

1. **What gets photographed**: Workbench **Visual Explain** diagrams, Workbench result grids, plain
   CLI screenshots, or syntax-highlighted rendered text? Visual Explain is the strongest candidate for
   plan figures; the CLI may read better for raw `EXPLAIN ANALYZE` text output.
2. **How many figures per chapter**, and what each must show. A rough per-chapter budget stops chapter
   4 from swallowing every figure.
3. **Capture and naming convention**: resolution, light or dark theme, cropping, and a filename scheme
   in `figures/` that survives chapter renumbering.
4. **Captions**: Serbian, numbered (*Slika 1.*), and whether they carry a source note.
5. **Reproducibility**: every figure's SQL must live in `examples/` so a figure can be regenerated
   rather than re-hunted.

## Answer

Settled by a grilling session (three rounds). Full detail written into `figures/README.md`;
summary here:

1. **What gets photographed** - assigned per purpose, not one medium for the whole paper:
   - **Visual Explain** (Workbench) for anything showing an access path or plan shape.
   - **EXPLAIN ANALYZE / FORMAT=TREE text**, captured inside Workbench (monospaced), wherever the
     tree text itself is the teaching point (ch. 4, ch. 8).
   - **Result grid** only when the data itself is the point (e.g. the `country_code` skew from
     ticket 01).
   - Choice per figure is whichever is most accurate and readable for that specific example, not a
     rigid rule forced onto a mismatched case. No raw CLI screenshots - one tool (Workbench), one
     visual style.
   - **Non-SQL diagrams** (architecture, conceptual comparisons): search first for a suitable
     **official/existing diagram** (MySQL reference manual, a citable paper) to reuse; fall back to
     an **original diagram made for this paper** only if nothing suitable turns up. Chapter 2
     (Arhitektura) is the clear case needing this path, since no single query's output is a
     pipeline diagram.

2. **Per-chapter figure budget** - soft guidance, not a hard ceiling:

   | Chapter | Expected | What it's for |
   |---|---|---|
   | 1 Uvod | 0 | no SQL runs here |
   | 2 Arhitektura | 1 | pipeline diagram (official reused, or original) |
   | 3 Od SQL-a do plana | 2 | parse/resolve stage, then optimized plan |
   | 4 EXPLAIN i EXPLAIN ANALYZE | 4 | ranked access-type showcase, estimated-vs-actual divergence, JSON/TREE format, optimizer_trace rejected-plan excerpt |
   | 5 Iterator model | 2 | iterator/pipeline diagram from Visual Explain, one EXPLAIN ANALYZE tree read as an iterator chain |
   | 6 Vektorizovano | 1 | row-at-a-time evidence |
   | 7 Paralelno | 1 | `innodb_parallel_read_threads` non-effect on ordinary SELECT |
   | 8 Plan cache | 2 | prepared-statement parse-tree reuse evidence, contrasted with "no shared plan cache" |
   | 9 Zaključak | 0 | no SQL runs here |

   ~13 figures total. A chapter may go over (e.g. a diagram plus a live example) if it genuinely
   needs both - this is a guide against padding chapter 4 with every screenshot going, not a quota
   to hit exactly.

3. **Capture and naming convention**: Workbench **light** theme (prints cleanly); bump the
   Workbench UI/result-grid font a notch or two before capturing, since every screenshot shrinks to
   fit a page margin; tight crop with no window chrome/menus/taskbar; target width ~1200-1600px;
   native PNG (no JPEG artifacts on text). Filename scheme unchanged from `figures/README.md`:
   `NN-<chapter-slug>-MM-<what-it-shows>.png`.

4. **Captions**: hand-typed `Slika N: <opis>` in the Markdown caption text (Pandoc does not
   auto-number, per ticket 02). **No source note** for the author's own live captures or the
   author's own original diagrams - authorship is implicit and constant, and repeating "Izvor:
   autor" on ~13 figures is pure noise. A source note **is** required, formatted as an IEEE
   numbered citation in the caption (`Slika N: ... [k]`), whenever a figure is a reused
   official/external diagram - and that source is added to `references.bib` like any other
   reference.

5. **Reproducibility**: every SQL-driven figure's script lives in `examples/`, filename mirroring
   the figure's filename (e.g. `figures/04-explain-01-visual-explain.png` <->
   `examples/04-explain/01-visual-explain.sql`), with a one-line comment at the top of the SQL file
   naming the figure it produces. **Non-SQL diagrams** (architecture, reused-official, or original)
   are explicitly exempt from this rule - there is nothing to run behind them.

## Reopened (2026-08-22) - Workbench Visual Explain broke, pipeline automated

Workbench's Visual Explain view stopped rendering for the user, and manually capturing/cropping/
naming/filing ~13 figures across nine sessions was also just something he'd rather not do by hand.
Superseding point 1 and the "Capture standard" section above (points 2-5 and everything else stand):

- **Tool**: [`myflames`](https://github.com/vgrippa/myflames) (`pip install myflames`), a CLI that
  renders `EXPLAIN ANALYZE FORMAT=JSON` as an SVG (flame graph / bar chart / treemap / diagram /
  tree), plus headless Microsoft Edge (`msedge --headless --screenshot=...`) to rasterize that SVG
  to the PNG the DOCX export needs. Both already present on the machine; no other install required.
- **Credentials**: `mysql-credentials.cnf` at the repo root (gitignored, `--defaults-extra-file` for
  the `mysql` client) holds the DB password so it never appears in an argument list or shell
  history. The user fills the password in himself; the agent only ever reads the file.
  `mysql`'s and the pip user-scripts' directories were added to `PATH` (user scope) so both tools
  are callable directly.
- **Driver scripts**: `tools/make-figure.ps1` (plan-shape/tree figures - the former Visual Explain
  and `FORMAT=TREE` captures) and `tools/make-table-figure.ps1` (result-grid figures, which have no
  plan to visualize - runs `mysql --html`, rasterizes the table directly). Both write straight into
  `figures/` under the existing naming convention. Full mechanics in `figures/README.md`.
- **What changes for "what gets photographed" (point 1)**: Visual Explain -> myflames
  `--type flamegraph` (or `--type diagram` for join order); Workbench `FORMAT=TREE` capture ->
  myflames `--type tree`; result grid -> `make-table-figure.ps1`'s `mysql --html` rasterization.
  Non-SQL diagrams are unaffected - still official-reused-or-original, no tool involved.
- **What changes for "capture standard" (point 3)**: no more Workbench light theme / font-bump /
  manual crop - both scripts produce a tight, chrome-free capture by construction. Colour scheme is
  myflames' `hot` default for flame graphs.
- **What does NOT change**: naming convention, per-chapter budget, caption format, no-source-note-
  for-own-work rule (an agent-run tool operated by the author is the same authorship story a
  Workbench screenshot was), and the reproducibility rule - the SQL in `examples/` is still the
  citable source of truth. One addition: plan-shape figures now also keep an `.svg` twin next to the
  `.png` (same base name, committed) as the exact source the PNG was rasterized from.
- `myflames` itself gets one citation in the paper's methodology/tooling mention, not per-figure.
