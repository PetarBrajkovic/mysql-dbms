# Research: vectorized execution, parallel execution, and plan caching in MySQL

Type: research
Status: resolved

## Question

Grounds chapters 6, 7 and 8 - the three where MySQL is **weaker** than the slide bullets imply, so
accuracy matters more here than anywhere else. Establish what MySQL genuinely does and what the
honest comparison is. Primary sources only; flag anything uncertain rather than guessing.

1. **Vectorized execution.** Does MySQL vectorize at all? Confirm whether the row-at-a-time iterator
   model is what InnoDB queries actually use, then establish the contrast case - how DuckDB,
   ClickHouse or Postgres handle batched/columnar execution, and what **HeatWave** does differently.
2. **Parallel query execution.** What is genuinely parallel in stock MySQL 8.4: InnoDB parallel read
   threads (`innodb_parallel_read_threads`), parallel index creation, `CHECK TABLE`. What is **not**
   parallel. Compare to Postgres parallel workers and Oracle parallel query.
3. **Plan caching.** The claim to verify: MySQL has **no plan cache** in the Oracle shared-pool sense,
   and the old **query cache was removed in 8.0**. Establish why it was removed, what prepared
   statements actually cache (and whether the *plan* is reused across executions), and how this
   compares to Oracle cursor sharing and Postgres generic vs custom plans.

If claim 3 is wrong, say so loudly - chapter 8's entire framing depends on it.

## Answer

Findings: [`research/06-vectorized-parallel-plancache.md`](../research/06-vectorized-parallel-plancache.md)
(531 lines, 22 distinct primary sources).

**All three chapters survive; chapter 8 needs a refinement, not a rewrite.**

1. **Vectorization - MySQL does not do it.** MySQL 8.4 executes row-at-a-time on the Volcano iterator
   model, evidenced by worklog WL#11785. The contrast cases are concrete and citable: DuckDB batches
   ~2,048 tuples, ClickHouse processes 1K-4K rows per operator, and HeatWave uses hybrid columnar
   storage with SIMD. Chapter 6 stands as an honest comparative chapter.
2. **Parallelism - highly constrained.** Parallel execution covers index creation, bulk loads and
   full table scans only. Critically, `innodb_parallel_read_threads` does **not** parallelize an
   ordinary `SELECT`. Postgres by contrast drives parallel scans and joins from the optimizer.
   Chapter 7 stands, and its thesis is the narrowness of the feature.
3. **Plan caching - the claim held, with one important distinction.** MySQL has no shared plan cache
   in Oracle's library-cache sense, and the query cache was indeed removed in 8.0 (deprecated in
   5.7.20). The refinement: MySQL *does* cache **parse trees** for prepared statements, per-session
   only, but not the optimizer's chosen **plan**. Chapter 8's framing is intact; it simply must draw
   the parse-tree/plan line carefully rather than claiming MySQL caches nothing.

**To verify against the live server** once ticket 01 is done: the report states prepared statements
re-optimize on each execution with new bind parameters. That is the single most load-bearing claim in
chapter 8 and it is empirically checkable, so check it rather than citing it on trust.
