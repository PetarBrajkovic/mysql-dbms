# Decide the figure and example strategy for a replication paper

Type: grilling
Status: resolved
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

## Answer

Resolved 2026-09-19 by grilling, eight decisions. Binding text: [`../../../figures/README.md`](../../../figures/README.md).

1. **Measured results become native Markdown tables**, a separate `Tabela N.N` series, rather than
   rendered images. This is new for the course; neither earlier paper has a native table. Every
   number in a table traces to a committed measurement `.md` record. The shared reference doc has
   never styled a table, so the first one (ch. 4) is checked in the exported DOCX and any fix goes
   into `../tools/build-reference-doc.py`.
2. **The lag chart uses matplotlib**, in a topic-local `tools/make-lag-plot.py`. The user chose it
   over a hand-built SVG partly for token cost (~15 lines vs hundreds). One `pip install --user`.
3. **One chart, not two**: a natural burst with `Seconds_Behind_Source` and the `performance_schema`
   lag overlaid. It is both the paper's single natural-lag figure and the unreliable-vs-real
   contrast. The script asserts the divergence.
4. **The harness is chosen by timing** (closes the map's harness fog): sub-second windows use
   mysqlsh JS with held sessions, as ticket 11 proved; coarse demos may stay PowerShell.
5. **Measurement files** (closes the map's format fog): chart input goes to
   `figures/raw/<figure-base>.csv`, gitignored, units in the column names. Table and prose numbers
   come from the committed `.scratch/replikacija/measurements/*.md` records.
6. **Diagrams are our own Mermaid with Serbian labels by default**, after checking the manual per
   figure. An official diagram is reused only if it shows exactly the chapter's point. Each
   own-drawn diagram records why the official one lost.
7. **Budget: ~7 figures + ~6 tables**, per chapter in the README. It is bound to the ~25-page
   target. An overrun drops an item (first candidates: the ch. 2 diagram and the ch. 3 log extract)
   and never shrinks a figure.
8. **Examples convention**: existing `NN-<subject>` folders are kept and not renamed. Every script
   carries a fixed header (`Feeds | Nodes with ports | State: async/cluster/clusterset`) and checks
   the sandbox state before running.

Item 4 (invariants) confirmed unchanged. The induced-lag honesty rule is extended from figure
captions to table captions.
