// Feeds: lesson 0004, ch. 4 | Nodes: node1 (3307) | State: semisync, receivers stopped
// Session B: a held session polling the source for the writer's row, so a sub-second window is
// not hidden behind ~20 ms of client start-up per query (figures/README.md, harness rule).
// It also samples what the writer's connection is doing (its PROCESSLIST state).
// Usage: mysqlsh --js --file 02-reader.js <id> <duration_ms>
var id = parseInt(sys.argv[1]), dur = parseInt(sys.argv[2] || '5000');
var b = mysql.getClassicSession({ host: '127.0.0.1', port: 3307, user: 'root', password: 'Repl#2026root' });
var t0 = Date.now(), firstSeen = null, polls = 0, states = {};
while (Date.now() - t0 < dur) {
  var n = b.runSql('SELECT COUNT(*) FROM poliklinika.semisync_demo WHERE id = ?', [id]).fetchOne()[0];
  polls++;
  var now = Date.now();
  if (n == 1 && firstSeen === null) firstSeen = now;
  if (polls % 20 === 0) {   // sample the writer's state every 20 polls
    var r = b.runSql("SELECT STATE FROM information_schema.PROCESSLIST WHERE INFO LIKE 'INSERT INTO poliklinika.semisync_demo%'").fetchOne();
    if (r && r[0]) { var k = r[0]; if (!states[k]) states[k] = now; }
  }
}
println(JSON.stringify({ who: 'reader', id: id, t_begin: t0, first_seen: firstSeen, polls: polls,
                         poll_ms: Math.round(100 * dur / polls) / 100, writer_states_first_seen: states }));
