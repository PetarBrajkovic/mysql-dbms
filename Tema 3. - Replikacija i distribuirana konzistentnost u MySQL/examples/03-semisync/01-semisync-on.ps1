# Feeds: lesson 0004, ch. 4 | Nodes: node1 (3307) source, node2 (3308) + node3 (3309) replicas | State: async -> semisync
# Switches the resting asynchronous topology to semisynchronous replication. The plugins are
# already installed (00-setup/06-semisync.sql, persistent); only the *_enabled variables are
# set here, and they return to OFF on every server start (record 0001).
. "$PSScriptRoot\_common.ps1"

Q 3307 "SET GLOBAL rpl_semi_sync_source_enabled = ON;
        SET GLOBAL rpl_semi_sync_source_wait_point = 'AFTER_SYNC';
        SET GLOBAL rpl_semi_sync_source_timeout = 10000" | Out-Null
foreach ($p in 3308, 3309) {
  # The receiver must reconnect to register itself as a semisync client.
  Q $p "SET GLOBAL rpl_semi_sync_replica_enabled = ON; STOP REPLICA IO_THREAD; START REPLICA IO_THREAD" | Out-Null
}
# One write so the replicas catch up and the source switches status ON.
Q 3307 "CREATE TABLE IF NOT EXISTS poliklinika.semisync_demo (
          id INT UNSIGNED PRIMARY KEY, note VARCHAR(64) NOT NULL,
          created_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6)) ENGINE=InnoDB" | Out-Null
if (WaitSemiOn 2) { '--- semisync ON, 2 clients' } else { '!!! semisync did not come ON' }
Q 3307 "SELECT @@rpl_semi_sync_source_wait_point AS wait_point, @@rpl_semi_sync_source_timeout AS timeout_ms,
               @@rpl_semi_sync_source_wait_for_replica_count AS acks_needed"
SemiStatus
