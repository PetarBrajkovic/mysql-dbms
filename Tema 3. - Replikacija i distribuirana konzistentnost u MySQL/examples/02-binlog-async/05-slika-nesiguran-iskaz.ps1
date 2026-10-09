# Feeds: Slika 3.2 | Nodes: node1 (3307) -> node2 (3308), node3 (3309) | State: async
#
# Chapter 3 - the same unsafe UPDATE ... LIMIT under the two binary log formats.
#   (a) STATEMENT, inside a rolled-back transaction: the server warns (Note 1592) and nothing is logged.
#   (b) ROW, committed: the binary log records WHICH rows changed (before and after image), so the
#       replica never has to choose them. Decoded with mysqlbinlog -v.
# The ROW update is replicated and then reverted by a second, also replicated, UPDATE on the same
# primary keys, so poliklinika ends exactly as it started on all three nodes.
#
# Run from the topic folder:  .\examples\02-binlog-async\05-slika-nesiguran-iskaz.ps1
# Writes figures\raw\03-binlog-01-nesiguran-iskaz.txt and renders the PNG beside it in figures\.

$ErrorActionPreference = 'Stop'
$bin   = 'C:\Program Files\MySQL\MySQL Server 8.4\bin'
$mysql = Join-Path $bin 'mysql.exe'
$mbl   = Join-Path $bin 'mysqlbinlog.exe'
# sandbox-only root password, same as topology.ps1; passed through a temp option file so the
# clients print no password warning on stderr (which would trip ErrorActionPreference = Stop)
$cnf = Join-Path $env:TEMP 'tema3-root.cnf'
Set-Content -Path $cnf -Encoding ASCII -Value "[client]`nuser=root`npassword=`"Repl#2026root`"`nhost=127.0.0.1"
function Q([int]$port, [string]$sql) {
    $out = & $mysql "--defaults-extra-file=$cnf" -P $port -N -B -e $sql
    if ($LASTEXITCODE -ne 0) { throw "mysql on ${port} failed: $out" }
    return $out
}

# ---- 0. State check: plain asynchronous replication, node1 the source of both replicas ----------
$inGroup = Q 3307 "SELECT COUNT(*) FROM performance_schema.replication_group_members WHERE MEMBER_STATE='ONLINE'"
if ([int]$inGroup -gt 0) { throw "Sandbox is in the cluster state. Run examples\01-group-replication\19-gr-down.ps1 first." }
foreach ($p in 3308, 3309) {
    $st = Q $p "SELECT CONCAT(c.SERVICE_STATE,'/',a.SERVICE_STATE) FROM performance_schema.replication_connection_status c JOIN performance_schema.replication_applier_status a USING (CHANNEL_NAME) WHERE CHANNEL_NAME=''"
    if ($st -ne 'ON/ON') { throw "Replica on $p is not replicating (receiver/applier = '$st'). Start the topology: examples\00-setup\topology.ps1 start" }
}

# ---- (a) STATEMENT: warning, rolled back ---------------------------------------------------------
$stmt = "UPDATE invoices SET paid_status = 'paid' WHERE tenant_id = 1 AND paid_status = 'unpaid' LIMIT 2"
$warn = Q 3307 "USE poliklinika; SET SESSION binlog_format='STATEMENT'; START TRANSACTION; $stmt; SHOW WARNINGS; ROLLBACK;"
if (-not ($warn -match '1592')) { throw "Expected Note 1592 under STATEMENT, got: $warn" }
$warnLine = ($warn | Select-Object -First 1) -replace "`t", ' '
# wrap the long server message at sentence boundaries so the figure stays narrow
$warnLines = ($warnLine -replace '\. ', ".`n" -replace ' since BINLOG_FORMAT', "`n  since BINLOG_FORMAT") -split "`n"

# ---- (b) ROW: commit, decode the event, revert ---------------------------------------------------
$pos  = Q 3307 "SHOW BINARY LOG STATUS"
$file = ($pos -split "`t")[0]; $start = ($pos -split "`t")[1]
$ids = Q 3307 ("USE poliklinika; SET @b := (SELECT GROUP_CONCAT(invoice_id) FROM invoices WHERE tenant_id=1 AND paid_status='unpaid'); " +
               "$stmt; SELECT GROUP_CONCAT(invoice_id ORDER BY invoice_id) FROM invoices WHERE FIND_IN_SET(invoice_id, @b) AND paid_status='paid';")
if (-not $ids) { throw "ROW update changed no rows (no unpaid invoices left for tenant 1?)" }
$gtid = Q 3307 "SELECT @@GLOBAL.gtid_executed"   # only for the console, not the figure

$decoded = & $mbl "--defaults-extra-file=$cnf" --read-from-remote-server -P 3307 `
    --start-position=$start --base64-output=DECODE-ROWS -v $file
$rows = $decoded | Where-Object { $_ -match '^### ' } | ForEach-Object { $_ -replace '^### ', '' }
if (-not ($rows -match 'UPDATE `poliklinika`.`invoices`')) { throw "No decoded Update_rows event for invoices found after position $start in $file" }
# Compact layout for the figure: one line per row image ("WHERE @1=.. @2=..", "SET @1=.. ..").
# Only whitespace changes; every token mysqlbinlog printed is kept, in order.
$compact = @(); $cur = $null
foreach ($r in $rows) {
    if ($r -match '^(UPDATE|WHERE|SET)') { if ($cur) { $compact += $cur }; $cur = $r.Trim() }
    else { $cur += ' ' + $r.Trim() }
}
if ($cur) { $compact += $cur }
$compact = $compact | ForEach-Object { if ($_ -match '^(WHERE|SET)') { '  ' + $_ } else { $_ } }

# revert on the same primary keys (replicated as well)
Q 3307 "UPDATE poliklinika.invoices SET paid_status='unpaid' WHERE invoice_id IN ($ids)" | Out-Null

# ---- the figure text -----------------------------------------------------------------------------
$lines = @(
    "-- isti iskaz, dva formata binarnog loga (izvor 3307, MySQL 8.4.11)",
    "UPDATE invoices SET paid_status = 'paid'",
    "  WHERE tenant_id = 1 AND paid_status = 'unpaid' LIMIT 2;",
    "",
    "-- (a) binlog_format = STATEMENT: server upozorava,",
    "--     a u log bi se upisao sam iskaz",
    $warnLines,
    "",
    "-- (b) binlog_format = ROW: u log se upisuju izmenjeni redovi,",
    "--     pre (WHERE) i posle (SET) izmene; mysqlbinlog -v, kolone:",
    "--     @1 invoice_id, @2 patient_id, @3 tenant_id, @4 amount,",
    "--     @5 paid_status (ENUM po indeksu: 1 = 'unpaid', 2 = 'paid')"
) + $compact
$lines = $lines | ForEach-Object { $_ }   # flatten the nested warning array
$rawDir = 'figures\raw'; New-Item -ItemType Directory -Force $rawDir | Out-Null
$rawFile = Join-Path $rawDir '03-binlog-01-nesiguran-iskaz.txt'
[System.IO.File]::WriteAllLines((Join-Path (Get-Location) $rawFile), [string[]]$lines)   # UTF-8, no BOM

& (Join-Path $PSScriptRoot '..\..\..\tools\make-table-figure.ps1') -Raw -RawFile $rawFile -OutBase 'figures\03-binlog-01-nesiguran-iskaz'

# ---- verify the revert reached every node --------------------------------------------------------
Start-Sleep -Seconds 2
foreach ($p in 3307, 3308, 3309) {
    $n = Q $p "SELECT COUNT(*) FROM poliklinika.invoices WHERE invoice_id IN ($ids) AND paid_status='unpaid'"
    $want = ($ids -split ',').Count
    if ([int]$n -ne $want) { throw "Revert not visible on ${p}: $n of $want rows back to unpaid" }
}
Remove-Item $cnf
Write-Host "OK  rows $ids changed and reverted on 3307/3308/3309; figure figures\03-binlog-01-nesiguran-iskaz.png"
