-- Poglavlje 3 - niti koje ucestvuju u replikaciji.
-- Samo citanje, nista se ne menja. Provereno na MySQL 8.4.11 (lekcija 0002).

-- ===== Na IZVORU (3307): po jedna nit koja salje log za svaku povezanu repliku =====
SELECT THREAD_ID, PROCESSLIST_COMMAND, PROCESSLIST_HOST
FROM performance_schema.threads
WHERE PROCESSLIST_COMMAND LIKE 'Binlog Dump%';

-- ===== Na REPLICI (3309) =====
-- replica_io     = nit prijema (receiver)
-- replica_sql    = koordinator primene; kad je replica_parallel_workers > 0 on samo deli posao
-- replica_worker = niti primene (applier workers), podrazumevano 4 u 8.4
SELECT THREAD_ID, NAME
FROM performance_schema.threads
WHERE NAME IN ('thread/sql/replica_io', 'thread/sql/replica_sql', 'thread/sql/replica_worker');

-- Dokle je stigla nit prijema (poslednja transakcija upisana u relay log)
SELECT SERVICE_STATE, LAST_QUEUED_TRANSACTION
FROM performance_schema.replication_connection_status;

-- Dokle je stigla svaka nit primene (poslednja izvrsena transakcija)
SELECT WORKER_ID, SERVICE_STATE, LAST_APPLIED_TRANSACTION
FROM performance_schema.replication_applier_status_by_worker;
