# 19-gr-down.ps1 - the full round trip back: dissolve the cluster/ClusterSet, clear what the
# AdminAPI persisted, drop the throwaway demo objects, and re-create the asynchronous channels
# so the sandbox rests exactly where ticket 10 left it.
#
#   .\19-gr-down.ps1
#
# Run this at the end of any session that brought the group up. Chapters 3, 4 and 7 measure
# asynchronous and semisynchronous replication and must not find a group running.

$ErrorActionPreference = 'Continue'
$bin   = 'C:\Program Files\MySQL\MySQL Server 8.4\bin\mysql.exe'
$sh    = 'C:\mysql-repl\tools\mysql-shell-8.4.10-windows-x86-64bit\bin\mysqlsh.exe'
$here  = $PSScriptRoot
$setup = Join-Path (Split-Path $here -Parent) '00-setup'

function RootQ([int]$p, [string]$q) {
  & $bin -h 127.0.0.1 -P $p -u root '-pRepl#2026root' --table -e $q 2>&1 |
    Where-Object { $_ -notmatch 'Using a password on the command line' }
}

'### 1. dissolve whatever is running, and clear the persisted read-only flags'
& $sh --js --no-wizard --file (Join-Path $here '19-gr-down.js')

'### 2. drop the throwaway demo objects (on 3307 only - they replicate)'
RootQ 3307 @"
DROP TABLE IF EXISTS poliklinika.cert_demo;
DROP TABLE IF EXISTS poliklinika.cons_demo;
DROP TABLE IF EXISTS poliklinika.no_pk_demo;
DELETE FROM poliklinika.heartbeat WHERE id >= 800000;
SELECT COUNT(*) AS heartbeat_rows FROM poliklinika.heartbeat;
"@

'### 3. re-create the asynchronous channels 3307 -> 3308 and 3307 -> 3309'
foreach ($p in 3308, 3309) {
  Get-Content (Join-Path $setup '05-replication.sql') -Raw |
    & $bin -h 127.0.0.1 -P $p -u root '-pRepl#2026root' 2>&1 |
    Where-Object { $_ -notmatch 'Using a password on the command line' }
  "  3307 -> $p re-created"
}
Start-Sleep -Seconds 6

'### 4. prove it end to end'
RootQ 3307 "INSERT INTO poliklinika.heartbeat (ts, node) VALUES (NOW(6), 'async-back');"
Start-Sleep -Seconds 3
foreach ($p in 3307, 3308, 3309) {
  RootQ $p "SELECT @@port AS port, @@read_only AS ro, COUNT(*) AS seen FROM poliklinika.heartbeat WHERE node='async-back';"
}
RootQ 3307 "DELETE FROM poliklinika.heartbeat WHERE node='async-back';"

'### 5. and 3306 is still not ours'
& (Join-Path $setup 'topology.ps1') status | Select-Object -Last 1
