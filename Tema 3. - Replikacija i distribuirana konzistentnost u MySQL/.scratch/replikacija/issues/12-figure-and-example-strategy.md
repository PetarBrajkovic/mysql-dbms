# Decide the figure and example strategy for a replication paper

Type: grilling
Status: open
Blocked by: 09, 10

## Question

What a figure *is* differs per topic, and this is the third different answer. Tema 1 had flame graphs.
Tema 2 had result-and-error pairs, table figures and Mermaid diagrams, and needed a new shared script
(`make-pair-figure.ps1`) written for it. Replication's natural figures are none of those.

Decide:

1. **The figure types this paper uses.** Candidates: a **topology diagram** (Mermaid via the
   `visualize` skill - cheap, and probably the workhorse here), a **two-node state pair** (the same
   row queried on both nodes, showing divergence - likely a variant of the existing pair script), a
   **lag time-series** (genuinely new; needs sampling and a plot, and nothing shared produces one), a
   **sequence diagram** for acknowledgement protocols (Mermaid `sequenceDiagram` - the obvious way to
   draw `AFTER_SYNC` against `AFTER_COMMIT`), and a **log extract** (`make-table-figure.ps1 -Raw`,
   already exists from Tema 2, for `mysqlbinlog` output).
2. **Whether a new shared tool is needed**, and if so what it produces. The lag time-series is the one
   with no existing path. Decide whether it earns a script or whether a table of sampled values makes
   the point just as well. Remember the split: `../tools/` is for topic-agnostic tools, this topic's
   own `tools/` is for its own figure scripts.
3. **The figure budget.** Tema 2 landed on about 8 total after the user pushed back on an initial
   14-figure draft. Set the number here with that history in mind, per chapter, including zero for
   Uvod and Zaključak.
4. **Carry forward the invariants**: no screenshots anywhere, captions in Serbian, explicit widths
   sized by aspect ratio for readability, every figure referenced by number in the text.
   `../WRITING.md` and `../tools/FIGURES.md` hold the rules - do not restate them, just confirm
   nothing changes.
5. **The examples convention** for anything needing concurrency or timing: where those scripts live,
   how they name nodes, and how a reader of `examples/` can tell which port a script expects.

Write the outcome into `figures/README.md`, binding from there on.
