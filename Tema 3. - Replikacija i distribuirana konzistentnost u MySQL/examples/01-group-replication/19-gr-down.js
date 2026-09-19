// 19-gr-down.js - dissolve the cluster (and the ClusterSet, if one exists) and hand the
// sandbox back to plain asynchronous replication, which is its resting state (ticket 10).
//
//   mysqlsh --js --no-wizard --file 19-gr-down.js
//   then, from examples\00-setup:  mysql ... < 05-replication.sql   on 3308 and 3309
//   (or just run ..\01-group-replication\19-gr-down.ps1, which does both)
//
// --no-wizard matters: Cluster.dissolve() asks "Are you sure? [y/N]" and a --file run will
// sit on that prompt forever. shell.options['useWizards'] = false is belt and braces.
//
// ClusterSet has NO dissolve() in Shell 8.4.10 - "Unknown identifier: dissolve". A ClusterSet
// is taken apart by removing each replica cluster and then dissolving what is left.

shell.options['useWizards'] = false;

var PW = 'IcAdmin#2026';
function cd(p) { return { host: '127.0.0.1', port: p, user: 'icadmin', password: PW }; }

shell.connect(cd(3307));

// --- 1. if this is a ClusterSet, peel the replica clusters off first ----------------------
try {
  var cs = dba.getClusterSet();
  var names = Object.keys(cs.status().clusters);
  var primary = cs.status().primaryCluster;
  names.forEach(function (n) {
    if (n != primary) { cs.removeCluster(n, { force: true }); println('removed replica cluster ' + n); }
  });
} catch (e) {
  println('no ClusterSet to take apart (' + e.message + ')');
}

// --- 2. dissolve the remaining cluster ----------------------------------------------------
try {
  dba.getCluster().dissolve({ force: true });
  println('cluster dissolved');
} catch (e) {
  println('dissolve: ' + e.message);
}

// --- 3. undo what the AdminAPI persisted --------------------------------------------------
// dissolve() leaves super_read_only = ON persisted in every node's mysqld-auto.cnf. Without
// this the "replicas" would still be read-only and, worse, node1 would refuse writes.
[3307, 3308, 3309].forEach(function (p) {
  var s = mysql.getClassicSession(cd(p));
  s.runSql('SET PERSIST read_only = OFF');
  s.runSql('SET PERSIST super_read_only = OFF');
  // the group channels linger as OFF rows in performance_schema until reset
  ['group_replication_applier', 'group_replication_recovery'].forEach(function (ch) {
    try { s.runSql("RESET REPLICA ALL FOR CHANNEL '" + ch + "'"); } catch (e) { /* not present */ }
  });
  var r = s.runSql('SELECT @@port, @@read_only, @@super_read_only').fetchOne();
  println('  port=' + r[0] + ' read_only=' + r[1] + ' super_read_only=' + r[2]);
  s.close();
});

println('--- now re-run examples\\00-setup\\05-replication.sql on 3308 and 3309');
