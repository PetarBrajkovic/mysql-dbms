// 20-clusterset-up.js - turn the three-member cluster into an InnoDB ClusterSet:
//   primary cluster  poliklinikaCluster  = 3307 + 3308   ("datacentre A")
//   replica cluster  drCluster           = 3309          ("datacentre B")
//
//   mysqlsh --js --no-wizard --file 20-clusterset-up.js     (run 10-gr-up.js first)
//
// The point this script exists to make: a cluster may be SINGLE-MEMBER. That is what lets a
// one-machine sandbox hold a real ClusterSet - two genuine clusters, a real ClusterSet
// replication channel between them - instead of two datacentres. The only thing that stays
// out of reach is inter-region latency, which is physics, not a missing feature.
//
// Trap: createReplicaCluster takes a URI STRING, not a connection dictionary, and '#' in a
// password must be percent-encoded (%23) or the URI parser rejects it at position 15.

shell.options['useWizards'] = false;

var PW = 'IcAdmin#2026';
var URI_3309 = 'icadmin:IcAdmin%232026@127.0.0.1:3309';
function cd(p) { return { host: '127.0.0.1', port: p, user: 'icadmin', password: PW }; }

shell.connect(cd(3307));
var c = dba.getCluster('poliklinikaCluster');

// --- 1. free 3309 so it can become a cluster of its own ----------------------------------
c.removeInstance(cd(3309));
println('3309 removed from the primary cluster');

// --- 2. promote the cluster to a ClusterSet ----------------------------------------------
var cs = c.createClusterSet('poliklinikaCS');
println('ClusterSet poliklinikaCS created');

// --- 3. 3309 becomes a replica cluster ----------------------------------------------------
cs.createReplicaCluster(URI_3309, 'drCluster', { recoveryMethod: 'incremental' });
println('drCluster created as a replica cluster');

var st = cs.status();
println('--- ' + st.status + ': ' + st.statusText);
println('--- primary cluster = ' + st.primaryCluster + ', global primary = ' + st.globalPrimaryInstance);
