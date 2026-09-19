-- 04-heartbeat.sql
-- Runs on node1 (3307) only; reaches the replicas through replication.
--
-- `heartbeat` is an INSTRUMENT, not part of the clinic domain (ticket 08). It carries no
-- foreign keys, so a ticker can write to it at a fixed rate without parent-row lookups on
-- the replica distorting the lag measurement. The lag time-series of ch. 7 is sampled from
-- this table and nothing else.
--
-- ts is DATETIME(6): microsecond resolution, because a local topology's real lag is far
-- below one second and whole-second timestamps would round the whole measurement away.

USE poliklinika;

DROP TABLE IF EXISTS heartbeat;

CREATE TABLE heartbeat (
  id    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  ts    DATETIME(6)     NOT NULL,       -- written by the ticker on the source
  node  VARCHAR(16)     NOT NULL,       -- which instance produced the row
  PRIMARY KEY (id)
) ENGINE = InnoDB;
