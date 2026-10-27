# Learning records — index

One record per taught lesson. **Read this index first and open only the records it points you at** —
reading all of them costs more context than any one lesson needs.

Each record holds: what was taught (short), the non-obvious insights worth revisiting, and what comes
next. Measured numbers, produced artifacts and write-up notes are **not** here — they live in
`.scratch/replikacija/measurements/<same-filename>` and are only needed when writing or checking a
chapter, never when planning a lesson.

| # | Chapter | Headline | Open it when you are teaching / writing about |
|---|---|---|---|
| [0001](0001-replication-topology.md) | — (ticket 10) | The three-instance sandbox, and what the live servers said about the memos | the topology itself; semisync latency and timeout degradation; applier vs receiver lag; `Seconds_Behind_Source`; read-your-writes |
| [0002](0002-group-replication.md) | — (ticket 11) | The group, the quorum, the conflicts and a live InnoDB ClusterSet — all of it works locally | Group Replication; quorum loss; multi-primary conflicts; `group_replication_consistency`; geo-distribution and ClusterSet |
| [0003](0003-theory-framework.md) | 2 (ticket 14, lesson) | Vocabulary from three roots; PACELC as two plain questions; Abadi is the citation for "Dynamo quorums are not linearizable" | consistency models, RYW vs monotonic reads, CAP misreadings, PACELC, replication models, consensus, the two quorums; memo 07's errors |
| [0004](0004-binlog-gtid-async.md) | 3, part A (ticket 15, lesson) | Replication = binlog shipping + replay; GTID is a name, file+offset an address; async acks before any replica saw it | binlog formats, unsafe statements, GTID / auto-positioning, receiver/applier threads, the rename, async loss window |
| [0005](0005-durability-wal-2pc.md) | 3, part B (ticket 15, lesson) | write ≠ fsync; WAL/redo; two logs need two-phase commit with the binlog as decision point; the matrix | durability, crash recovery, `sync_binlog` × `innodb_flush_log_at_trx_commit`, process vs OS crash; ch. 4 `AFTER_SYNC` builds on it |
| [0006](0006-semisync-acknowledgement.md) | 4 (ticket 16, lesson) | Ack = relay log + fsync; decision ≠ visibility; AFTER_COMMIT anomaly reproduced live; the failed source rejoins with zero errors | semisync, `AFTER_SYNC`/`AFTER_COMMIT`, failover vs switchover, errant/extra GTIDs, timeout signals, ack cost |
| [0007](0007-group-replication-lesson.md) | 5 (ticket 17, lesson) | One decision point orders writes; certification = one total order + deterministic verdict; minority blocks; the level picks who waits (BEFORE measured live) | certification, write-sets, 1180, PK requirement, quorum loss, single vs multi-primary, `group_replication_consistency` → ch. 2 models |
| [0008](0008-geo-clusterset.md) | 6 (ticket 18, lesson) | GR cannot stretch (RTT per commit, expel); ClusterSet = GR per DC + async, one writer; C inside, A across — the A choice is one operator command | geo-distribution, ClusterSet, switchover vs forced failover, INVALIDATED/fencing, the CAP-at-two-scopes payoff, CAP judged per operation |

## Standing constraints these records impose on every later chapter

Facts already settled, with the record that settled them. **Do not re-litigate or re-measure these.**

- The topology is 3307 / 3308 / 3309, `server_id` 1/2/3, datadirs under `C:\mysql-repl\`, started by
  hand with `examples\00-setup\topology.ps1 start` at the top of every session — they are background
  processes, not services (no Administrator on this account). (0001)
- **Port 3306 is Tema 2's server and stays untouched**; verified still serving at the end of the build. (0001)
- The replicas were provisioned by `SOURCE_AUTO_POSITION = 1` from node1's binary log alone, so there
  are **no errant GTIDs** anywhere. Do not create accounts or objects directly on 3308/3309. (0001)
- `GET_SOURCE_PUBLIC_KEY = 1` is required on every channel; without it replication breaks after any
  restart of the source. (0001)
- Resting state after a start is **plain asynchronous** replication: the semisync plugins are installed
  but `rpl_semi_sync_*_enabled` returns to OFF on every start. (0001)
- Lag is induced with `SOURCE_DELAY` on node3 by default; every such caption says so in Serbian
  (ticket 08's honesty rule).
- **The sandbox has two mutually exclusive states**: plain asynchronous (the resting state) and the
  InnoDB Cluster / ClusterSet. `examples\01-group-replication\10-gr-up.js` goes one way,
  `19-gr-down.ps1` the other; **always run `19-gr-down.ps1` at the end of a group session.** (0002)
- **MySQL Shell is not installed system-wide** — it lives unpacked at
  `C:\mysql-repl\tools\mysql-shell-8.4.10-windows-x86-64bit\bin\mysqlsh.exe` (no Administrator
  needed). Shell 8.4.10 is the newest 8.4 build Oracle serves; it drives 8.4.11 servers without
  complaint. (0002)
- **Group Replication, quorum, multi-primary and InnoDB ClusterSet are all demonstrable locally.** Do
  not plan any part of chapters 5 or 6 as theory-only. (0002)
- **The AdminAPI PERSISTs `skip_replica_start=ON`**; until 0003 `19-gr-down.ps1` did not clear it, so
  3308's channel silently stayed OFF after every start. Fixed and the script patched. If a channel is
  ever OFF after `start`, check `mysqld-auto.cnf` first. (0003)
- **Memo 07 §1's `group_replication_consistency` levels are wrong** (names and semantics); ch. 5 takes
  them from the refman only. Ch. 2 cites **Abadi 2012** for "Dynamo quorums are not linearizable". (0003)
- **Ch. 3 is taught as two lessons**: A (0004: binlog, formats, GTID, threads, rename, async) and B
  (0005: durability, WAL, two-phase commit, the matrix); both taught. Lessons and examples use **root** on the topology:
  `dbadmin` lacks `REPLICATION SLAVE`, so `SHOW BINLOG EVENTS` fails for it. (0004)
- In 8.4 only the new statement forms exist (`SHOW BINARY LOG STATUS`, `RESET BINARY LOGS AND GTIDS`,
  `CHANGE REPLICATION SOURCE TO` …); the MASTER/SLAVE forms were removed in 8.4.0. (0004)
- Two-phase commit is **„dvofazno komitovanje“**, never „dvofazna potvrda“ (potvrda = acknowledgement).
  Matrix row 2/1 and the process-crash column are derived, not quoted; the ~2 redo fsyncs per commit
  with the binlog on is a measurement, not a documented mechanism. (0005)
- **Ch. 4's measurements are done** (memo 04 claims 2, 3, 6): AFTER_COMMIT window 3005 ms vs 0 ms;
  a reader saw a row the failover erased; under both wait points the restarted old source holds an
  extra GTID and **rejoins with no error** (ER 1885 only covers the new source's UUID). Scripts in
  `examples/03-semisync/`; always finish with `09-restore.ps1`. (0006)
- **The 8.4 default of `group_replication_consistency` is `BEFORE_ON_PRIMARY_FAILOVER`**, not
  `EVENTUAL` (8.4.0 release notes; verified live). It equals EVENTUAL in steady state. Never call
  EVENTUAL "the default" in ch. 5/7. **`BEFORE` is measured** (`42-ryw-before.js`): 0/40 stale,
  reader pays ~one apply time, writer unchanged. The level → model mapping is ours, not the refman's. (0007)
- No sentence may say asynchronous replication "has no automatic failover": refman §19.4.9
  Asynchronous Connection Failover re-points automatically; contrast **who promotes**. Multi-primary
  does **not** scale writes proportionally (derived, not measured). (0007)
- **Ch. 6's measurements are done** (re-run 0008): switchover 539/444 ms vs forced failover 21.6 s (0002:
  478/398 ms vs 23.1 s); the replica cluster never promotes itself; old cluster stays INVALIDATED until
  `rejoinCluster`, and 3308 needs `rejoinInstance` after `40`. Shell `8.4` doc URLs serve 26.7 content:
  re-verify quotes. `super_read_only` on replica clusters is measured, not quoted. (0008)
- A clean `topology.ps1 stop` is a **graceful leave**, not a failure — it cannot be used to
  demonstrate quorum loss. Losing majority requires killing the process. (0002)

## Corrections filed against the research memos

- **Measurement 0002 mislabelled `EVENTUAL` as the default** (ticket 11's own record, not a memo).
  Corrected in place in 0002; the numbers stand because the level was set explicitly. (0007)

- **Memo 04, claim 5 (semisync latency cost) fails as written.** It predicted async 0.1–1 ms against
  semisync 2–10 ms. On loopback with full durability the difference is inside run-to-run noise, because
  two fsyncs (~900 µs) dwarf the acknowledgement; with both fsyncs off, semisync doubles commit latency
  (61 → 124 µs). The cost is real but it is a network-distance cost, and no number may be quoted
  without its durability setting. (0001)
- **Memo 03's setup sequence is incomplete**: it omits `GET_SOURCE_PUBLIC_KEY = 1`, without which a
  fresh 8.4 channel cannot authenticate over an unencrypted connection once the source's password cache
  is cold. (0001)
- **Memo 05's certification story is right about the mechanism and wrong about the observable.** The
  losing transaction receives `ERROR 1180 … Got error 149 - 'Lock deadlock; Retry transaction' during
  COMMIT`, not `ER_TRANSACTION_ROLLBACK_DURING_COMMIT` (3101), and `COUNT_CONFLICTS_DETECTED` never
  moves — measured across four different timings. First-commit-wins and row-level granularity both
  hold. (0002)
- **Memo 04 invents `Rpl_semi_sync_source_timeouted`** (absent from 8.4 refman and the live server)
  and lists five signals, not seven; **claim 6 is wrong in mechanism**: the failed source does not
  cause replication errors on rejoin, it diverges silently. `_clients` is not a signal (stayed 2 with
  receivers stopped). (0006)
- **Memo 03 is wrong on `NOW()`** (lists it as unsafe; refman: safe, the binlog carries the timestamp)
  and **overstates GTIDs** ("failover is automatic"; refman: GTIDs *simplify* failover). (0004)
- **Memo 03, claim 9 (parallel applier 2–4×) is understated** for this workload: measured 8.2×
  (40 507 ms → 4 950 ms at 4 workers). Treat as an optimistic upper bound — independent single-row
  inserts are the ideal case. (0001)
