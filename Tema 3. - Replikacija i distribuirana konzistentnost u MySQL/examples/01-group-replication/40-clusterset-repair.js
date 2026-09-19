function cd(p) { return { host: '127.0.0.1', port: p, user: 'icadmin', password: 'IcAdmin#2026' }; }
println('=== reboot poliklinikaCluster from its outage');
shell.connect(cd(3307));
var c;
try { c = dba.rebootClusterFromCompleteOutage('poliklinikaCluster'); println('rebooted'); }
catch (e) { println('reboot ERROR: ' + e.message); }

println('=== rejoin it to the ClusterSet');
shell.connect(cd(3309));
var cs = dba.getClusterSet();
try { cs.rejoinCluster('poliklinikaCluster'); println('rejoined'); }
catch (e) { println('rejoin ERROR: ' + e.message); }

println('=== hand the primary role back to poliklinikaCluster');
try { cs.setPrimaryCluster('poliklinikaCluster'); println('switched back'); }
catch (e) { println('switchback ERROR: ' + e.message); }

var st = cs.status();
println('clusterset: ' + st.status + ' : ' + st.statusText + '  primary=' + st.primaryCluster);
Object.keys(st.clusters).forEach(function (k) {
  println('  ' + k + ' role=' + st.clusters[k].clusterRole + ' global=' + st.clusters[k].globalStatus + ' status=' + st.clusters[k].status);
});
