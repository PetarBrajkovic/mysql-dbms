$ErrorActionPreference = 'Continue'
$bin = 'C:\Program Files\MySQL\MySQL Server 8.4\bin\mysql.exe'
function Q([int]$p, [string]$sql) {
  & $bin -h 127.0.0.1 -P $p -u icadmin '-pIcAdmin#2026' --table -e $sql 2>&1 |
    Where-Object { $_ -notmatch 'Using a password on the command line' }
}

'### 2a. member roles as each member itself reports them'
foreach ($p in 3307, 3308, 3309) {
  "-- $p"
  Q $p "SELECT @@port port, @@read_only ro, @@super_read_only sro,
        (SELECT MEMBER_ROLE FROM performance_schema.replication_group_members WHERE MEMBER_PORT=@@port) role,
        (SELECT MEMBER_STATE FROM performance_schema.replication_group_members WHERE MEMBER_PORT=@@port) state;"
}

'### 2b. write on the primary'
Q 3307 "INSERT INTO poliklinika.heartbeat (ts, node) VALUES (NOW(6), 'gr-sp-test');
        SELECT LAST_INSERT_ID() id;"

'### 2c. the same row read on all three members'
foreach ($p in 3307, 3308, 3309) {
  "-- $p"
  Q $p "SELECT @@port port, id, node, ts FROM poliklinika.heartbeat WHERE node='gr-sp-test';"
}

'### 2d. the same write attempted on a secondary'
Q 3308 "INSERT INTO poliklinika.heartbeat (ts, node) VALUES (NOW(6), 'sec-write');"

'### 2e. group membership as seen from every member (identical view = agreement)'
foreach ($p in 3307, 3308, 3309) {
  "-- seen from $p"
  Q $p "SELECT MEMBER_HOST, MEMBER_PORT, MEMBER_STATE, MEMBER_ROLE, MEMBER_VERSION
        FROM performance_schema.replication_group_members ORDER BY MEMBER_PORT;"
}
