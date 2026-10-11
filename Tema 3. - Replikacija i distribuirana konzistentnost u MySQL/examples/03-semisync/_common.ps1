# _common.ps1 - shared helpers for examples/03-semisync. Dot-source it: . "$PSScriptRoot\_common.ps1"
# Sandbox-only credentials (the same root password topology.ps1 uses), never a real secret.
$ErrorActionPreference = 'Continue'
$mysql   = 'C:\Program Files\MySQL\MySQL Server 8.4\bin\mysql.exe'
$mysqlsh = 'C:\mysql-repl\tools\mysql-shell-8.4.10-windows-x86-64bit\bin\mysqlsh.exe'
$rootPw  = 'Repl#2026root'
$replPw  = 'Repl#2026repl'

# Run SQL on one node; table output; drop the password warning.
function Q([int]$p, [string]$sql, [switch]$Raw) {
  [string[]]$fmt = if ($Raw) { '-N', '-B' } else { '--table' }
  & $mysql -h 127.0.0.1 -P $p -u root "-p$rootPw" @fmt -e $sql 2>&1 |
    Where-Object { $_ -notmatch 'Using a password on the command line' }
}

# Semisync status counters on the source that an operator would watch.
function SemiStatus([int]$p = 3307) {
  Q $p "SELECT VARIABLE_NAME, VARIABLE_VALUE FROM performance_schema.global_status
        WHERE VARIABLE_NAME IN ('Rpl_semi_sync_source_status','Rpl_semi_sync_source_clients',
          'Rpl_semi_sync_source_yes_tx','Rpl_semi_sync_source_no_tx','Rpl_semi_sync_source_no_times',
          'Rpl_semi_sync_source_wait_sessions') ORDER BY VARIABLE_NAME"
}

# Wait until the source reports semisync ON with the expected number of clients.
function WaitSemiOn([int]$clients = 2, [int]$maxS = 30) {
  foreach ($i in 1..($maxS * 2)) {
    $st = Q 3307 "SELECT VARIABLE_VALUE FROM performance_schema.global_status WHERE VARIABLE_NAME='Rpl_semi_sync_source_status'" -Raw
    $cl = Q 3307 "SELECT VARIABLE_VALUE FROM performance_schema.global_status WHERE VARIABLE_NAME='Rpl_semi_sync_source_clients'" -Raw
    if ("$st" -eq 'ON' -and [int]"$cl" -ge $clients) { return $true }
    Start-Sleep -Milliseconds 500
  }
  return $false
}

function NodePid([int]$n) { [int](Get-Content ("C:\mysql-repl\node{0}\node{0}.pid" -f $n)) }
