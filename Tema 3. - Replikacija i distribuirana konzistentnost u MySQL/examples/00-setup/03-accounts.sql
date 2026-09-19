-- 03-accounts.sql
-- Runs on ALL THREE instances (3307, 3308, 3309), as root. Safe to re-run.
--
-- Two accounts, deliberately separated:
--   repl     - used only by the replication channel itself (receiver thread).
--   dbadmin  - used by every example script and by mysql-credentials.cnf, so the paper's
--              own tooling never connects as root (the habit carried from Tema 2).
--
-- Roles are symmetric on purpose: any node can be made source or replica without
-- creating accounts first, which the failover and switchover demos need.

-- The replication account. REPLICATION SLAVE is still the privilege's name in 8.4 even
-- though the role vocabulary changed to SOURCE/REPLICA.
CREATE USER IF NOT EXISTS 'repl'@'%' IDENTIFIED BY 'Repl#2026repl';
ALTER USER 'repl'@'%' IDENTIFIED BY 'Repl#2026repl';
GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%';

-- Group Replication additionally needs these on the recovery account (ticket 11).
GRANT BACKUP_ADMIN, CLONE_ADMIN, CONNECTION_ADMIN, GROUP_REPLICATION_STREAM,
      REPLICATION_SLAVE_ADMIN ON *.* TO 'repl'@'%';

-- The working account for examples and figures.
CREATE USER IF NOT EXISTS 'dbadmin'@'%' IDENTIFIED BY 'DbAdmin#2026';
ALTER USER 'dbadmin'@'%' IDENTIFIED BY 'DbAdmin#2026';
GRANT ALL PRIVILEGES ON poliklinika.* TO 'dbadmin'@'%';
GRANT SELECT ON performance_schema.* TO 'dbadmin'@'%';
GRANT REPLICATION CLIENT, PROCESS, SYSTEM_VARIABLES_ADMIN, REPLICATION_SLAVE_ADMIN,
      GROUP_REPLICATION_ADMIN ON *.* TO 'dbadmin'@'%';

FLUSH PRIVILEGES;
