# Feeds: nothing - housekeeping | Nodes: all three | State: failed over -> async resting state
# Puts the sandbox back: node1 (3307) source, node2/node3 replicas of it, semisync OFF, and
# identical gtid_executed on all three. Valid ONLY because nothing was written on 3308 while it
# was promoted: then 3308 is a subset of 3307, and pointing the replicas back at 3307 simply
# lets them fetch the old source's extra transaction. In production this is exactly the step
# the manual forbids ("the failed source ... should be discarded"); here it is a sandbox reset.
# Usage: .\09-restore.ps1 [-DropTable]
param([switch]$DropTable)
. "$PSScriptRoot\_common.ps1"

Q 3307 "STOP REPLICA; RESET REPLICA ALL;
        SET GLOBAL rpl_semi_sync_source_enabled = OFF;
        SET GLOBAL rpl_semi_sync_source_wait_point = 'AFTER_SYNC';
        SET GLOBAL rpl_semi_sync_source_timeout = 10000" | Out-Null
foreach ($p in 3308, 3309) {
  Q $p "STOP REPLICA; SET GLOBAL rpl_semi_sync_replica_enabled = OFF;
        CHANGE REPLICATION SOURCE TO SOURCE_HOST='127.0.0.1', SOURCE_PORT=3307, SOURCE_USER='repl',
          SOURCE_PASSWORD='$replPw', SOURCE_AUTO_POSITION=1, GET_SOURCE_PUBLIC_KEY=1;
        START REPLICA" | Out-Null
}
if ($DropTable) { Q 3307 "DROP TABLE IF EXISTS poliklinika.semisync_demo" | Out-Null }
else            { Q 3307 "DELETE FROM poliklinika.semisync_demo" | Out-Null }
Start-Sleep -Seconds 3
"--- gtid_executed on all three (must be identical):"
$g = foreach ($p in 3307, 3308, 3309) { ((Q $p "SELECT @@gtid_executed" -Raw) -join '') -replace '\\n', '' }
$g | ForEach-Object { "  $_" }
if (($g | Select-Object -Unique).Count -eq 1) { '--- IDENTICAL: no errant GTIDs' } else { '!!! GTID sets differ' }
foreach ($p in 3308, 3309) {
  "  $p : " + ((Q $p "SELECT CONCAT(c.SERVICE_STATE,'/',a.SERVICE_STATE,' src=',(SELECT PORT FROM performance_schema.replication_connection_configuration))
                FROM performance_schema.replication_connection_status c JOIN performance_schema.replication_applier_status a USING (CHANNEL_NAME)" -Raw) -join '')
}
