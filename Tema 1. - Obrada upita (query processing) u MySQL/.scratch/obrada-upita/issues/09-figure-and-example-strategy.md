# Decide the figure and example strategy

Type: grilling
Status: open
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
