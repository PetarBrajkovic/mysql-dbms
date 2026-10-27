// 43-clusterset-status.js - who is primary, the clusterset_replication channel, and who accepts a write.
//   mysqlsh --js --no-wizard --file 43-clusterset-status.js   (after 20-clusterset-up.js)
// Writes one probe row on the primary (3307); the other two INSERTs must be refused (ERROR 1290).

function cd(p) { return { host: '127.0.0.1', port: p, user: 'icadmin', password: 'IcAdmin#2026' }; }
shell.connect(cd(3307));
var cs = dba.getClusterSet();
var st = cs.status({extended:1});
println('ClusterSet ' + st.domainName + ': ' + st.status + ' - ' + st.statusText);
Object.keys(st.clusters).forEach(function(k){ var c = st.clusters[k];
  println('  ' + k + ': role=' + c.clusterRole + ' global=' + c.globalStatus + (c.clusterSetReplication ? ' channel=' + c.clusterSetReplication.channelName + ' receiver=' + c.clusterSetReplication.receiverStatus + ' applier=' + c.clusterSetReplication.applierStatus + ' source=' + c.clusterSetReplication.source : '')); });
[3307,3308,3309].forEach(function(p){ var s = mysql.getClassicSession(cd(p));
  var r = s.runSql("SELECT @@port, @@super_read_only").fetchOne();
  var res; try { s.runSql("INSERT INTO poliklinika.heartbeat (ts,node) VALUES (NOW(6),'probe-" + p + "')"); res='ACCEPTED'; } catch(e) { res='REFUSED: ' + e.message; }
  println('  port ' + r[0] + ' super_read_only=' + r[1] + '  INSERT -> ' + res); s.close(); });
var s = mysql.getClassicSession(cd(3309));
println('  3309 channels: ' + JSON.stringify(s.runSql("SELECT CHANNEL_NAME, SERVICE_STATE FROM performance_schema.replication_connection_status").fetchAll()));
