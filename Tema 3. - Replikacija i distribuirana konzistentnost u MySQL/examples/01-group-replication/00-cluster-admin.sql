-- 00-cluster-admin.sql
-- Run on EACH of the three nodes (3307, 3308, 3309), as root.
--
-- This is the one setup step that must NOT go through replication. The AdminAPI needs an
-- account it can reach every node with, from '%' rather than 'localhost'; the existing
-- root@localhost is refused outright:
--
--     Dba.checkInstanceConfiguration: User 'root' can only connect from 'localhost'.
--
-- Creating it on node1 and letting it replicate would work today, but the same account has
-- to exist after the cluster is dissolved and rebuilt, in either direction. SET sql_log_bin
-- = 0 keeps the statement out of the binary log entirely, so gtid_executed stays byte for
-- byte identical on all three nodes and Group Replication never sees an errant GTID -
-- which is the one thing the sandbox was built (ticket 10) to avoid.

SET SESSION sql_log_bin = 0;

CREATE USER IF NOT EXISTS 'icadmin'@'%' IDENTIFIED BY 'IcAdmin#2026';
GRANT ALL PRIVILEGES ON *.* TO 'icadmin'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;

SET SESSION sql_log_bin = 1;

SELECT @@port AS port, @@global.gtid_executed AS gtid_executed_unchanged;
