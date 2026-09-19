$ErrorActionPreference = 'Continue'
$bin  = 'C:\Program Files\MySQL\MySQL Server 8.4\bin\mysql.exe'
function Q([int]$p, [string]$sql) {
  & $bin -h 127.0.0.1 -P $p -u icadmin '-pIcAdmin#2026' --table -e $sql 2>&1 |
    Where-Object { $_ -notmatch 'Using a password on the command line' }
}
function PidOnPort([int]$p) {
  (Get-NetTCPConnection -State Listen -LocalPort $p -ErrorAction SilentlyContinue | Select-Object -First 1).OwningProcess
}
# Run a statement in a child process with a hard timeout; report whether it returned or hung.
function Timed([int]$port, [string]$sql, [int]$timeoutSec) {
  $sw = [Diagnostics.Stopwatch]::StartNew()
  $out = New-TemporaryFile
  $pr = Start-Process -FilePath $bin -PassThru -NoNewWindow -RedirectStandardOutput $out `
        -ArgumentList @('-h','127.0.0.1','-P',"$port",'-u','icadmin','-pIcAdmin#2026','--connect-timeout=5','-e',"`"$sql`"")
  if ($pr.WaitForExit($timeoutSec * 1000)) {
    "  returned after {0:N0} ms : {1}" -f $sw.Elapsed.TotalMilliseconds, ((Get-Content $out -Raw) -replace '\s+',' ').Trim()
  } else {
    $pr.Kill(); "  STILL BLOCKED after $timeoutSec s (killed the client)"
  }
  Remove-Item $out -Force -ErrorAction SilentlyContinue
}

'### 4a. healthy group of three'
Q 3307 "SELECT MEMBER_PORT, MEMBER_STATE FROM performance_schema.replication_group_members ORDER BY MEMBER_PORT;"

'### 4b. killing 3308 and 3309 outright (no clean shutdown, so no graceful leave)'
foreach ($p in 3308, 3309) {
  $procId = PidOnPort $p
  "  port $p -> pid $procId : Stop-Process -Force"
  Stop-Process -Id $procId -Force
}
Start-Sleep -Seconds 5

'### 4c. what the survivor sees (t+5s)'
Q 3307 "SELECT MEMBER_PORT, MEMBER_STATE FROM performance_schema.replication_group_members ORDER BY MEMBER_PORT;"
Start-Sleep -Seconds 20
'### 4d. what the survivor sees (t+25s, after the failure detector has given up)'
Q 3307 "SELECT MEMBER_PORT, MEMBER_STATE FROM performance_schema.replication_group_members ORDER BY MEMBER_PORT;"
Q 3307 "SELECT VARIABLE_NAME, VARIABLE_VALUE FROM performance_schema.global_status
        WHERE VARIABLE_NAME IN ('group_replication_primary_member');
        SELECT @@group_replication_unreachable_majority_timeout unreach_timeout,
               @@group_replication_exit_state_action exit_action;"

'### 4e. can the survivor still READ?'
Timed 3307 "SELECT COUNT(*) AS patients FROM poliklinika.patients;" 20

'### 4f. can the survivor still WRITE?'
Timed 3307 "INSERT INTO poliklinika.heartbeat (ts, node) VALUES (NOW(6), 'no-quorum');" 30

'### 4g. the write is still pending - is it visible to anyone?'
Timed 3307 "SELECT COUNT(*) AS seen FROM poliklinika.heartbeat WHERE node='no-quorum';" 20
