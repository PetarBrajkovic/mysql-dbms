// Feeds: Tabela 7.1 (async half), lesson 0007 | Nodes: node1 (3307) writer, node2 (3308) and node3 (3309) readers | State: async
//
//   mysqlsh --js --no-wizard --file 20-ryw-async.js
//
// INDUCED lag: node3 gets SOURCE_DELAY = 3 for the duration of this script and is restored to 0
// at the end. Every caption built from this output must say the lag was induced (GLOSSARY.md 5).
//
// The first half of ticket 08's twice-run sequence (the second half, under
// group_replication_consistency = 'BEFORE', is examples/01-group-replication/42-ryw-before.js):
//   A. read-your-writes: write on node1, read the same row from node3 immediately -> stale;
//      diagnosis: the GTID is in node3's RECEIVED_TRANSACTION_SET but not in gtid_executed.
//   B. monotonic reads: one client reads node2 (fresh), then node3 (stale) -> goes back in time.
//   C. WAIT_FOR_EXECUTED_GTID_SET(g, 1): timeout shorter than the delay -> returns 1, still stale.
//   D. WAIT_FOR_EXECUTED_GTID_SET(g, 10): blocks ~ the delay, returns 0, the read is fresh.
//   E. SOURCE_POS_WAIT(file, pos, 10): the same wait by binlog address instead of GTID name.
// Harness: held sessions in one mysqlsh process (figures/README.md, harness rule).

shell.options['useWizards'] = false;
function cd(p) { return { host: '127.0.0.1', port: p, user: 'root', password: 'Repl#2026root' }; }
var src = mysql.getClassicSession(cd(3307));
var r2  = mysql.getClassicSession(cd(3308));
var r3  = mysql.getClassicSession(cd(3309));
var DELAY = 3;
function one(s, q, a) { return s.runSql(q, a || []).fetchOne(); }
function now() { return Date.now(); }

// --- state check -----------------------------------------------------------------------------
[r2, r3].forEach(function (s, i) {
  var on = one(s, "SELECT COUNT(*) FROM performance_schema.replication_connection_status WHERE CHANNEL_NAME='' AND SERVICE_STATE='ON'")[0];
  if (on != 1) throw new Error('Need State: async, default channel ON on node' + (i + 2) + '. Run 19-gr-down.ps1 / topology.ps1 start.');
});
println('state check OK: async, channels ON on node2 and node3');

src.runSql("DROP TABLE IF EXISTS poliklinika.ch7_demo");
src.runSql("CREATE TABLE poliklinika.ch7_demo (id INT UNSIGNED PRIMARY KEY, v INT NOT NULL) ENGINE=InnoDB");
src.runSql("INSERT INTO poliklinika.ch7_demo VALUES (1, 0)");
os.sleep(1);
r3.runSql("STOP REPLICA SQL_THREAD");
r3.runSql("CHANGE REPLICATION SOURCE TO SOURCE_DELAY = " + DELAY);
r3.runSql("START REPLICA SQL_THREAD");
println('node3 SOURCE_DELAY = ' + DELAY + ' (INDUCED lag)');

// The GTID of OUR write: gtid_executed after minus before. Exact here because nothing else writes
// to node1 during the script; an application would take it from session_track_gtids instead.
function writeAndName(v) {
  var before = one(src, "SELECT @@global.gtid_executed")[0];
  src.runSql("UPDATE poliklinika.ch7_demo SET v = ? WHERE id = 1", [v]);  // autocommit
  return one(src, "SELECT GTID_SUBTRACT(@@global.gtid_executed, ?)", [before])[0];
}
function lastGno(set) { return set.replace(/\s/g, ''); }

try {
  // A. read-your-writes ---------------------------------------------------------------------
  var g = writeAndName(1);
  var v3 = one(r3, "SELECT v FROM poliklinika.ch7_demo WHERE id = 1")[0];
  var rec = one(r3, "SELECT RECEIVED_TRANSACTION_SET FROM performance_schema.replication_connection_status WHERE CHANNEL_NAME=''")[0];
  var exe = one(r3, "SELECT @@global.gtid_executed")[0];
  var inRec = one(r3, "SELECT GTID_SUBSET(?, ?)", [g, rec])[0];
  var inExe = one(r3, "SELECT GTID_SUBSET(?, ?)", [g, exe])[0];
  var rem = r3.runSql("SHOW REPLICA STATUS").fetchOneObject()['SQL_Remaining_Delay'];
  println('\nA. read-your-writes: wrote v=1 on node1 (GTID ' + lastGno(g) + '), read node3 at once -> v=' + v3);
  println('   received on node3: ' + (inRec == 1) + ' | applied on node3: ' + (inExe == 1) + ' | SQL_Remaining_Delay=' + rem);

  // B. monotonic reads ----------------------------------------------------------------------
  os.sleep(DELAY + 1);
  writeAndName(2);
  os.sleep(0.2);
  var b2 = one(r2, "SELECT v FROM poliklinika.ch7_demo WHERE id = 1")[0];
  var b3 = one(r3, "SELECT v FROM poliklinika.ch7_demo WHERE id = 1")[0];
  println('\nB. monotonic reads: wrote v=2; same client reads node2 -> v=' + b2 + ', then node3 -> v=' + b3);

  // C. wait with a timeout shorter than the delay --------------------------------------------
  os.sleep(DELAY + 1);
  g = writeAndName(3);
  var t = now();
  var rc = one(r3, "SELECT WAIT_FOR_EXECUTED_GTID_SET(?, 1)", [g])[0];
  var ms = now() - t;
  var c3 = one(r3, "SELECT v FROM poliklinika.ch7_demo WHERE id = 1")[0];
  println('\nC. WAIT_FOR_EXECUTED_GTID_SET(g, 1): returned ' + rc + ' after ' + ms + ' ms; read node3 -> v=' + c3);

  // D. wait long enough ---------------------------------------------------------------------
  os.sleep(DELAY + 1);
  g = writeAndName(4);
  t = now();
  rc = one(r3, "SELECT WAIT_FOR_EXECUTED_GTID_SET(?, 10)", [g])[0];
  ms = now() - t;
  var d3 = one(r3, "SELECT v FROM poliklinika.ch7_demo WHERE id = 1")[0];
  println('\nD. WAIT_FOR_EXECUTED_GTID_SET(g, 10): returned ' + rc + ' after ' + ms + ' ms; read node3 -> v=' + d3);

  // E. the same by binlog address ------------------------------------------------------------
  os.sleep(DELAY + 1);
  src.runSql("UPDATE poliklinika.ch7_demo SET v = 5 WHERE id = 1");
  var bs = src.runSql("SHOW BINARY LOG STATUS").fetchOneObject();
  t = now();
  rc = one(r3, "SELECT SOURCE_POS_WAIT(?, ?, 10)", [bs['File'], bs['Position']])[0];
  ms = now() - t;
  var e3 = one(r3, "SELECT v FROM poliklinika.ch7_demo WHERE id = 1")[0];
  println('\nE. SOURCE_POS_WAIT(\'' + bs['File'] + '\', ' + bs['Position'] + ', 10): returned ' + rc +
          ' (events waited for) after ' + ms + ' ms; read node3 -> v=' + e3);
} finally {
  r3.runSql("STOP REPLICA SQL_THREAD");
  r3.runSql("CHANGE REPLICATION SOURCE TO SOURCE_DELAY = 0");
  r3.runSql("START REPLICA SQL_THREAD");
  os.sleep(DELAY + 1);
  src.runSql("DROP TABLE IF EXISTS poliklinika.ch7_demo");
  println('\nrestored: node3 SOURCE_DELAY = ' +
          one(r3, "SELECT DESIRED_DELAY FROM performance_schema.replication_applier_configuration WHERE CHANNEL_NAME=''")[0]);
}
