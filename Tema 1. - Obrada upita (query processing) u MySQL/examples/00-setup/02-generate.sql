-- 02-generate.sql
-- Populates wide_events with synthetic rows, one batch of 1,000,000 at a time.
--
-- To change the row count, edit @batches below (default 5 -> 5,000,000 rows) before
-- running. Each batch takes roughly a minute on ordinary laptop hardware; watch the
-- progress messages between batches.
--
-- Values are randomised (RAND()), not seeded, so re-running produces different data
-- with the same shape and skew every time - fine for a synthetic demo table where only
-- the distribution matters, not exact reproducibility.

USE obrada_upita;

SET autocommit = 0;
SET unique_checks = 0;
SET foreign_key_checks = 0;

-- Row-number source: a plain digits table cross-joined with itself six times gives
-- 10^6 = 1,000,000 rows (0..999999) without a procedural loop - the classic fast way
-- to manufacture large row counts in pure SQL.
DROP TABLE IF EXISTS _seq_digits;
CREATE TABLE _seq_digits (d TINYINT NOT NULL PRIMARY KEY);
INSERT INTO _seq_digits VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9);

DROP TABLE IF EXISTS _seq_1m;
CREATE TABLE _seq_1m (n INT UNSIGNED NOT NULL PRIMARY KEY);
INSERT INTO _seq_1m (n)
SELECT d1.d * 100000 + d2.d * 10000 + d3.d * 1000 + d4.d * 100 + d5.d * 10 + d6.d
FROM _seq_digits d1, _seq_digits d2, _seq_digits d3,
     _seq_digits d4, _seq_digits d5, _seq_digits d6;
COMMIT;

DELIMITER $$

DROP PROCEDURE IF EXISTS _generate_wide_events_batch $$
CREATE PROCEDURE _generate_wide_events_batch(IN p_base BIGINT UNSIGNED)
BEGIN
  INSERT INTO wide_events (
    event_type, country_code, customer_id, status, amount, currency, priority,
    created_at, updated_at, is_flagged, region, channel, device_type,
    customer_segment, notes, metadata_json, ip_address, referrer_url
  )
  SELECT
    ELT(1 + (s.n MOD 8), 'page_view','click','purchase','signup',
                          'login','logout','error','refund'),
    -- ~70% US, remainder spread evenly across 14 other countries. r_country is
    -- drawn once in the derived table below (materialized - see the LIMIT trick
    -- on it) so every branch below tests the same draw. Without forcing
    -- materialization, MySQL can merge/inline the derived table and silently
    -- re-evaluate RAND() at each of the three references below, which can drift
    -- ELT()'s index to 0 and return NULL - the "country_code cannot be null"
    -- error this comment is here to explain if you ever see it again.
    IF(s.r_country < 0.70, 'US',
       ELT(1 + FLOOR((s.r_country - 0.70) / 0.30 * 14),
           'DE','FR','GB','RS','IT','ES','NL','SE','NO','DK','PL','CA','AU','JP')),
    1 + FLOOR(RAND() * 200000),
    CASE
      WHEN s.r_status < 0.85 THEN 'completed'
      WHEN s.r_status < 0.90 THEN 'pending'
      WHEN s.r_status < 0.95 THEN 'processing'
      WHEN s.r_status < 0.98 THEN 'failed'
      ELSE 'refunded'
    END,
    ROUND(RAND() * 500 + 5, 2),
    ELT(1 + FLOOR(RAND() * 3), 'RSD','EUR','USD'),
    1 + FLOOR(RAND() * 5),
    DATE_ADD(DATE_ADD('2023-01-01 00:00:00', INTERVAL FLOOR(RAND() * 1095) DAY),
             INTERVAL FLOOR(RAND() * 86400) SECOND),
    DATE_ADD(DATE_ADD('2023-01-01 00:00:00', INTERVAL FLOOR(RAND() * 1095) DAY),
             INTERVAL FLOOR(RAND() * 86400) SECOND),
    -- ~2% TRUE - a needle-in-a-haystack filter despite looking like a boolean.
    IF(RAND() < 0.02, 1, 0),
    ELT(1 + FLOOR(RAND() * 6), 'Balkans','Western Europe','Northern Europe',
                                'North America','Asia Pacific','Other'),
    ELT(1 + FLOOR(RAND() * 4), 'web','mobile_app','api','partner'),
    ELT(1 + FLOOR(RAND() * 3), 'desktop','mobile','tablet'),
    ELT(1 + FLOOR(RAND() * 4), 'new','returning','vip','churn_risk'),
    CONCAT('note-', p_base + s.n, '-', LEFT(MD5(RAND()), 40)),
    JSON_OBJECT('session_id', UUID(), 'retries', FLOOR(RAND() * 5)),
    CONCAT(1 + FLOOR(RAND() * 223), '.', FLOOR(RAND() * 255), '.',
           FLOOR(RAND() * 255), '.', FLOOR(RAND() * 255)),
    CONCAT('https://example.com/ref/', FLOOR(RAND() * 10000))
  FROM (SELECT n, RAND() AS r_country, RAND() AS r_status FROM _seq_1m
        -- LIMIT with no real effect (1,000,000 rows exist) other than blocking
        -- derived-table merge, which is what forces materialization.
        LIMIT 18446744073709551615) AS s;
  COMMIT;
END $$

DROP PROCEDURE IF EXISTS generate_wide_events $$
CREATE PROCEDURE generate_wide_events(IN p_batches INT UNSIGNED)
BEGIN
  DECLARE i INT UNSIGNED DEFAULT 0;
  WHILE i < p_batches DO
    CALL _generate_wide_events_batch(i * 1000000);
    SELECT CONCAT('Batch ', i + 1, '/', p_batches,
                   ' done - about ', (i + 1) * 1000000, ' rows so far') AS progress;
    SET i = i + 1;
  END WHILE;
END $$

DELIMITER ;

SET @batches = 5;  -- 5 x 1,000,000 = 5,000,000 rows. Edit and re-run CALL to change.
CALL generate_wide_events(@batches);

-- Plumbing only - drop once generation is done.
DROP PROCEDURE _generate_wide_events_batch;
DROP PROCEDURE generate_wide_events;
DROP TABLE _seq_1m;
DROP TABLE _seq_digits;

SET autocommit = 1;
SET unique_checks = 1;
SET foreign_key_checks = 1;
