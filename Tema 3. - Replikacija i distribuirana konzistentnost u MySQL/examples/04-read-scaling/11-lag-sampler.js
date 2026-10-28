// Feeds: Slika 7.1 (natural lag), lesson 0007 | Nodes: node1 (3307) ticker, node3 (3309) sampled | State: async
//
//   mysqlsh --js --no-wizard --file 11-lag-sampler.js <max-seconds>
//
// Started by 10-lag-burst.ps1, never on its own: the orchestrator pins node3's applier to one
// worker and fires the burst while this script samples.
//
// Every SAMPLE_MS it does two things over held sessions (harness rule, figures/README.md):
//   1. ticker: INSERT one heartbeat row on node1 with ts = NOW(6), the source's clock;
//   2. sampler: on node3 read, in one round trip-ish sequence,
//        - Seconds_Behind_Source               (SHOW REPLICA STATUS; whole seconds)
//        - applying_age_ms  = NOW(6) - APPLYING_TRANSACTION_ORIGINAL_COMMIT_TIMESTAMP of the
//                             worker currently applying (0 when no worker is applying)
//        - last_applied_lag_ms = END_APPLY - ORIGINAL_COMMIT of the newest applied transaction
//                             (the per-transaction definition, R2 in the lesson)
//        - heartbeat_lag_ms = NOW(6) - MAX(heartbeat.ts) visible on node3 (data staleness)
//        - relay_log_space_bytes, and the receiver's last queued GTID number
// All three nodes share one machine and one clock, so clock skew (weakness 2) is zero by
// construction here; that is a property of the sandbox, not of the method.
//
// Stops when the burst is over and node3 has been caught up for IDLE_STOP_S seconds, or at
// max-seconds. Output: CSV with units in the column names (figures/README.md).

shell.options['useWizards'] = false;
var args = sys.argv;
var MAX_S = parseFloat(args[1] || '150');
var SAMPLE_MS = 250;
var IDLE_STOP_S = 6;

function cd(p) { return { host: '127.0.0.1', port: p, user: 'root', password: 'Repl#2026root' }; }
var src = mysql.getClassicSession(cd(3307));
var rep = mysql.getClassicSession(cd(3309));

// --- state check: async channel on node3, no group ------------------------------------------
var ch = rep.runSql("SELECT COUNT(*) FROM performance_schema.replication_connection_status " +
                    "WHERE CHANNEL_NAME = '' AND SERVICE_STATE = 'ON'").fetchOne()[0];
if (ch != 1) throw new Error('Need State: async (node3 default channel ON). Run examples/01-group-replication/19-gr-down.ps1 and topology.ps1 start.');

var rows = ['t_s,seconds_behind_source_s,applying_age_ms,last_applied_lag_ms,heartbeat_lag_ms,relay_log_space_bytes,workers_busy'];
var t0 = Date.now();
var sawLag = false, idleSince = null;

function num(v) { return (v === null || v === undefined) ? '' : String(v); }

while (true) {
  var t = (Date.now() - t0) / 1000;
  src.runSql("INSERT INTO poliklinika.heartbeat (ts, node) VALUES (NOW(6), 'ch7-ticker')");

  var s = rep.runSql("SHOW REPLICA STATUS").fetchOneObject();
  var sbs = s['Seconds_Behind_Source'];
  var rls = s['Relay_Log_Space'];
  var ps = rep.runSql(
    "SELECT " +
    " (SELECT IFNULL(MAX(TIMESTAMPDIFF(MICROSECOND, APPLYING_TRANSACTION_ORIGINAL_COMMIT_TIMESTAMP, NOW(6)))/1000, 0) " +
    "    FROM performance_schema.replication_applier_status_by_worker WHERE APPLYING_TRANSACTION <> ''), " +
    " (SELECT TIMESTAMPDIFF(MICROSECOND, LAST_APPLIED_TRANSACTION_ORIGINAL_COMMIT_TIMESTAMP, LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP)/1000 " +
    "    FROM performance_schema.replication_applier_status_by_worker ORDER BY LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP DESC LIMIT 1), " +
    " (SELECT TIMESTAMPDIFF(MICROSECOND, MAX(ts), NOW(6))/1000 FROM poliklinika.heartbeat), " +
    " (SELECT COUNT(*) FROM performance_schema.replication_applier_status_by_worker WHERE APPLYING_TRANSACTION <> '')"
  ).fetchOne();

  rows.push([t.toFixed(3), num(sbs), num(ps[0]), num(ps[1]), num(ps[2]), num(rls), num(ps[3])].join(','));

  var busy = (sbs !== null && sbs > 0) || ps[0] > 0 || ps[2] > 1000;
  if (busy) { sawLag = true; idleSince = null; }
  else if (sawLag && idleSince === null) { idleSince = t; }
  if (sawLag && idleSince !== null && t - idleSince >= IDLE_STOP_S) break;
  if (t >= MAX_S) break;
  os.sleep(SAMPLE_MS / 1000);
}

// mysqlsh's JS mode has no file-write helper, so the CSV is printed between markers and the
// orchestrator (10-lag-burst.ps1) cuts it out of stdout into figures/raw/.
println('---CSV-BEGIN---');
print(rows.join('\n') + '\n');
println('---CSV-END---');
println('samples=' + (rows.length - 1) + ' sawLag=' + sawLag);
