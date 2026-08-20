# Research: how MySQL turns SQL into an executing plan

Type: research
Status: resolved

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

Findings: [`research/04-sql-to-plan-and-iterator.md`](../research/04-sql-to-plan-and-iterator.md)
(593 lines, 95 distinct primary sources).

The strongest of the four reports, and the only one that corrected the premise of its own questions.

- **Five stages, not four.** Parser -> **Query Resolver** -> Query Optimizer -> Query Planner (join
  order and access paths, a sub-phase) -> Query Executor. There is no separate transformer/rewriter
  stage: transformations happen during **resolution**. Chapter 2's architecture diagram must reflect
  this rather than the generic textbook pipeline.
- **The hypergraph join optimizer is unreachable in stock MySQL 8.4** - compile-gated, not merely
  disabled. `WITH_HYPERGRAPH_OPTIMIZER` is enabled only for debug builds; on a release build
  `SET optimizer_switch='hypergraph_optimizer=on'` fails outright. This is the answer to the "verify,
  do not assume" instruction, and it is a real constraint: **do not plan a demonstration of it**, and
  note that the manual shows the flag in sample output without mentioning the compile gate.
- **Two corrections.** `optimizer_search_depth` defaults to **62**, not 0. Derived condition pushdown
  landed in **8.0.22** (refined in 8.0.28/8.0.29), not 8.4.
- **A nuance for chapter 5.** `EXPLAIN FORMAT=TREE` does not introspect iterators; it reads
  **AccessPath** enums and renders descriptions from them in `explain_access_path.cc`. The output is
  accurate because AccessPaths and iterators correspond 1:1, but the chapter should describe the
  mechanism correctly rather than claiming the tree is read off the running iterators.

**Do not cite, under any circumstances** - the report marks both `[SOURCE NOT FOUND]`:
1. A worklog number for the hypergraph optimizer. None was verified.
2. A release note announcing `hypergraph_optimizer` in `optimizer_switch`. The 8.0.22 release notes
   contain zero hits for "hypergraph".

Additionally, both `blogs.oracle.com/mysql` hypergraph posts returned **HTTP 403** and were never
read. They are listed as existing, with no claims resting on them. Preserve that discipline when
writing: an uncited gap is acceptable in this paper, an invented citation is not.
