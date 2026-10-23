// Feeds: ch. 5 (lesson 0005, record 0007) | Nodes: node1 (3307) | State: cluster
//
//   mysqlsh --js --no-wizard --file 41-no-pk-live.js
//
// The live half of ticket 08's no_pk_demo: inside a RUNNING group, a PK-less InnoDB table can be
// created, but a write to it is refused, because certification has no row identifier to put in
// the write-set. Then the AdminAPI's own verdict on the same table, then the table is dropped.
// 37-no-primary-key.js shows only the AdminAPI half and needs no running group.

shell.options['useWizards'] = false;
function cd(p) { return { host: '127.0.0.1', port: p, user: 'icadmin', password: 'IcAdmin#2026' }; }
var s = mysql.getClassicSession(cd(3307));

// --- state check: this script needs the group, not async -------------------------------------
var online = s.runSql("SELECT COUNT(*) FROM performance_schema.replication_group_members " +
                      "WHERE MEMBER_STATE = 'ONLINE'").fetchOne()[0];
if (online < 1) {
  throw new Error('State is not "cluster" (no ONLINE group members on 3307). ' +
                  'Run 10-gr-up.js first.');
}
println('state check: ' + online + ' ONLINE group member(s) - OK');

s.runSql("DROP TABLE IF EXISTS poliklinika.no_pk_demo");
s.runSql("CREATE TABLE poliklinika.no_pk_demo (label VARCHAR(40) NOT NULL, amount INT NOT NULL) ENGINE=InnoDB");
println('\n=== 1. CREATE TABLE without a primary key: accepted');

println('\n=== 2. INSERT into it while Group Replication is running');
try {
  s.runSql("INSERT INTO poliklinika.no_pk_demo VALUES ('first', 1)");
  println('INSERT accepted (unexpected)');
} catch (e) {
  println('INSERT refused: ' + e.message + ' (code ' + e.code + ')');
}

println('\n=== 3. what the AdminAPI says about the instance with this table present');
var r = dba.checkInstanceConfiguration(cd(3307));
println('status = ' + r.status);

s.runSql("DROP TABLE poliklinika.no_pk_demo");
println('\n=== 4. table dropped; AdminAPI again');
println('status = ' + dba.checkInstanceConfiguration(cd(3307)).status);
s.close();
