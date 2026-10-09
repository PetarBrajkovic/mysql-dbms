-- Chapter 3 (part B) - durability: redo log, binary log and fsync at commit.
-- Run on the SOURCE (3307) as root: SET GLOBAL and sql_log_bin need admin privileges.
-- Verified on MySQL 8.4.11 (lesson 0003, record 0005). Restores 1/1 and drops the lab database.
--
-- WARNING: the sql_log_bin = 0 part writes rows ONLY on 3307 (they never reach the binary log,
-- so the replicas never get them). That is why durability_lab is dropped at the end - the DROP
-- is replicated, so all three nodes converge again.

-- ===== 1. Current matrix settings and where the redo log lives =====
SELECT @@sync_binlog,
       @@innodb_flush_log_at_trx_commit,
       @@innodb_flush_log_at_timeout,
       @@innodb_flush_method;            -- Windows default: unbuffered

SELECT FILE_NAME, START_LSN, END_LSN, SIZE_IN_BYTES
FROM performance_schema.innodb_redo_log_files;   -- files under #innodb_redo

-- ===== 2. Lab table and 100 commits =====
CREATE DATABASE IF NOT EXISTS durability_lab;
USE durability_lab;
CREATE TABLE IF NOT EXISTS writes (id INT AUTO_INCREMENT PRIMARY KEY, v CHAR(20));

DROP PROCEDURE IF EXISTS hundred_commits;
DELIMITER //
CREATE PROCEDURE hundred_commits()
BEGIN
  DECLARE i INT DEFAULT 0;
  WHILE i < 100 DO
    INSERT INTO writes (v) VALUES ('x');   -- autocommit: every INSERT is one commit
    SET i = i + 1;
  END WHILE;
END//
DELIMITER ;
SET autocommit = 1;

-- ===== 3. Redo-log fsyncs per 100 commits =====
-- 3a. binary log off for this session (no two-phase commit)
SET SESSION sql_log_bin = 0;
SELECT VARIABLE_VALUE INTO @f0 FROM performance_schema.global_status
 WHERE VARIABLE_NAME = 'Innodb_os_log_fsyncs';
SET @t0 = NOW(6);
CALL hundred_commits();
SELECT 'no binlog, 1/1' AS mode,
       VARIABLE_VALUE - @f0 AS redo_fsyncs_per_100,
       TIMESTAMPDIFF(MICROSECOND, @t0, NOW(6)) / 100 AS us_per_commit
FROM performance_schema.global_status WHERE VARIABLE_NAME = 'Innodb_os_log_fsyncs';
SET SESSION sql_log_bin = 1;

-- 3b. binary log on, sync_binlog = 1, innodb_flush_log_at_trx_commit = 1
SELECT VARIABLE_VALUE INTO @f0 FROM performance_schema.global_status
 WHERE VARIABLE_NAME = 'Innodb_os_log_fsyncs';
SET @t0 = NOW(6);
CALL hundred_commits();
SELECT 'binlog, 1/1' AS mode,
       VARIABLE_VALUE - @f0 AS redo_fsyncs_per_100,
       TIMESTAMPDIFF(MICROSECOND, @t0, NOW(6)) / 100 AS us_per_commit
FROM performance_schema.global_status WHERE VARIABLE_NAME = 'Innodb_os_log_fsyncs';

-- 3c. binary log on, innodb_flush_log_at_trx_commit = 2 (redo: write only at commit)
SET GLOBAL innodb_flush_log_at_trx_commit = 2;
SELECT VARIABLE_VALUE INTO @f0 FROM performance_schema.global_status
 WHERE VARIABLE_NAME = 'Innodb_os_log_fsyncs';
SET @t0 = NOW(6);
CALL hundred_commits();
SELECT 'binlog, redo=2' AS mode,
       VARIABLE_VALUE - @f0 AS redo_fsyncs_per_100,
       TIMESTAMPDIFF(MICROSECOND, @t0, NOW(6)) / 100 AS us_per_commit
FROM performance_schema.global_status WHERE VARIABLE_NAME = 'Innodb_os_log_fsyncs';

-- ===== 4. Restore defaults and clean up =====
SET GLOBAL innodb_flush_log_at_trx_commit = 1;
DROP DATABASE durability_lab;
SELECT @@sync_binlog, @@innodb_flush_log_at_trx_commit;   -- must be 1, 1
