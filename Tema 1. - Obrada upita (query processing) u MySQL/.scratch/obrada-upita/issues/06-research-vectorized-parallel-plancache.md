# Research: vectorized execution, parallel execution, and plan caching in MySQL

Type: research
Status: claimed

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
