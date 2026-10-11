# 0006 — Semisync acknowledgement: measurements (ticket 16, lesson half)

Taken live during the lesson, 2026-10-11, MySQL 8.4.11 Community, Win64, topology 3307/3308/3309,
`sync_binlog=1`, `innodb_flush_log_at_trx_commit=1`. Scripts: `examples/03-semisync/`. Memo 04
claims 2, 3 and 6 — the measurement debt from ticket 11 — are now paid.

## Harness

- Window: writer = separate `mysqlsh --js` process (its COMMIT blocks; mysqlsh JS has no threads);
  reader = held mysqlsh session polling `SELECT COUNT(*)` every **0.14 ms**, also sampling the
  writer's PROCESSLIST state. Both use `Date.now()` on the same clock.
- The acknowledgement is **withheld** by `STOP REPLICA IO_THREAD` on both replicas, so the window is
  as long as the timeout. **Staged, not natural**: every caption says so. A natural window on loopback
  would be tens of µs (the ack round trip), unobservable with this harness.
- Crash = `Stop-Process -Force` on node1's mysqld (process crash, not OS crash; with 1/1 that makes
  no difference to what is on disk).

## M1 — visibility window (claims 2 and 3a), timeout 3000 ms

| wait point | writer COMMIT | writer result | B first sees row | window | row on 3308/3309 |
|---|---|---|---|---|---|
| AFTER_SYNC (id 1001) | 3012 ms | OK | 3012 ms | **0 ms** | 0 / 0 |
| AFTER_COMMIT (id 1002) | 3010 ms | OK | **5 ms** | **3005 ms** | 0 / 0 |

Writer PROCESSLIST state seen by B: `Waiting for semi-sync ACK from replica` (both); under
AFTER_COMMIT also `waiting for handler commit` first. Counters per run: status ON→OFF→ON (after
`START REPLICA IO_THREAD`), `no_tx` 0→1→2, `no_times` 0→1→2, `yes_tx` stuck at 1,
**`Rpl_semi_sync_source_clients` stayed 2 with both receivers stopped** (not a reliable signal).
Error log: `[Warning] [MY-011153] [Repl] Timeout waiting for reply of binlog (file: node1-bin.000010,
pos: 1010), semi-sync up to file node1-bin.000010, position 678.` No "switched OFF" line appears at
the default error-log verbosity.

## M2 — crash + failover under AFTER_COMMIT (claim 3b), id 2001, timeout 120 s

- 1.5 s into the wait: writer state `Waiting for semi-sync ACK from replica`; **B reads 1** on 3307.
- Kill node1 → writer: `ERROR`, `ClassicSession.runSql: Lost connection to MySQL server during query`
  (1497 ms).
- Failover (3308 `RESET REPLICA ALL`, 3309 re-pointed to 3308): **row on 3308 = 0, on 3309 = 0**.
  3308 `gtid_executed` unchanged from before the write (`92f36f51…:1-17678`).
- **Reproduces.** The chapter's claim stands as written: a client read a transaction a failover
  then erased.

## M3 — the failed source rejoins (claim 6), after M2

- Restart node1: row id 2001 **present** (was engine-committed before the crash).
- `GTID_SUBTRACT(gtid_3307, gtid_3308)` = `92f36f51-b420-11f1-aa37-9c6b001d863b:17679`;
  `GTID_SUBSET` = 0.
- `CHANGE REPLICATION SOURCE TO … 3308 … SOURCE_AUTO_POSITION=1; START REPLICA` on 3307:
  `Replica_IO_Running: Yes`, `Replica_SQL_Running: Yes`, `Last_IO_Errno: 0`, `Last_SQL_Errno: 0`,
  `Seconds_Behind_Source: 0`.
- Row id 2001: 3307 = 1, 3308 = 0, 3309 = 0. `CHECKSUM TABLE`: 3307 1524585538, 3308/3309 2038849628.
- **Claim 6 is right in substance, wrong in mechanism.** The memo says the old source "cannot
  rejoin … causes replication errors". It rejoins with **no error at all**; the divergence is silent.
  ER 1885 (`ER_REPLICA_HAS_MORE_GTIDS_THAN_SOURCE`) only fires for GTIDs carrying the *new source's*
  UUID (refman 19.1.3.3); the extra GTID carries the old source's own UUID.

## M4 — the same under AFTER_SYNC, id 3001

- B reads **0** before the kill (transaction prepared + in binlog, not engine-committed).
- Writer: `Lost connection …` (1503 ms). Row on new source 3308 = 0.
- Restart node1: row id 3001 **present** → crash recovery committed a prepared transaction found in
  the binlog (lesson 0003 rule), although no replica ever acknowledged it and nobody saw it.
  Extra GTID `92f36f51…:17682`. Rejoin again Yes/Yes, 0 errors; CHECKSUM 3307 3344619555 vs 0 / 0.
- This is exactly the refman's AFTER_SYNC sentence: lossless failover for clients, but the source
  "must be discarded, because its binary log might contain uncommitted transactions".
- Error log at recovery shows only `Starting XA crash recovery...` / `XA crash recovery finished.`,
  no per-transaction line at default verbosity.

## Restore

`09-restore.ps1` after M3 and after M4: all three `gtid_executed` identical
(`…92f36f51…:1-17683` at the end), 3308/3309 ON/ON from 3307, semisync OFF on all, `semisync_demo`
emptied. Valid only because nothing was written on 3308 while promoted (3308 ⊂ 3307).
**The table `poliklinika.semisync_demo` still exists** (empty, replicated to all three); drop it with
`09-restore.ps1 -DropTable` if a later chapter needs a clean schema.

## Verified sources (researcher, rung 1 unless noted)

- Ack: "The replica acknowledges receipt of a transaction's events only after the events have been
  written to its relay log and flushed to disk." — refman 19.4.10.
- AFTER_COMMIT: "After the commit and before replica acknowledgment, other clients can see the committed
  transaction before the committing client." … "it is possible for such clients to see a loss of data
  relative to what they saw on the source." — sysvar `rpl_semi_sync_source_wait_point`.
- AFTER_SYNC: "all clients see the committed transaction at the same time …" / "failover to the
  replica is lossless because the replica is up to date. Note, however, that the source cannot be
  restarted in this scenario and must be discarded, because its binary log might contain uncommitted
  transactions that would cause a conflict with the replica." — same sysvar entry.
- Overview: "the failed source should not be reused as the replication source, and should be
  discarded." — 19.4.10.
- Timeout: default 10000 ms; "If a timeout occurs without any replica having acknowledged the
  transaction, the source reverts to asynchronous replication. When at least one semisynchronous
  replica catches up, the source returns to semisynchronous replication." — 19.4.10.
- `rpl_semi_sync_source_wait_no_replica` default ON; `wait_for_replica_count` default 1.
- Cost: "at least the TCP/IP roundtrip time to send the commit to the replica and wait for the
  acknowledgment of receipt by the replica." — 19.4.10.
- Status list in 8.4 (14 vars, matches live `SHOW STATUS`): clients, net_avg_wait_time,
  net_wait_time, net_waits, no_times, no_tx, status, timefunc_failures, tx_avg_wait_time,
  tx_wait_time, tx_waits, wait_pos_backtraverse, wait_sessions, yes_tx. `net_*` deprecated, always 0.
  **No `Rpl_semi_sync_source_timeouted`.**
- ER 1885 condition — refman 19.1.3.3; message from the 8.4 error reference (docs.oracle.com mirror).
- **Absence claim, open:** "MySQL 8.4 Community has no mechanism that discards a never-acknowledged
  binlog transaction on recovery of a former semisync source." Checked on rung 1 (refman: binlog
  crash-recovery truncation is only to the last valid position, unrelated to acks) and confirmed
  behaviourally by M4. **Rung 2 (8.4 release notes, source) not yet checked** — check before the
  sentence enters `rad.md`.
- "AFTER_COMMIT was the only behaviour before 5.7.2" — said in the lesson from memory; **verify
  (5.7 refman, `rpl_semi_sync_master_wait_point`, "added in 5.7.2") before citing.**
- "Errant transaction": no refman definition; Shell 8.4 uses "extra transactions" / "Errant
  transactions detected". Use *višak transakcija* and define it in our own words.

## Used in the writing session (2026-10-11)

- **Tabela 4.1 row 1/1 = means of the three repeat pairs** in record 0001 (async 899/913/926 → 913,
  semisync 914/912/915 → 914), not the single 764/978 reading, which overstated the gap; caption
  says so. Rows 2-4 are the single 0001 readings.
- **`_clients` disagreed between runs**: 0001 saw 2 → 0, this record saw it stay 2. Ch. 4 states both,
  which is the reason it is called not a reliable signal.
- **5.7.2 history verified** (rung 2, 5.7.2 release notes): older versions are "equivalent to a
  setting of AFTER_COMMIT"; cited as `mysql572relnotes`. "Only behaviour" was not claimed.
- **Absence claim checked, then avoided**: rung 1 (refman 19.4.10, 7.4.4), rung 2 (8.0/8.4
  release-note indexes, weak), rung 4 (MySQL Bug #99370: "expected behavior, a limitation"). The
  prose states the measured behaviour and the manual's "should be discarded" instead; the check is
  recorded as an HTML comment above that paragraph in `rad.md`. MariaDB does truncate
  (`init_rpl_role`, MDEV-33465), not used.

## For the writing session (as planned by the lesson)

- Tabela 4.1 = the 2×2 latency matrix from record 0001 (async vs semisync), first native table.
- Figures available in `viz/` (lesson versions): `viz-l04-tacke-cekanja-*`, `viz-l04-prozor-vidljivosti-*`,
  `viz-l04-pad-i-failover-*`, `viz-l04-tiha-degradacija-*`, `viz-l04-cena-potvrde-*`. Paper figures go
  to `figures/04-…` per `figures/README.md`; window figure data should be re-run into
  `figures/raw/*.csv` if a chart is drawn from it.
- Memo 04 lists **five** signals (one of them nonexistent), not seven as ticket 16 says; the chapter
  uses the seven-row list in this file (status, no_tx, no_times, yes_tx, wait_sessions, error log
  MY-011153, commit latency) plus the explicit non-signal (clients).
