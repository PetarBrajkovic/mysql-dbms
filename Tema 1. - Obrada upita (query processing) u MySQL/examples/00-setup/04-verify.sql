-- 04-verify.sql
-- Sanity checks after 01-03 have run. Run this and keep the output - the row count,
-- table size, and the two EXPLAIN results are what get recorded in ticket 01's Answer.

USE obrada_upita;

-- 1. Row count.
SELECT COUNT(*) AS row_count FROM wide_events;

-- 2. Table + index size on disk.
SELECT
  table_name,
  table_rows AS approx_rows,
  ROUND(data_length / 1024 / 1024, 1)  AS data_mb,
  ROUND(index_length / 1024 / 1024, 1) AS index_mb,
  ROUND((data_length + index_length) / 1024 / 1024, 1) AS total_mb
FROM information_schema.tables
WHERE table_schema = 'obrada_upita' AND table_name = 'wide_events';

-- 3. Indexes actually present.
SHOW INDEX FROM wide_events;

-- 4. A quick look at the data.
SELECT * FROM wide_events LIMIT 5;

-- 5. Confirm the country_code skew is real (should show ~70% US).
SELECT country_code, COUNT(*) AS n,
       ROUND(100 * COUNT(*) / (SELECT COUNT(*) FROM wide_events), 1) AS pct
FROM wide_events
GROUP BY country_code
ORDER BY n DESC
LIMIT 5;

-- 6. Verified on the live server (ticket 01): both the common value ('US', ~70%)
--    and the rare value ('JP') come back as `type: ref` using idx_country_code,
--    NOT the "common value forces a table scan" prediction this comment used to
--    make. The reason: COUNT(*) is answered entirely from the secondary index
--    (`Using index` in Extra) - a skinny index-only scan beats a table scan over
--    this wide row even at bad selectivity. The estimated `rows` still differs
--    sharply by value (~2.45M for 'US' vs ~214k for 'JP'), so this is still a
--    real estimated-vs-actual example for chapter 4 - just not the scan-type
--    contrast originally expected. To see selectivity actually flip the access
--    path, chapter 4 should try a NON-covering query, e.g. `SELECT notes FROM
--    wide_events WHERE country_code = 'US'` vs `= 'JP'`, which forces a lookup
--    back into the wide clustered row and should behave differently.
EXPLAIN SELECT COUNT(*) FROM wide_events WHERE country_code = 'US';

EXPLAIN SELECT COUNT(*) FROM wide_events WHERE country_code = 'JP';

-- 7. A highly selective equality lookup - should always use idx_customer_id.
EXPLAIN SELECT * FROM wide_events WHERE customer_id = 12345;

-- 8. The parallel-scan candidate for chapter 7: a bare COUNT(*), which InnoDB can
--    execute as a parallel clustered-index scan when innodb_parallel_read_threads > 1.
--    Time this once at the default thread count, then again after raising it, and
--    record both timings when chapter 7 is written.
SELECT @@innodb_parallel_read_threads AS current_parallel_read_threads;
SELECT COUNT(*) FROM wide_events;
