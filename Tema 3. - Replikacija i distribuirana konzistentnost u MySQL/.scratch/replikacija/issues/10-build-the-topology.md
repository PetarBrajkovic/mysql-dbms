# Stand up the multi-instance replication topology

Type: task
Status: closed
Assignee: Pex
Blocked by: 08 — closed

## Question

Nothing in this paper can be measured on one server, so this ticket is the prerequisite for almost
every figure. It is the equivalent of Tema 2's sandbox ticket, and it is bigger.

Build, on this Windows machine:

1. **Three `mysqld` instances** on ports **3307**, **3308**, **3309** - separate datadirs, separate
   option files, distinct `server_id`, each startable and stoppable independently. **Port 3306 is not
   touched**: it runs Tema 2's `poliklinika` server and must still work when this is done. Verify that
   explicitly at the end.
2. **Asynchronous replication running** from 3307 to 3308, using the 8.4-current command sequence from
   memo 03: replication account with the right privileges, `CHANGE REPLICATION SOURCE TO` with
   `SOURCE_AUTO_POSITION`, GTIDs enabled. Prove it with a write on the source appearing on the
   replica.
3. **The running example from ticket 08** loaded, and its write workload runnable.
4. **Semisynchronous replication installable and removable** - the 8.4 component path from memo 04,
   confirmed to install and confirmed to switch back off, so later chapters can compare the two modes
   rather than describing one of them.
5. **Lag made visible and reproducible**, by whichever mechanism ticket 08 chose.
6. **Test the flagged claims.** Every research memo ends with a list of claims needing the live
   topology; work through them and record which held. Tema 2's equivalent ticket **overturned a memo
   claim outright**, which changed a chapter. Expect the same here, most likely around
   `Seconds_Behind_Source` and semisynchronous timeout degradation.

Record scripts and option files in `examples/00-setup/`, findings in a learning record, and the
startup and shutdown procedure somewhere the user can find it in a later session without rereading
this ticket. Three instances are not something to re-derive every time.

**Repoint `mysql-credentials.cnf`** at the new topology, or add per-node files, and say plainly in the
file's comment which port holds which role. Keep it gitignored.

The answer must record the facts later tickets depend on: ports, datadir paths, account names,
`server_id` values, how to start and stop the set, and anything that needed Administrator rights.

---

## Resolution (2026-09-19)

**Built, running, and it corrected two memos.** Full findings:
`../../../learning-records/0001-replication-topology.md`; raw numbers:
`../measurements/0001-replication-topology.md`; how to run it:
`../../../examples/00-setup/README.md`.

### Facts later tickets depend on

| | |
|---|---|
| Instances | node1 **3307** (`server_id` 1, izvor), node2 **3308** (2), node3 **3309** (3, the delayed one) |
| X protocol ports | 33070 / 33080 / 33090 (ticket 11 needs these for MySQL Shell) |
| Datadirs | `C:\mysql-repl\node<N>\data`; binlogs, relay logs and `node<N>.err` alongside |
| Option files | `examples/00-setup/node1.cnf` … `node3.cnf` — GTID on, ROW binlog, `log_replica_updates` on, `sync_binlog=1`, `innodb_flush_log_at_trx_commit=1` |
| Accounts | `root`@`localhost` / `Repl#2026root`; `repl`@`%` / `Repl#2026repl`; `dbadmin`@`%` / `DbAdmin#2026` |
| Start / stop | `examples\00-setup\topology.ps1 start|stop|status` |
| Administrator | **not held, and not needed.** No Windows services; the three are background processes and must be restarted by hand every session. That is the only manual step. |
| 3306 | untouched and verified serving at the end (service `MySQL84` Running, `poliklinika.patients` = 90) |
| Credentials file | `mysql-credentials.cnf` repointed from 3306 to 3307, with the per-node override documented in its header. Still gitignored. |

### Against the ticket's six items

1. **Three instances** — done, independently startable, 3306 verified untouched.
2. **Async 3307 → 3308** — done, and 3307 → 3309 as well; `SOURCE_AUTO_POSITION = 1`, proven by a write
   appearing on both. **One correction to memo 03's sequence: `GET_SOURCE_PUBLIC_KEY = 1` is mandatory**
   and its absence only bites after a restart, which is exactly when it is hardest to debug.
3. **Running example loaded** — `poliklinika` plus the `heartbeat` instrument table, provisioned to both
   replicas through the binary log itself (no dump, no errant GTIDs — which ticket 11 would have
   tripped over).
4. **Semisync installable and removable** — `INSTALL PLUGIN` / `UNINSTALL PLUGIN` round-trip cleanly
   with replication running. Memo 04's correction confirmed: plugins, not components; `.dll`, not `.so`.
   The plugin persists across restart but `rpl_semi_sync_*_enabled` does not, so the sandbox always
   rests in plain asynchronous mode.
5. **Lag visible and reproducible** — both mechanics work: `SOURCE_DELAY = 2` on node3 (deterministic,
   the read-your-writes anomaly reproduces every time with the received-but-not-applied GTID diagnosis),
   and a natural burst against a one-worker applier (lag grew 1 s/s to 10 s while `Relay_Log_Space`
   plateaued after 3 s — the receiver finished, the applier did not).
6. **Flagged claims tested** — memo 03 claims 1, 2, 5, 7, 8, 9, 11, 15; memo 04 claims 1, 4, 7; memo 06
   claims 1–5. All held except the two below. Untested here and left to ticket 11: memo 04 claims 2, 3
   and 6 (the `AFTER_SYNC` / `AFTER_COMMIT` visibility window and failover reuse, which need two
   concurrent sessions and a staged crash) and memo 06 claims 6 and 7.

### The two overturns — as on Tema 2, the ticket changed a chapter

- **Memo 04 claim 5 is wrong for this topology.** Semisync was predicted to cost 2–10 ms per commit; at
  full durability it costs nothing measurable, because two fsyncs (~900 µs) dominate the loopback
  acknowledgement. With both fsyncs off it doubles commit latency (61 → 124 µs). **Ch. 4 must not quote
  a semisync latency penalty without its durability setting**, and the 2×2 matrix that shows this is a
  figure ch. 3 and ch. 4 share.
- **Memo 03 claim 9 is understated**: 8.2× from four applier workers, not 2–4×. Flagged as an
  optimistic upper bound; ch. 7 re-measures with a script.

Ticket 11 unblocked. Everything Group Replication needs is in place: all-InnoDB, every table keyed,
`log_replica_updates` on, no errant GTIDs, `repl` already holding `GROUP_REPLICATION_STREAM`,
`REPLICATION_SLAVE_ADMIN`, `CONNECTION_ADMIN`, `BACKUP_ADMIN` and `CLONE_ADMIN`.
