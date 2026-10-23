// Feeds: ch. 5 climax, ch. 7 read-your-writes (lesson 0005, record 0007)
// Nodes: node1 (3307) primary writer, node3 (3309) secondary reader | State: cluster, single-primary
//
//   mysqlsh --js --no-wizard --file 42-ryw-before.js
//
// The second half of ticket 08's read-your-writes sequence: a write on the primary, then the same
// logical client reads it back from a secondary MICROSECONDS later. The writer never changes its
// level; only the READER's session level changes:
//   BEFORE_ON_PRIMARY_FAILOVER  - the 8.4 default (8.4.0 release notes), = EVENTUAL in steady state
//   EVENTUAL                    - explicit, for comparison with ticket 11
//   BEFORE                      - the reader waits for every preceding transaction to be applied
// Reported per level: stale reads, the READER's latency and the WRITER's commit latency, so it is
// visible who pays. Harness: held sessions in one mysqlsh process (figures/README.md, harness rule):
// one mysql.exe per statement adds ~20 ms and erases the window (ticket 11).

shell.options['useWizards'] = false;
function cd(p) { return { host: '127.0.0.1', port: p, user: 'icadmin', password: 'IcAdmin#2026' }; }
var w = mysql.getClassicSession(cd(3307));
var r = mysql.getClassicSession(cd(3309));

// --- state check: cluster, single-primary, 3307 is the primary --------------------------------
var st = w.runSql("SELECT @@group_replication_single_primary_mode, " +
  "(SELECT MEMBER_ROLE FROM performance_schema.replication_group_members WHERE MEMBER_PORT = 3307), " +
  "(SELECT COUNT(*) FROM performance_schema.replication_group_members WHERE MEMBER_STATE = 'ONLINE')").fetchOne();
if (st[0] != 1 || st[1] != 'PRIMARY' || st[2] != 3) {
  throw new Error('Need State: cluster, single-primary, 3307 PRIMARY, 3 ONLINE. Got single_primary=' +
                  st[0] + ', 3307 role=' + st[1] + ', online=' + st[2] +
                  '. Run 10-gr-up.js (and 34b-to-single-primary.js if in multi-primary).');
}
println('state check OK: single-primary, 3307 PRIMARY, 3 ONLINE');
println('global group_replication_consistency on 3309 = ' +
        r.runSql("SELECT @@global.group_replication_consistency").fetchOne()[0]);

w.runSql("DROP TABLE IF EXISTS poliklinika.cons_demo");
w.runSql("CREATE TABLE poliklinika.cons_demo (id INT UNSIGNED PRIMARY KEY, v INT NOT NULL) ENGINE=InnoDB");
w.runSql("DROP TABLE IF EXISTS poliklinika.cert_demo");
w.runSql("CREATE TABLE poliklinika.cert_demo (id INT UNSIGNED PRIMARY KEY, v INT NOT NULL) ENGINE=InnoDB");
w.runSql("SET SESSION cte_max_recursion_depth = 10000");
w.runSql("INSERT INTO poliklinika.cert_demo (id, v) WITH RECURSIVE s(n) AS (SELECT 1 UNION ALL " +
         "SELECT n+1 FROM s WHERE n < 5000) SELECT n, 0 FROM s");
os.sleep(5);

var N = 40, BATCH = 5000;
var levels = ['BEFORE_ON_PRIMARY_FAILOVER', 'EVENTUAL', 'BEFORE'];
var out = [];
function med(a) { var b = a.slice().sort(function (x, y) { return x - y; }); return b[Math.floor(b.length / 2)]; }
function p95(a) { var b = a.slice().sort(function (x, y) { return x - y; }); return b[Math.floor(b.length * 0.95)]; }

levels.forEach(function (lvl, li) {
  r.runSql("SET SESSION group_replication_consistency = '" + lvl + "'");
  var stale = 0, wl = [], rl = [];
  for (var i = 0; i < N; i++) {
    var off = 1000000 * (li + 1) + i * BATCH;
    var t0 = Date.now();
    w.runSql("INSERT INTO poliklinika.cons_demo (id, v) SELECT id + ?, 0 FROM poliklinika.cert_demo", [off]);
    var t1 = Date.now();
    var got = r.runSql("SELECT COUNT(*) FROM poliklinika.cons_demo WHERE id = ?", [off + BATCH]).fetchOne()[0];
    var t2 = Date.now();
    wl.push(t1 - t0); rl.push(t2 - t1);
    if (got != 1) stale++;
  }
  out.push({ reader_level: lvl, iterations: N, rows_per_txn: BATCH, stale_reads: stale,
             stale_pct: Math.round(1000 * stale / N) / 10,
             writer_median_ms: med(wl), writer_p95_ms: p95(wl),
             reader_median_ms: med(rl), reader_p95_ms: p95(rl) });
  println(JSON.stringify(out[out.length - 1]));
  os.sleep(2);
});

println('--- summary');
println(JSON.stringify(out, null, 2));
w.runSql("DROP TABLE poliklinika.cons_demo");
w.runSql("DROP TABLE poliklinika.cert_demo");
w.close(); r.close();
