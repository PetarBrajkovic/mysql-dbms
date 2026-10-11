// Feeds: lesson 0004, ch. 4 | Nodes: node1 (3307) | State: semisync, receivers stopped
// The committing client (session A). Runs as its OWN mysqlsh process, because its COMMIT blocks
// while the source waits for the acknowledgement, and mysqlsh JS has no threads.
// Usage: mysqlsh --js --file 02-writer.js <id> <note>
var id = parseInt(sys.argv[1]), note = sys.argv[2] || 'demo';
var s = mysql.getClassicSession({ host: '127.0.0.1', port: 3307, user: 'root', password: 'Repl#2026root' });
var conn = s.runSql('SELECT CONNECTION_ID()').fetchOne()[0];
var t0 = Date.now(), res = 'OK', err = null;
try {
  s.runSql('INSERT INTO poliklinika.semisync_demo (id, note) VALUES (?, ?)', [id, note]); // autocommit = COMMIT
} catch (e) { res = 'ERROR'; err = String(e.message || e); }
var t1 = Date.now();
println(JSON.stringify({ who: 'writer', conn: conn, id: id, t_start: t0, t_end: t1, ms: t1 - t0, result: res, error: err }));
