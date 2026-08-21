-- 01-schema.sql
-- Creates the `obrada_upita` schema and the synthetic wide table `wide_events`.
-- Run once, before 02-generate.sql. Safe to re-run: drops the table first.
--
-- Secondary indexes are added later, in 03-index-and-analyze.sql, after the bulk load -
-- building them in one pass with ALTER TABLE ... ADD INDEX is far faster than maintaining
-- them row-by-row during a multi-million-row INSERT.

CREATE DATABASE IF NOT EXISTS obrada_upita
  CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;

USE obrada_upita;

DROP TABLE IF EXISTS wide_events;

CREATE TABLE wide_events (
  -- Clustered index (InnoDB's primary key IS the row storage order). A COUNT(*)
  -- over just this column is the operation innodb_parallel_read_threads actually
  -- speeds up - see chapter 7.
  id               BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

  -- Low cardinality (8 values), roughly uniform -> a secondary index on this is
  -- selective enough that the optimizer should choose an index scan over it.
  event_type       VARCHAR(20)     NOT NULL,

  -- Low cardinality (15 values) but deliberately SKEWED (~70% 'US'). Same
  -- shape as event_type, opposite optimizer decision: a worked example for why
  -- cardinality alone does not predict selectivity, and for EXPLAIN's
  -- estimated-vs-actual row divergence when a query filters the skewed value
  -- versus a rare one.
  country_code     CHAR(2)         NOT NULL,

  -- High cardinality (~200k distinct across 5M rows) -> unambiguously selective,
  -- the access path an equality lookup should always prefer.
  customer_id      INT UNSIGNED    NOT NULL,

  status           ENUM('pending','processing','completed','failed','refunded')
                                    NOT NULL,
  amount           DECIMAL(10,2)   NOT NULL,
  currency         CHAR(3)         NOT NULL DEFAULT 'RSD',
  priority         TINYINT UNSIGNED NOT NULL,

  -- Spread over ~3 years -> supports range-scan and composite-index examples.
  created_at       DATETIME        NOT NULL,
  updated_at       DATETIME        NOT NULL,

  -- Extreme skew the other way: ~2% TRUE. A "needle in a haystack" filter -
  -- highly selective despite being a near-boolean column.
  is_flagged       TINYINT(1)      NOT NULL DEFAULT 0,

  region           VARCHAR(30)     NOT NULL,
  channel          VARCHAR(20)     NOT NULL,
  device_type      VARCHAR(20)     NOT NULL,
  customer_segment VARCHAR(20)     NOT NULL,

  -- Unindexed filler: widens every row so a non-covering index lookup has a
  -- real extra cost (a trip back to the clustered index), and the table is
  -- large in bytes, not just in row count.
  notes            VARCHAR(500)    NOT NULL,
  metadata_json    JSON            NULL,
  ip_address       VARCHAR(45)     NOT NULL,
  referrer_url     VARCHAR(255)    NOT NULL,

  PRIMARY KEY (id)
) ENGINE = InnoDB;
