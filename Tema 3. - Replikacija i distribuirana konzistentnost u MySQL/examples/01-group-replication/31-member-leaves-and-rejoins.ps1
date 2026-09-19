$ErrorActionPreference = 'Continue'
$bin  = 'C:\Program Files\MySQL\MySQL Server 8.4\bin\mysql.exe'
$topo = 'C:\Faks\Sistemi Baza\Tema 3. - Replikacija i distribuirana konzistentnost u MySQL\examples\00-setup\topology.ps1'
function Q([int]$p, [string]$sql) {
  & $bin -h 127.0.0.1 -P $p -u icadmin '-pIcAdmin#2026' --table -e $sql 2>&1 |
    Where-Object { $_ -notmatch 'Using a password on the command line' }
}
function Members([int]$p) { Q $p "SELECT MEMBER_PORT, MEMBER_STATE, MEMBER_ROLE FROM performance_schema.replication_group_members ORDER BY MEMBER_PORT;" }

'### 3a. before: group of three'
Members 3307
"`n### 3b. node3 (3309) shut down cleanly"
& powershell -NoProfile -ExecutionPolicy Bypass -File $topo stop -Node 3
Start-Sleep -Seconds 3
Members 3307

"`n### 3c. the group keeps writing while a member is gone"
Q 3307 "INSERT INTO poliklinika.heartbeat (ts, node) VALUES (NOW(6), 'while-3309-down');
        SELECT COUNT(*) rows_while_down FROM poliklinika.heartbeat WHERE node='while-3309-down';"

"`n### 3d. node3 started again - does it rejoin by itself?"
& powershell -NoProfile -ExecutionPolicy Bypass -File $topo start -Node 3
foreach ($i in 1..20) {
  Start-Sleep -Seconds 2
  $s = & $bin -h 127.0.0.1 -P 3309 -u icadmin '-pIcAdmin#2026' -N -B -e "SELECT MEMBER_STATE FROM performance_schema.replication_group_members WHERE MEMBER_PORT=3309;" 2>$null
  "t+$($i*2)s : 3309 state = '$s'"
  if ($s -eq 'ONLINE') { break }
}
Q 3309 "SELECT @@group_replication_start_on_boot start_on_boot;"
Members 3307

"`n### 3e. did the rejoined member catch up on what it missed?"
Q 3309 "SELECT COUNT(*) caught_up FROM poliklinika.heartbeat WHERE node='while-3309-down';"
