-- 03-index-and-analyze.sql
-- Adds secondary indexes after the bulk load (faster than maintaining them during
-- 5,000,000 row-by-row inserts) and refreshes the optimizer's statistics.
--
-- The index set is deliberately mixed selectivity, for chapters 3 and 4:
--   - idx_customer_id, idx_is_flagged: unambiguously selective -> the optimizer
--     should always prefer these for an equality lookup.
--   - idx_event_type: uniform, moderate cardinality (8 values) -> a believable case
--     for an index scan.
--   - idx_country_code: same shape as idx_event_type but SKEWED (~70% one value).
--     Verified on the live server (ticket 01): a COUNT(*) filter still picks this
--     index for BOTH the common and the rare value, because COUNT(*) is a covering
--     query the index alone can answer - selectivity alone doesn't flip the access
--     path here. See 04-verify.sql's query 6 comment for the non-covering query
--     chapter 4 should try instead to see selectivity actually matter.
--   - idx_created_at, idx_customer_created: range scans and a composite/covering
--     index case.
--   - idx_status_created: a skewed low-cardinality column combined with a range.

USE obrada_upita;

ALTER TABLE wide_events
  ADD INDEX idx_event_type      (event_type),
  ADD INDEX idx_country_code    (country_code),
  ADD INDEX idx_customer_id     (customer_id),
  ADD INDEX idx_is_flagged      (is_flagged),
  ADD INDEX idx_created_at      (created_at),
  ADD INDEX idx_customer_created (customer_id, created_at),
  ADD INDEX idx_status_created  (status, created_at);

ANALYZE TABLE wide_events;
