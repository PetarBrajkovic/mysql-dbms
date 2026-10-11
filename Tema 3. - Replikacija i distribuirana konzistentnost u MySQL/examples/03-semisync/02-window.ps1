# Feeds: lesson 0004, ch. 4 (Slika 4.x, visibility window) | Nodes: node1 (3307), node2 (3308), node3 (3309) | State: semisync
# The AFTER_SYNC vs AFTER_COMMIT visibility window, made deterministic: both receivers are
# stopped, so the acknowledgement CANNOT arrive and the writer's COMMIT sits in the wait for the
# full timeout. Session B polls the source the whole time. The window is staged - a withheld
# acknowledgement, not natural network delay - and every caption must say so.
# Usage: .\02-window.ps1 -WaitPoint AFTER_COMMIT -Id 1001 [-TimeoutMs 3000]
param([ValidateSet('AFTER_SYNC', 'AFTER_COMMIT')][string]$WaitPoint = 'AFTER_SYNC',
      [int]$Id = 1001, [int]$TimeoutMs = 3000)
. "$PSScriptRoot\_common.ps1"

if (-not (WaitSemiOn 2 5)) { '!!! semisync is not ON with 2 clients - run 01-semisync-on.ps1'; exit 1 }
Q 3307 "DELETE FROM poliklinika.semisync_demo WHERE id = $Id;
        SET GLOBAL rpl_semi_sync_source_wait_point = '$WaitPoint';
        SET GLOBAL rpl_semi_sync_source_timeout = $TimeoutMs" | Out-Null
Start-Sleep -Milliseconds 500                              # let the DELETE reach both replicas
foreach ($p in 3308, 3309) { Q $p "STOP REPLICA IO_THREAD" | Out-Null }   # withhold the ack
"--- wait_point=$WaitPoint timeout=${TimeoutMs}ms, receivers on 3308/3309 STOPPED"
SemiStatus

$tmp = $env:TEMP
$rOut = "$tmp\semi-reader.json"; $wOut = "$tmp\semi-writer.json"
Remove-Item $rOut, $wOut -ErrorAction SilentlyContinue
$dur = $TimeoutMs + 2000
$reader = Start-Process $mysqlsh -ArgumentList '--js', '--file', "`"$PSScriptRoot\02-reader.js`"", $Id, $dur `
            -NoNewWindow -PassThru -RedirectStandardOutput $rOut
Start-Sleep -Milliseconds 800                              # reader connected and polling
$writer = Start-Process $mysqlsh -ArgumentList '--js', '--file', "`"$PSScriptRoot\02-writer.js`"", $Id, "window-$WaitPoint" `
            -NoNewWindow -PassThru -RedirectStandardOutput $wOut
$writer.WaitForExit(); $reader.WaitForExit()

$w = Get-Content $wOut | Where-Object { $_ -match '^\{' } | ConvertFrom-Json
$r = Get-Content $rOut | Where-Object { $_ -match '^\{' } | ConvertFrom-Json
"--- timeline (ms, relative to the writer sending COMMIT)"
[pscustomobject]@{
  wait_point          = $WaitPoint
  writer_result       = $w.result
  writer_commit_ms    = $w.ms
  B_first_sees_row_ms = if ($r.first_seen) { $r.first_seen - $w.t_start } else { 'never' }
  window_ms           = if ($r.first_seen) { $w.t_end - $r.first_seen } else { 0 }
  reader_poll_ms      = $r.poll_ms
} | Format-List
"--- writer connection states seen by B (ms after COMMIT sent)"
$r.writer_states_first_seen.PSObject.Properties | ForEach-Object { "  {0,-45} {1,6}" -f $_.Name, ($_.Value - $w.t_start) }
"--- source counters right after the commit returned"
SemiStatus
"--- is the row on the replicas? (receivers still stopped)"
foreach ($p in 3308, 3309) { "  $p : " + (Q $p "SELECT COUNT(*) FROM poliklinika.semisync_demo WHERE id = $Id" -Raw) }

# Restore: receivers back, wait for semisync to switch itself ON again.
foreach ($p in 3308, 3309) { Q $p "START REPLICA IO_THREAD" | Out-Null }
if (WaitSemiOn 2) { '--- receivers restarted; semisync back ON by itself' } else { '!!! semisync did not return ON' }
SemiStatus
