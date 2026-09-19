$ErrorActionPreference = 'Continue'
$sh   = 'C:\mysql-repl\tools\mysql-shell-8.4.10-windows-x86-64bit\bin\mysqlsh.exe'
$bin  = 'C:\Program Files\MySQL\MySQL Server 8.4\bin\mysql.exe'
$topo = Join-Path (Split-Path $PSScriptRoot -Parent) '00-setup\topology.ps1'
$js   = $PSScriptRoot
function PidOnPort([int]$p) { (Get-NetTCPConnection -State Listen -LocalPort $p -ErrorAction SilentlyContinue | Select-Object -First 1).OwningProcess }

'### 16a. the whole PRIMARY cluster dies - 3307 and 3308 killed, no clean shutdown'
foreach ($p in 3307, 3308) { $id = PidOnPort $p; "  port $p -> pid $id killed"; Stop-Process -Id $id -Force }
Start-Sleep -Seconds 20

'### 16b. the surviving DR cluster before any operator action'
@'
var cd = { host: '127.0.0.1', port: 3309, user: 'icadmin', password: 'IcAdmin#2026' };
shell.connect(cd);
var s = mysql.getClassicSession(cd);
println('   3309 super_read_only = ' + s.runSql('SELECT @@super_read_only').fetchOne()[0]);
try { s.runSql("INSERT INTO poliklinika.heartbeat (ts,node) VALUES (NOW(6),'dr-before')"); println('   write ACCEPTED'); }
catch (e) { println('   write REFUSED: ' + e.message); }
var cs = dba.getClusterSet();
try { var st = cs.status(); println('   clusterset status = ' + st.status + ' : ' + st.statusText); }
catch (e) { println('   status ERROR: ' + e.message); }
'@ | Set-Content "$PSScriptRoot\.tmp-f1.js" -Encoding UTF8
& $sh --js --file "$PSScriptRoot\.tmp-f1.js" 2>&1 | Where-Object { $_ -notmatch '^\s*$' }

'### 16c. emergency failover - forcePrimaryCluster(drCluster)'
@'
var cd = { host: '127.0.0.1', port: 3309, user: 'icadmin', password: 'IcAdmin#2026' };
shell.connect(cd);
var cs = dba.getClusterSet();
var t0 = Date.now();
try { cs.forcePrimaryCluster('drCluster'); println('   failover took ' + (Date.now() - t0) + ' ms'); }
catch (e) { println('   ERROR: ' + e.message); }
var s = mysql.getClassicSession(cd);
println('   3309 super_read_only = ' + s.runSql('SELECT @@super_read_only').fetchOne()[0]);
try { s.runSql("INSERT INTO poliklinika.heartbeat (ts,node) VALUES (NOW(6),'dr-after')"); println('   write ACCEPTED'); }
catch (e) { println('   write REFUSED: ' + e.message); }
try { var st = cs.status(); println('   clusterset status = ' + st.status + ' : ' + st.statusText);
      Object.keys(st.clusters).forEach(function(k){ println('     ' + k + ' : role=' + st.clusters[k].clusterRole + ' global=' + st.clusters[k].globalStatus); }); }
catch (e) { println('   status ERROR: ' + e.message); }
'@ | Set-Content "$PSScriptRoot\.tmp-f2.js" -Encoding UTF8
& $sh --js --file "$PSScriptRoot\.tmp-f2.js" 2>&1 | Where-Object { $_ -notmatch '^\s*$' }

'### 16d. the dead datacentre comes back'
& powershell -NoProfile -ExecutionPolicy Bypass -File $topo start -Node 1 | Out-Null
& powershell -NoProfile -ExecutionPolicy Bypass -File $topo start -Node 2 | Out-Null
Start-Sleep -Seconds 20
@'
var cd = { host: '127.0.0.1', port: 3309, user: 'icadmin', password: 'IcAdmin#2026' };
shell.connect(cd);
var cs = dba.getClusterSet();
var st = cs.status();
println('   on return: ' + st.status + ' : ' + st.statusText);
Object.keys(st.clusters).forEach(function(k){ println('     ' + k + ' : role=' + st.clusters[k].clusterRole + ' global=' + st.clusters[k].globalStatus + ' status=' + st.clusters[k].status); });
'@ | Set-Content "$PSScriptRoot\.tmp-f3.js" -Encoding UTF8
& $sh --js --file "$PSScriptRoot\.tmp-f3.js" 2>&1 | Where-Object { $_ -notmatch '^\s*$' }
