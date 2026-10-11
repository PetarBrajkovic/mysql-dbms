# Feeds: lesson 0004, ch. 4 (memo 04 claim 6) | Nodes: node1 (3307) restarted, node2 (3308) new source | State: failed over
# The failed source comes back. Crash recovery runs (lesson 0005: a prepared transaction that is
# in the binary log is COMMITTED), then we try to attach it as a replica of the new source with
# GTID auto-positioning, and look at whether anything stops us.
# Usage: .\04-rejoin.ps1 -Id 2001
param([int]$Id = 2001)
. "$PSScriptRoot\_common.ps1"

$t0 = Get-Date
& powershell -NoProfile -File "$PSScriptRoot\..\00-setup\topology.ps1" start -Node 1
"--- recovery lines from node1's error log since the restart:"
Get-Content 'C:\mysql-repl\node1\node1.err' -Tail 60 |
  Where-Object { $_ -match 'recover|Recover|XA|prepared|rollback|commit|binlog|Crash|crash' } |
  Select-Object -Last 12

"--- the old source after recovery: does it hold id=$Id ?  " +
  (Q 3307 "SELECT COUNT(*) FROM poliklinika.semisync_demo WHERE id = $Id" -Raw)
"--- GTIDs the old source has and the new source does NOT (GTID_SUBTRACT):"
$g1 = Q 3307 "SELECT @@gtid_executed" -Raw
$g2 = Q 3308 "SELECT @@gtid_executed" -Raw
$g1s = ($g1 -join '') -replace '\\n', ''; $g2s = ($g2 -join '') -replace '\\n', ''
Q 3308 "SELECT GTID_SUBTRACT('$g1s', '$g2s') AS extra_on_old_source,
               GTID_SUBSET('$g1s', '$g2s')   AS old_is_subset_of_new"

"--- REJOIN: attach 3307 as a replica of 3308 (auto-positioning)"
Q 3307 "SET GLOBAL rpl_semi_sync_source_enabled = OFF;
        CHANGE REPLICATION SOURCE TO SOURCE_HOST='127.0.0.1', SOURCE_PORT=3308, SOURCE_USER='repl',
          SOURCE_PASSWORD='$replPw', SOURCE_AUTO_POSITION=1, GET_SOURCE_PUBLIC_KEY=1;
        START REPLICA" | Out-Null
Start-Sleep -Seconds 4
Q 3307 "SHOW REPLICA STATUS\G" |
  Select-String 'Source_Port|Replica_IO_Running|Replica_SQL_Running:|Last_IO_Errno|Last_IO_Error:|Last_SQL_Errno|Last_SQL_Error:|Seconds_Behind'
"--- the same row, on all three nodes now that 3307 is 'back':"
foreach ($p in 3307, 3308, 3309) { "  $p : " + (Q $p "SELECT COUNT(*) FROM poliklinika.semisync_demo WHERE id = $Id" -Raw) }
"--- table checksums (3307 / 3308 / 3309):"
foreach ($p in 3307, 3308, 3309) { "  $p : " + ((Q $p "CHECKSUM TABLE poliklinika.semisync_demo" -Raw) -join ' ') }
