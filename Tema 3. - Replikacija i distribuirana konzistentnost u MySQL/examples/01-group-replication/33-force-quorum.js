var cd = { host: '127.0.0.1', port: 3307, user: 'icadmin', password: 'IcAdmin#2026' };
shell.connect(cd);
var c = dba.getCluster();
println('--- status before the repair');
try { println(JSON.stringify(c.status(), null, 2)); } catch (e) { println('status ERROR: ' + e.message); }
println('--- forceQuorumUsingPartitionOf(3307)');
try { c.forceQuorumUsingPartitionOf(cd); } catch (e) { println('ERROR: ' + e.message); }
println('--- status after the repair');
try { println(JSON.stringify(c.status(), null, 2)); } catch (e) { println('status ERROR: ' + e.message); }
