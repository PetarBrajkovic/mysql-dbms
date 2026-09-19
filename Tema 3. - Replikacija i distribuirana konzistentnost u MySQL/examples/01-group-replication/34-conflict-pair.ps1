# Certification conflict, run as a pair (ticket 08): same row -> one rolls back;
# different rows -> both commit. Multi-primary mode, writes on 3307 and 3308 at once.
$ErrorActionPreference = 'Continue'
$bin = 'C:\Program Files\MySQL\MySQL Server 8.4\bin\mysql.exe'
function Q([int]$p, [string]$sql) {
  & $bin -h 127.0.0.1 -P $p -u icadmin '-pIcAdmin#2026' --table -e $sql 2>&1 |
    Where-Object { $_ -notmatch 'Using a password on the command line' }
}
# Fire a multi-statement session in the background and return the job.
function Session([int]$p, [string]$sql, [string]$tag) {
  Start-Job -ScriptBlock {
    param($bin, $p, $sql, $tag)
    $t0 = Get-Date
    $out = & $bin -h 127.0.0.1 -P $p -u icadmin '-pIcAdmin#2026' --table -e $sql 2>&1 |
             Where-Object { $_ -notmatch 'Using a password on the command line' }
    [pscustomobject]@{ tag = $tag; port = $p; ms = [int]((Get-Date) - $t0).TotalMilliseconds; out = ($out -join "`n") }
  } -ArgumentList $bin, $p, $sql, $tag
}

'### 6a. mode and per-member writability'
foreach ($p in 3307, 3308, 3309) {
  Q $p "SELECT @@port port, @@super_read_only sro,
        (SELECT MEMBER_ROLE FROM performance_schema.replication_group_members WHERE MEMBER_PORT=@@port) role,
        @@group_replication_single_primary_mode single_primary;"
}

'### 6b. the row both sessions will fight over'
Q 3307 "SELECT invoice_id, amount, paid_status FROM poliklinika.invoices WHERE invoice_id IN (1,2);"

'### 6c. SAME row on two primaries - A opens first, B commits first'
$a = Session 3307 "BEGIN; UPDATE poliklinika.invoices SET amount = amount + 100 WHERE invoice_id = 1; SELECT SLEEP(6); COMMIT; SELECT 'A COMMIT returned' AS a;" 'A(3307) same row'
Start-Sleep -Seconds 2
$b = Session 3308 "BEGIN; UPDATE poliklinika.invoices SET amount = amount + 999 WHERE invoice_id = 1; COMMIT; SELECT 'B COMMIT returned' AS b;" 'B(3308) same row'
Wait-Job $a, $b -Timeout 60 | Out-Null
foreach ($j in $a, $b) { $r = Receive-Job $j; "-- $($r.tag)  [$($r.ms) ms]"; $r.out }
Remove-Job $a, $b -Force

'### 6d. what the row actually holds now, on all three members'
foreach ($p in 3307, 3308, 3309) { Q $p "SELECT @@port port, invoice_id, amount FROM poliklinika.invoices WHERE invoice_id = 1;" }

'### 6e. DIFFERENT rows on two primaries - same timing, same tables'
$a = Session 3307 "BEGIN; UPDATE poliklinika.invoices SET amount = amount + 100 WHERE invoice_id = 1; SELECT SLEEP(6); COMMIT; SELECT 'A COMMIT returned' AS a;" 'A(3307) row 1'
Start-Sleep -Seconds 2
$b = Session 3308 "BEGIN; UPDATE poliklinika.invoices SET amount = amount + 999 WHERE invoice_id = 2; COMMIT; SELECT 'B COMMIT returned' AS b;" 'B(3308) row 2'
Wait-Job $a, $b -Timeout 60 | Out-Null
foreach ($j in $a, $b) { $r = Receive-Job $j; "-- $($r.tag)  [$($r.ms) ms]"; $r.out }
Remove-Job $a, $b -Force

'### 6f. both rows, on all three members'
foreach ($p in 3307, 3308, 3309) { Q $p "SELECT @@port port, invoice_id, amount FROM poliklinika.invoices WHERE invoice_id IN (1,2);" }

'### 6g. the counter that proves certification did the rejecting'
foreach ($p in 3307, 3308) {
  Q $p "SELECT @@port port, COUNT_TRANSACTIONS_ROWS_VALIDATING rows_validating,
        COUNT_CONFLICTS_DETECTED conflicts, COUNT_TRANSACTIONS_CHECKED checked
        FROM performance_schema.replication_group_member_stats WHERE MEMBER_ID = @@server_uuid;"
}
