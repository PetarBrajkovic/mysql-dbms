// 10-gr-up.js - take the sandbox from asynchronous replication to a three-member InnoDB Cluster.
//
//   mysqlsh --js --no-wizard --file 10-gr-up.js
//
// Preconditions: all three nodes up (topology.ps1 start), 00-cluster-admin.sql run on each.
// The asynchronous channels are torn down here, because an instance carrying an unmanaged
// replication channel is refused by the AdminAPI.
//
// Two traps this script encodes (both cost a run to discover - see learning record 0002):
//
//  1. NO localAddress. 8.4 defaults to group_replication_communication_stack = MYSQL, which
//     reuses the server's own port and accounts. Passing a separate XCom-style port fails with
//     "the port must be the same in use by MySQL Server". The AdminAPI default would otherwise
//     be port * 10 = 33070/33080/33090 - this sandbox's X-protocol ports exactly.
//  2. recoveryMethod:'incremental' is safe here ONLY because ticket 10 provisioned both
//     replicas from node1's binary log, so no node holds a GTID the others lack.

shell.options['useWizards'] = false;

var PW = 'IcAdmin#2026';
function cd(p) { return { host: '127.0.0.1', port: p, user: 'icadmin', password: PW }; }

// --- 1. drop the asynchronous channels on the two replicas -------------------------------
[3308, 3309].forEach(function (p) {
  var s = mysql.getClassicSession(cd(p));
  s.runSql('STOP REPLICA');
  s.runSql('RESET REPLICA ALL');
  println('async channel removed on ' + p);
  s.close();
});

// --- 2. every instance must agree it is fit for a cluster ---------------------------------
[3307, 3308, 3309].forEach(function (p) {
  var r = dba.checkInstanceConfiguration(cd(p));
  println('checkInstanceConfiguration(' + p + ') = ' + r.status);
  if (r.status != 'ok') { throw new Error('instance ' + p + ' is not cluster-ready'); }
});

// --- 3. bootstrap on node1, then add the other two ----------------------------------------
shell.connect(cd(3307));
var c = dba.createCluster('poliklinikaCluster');
c.addInstance(cd(3308), { recoveryMethod: 'incremental' });
c.addInstance(cd(3309), { recoveryMethod: 'incremental' });

var st = c.status();
println('--- ' + st.defaultReplicaSet.statusText);
println('--- primary = ' + st.defaultReplicaSet.primary + ', mode = ' + st.defaultReplicaSet.topologyMode);
