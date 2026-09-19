function cd(p) { return { host: '127.0.0.1', port: p, user: 'icadmin', password: 'IcAdmin#2026' }; }
function sess(p) { return mysql.getClassicSession(cd(p)); }
function show(tag) {
  [3307, 3308, 3309].forEach(function (p) {
    var s = sess(p);
    var r = s.runSql("SELECT @@port, @@read_only, @@super_read_only, @@offline_mode").fetchOne();
    println('   ' + tag + '  port=' + r[0] + ' read_only=' + r[1] + ' super_read_only=' + r[2] + ' offline_mode=' + r[3]);
    s.close();
  });
}

println('=== 15a. roles now');
show('');

println('=== 15b. write to the REPLICA cluster (3309)');
var s = sess(3309);
try { s.runSql("INSERT INTO poliklinika.heartbeat (ts, node) VALUES (NOW(6), 'to-replica')"); println('   ACCEPTED - unexpected'); }
catch (e) { println('   REFUSED: ' + e.message); }
try { println('   read works: patients = ' + s.runSql("SELECT COUNT(*) FROM poliklinika.patients").fetchOne()[0]); }
catch (e) { println('   read ERROR: ' + e.message); }
s.close();

println('=== 15c. controlled switchover: drCluster becomes the primary cluster');
shell.connect(cd(3307));
var cs = dba.getClusterSet();
var t0 = Date.now();
try { cs.setPrimaryCluster('drCluster'); println('   switchover took ' + (Date.now() - t0) + ' ms'); }
catch (e) { println('   ERROR: ' + e.message); }
show('after');

println('=== 15d. who accepts a write now');
[3307, 3309].forEach(function (p) {
  var x = sess(p);
  try { x.runSql("INSERT INTO poliklinika.heartbeat (ts, node) VALUES (NOW(6), 'sw-" + p + "')"); println('   ' + p + ': ACCEPTED'); }
  catch (e) { println('   ' + p + ': REFUSED - ' + e.message); }
  x.close();
});

println('=== 15e. switch back');
t0 = Date.now();
try { cs.setPrimaryCluster('poliklinikaCluster'); println('   switchback took ' + (Date.now() - t0) + ' ms'); }
catch (e) { println('   ERROR: ' + e.message); }
show('back');
var st = cs.status();
println('   primaryCluster = ' + st.primaryCluster + ' ; ' + st.statusText);
