# topology.ps1 - start, stop and inspect the three-instance replication sandbox.
#
#   .\topology.ps1 start          # start all three (3307, 3308, 3309)
#   .\topology.ps1 start  -Node 2 # start just node2
#   .\topology.ps1 stop           # shut all three down cleanly
#   .\topology.ps1 status         # ports, PIDs, replication state
#
# The instances are NOT Windows services (creating one needs Administrator, which this
# account does not have). They are plain background mysqld processes: they die with the
# machine, not with the shell, and must be started again by hand each session.
#
# Port 3306 is another topic's server and is never touched by this script.

param(
  [Parameter(Position = 0)][ValidateSet('start', 'stop', 'status')][string]$Action = 'status',
  [ValidateRange(1, 3)][int]$Node = 0
)

$ErrorActionPreference = 'Stop'
$bin      = 'C:\Program Files\MySQL\MySQL Server 8.4\bin'
$setupDir = $PSScriptRoot
$nodes    = @(
  [pscustomobject]@{ N = 1; Port = 3307 },
  [pscustomobject]@{ N = 2; Port = 3308 },
  [pscustomobject]@{ N = 3; Port = 3309 }
)
if ($Node -ne 0) { $nodes = $nodes | Where-Object { $_.N -eq $Node } }

# Root password for all three sandbox instances. Sandbox-only, never a real secret.
$rootPw = 'Repl#2026root'

function Test-Port([int]$p) {
  $c = Get-NetTCPConnection -State Listen -LocalPort $p -ErrorAction SilentlyContinue
  return [bool]$c
}

switch ($Action) {

  'start' {
    foreach ($n in $nodes) {
      if (Test-Port $n.Port) { Write-Host ("node{0} already listening on {1}" -f $n.N, $n.Port) -ForegroundColor DarkGray; continue }
      $cnf = Join-Path $setupDir ("node{0}.cnf" -f $n.N)
      Start-Process -FilePath (Join-Path $bin 'mysqld.exe') `
                    -ArgumentList "--defaults-file=`"$cnf`"" `
                    -WindowStyle Hidden
      Write-Host ("node{0} starting on {1}..." -f $n.N, $n.Port)
    }
    foreach ($n in $nodes) {
      $ok = $false
      foreach ($try in 1..30) {
        Start-Sleep -Milliseconds 700
        if (Test-Port $n.Port) { $ok = $true; break }
      }
      if ($ok) { Write-Host ("node{0} up on {1}" -f $n.N, $n.Port) -ForegroundColor Green }
      else     { Write-Host ("node{0} did NOT come up - see C:\mysql-repl\node{0}\node{0}.err" -f $n.N) -ForegroundColor Red }
    }
  }

  'stop' {
    foreach ($n in $nodes) {
      if (-not (Test-Port $n.Port)) { Write-Host ("node{0} not running" -f $n.N) -ForegroundColor DarkGray; continue }
      $ErrorActionPreference = 'Continue'   # see the note in 'status' below
      & (Join-Path $bin 'mysqladmin.exe') -h 127.0.0.1 -P $n.Port -u root "-p$rootPw" shutdown 2>&1 | Out-Null
      $ErrorActionPreference = 'Stop'
      # Wait for the PID FILE to disappear, not for the port to close. mysqld closes its
      # listener early in shutdown but keeps ibdata1 open for several more seconds; a start
      # issued in that window dies with "The innodb_system data file 'ibdata1' must be
      # writable". Ticket 10 hit exactly that on the first stop/start cycle.
      $pidFile = "C:\mysql-repl\node{0}\node{0}.pid" -f $n.N
      foreach ($try in 1..60) {
        if (-not (Test-Path $pidFile) -and -not (Test-Port $n.Port)) { break }
        Start-Sleep -Milliseconds 500
      }
      Write-Host ("node{0} shut down (port {1})" -f $n.N, $n.Port)
    }
  }

  'status' {
    foreach ($n in $nodes) {
      if (-not (Test-Port $n.Port)) {
        Write-Host ("node{0}  {1}  DOWN" -f $n.N, $n.Port) -ForegroundColor DarkGray
        continue
      }
      $q = "SELECT @@server_id AS server_id, @@gtid_mode AS gtid, " +
           "(SELECT COUNT(*) FROM performance_schema.replication_connection_status) AS channels, " +
           "@@global.read_only AS read_only;"
      # mysql.exe writes its "password on the command line" warning to stderr, and under
      # $ErrorActionPreference = 'Stop' PowerShell promotes any stderr line from a native
      # command into a terminating NativeCommandError. Dropping to 'Continue' for the call
      # is the fix; filtering the stream afterwards is too late.
      $ErrorActionPreference = 'Continue'
      $out = & (Join-Path $bin 'mysql.exe') -h 127.0.0.1 -P $n.Port -u root "-p$rootPw" -N -B -e $q 2>&1 |
              Where-Object { $_ -notmatch 'Using a password on the command line' } |
              ForEach-Object { $_.ToString() }
      $ErrorActionPreference = 'Stop'
      Write-Host ("node{0}  {1}  UP   {2}" -f $n.N, $n.Port, ($out -join ' ')) -ForegroundColor Green
    }
    if (Test-Port 3306) { Write-Host "3306 (other topic's server) still listening - untouched" -ForegroundColor Cyan }
    else                { Write-Host "3306 NOT listening (it is a Manual-start service; that is normal if nobody started it)" -ForegroundColor Yellow }
  }
}
