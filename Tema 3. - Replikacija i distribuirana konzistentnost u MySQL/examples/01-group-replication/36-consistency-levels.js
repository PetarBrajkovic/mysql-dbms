// group_replication_consistency measured with the read issued MICROSECONDS after the commit
// returns: two persistent sessions inside one process, no client start-up in the gap.
// The write is a 5000-row transaction so that applying it on the secondary takes long enough
// for a stale read to be possible at all.
function cd(p) { return { host: '127.0.0.1', port: p, user: 'icadmin', password: 'IcAdmin#2026' }; }
var w = mysql.getClassicSession(cd(3307));   // primary
var r = mysql.getClassicSession(cd(3309));   // secondary

w.runSql("DROP TABLE IF EXISTS poliklinika.cons_demo");
w.runSql("CREATE TABLE poliklinika.cons_demo (id INT UNSIGNED PRIMARY KEY, v INT NOT NULL) ENGINE=InnoDB");
// cert_demo is the row source the batches are copied from: 5000 rows per transaction is what
// makes the apply window on the secondary wide enough for a stale read to be possible at all.
w.runSql("DROP TABLE IF EXISTS poliklinika.cert_demo");
w.runSql("CREATE TABLE poliklinika.cert_demo (id INT UNSIGNED PRIMARY KEY, v INT NOT NULL) ENGINE=InnoDB");
w.runSql("SET SESSION cte_max_recursion_depth = 400000");
w.runSql("INSERT INTO poliklinika.cert_demo (id, v) WITH RECURSIVE s(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM s WHERE n < 300000) SELECT n, 0 FROM s");
os.sleep(5);

var N = 40, BATCH = 5000;
var levels = ['EVENTUAL', 'AFTER', 'BEFORE_AND_AFTER'];
var out = [];

levels.forEach(function (lvl) {
  w.runSql("SET SESSION group_replication_consistency = '" + lvl + "'");
  var stale = 0, lat = [];
  for (var i = 0; i < N; i++) {
    var off = 1000000 * (levels.indexOf(lvl) + 1) + i * BATCH;
    var t0 = Date.now();
    w.runSql("INSERT INTO poliklinika.cons_demo (id, v) SELECT id + ? , 0 FROM poliklinika.cert_demo WHERE id <= ?", [off, BATCH]);
    lat.push(Date.now() - t0);
    var marker = off + BATCH;               // the last row of the batch
    var got = r.runSql("SELECT COUNT(*) FROM poliklinika.cons_demo WHERE id = ?", [marker]).fetchOne()[0];
    if (got != 1) stale++;
  }
  lat.sort(function (a, b) { return a - b; });
  var sum = 0; lat.forEach(function (x) { sum += x; });
  out.push({ level: lvl, iterations: N, rows_per_txn: BATCH, stale_reads: stale,
             stale_pct: Math.round(1000 * stale / N) / 10,
             median_ms: lat[Math.floor(N / 2)], p95_ms: lat[Math.floor(N * 0.95)],
             mean_ms: Math.round(10 * sum / N) / 10 });
  println(JSON.stringify(out[out.length - 1]));
});

println('--- summary');
println(JSON.stringify(out, null, 2));
w.runSql("DROP TABLE poliklinika.cons_demo");
w.runSql("DROP TABLE poliklinika.cert_demo");
