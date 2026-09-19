# Same primary-key INSERT on two primaries at once.
# Neither member takes a lock the other can see, so nothing aborts locally:
# the write-sets collide only in the certifier.
$ErrorActionPreference = 'Continue'
$bin = 'C:\Program Files\MySQL\MySQL Server 8.4\bin\mysql.exe'
function Q([int]$p, [string]$sql) {
  & $bin -h 127.0.0.1 -P $p -u icadmin '-pIcAdmin#2026' --table -e $sql 2>&1 |
    Where-Object { $_ -notmatch 'Using a password on the command line' }
}
function Session([int]$p, [string]$sql, [string]$tag) {
  Start-Job -ScriptBlock {
    param($bin, $p, $sql, $tag)
    $t0 = Get-Date
    $out = & $bin -h 127.0.0.1 -P $p -u icadmin '-pIcAdmin#2026' --table -e $sql 2>&1 |
             Where-Object { $_ -notmatch 'Using a password on the command line' }
    [pscustomobject]@{ tag = $tag; ms = [int]((Get-Date) - $t0).TotalMilliseconds; out = ($out -join "`n") }
  } -ArgumentList $bin, $p, $sql, $tag
}

$id = 990001
Q 3307 "DELETE FROM poliklinika.heartbeat WHERE id = $id;"
Start-Sleep -Seconds 1

'### 8a. counters before'
foreach ($p in 3307, 3308) {
  Q $p "SELECT @@port port, COUNT_TRANSACTIONS_CHECKED checked, COUNT_CONFLICTS_DETECTED conflicts
        FROM performance_schema.replication_group_member_stats WHERE MEMBER_ID = @@server_uuid;"
}

"### 8b. both members insert id=$id, both COMMIT at t+5s"
$a = Session 3307 "BEGIN; INSERT INTO poliklinika.heartbeat (id, ts, node) VALUES ($id, NOW(6), 'from-3307'); SELECT SLEEP(5); COMMIT; SELECT 'A committed' AS result;" 'A on 3307'
$b = Session 3308 "BEGIN; INSERT INTO poliklinika.heartbeat (id, ts, node) VALUES ($id, NOW(6), 'from-3308'); SELECT SLEEP(5); COMMIT; SELECT 'B committed' AS result;" 'B on 3308'
Wait-Job $a, $b -Timeout 90 | Out-Null
foreach ($j in $a, $b) { $r = Receive-Job $j; "-- $($r.tag)  [$($r.ms) ms]"; $r.out }
Remove-Job $a, $b -Force

'### 8c. which row survived, on every member'
foreach ($p in 3307, 3308, 3309) { Q $p "SELECT @@port port, id, node FROM poliklinika.heartbeat WHERE id = $id;" }

'### 8d. counters after'
foreach ($p in 3307, 3308, 3309) {
  Q $p "SELECT @@port port, COUNT_TRANSACTIONS_CHECKED checked, COUNT_CONFLICTS_DETECTED conflicts
        FROM performance_schema.replication_group_member_stats WHERE MEMBER_ID = @@server_uuid;"
}
