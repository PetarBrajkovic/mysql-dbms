# Feeds: lesson 0004, ch. 4 | Nodes: node1 (3307) killed, node2 (3308) promoted, node3 (3309) re-pointed | State: semisync -> failed over
# A REAL source crash inside the acknowledgement wait, then a failover. The ack is withheld by
# stopping both receivers (staged, as in 02-window.ps1); the crash is a forced process kill of
# node1's mysqld (a process crash, not an OS crash - with sync_binlog=1 and
# innodb_flush_log_at_trx_commit=1 the binlog and redo are on disk either way).
# Afterwards: 04-rejoin.ps1 (restart node1 and try to bring it back), then 09-restore.ps1.
# Usage: .\03-crash-failover.ps1 -WaitPoint AFTER_COMMIT -Id 2001
param([ValidateSet('AFTER_SYNC', 'AFTER_COMMIT')][string]$WaitPoint = 'AFTER_COMMIT', [int]$Id = 2001)
. "$PSScriptRoot\_common.ps1"

if (-not (WaitSemiOn 2 5)) { '!!! semisync is not ON with 2 clients - run 01-semisync-on.ps1'; exit 1 }
Q 3307 "SET GLOBAL rpl_semi_sync_source_wait_point = '$WaitPoint';
        SET GLOBAL rpl_semi_sync_source_timeout = 120000" | Out-Null      # long: the crash comes first
foreach ($p in 3308, 3309) { Q $p "STOP REPLICA IO_THREAD" | Out-Null }
"--- wait_point=$WaitPoint, timeout=120 s, receivers on 3308/3309 STOPPED"
"--- GTIDs before the write (3307 / 3308):"
Q 3307 "SELECT @@gtid_executed" -Raw; Q 3308 "SELECT @@gtid_executed" -Raw

$wOut = "$env:TEMP\semi-crash-writer.json"; Remove-Item $wOut -ErrorAction SilentlyContinue
$writer = Start-Process $mysqlsh -ArgumentList '--js', '--file', "`"$PSScriptRoot\02-writer.js`"", $Id, "crash-$WaitPoint" `
            -NoNewWindow -PassThru -RedirectStandardOutput $wOut
Start-Sleep -Milliseconds 1500

"--- 1.5 s into the wait: writer's state, and what session B reads on 3307"
Q 3307 "SELECT ID, STATE, INFO FROM information_schema.PROCESSLIST WHERE INFO LIKE 'INSERT INTO poliklinika.semisync_demo%'"
"  B reads id=$Id on 3307 : " + (Q 3307 "SELECT COUNT(*) FROM poliklinika.semisync_demo WHERE id = $Id" -Raw)

$pid1 = NodePid 1
"--- KILL node1 mysqld (pid $pid1) - forced process kill, mid-wait"
Stop-Process -Id $pid1 -Force
$writer.WaitForExit()
"--- writer A's outcome:"
Get-Content $wOut | Where-Object { $_ -match '^\{' }

"--- FAILOVER: promote 3308, re-point 3309 to it"
Start-Sleep -Seconds 1                                     # let 3308's applier finish its relay log
Q 3308 "STOP REPLICA; RESET REPLICA ALL" | Out-Null
Q 3309 "STOP REPLICA;
        CHANGE REPLICATION SOURCE TO SOURCE_HOST='127.0.0.1', SOURCE_PORT=3308, SOURCE_USER='repl',
          SOURCE_PASSWORD='$replPw', SOURCE_AUTO_POSITION=1, GET_SOURCE_PUBLIC_KEY=1;
        START REPLICA" | Out-Null
Start-Sleep -Seconds 2
"--- after failover, the application reads id=$Id from the NEW source 3308 : " +
  (Q 3308 "SELECT COUNT(*) FROM poliklinika.semisync_demo WHERE id = $Id" -Raw)
"  3309 (now replica of 3308)                           : " +
  (Q 3309 "SELECT COUNT(*) FROM poliklinika.semisync_demo WHERE id = $Id" -Raw)
Q 3309 "SELECT SERVICE_STATE AS receiver, LAST_ERROR_MESSAGE FROM performance_schema.replication_connection_status"
"--- 3308 gtid_executed:"; Q 3308 "SELECT @@gtid_executed" -Raw
