# Feeds: Slika 7.1 (the paper's ONE natural-lag figure), lesson 0007 | Nodes: node1 (3307) -> node3 (3309) | State: async
#
#   cd examples\04-read-scaling
#   .\10-lag-burst.ps1
#
# Natural lag, no SOURCE_DELAY: node3's applier is pinned to ONE worker, eight sessions on node1
# fire single-row INSERTs into poliklinika.visits at once, and 11-lag-sampler.js samples node3
# every 250 ms. The source commits the burst in parallel (group commit); one worker on the replica
# has to replay it serially - so the lag is produced by the applier, not by the receiver.
#
# Output: ..\..\figures\raw\07-skaliranje-01-kasnjenje.csv (gitignored, regenerated).
# Restores node3 to its previous replica_parallel_workers and deletes the burst rows at the end
# (the delete replicates as ordinary transactions), so the seed data is unchanged afterwards.
# Harness: PowerShell orchestrates (coarse), the sampler is mysqlsh with held sessions.

param([int]$Sessions = 8, [int]$RowsPerSession = 1000, [int]$MaxSeconds = 150)
$ErrorActionPreference = 'Stop'

$bin    = 'C:\Program Files\MySQL\MySQL Server 8.4\bin\mysql.exe'
$shell  = 'C:\mysql-repl\tools\mysql-shell-8.4.10-windows-x86-64bit\bin\mysqlsh.exe'
$pw     = 'Repl#2026root'   # sandbox-only root password, same as topology.ps1
$here   = $PSScriptRoot
$csv    = Join-Path $here '..\..\figures\raw\07-skaliranje-01-kasnjenje.csv'

function Q([int]$port, [string]$sql) {
  $ErrorActionPreference = 'Continue'
  $out = & $bin -h 127.0.0.1 -P $port -u root "-p$pw" -N -B -e $sql 2>&1 |
         Where-Object { $_ -notmatch 'Using a password on the command line' }
  if ($LASTEXITCODE -ne 0) { throw "mysql $port failed: $out" }
  return $out
}

# --- state check ------------------------------------------------------------------------------
$st = Q 3309 "SELECT (SELECT SERVICE_STATE FROM performance_schema.replication_connection_status WHERE CHANNEL_NAME=''), (SELECT DESIRED_DELAY FROM performance_schema.replication_applier_configuration WHERE CHANNEL_NAME='')"
$f = "$st" -split "`t"
if ($f[0] -ne 'ON') { throw "Need State: async, node3 channel ON (got '$st'). Run examples\00-setup\topology.ps1 start (and 19-gr-down.ps1 if a group is up)." }
if ($f[1] -ne '0')  { throw "node3 has SOURCE_DELAY=$($f[1]); this figure must show NATURAL lag. Run 29-restore.ps1 first." }
$workers = (Q 3309 "SELECT @@global.replica_parallel_workers")
Write-Host "state check OK: async, node3 channel ON, SOURCE_DELAY 0, workers=$workers"

try {
# --- pin node3 to one applier worker ------------------------------------------------------------
Q 3309 "STOP REPLICA SQL_THREAD; SET GLOBAL replica_parallel_workers = 1; START REPLICA SQL_THREAD" | Out-Null
Write-Host "node3 applier pinned to 1 worker"

# --- burst procedure on node1 (replicates; never created on a replica) ------------------------
Q 3307 "DROP PROCEDURE IF EXISTS poliklinika.ch7_burst" | Out-Null
# mysql -e splits on ';', so the body is sent under a different client delimiter.
Q 3307 "DELIMITER //`nCREATE PROCEDURE poliklinika.ch7_burst(IN n INT) BEGIN DECLARE i INT DEFAULT 0; WHILE i < n DO INSERT INTO poliklinika.visits (patient_id, tenant_id, staff_id, visit_date, chief_complaint) VALUES (1, 1, 1, CURDATE(), 'ch7-burst'); SET i = i + 1; END WHILE; END//" | Out-Null

# --- sampler in the background, baseline, then the burst ---------------------------------------
$tmpOut = [IO.Path]::GetTempFileName()
$sampler = Start-Process -FilePath $shell -PassThru -NoNewWindow -RedirectStandardOutput $tmpOut `
  -ArgumentList @('--js', '--no-wizard', '--file', ('"' + (Join-Path $here '11-lag-sampler.js') + '"'), "$MaxSeconds")
Start-Sleep -Seconds 4

$burstStart = Get-Date
$procs = 1..$Sessions | ForEach-Object {
  Start-Process -FilePath $bin -PassThru -NoNewWindow -RedirectStandardError ([IO.Path]::GetTempFileName()) `
    -ArgumentList @('-h', '127.0.0.1', '-P', '3307', '-u', 'root', "-p$pw", '-e', "`"CALL poliklinika.ch7_burst($RowsPerSession)`"")
}
$procs | Wait-Process
$burstMs = [int]((Get-Date) - $burstStart).TotalMilliseconds
Write-Host "burst committed on node1: $($Sessions * $RowsPerSession) transactions in $burstMs ms"

$sampler | Wait-Process
$raw = Get-Content $tmpOut
$b = [array]::IndexOf($raw, '---CSV-BEGIN---'); $e = [array]::IndexOf($raw, '---CSV-END---')
if ($b -lt 0 -or $e -lt 0) { throw "sampler produced no CSV: $raw" }
New-Item -ItemType Directory -Force -Path (Split-Path $csv) | Out-Null
$raw[($b + 1)..($e - 1)] | Where-Object { $_ -ne '' } | Set-Content -Encoding ascii $csv
$raw | Select-Object -Skip ($e + 1) | Write-Host
Write-Host "CSV -> $csv"

} finally {
# --- restore (always, even if the run failed halfway) ------------------------------------------
Q 3309 "STOP REPLICA SQL_THREAD; SET GLOBAL replica_parallel_workers = $workers; START REPLICA SQL_THREAD" | Out-Null
Q 3307 "DELETE FROM poliklinika.visits WHERE chief_complaint = 'ch7-burst'; DELETE FROM poliklinika.heartbeat WHERE node = 'ch7-ticker'; DROP PROCEDURE IF EXISTS poliklinika.ch7_burst" | Out-Null
Start-Sleep -Seconds 3
Write-Host ("restored: node3 workers=" + (Q 3309 "SELECT @@global.replica_parallel_workers") +
            ", visits on node1/node3 = " + (Q 3307 "SELECT COUNT(*) FROM poliklinika.visits") + "/" +
            (Q 3309 "SELECT COUNT(*) FROM poliklinika.visits"))
}
