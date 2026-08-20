# Research: how MySQL turns SQL into an executing plan

Type: research
Status: claimed

## Question

Grounds chapters 2, 3 and 5. Primary sources only - the MySQL 8.4 reference manual, the MySQL server
team blog, and the source tree where the manual is vague.

1. The **stages** a statement passes through: parser, resolver, transformer/rewriter, cost-based
   optimizer, executor. What are these called in the MySQL codebase and docs?
2. **Optimizer specifics**: join-order search (greedy vs exhaustive, `optimizer_search_depth`),
   access-path selection, the cost model and where its constants live, condition pushdown, and
   subquery transformations.
3. The **iterator executor** introduced around 8.0.18: how it replaced the older executor, its
   relationship to the classic **Volcano/iterator model**, and how `EXPLAIN FORMAT=TREE` output maps
   onto real iterator classes.
4. The **hypergraph join optimizer** - which versions have it, whether it is experimental, and whether
   it is reachable in a stock 8.4 build. Verify this; do not assume.

Cite everything with URLs; the paper needs IEEE references.

## Answer
