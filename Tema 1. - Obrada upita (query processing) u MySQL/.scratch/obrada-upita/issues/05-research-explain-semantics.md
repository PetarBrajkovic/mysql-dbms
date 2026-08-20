# Research: EXPLAIN, EXPLAIN ANALYZE, and optimizer trace

Type: research
Status: open

## Question

Grounds chapter 4, the largest chapter. Primary sources only.

1. **`EXPLAIN` output formats** - traditional, `FORMAT=JSON`, `FORMAT=TREE`. What each column and
   field means, especially `type`, `key`, `rows`, `filtered`, and `Extra`.
2. **`EXPLAIN ANALYZE`** - how it differs from plain `EXPLAIN`, that it actually executes the
   statement, and how to read `actual time`, `rows`, `loops`, and cost estimates. Crucially: how to
   read **estimated vs actual** divergence, which is the whole diagnostic point.
3. **`EXPLAIN FOR CONNECTION`** and explaining a running statement.
4. **`optimizer_trace`** - enabling it, reading it, and what it exposes that EXPLAIN does not.
5. **Workbench Visual Explain** - what it renders and what the shapes and colours mean, since the
   paper's figures will come from it.

## Answer
