-- 06-semisync.sql
-- Installs the semisynchronous plugins. Source half runs on node1 (3307), replica half on
-- node2 (3308) and node3 (3309) - the statements are separated below, do not run the whole
-- file against one instance.
--
-- Verified at ticket 10, and two of these facts correct the research memos:
--
--   * 8.4 installs semisync as PLUGINS (INSTALL PLUGIN), not as components. Ticket 04's own
--     wording was wrong about this; memo 04 corrected it and the live server agrees.
--   * The library names on Windows are .dll, not .so. Both the old (semisync_master.dll /
--     semisync_slave.dll) and the new (semisync_source.dll / semisync_replica.dll) files
--     ship in lib/plugin; use the new names.
--   * INSTALL PLUGIN survives a restart (it is recorded in mysql.plugin), but
--     rpl_semi_sync_*_enabled does NOT - it is a plain dynamic variable and comes back OFF
--     on every start. So the topology's resting state is always plain asynchronous
--     replication, and a semisynchronous chapter must switch it on explicitly. That is a
--     feature here, not a nuisance: ch. 3 wants the async baseline.
--
-- UNINSTALL PLUGIN round-trips cleanly on all three instances with replication running -
-- tested, no channel restart needed - so the two modes can be compared in one session.

-- ============================================================ node1 (3307), the source
INSTALL PLUGIN rpl_semi_sync_source SONAME 'semisync_source.dll';

-- Off by default; the chapter turns it on.
-- SET GLOBAL rpl_semi_sync_source_enabled = 1;
-- SET GLOBAL rpl_semi_sync_source_wait_point = 'AFTER_SYNC';   -- the default, and the safe one
-- SET GLOBAL rpl_semi_sync_source_timeout = 10000;             -- ms; the silent-degradation knob

-- ============================================ node2 (3308) and node3 (3309), the replicas
-- INSTALL PLUGIN rpl_semi_sync_replica SONAME 'semisync_replica.dll';
-- SET GLOBAL rpl_semi_sync_replica_enabled = 1;
-- STOP REPLICA IO_THREAD; START REPLICA IO_THREAD;   -- the receiver must reconnect to
--                                                    -- register as a semisync client

-- Health check on the source, after enabling on both sides:
--   SHOW STATUS LIKE 'Rpl_semi_sync_source_status';    -- ON
--   SHOW STATUS LIKE 'Rpl_semi_sync_source_clients';   -- 2
