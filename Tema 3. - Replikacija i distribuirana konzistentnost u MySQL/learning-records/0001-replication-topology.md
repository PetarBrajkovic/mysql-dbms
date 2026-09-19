# 0001 — Standing up the three-instance topology (ticket 10)

Not a taught lesson — the execution record for ticket 10, which builds ticket 08's scenario on live
servers. Kept in the same index because it settles facts chapters 3–7 need and must not re-measure,
and because it **corrects two research memos**.

Measured on **MySQL 8.4.11, Community Server – GPL, Win64**, three instances on one machine, loopback
only. Build and run instructions: `examples/00-setup/README.md`. Raw numbers:
`.scratch/replikacija/measurements/0001-replication-topology.md`.

## What was built

Three `mysqld` instances — **3307 / 3308 / 3309**, `server_id` 1 / 2 / 3, separate datadirs under
`C:\mysql-repl\`, GTIDs on, ROW binlog, `sync_binlog=1` + `innodb_flush_log_at_trx_commit=1` — with
asynchronous replication running **3307 → 3308** and **3307 → 3309**, `poliklinika` plus the
`heartbeat` instrument table loaded, and the semisynchronous plugins installed (disabled at rest).
`topology.ps1 start|stop|status` drives the set. **Port 3306 verified untouched and still serving Tema
2's schema** at the end.

No Administrator rights on this account, so the instances are **background processes, not services**:
they must be started by hand at the top of every session.

## Non-obvious insights

1. **`GET_SOURCE_PUBLIC_KEY = 1` is mandatory, and it is missing from memo 03's setup sequence.** 8.4
   authenticates with `caching_sha2_password`; this channel is unencrypted. Tested both ways: while the
   source still holds the account in its in-memory password cache the channel connects happily with the
   option off — which is why it looks optional and why it would have been "tested working" and then
   failed later. After `FLUSH PRIVILEGES` (or any restart of the source, i.e. at the start of **every**
   session) the receiver fails with errno **2061**, *"Authentication plugin 'caching_sha2_password'
   reported error: Authentication requires secure connection."* A worked-once-then-broke failure is the
   worst kind to debug mid-chapter; it is now in the script with the reason.

2. **Semisynchronous replication costs nothing measurable on loopback — memo 04's claim 5 fails as
   written, and the reason is the paper's point.** Memo 04 predicted async ≈0.1–1 ms per commit against
   semisync ≈2–10 ms. Measured, 300 single-row commits per cell, three alternating runs:

   | `sync_binlog` | `innodb_flush_log_at_trx_commit` | async | semisync | semisync cost |
   |---|---|---|---|---|
   | 1 | 1 (full durability) | 764 µs | 978 µs | +28 %, and inside run-to-run noise (three paired runs gave 914/899, 912/913, 915/926 µs) |
   | 1 | 2 | 355 µs | 406 µs | +14 % |
   | 0 | 1 | 634 µs | 533 µs | none visible |
   | 0 | 2 (no fsync) | **61 µs** | **124 µs** | **+103 %** |

   With both fsyncs on, commit latency is dominated by two disk flushes (~900 µs) and the loopback
   acknowledgement disappears into them. Turn the flushes off and semisync **doubles** commit latency —
   the protocol cost was always there, just cheaper than the disk. So: the acknowledgement's price is a
   *network-distance* story, not a protocol-overhead story, and this table is a figure for ch. 4 on its
   own. **The paper must not claim a measured semisync latency penalty on this topology** without the
   durability setting attached to the number.

3. **Timeout degradation is exactly as memo 04 describes, and the second write is the teaching
   moment.** With `rpl_semi_sync_source_timeout = 1000` and both receivers stopped: first commit took
   **1 004 293 µs** — the timeout, to the millisecond — and then **succeeded, telling the client
   nothing**. The *second* commit took **782 µs**: normal async speed, no wait at all. The guarantee is
   not degraded gradually, it is switched off after one timeout and stays off. `Rpl_semi_sync_source_status`
   ON→OFF, `Rpl_semi_sync_source_clients` 2→0, `Rpl_semi_sync_source_no_tx` 0→2. When the receivers came
   back, status returned to ON by itself, but `no_tx = 2` remains as the only permanent scar. That
   counter is the honest answer to "how would an operator know".

4. **The applier is the bottleneck, and the relay log proves it without any lag metric.** 4 000
   single-row transactions against node2 pinned to `replica_parallel_workers = 1`: `Relay_Log_Space`
   climbed to 2.9 MB and then **stopped changing after 3 s**, while applied lag went on growing
   1 s per second to 10 s. The receiver had pulled the entire burst in three seconds; the applier needed
   more than ten. Memo 03 claims 7 and 8 confirmed — and the plateau is a better figure than the lag
   curve, because it shows *which* thread is behind rather than *that* something is.

5. **Parallel appliers gave 8×, not the 2–4× memo 03 estimated.** Same 4 000-transaction burst, time to
   drain after the source finished: **40 507 ms at 1 worker, 4 950 ms at 4**. Above the memo's range
   because the workload is the ideal case — independent single-row inserts into one table, no
   dependencies for `replica_preserve_commit_order` to serialise. Honest caveat for ch. 7: this is an
   upper bound, and the run was slightly contaminated by residual backlog from the previous burst. The
   chapter re-measures with a script.

6. **`Seconds_Behind_Source` reads 3 on a replica that is idle and fully caught up.** Node3 with
   `SOURCE_DELAY = 2`, nothing to apply, `SQL_Remaining_Delay` NULL, `Replica_SQL_Running_State` =
   "waiting for more updates" — and `Seconds_Behind_Source: 3`. Memo 06's "unreliable on three counts"
   confirmed on the cheapest possible case. The `performance_schema` measurement over the same moment
   (`LAST_APPLIED_TRANSACTION_ORIGINAL_COMMIT_TIMESTAMP` → `..._END_APPLY_TIMESTAMP`) gave **3 006.25
   ms**, microsecond-resolution and explicable. The two side by side are ch. 7's opening figure.

7. **The read-your-writes anomaly reproduces deterministically, with a clean diagnosis.** Insert on
   3307, immediate read on the 2-s-delayed 3309: **0 rows**, while
   `replication_connection_status.RECEIVED_TRANSACTION_SET` already held GTID `…:4837` and
   `gtid_executed` stopped at `…:1-4836`. *Received but not applied* — the precise phrasing ch. 7 needs.
   `WAIT_FOR_EXECUTED_GTID_SET(gtid, 10)` then blocked **2 976 ms**, returned 0, and the row was there.
   Not a race: the same sequence behaves the same way every time.

8. **Both replicas were provisioned by GTID auto-positioning alone — no dump.** Everything (accounts,
   schema, seed, heartbeat) ran on node1 only, after a `RESET BINARY LOGS AND GTIDS` on all three;
   node1's binary log still held every transaction since initialisation, so one
   `CHANGE REPLICATION SOURCE TO … SOURCE_AUTO_POSITION = 1` brought both replicas from empty to
   identical. Memo 03 claim 5 confirmed in its strongest form, and it also avoids the errant GTIDs that
   creating the same accounts separately on three nodes would have left for Group Replication to choke
   on at ticket 11.

9. **Two facts about restarts that shape every chapter's opening.** `INSTALL PLUGIN` is persistent
   (it lives in `mysql.plugin`) but `rpl_semi_sync_source_enabled` / `_replica_enabled` are plain
   dynamic variables and come back **OFF** on every start. The topology's resting state after
   `topology.ps1 start` is therefore always plain asynchronous replication — convenient for ch. 3, and
   something ch. 4 must switch on explicitly rather than assume. Also: `UNINSTALL PLUGIN` round-trips
   cleanly on all three with replication running, no channel restart needed, so the two modes can be
   compared inside one session.

10. **Two Windows traps, both already fixed in the scripts.** `mysqld` closes its listening port several
    seconds before it releases `ibdata1`, so a stop-then-start cycle fails with *"The innodb_system data
    file 'ibdata1' must be writable"* — `topology.ps1 stop` now waits on the **PID file**, not the port.
    And `mysql.exe`'s "password on the command line" warning goes to stderr, which PowerShell promotes
    to a terminating error under `$ErrorActionPreference = 'Stop'`.

11. **Verbatim artifacts worth quoting in the paper.** The unsafe-statement note is warning **1592**:
    *"…The statement is unsafe because it uses a LIMIT clause. This is unsafe because the set of rows
    included cannot be predicted."* — produced by exactly the statement ticket 08 chose,
    `UPDATE invoices SET paid_status='paid' WHERE tenant_id=1 LIMIT 5`. And `mysqlbinlog -v
    --base64-output=DECODE-ROWS` prints `### INSERT INTO \`poliklinika\`.\`heartbeat\`` followed by
    `@1=…, @2=…, @3=…` — positional, not named, exactly as memo 03 claim 15 says.

## What comes next

Ticket 11: Group Replication and the InnoDB ClusterSet attempt on this topology. Everything it needs is
in place — all-InnoDB schema, every table keyed, `log_replica_updates` on, no errant GTIDs, `repl`
already holding `GROUP_REPLICATION_STREAM` and friends.
