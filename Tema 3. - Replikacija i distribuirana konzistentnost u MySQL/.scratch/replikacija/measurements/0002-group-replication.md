# 0002 — Group Replication, quorum, conflicts, consistency levels, InnoDB ClusterSet

Ticket 11, 2026-09-19. Three instances 3307/3308/3309, MySQL 8.4.11 Community, MySQL Shell 8.4.10,
one Windows machine, loopback only. Scripts: `examples/01-group-replication/`.

Every number below is from a run recorded in this session. Findings and their consequences are in
`learning-records/0002-group-replication.md`; this file is the numbers only.

---

## 1. The cluster came up

`dba.createCluster('poliklinikaCluster')` on 3307, then `addInstance` for 3308 and 3309 with
`recoveryMethod: 'incremental'`. Both additions reported **"State recovery already finished"** — no
data transfer at all, because ticket 10 had provisioned both replicas from node1's binary log and all
three held byte-identical `gtid_executed` (`92f36f51-…:1-16840`).

```
statusText : "Cluster is ONLINE and can tolerate up to ONE failure."
primary    : 127.0.0.1:3307   R/W   PRIMARY   ONLINE   8.4.11
             127.0.0.1:3308   R/O   SECONDARY ONLINE   8.4.11
             127.0.0.1:3309   R/O   SECONDARY ONLINE   8.4.11
topologyMode : Single-Primary
ssl          : REQUIRED
```

Failed attempts before this worked, both on the first call:

| Attempt | Result |
|---|---|
| `dba.checkInstanceConfiguration` as `root` | `User 'root' can only connect from 'localhost'.` |
| `localAddress: '127.0.0.1:13307'` | `Invalid port '13307' for localAddress option. When using 'MYSQL' communication stack, the port must be the same in use by MySQL Server` |

## 2. Single-primary behaviour

| Port | `read_only` | `super_read_only` | role reported by the member itself |
|---|---|---|---|
| 3307 | 0 | 0 | PRIMARY |
| 3308 | 1 | 1 | SECONDARY |
| 3309 | 1 | 1 | SECONDARY |

- Write on 3307 (`heartbeat` id 16807, ts `14:39:24.468818`) read back **identically on all three**.
- Write attempted on 3308: `ERROR 1290 (HY000): The MySQL server is running with the
  --super-read-only option so it cannot execute this statement`.
- `replication_group_members` queried on each of the three members returns the **same three rows** in
  the same states — the agreement is visible, not inferred.

## 3. A member leaving and rejoining (clean shutdown)

```
before        : 3307 ONLINE PRIMARY | 3308 ONLINE SECONDARY | 3309 ONLINE SECONDARY
topology.ps1 stop -Node 3
+3 s          : 3307 ONLINE PRIMARY | 3308 ONLINE SECONDARY          <- 3309 GONE from the view
write on 3307 while 3309 is down: accepted (1 row)
topology.ps1 start -Node 3
t+2 s         : 3309 state = OFFLINE
t+4 s         : 3309 state = ONLINE
group_replication_start_on_boot = 1   (persisted by the AdminAPI)
after         : all three ONLINE
row written while 3309 was down, now on 3309: 1
```

**A clean shutdown is a graceful leave**: the member is removed from the view entirely, the group
reconfigures to two, and majority is recalculated over two. No `UNREACHABLE`, no blocking.

## 4. Quorum loss — 3308 and 3309 killed with `Stop-Process -Force`

```
t+5 s   : 3307 ONLINE | 3308 UNREACHABLE | 3309 ONLINE
t+25 s  : 3307 ONLINE | 3308 UNREACHABLE | 3309 UNREACHABLE
group_replication_unreachable_majority_timeout = 0      (wait for ever)
group_replication_exit_state_action             = OFFLINE_MODE
```

The two failures are **detected several seconds apart**, so the group passes through a
one-member-down view before reaching the minority state.

| Statement on the survivor 3307 | Result |
|---|---|
| `SELECT COUNT(*) FROM poliklinika.patients` | **returned in 39 ms**, `90` |
| `INSERT INTO poliklinika.heartbeat …` | **still blocked after 30 s**; client killed |
| `SELECT COUNT(*) … WHERE node='no-quorum'` | returned in 28 ms, **`0`** |

So: reads served, the write neither committed nor failed nor visible. The minority **blocks; it does
not diverge.**

### The repair, and the fate of the suspended write

`cluster.forceQuorumUsingPartitionOf('127.0.0.1:3307')`:

```
Restoring cluster 'poliklinikaCluster' from loss of quorum, by using the partition composed of [127.0.0.1:3307]
The InnoDB cluster was successfully restored using the partition from the instance 'icadmin@127.0.0.1:3307'.
WARNING: To avoid a split-brain scenario, ensure that all other members of the cluster are removed or
joined back to the group that was restored.
status: OK_NO_TOLERANCE_PARTIAL — "Cluster is NOT tolerant to any failures. 2 members are not active."
```

Afterwards:

```
id    | node       | ts
16809 | no-quorum  | 2026-09-19 14:40:56.635916     <- issued before the repair, committed after
16810 | post-force | 2026-09-19 14:43:00.831632
```

**The blocked transaction committed**, roughly two minutes after it was issued, although its client
had been killed long before. It was suspended inside commit, not aborted.

Restarting 3308 and 3309 was enough to make the group whole again — all three ONLINE within 15 s, no
further operator action.

## 5. Multi-primary conflicts

`cluster.switchToMultiPrimaryMode()` — all three become PRIMARY / R/W,
`group_replication_single_primary_mode = 0`.

Four separate timings, all on `poliklinika` rows:

| # | Transaction A (3307) | Transaction B (3308) | Winner | Loser's error |
|---|---|---|---|---|
| 1 | `UPDATE invoices … id=1`, opened first, commits at t+6 s | same row, commits at t+2 s | B | `ERROR 1180 (HY000): Got error 149 - 'Lock deadlock; Retry transaction' during COMMIT` |
| 2 | `UPDATE invoices … id=1`, commits at t+5 s | `UPDATE invoices … id=1`, commits at t+5 s (simultaneous) | A | same, 1180/149 |
| 3 | `INSERT heartbeat id=990001`, commits at t+5 s | `INSERT heartbeat id=990001`, commits at t+5 s | A | same, 1180/149 |
| 4 | `UPDATE cert_demo` **300 000 rows** incl. id 300000, commits at t+12 s | `UPDATE cert_demo … id=300000`, commits at t+12.4 s | **B** | same, 1180/149 — the 300 000-row transaction is the one discarded |

In every case **all three members converged on the winner's value**, checked row by row:

```
case 1  invoices.id=1  ->  1144.05   on 3307, 3308 and 3309
case 4  cert_demo.id=300000 -> 999   on 3307, 3308 and 3309
```

**Different rows, identical timing** (A on `invoices` id 1, B on id 2): **both committed**, both
values present on all three members — certification is row-level, not table-level.

### The counter that did not move

`performance_schema.replication_group_member_stats.COUNT_CONFLICTS_DETECTED` stayed at **0 on every
member through all four cases**. `COUNT_TRANSACTIONS_CHECKED` advanced by exactly one per case — the
winner. The loser never reached certification: it was aborted locally when the winner's already
certified write-set met its row lock.

Source-ladder check on this (practitioner rung, docs silent): MySQL bug **78705 "Improve Client Error
For Certification Failures"** exists precisely because this error is unhelpful, and independent
InnoDB Cluster multi-primary reports show the same `ER_ERROR_DURING_COMMIT` / handler 149. So the
behaviour is normal, not a sandbox artefact. `ER_TRANSACTION_ROLLBACK_DURING_COMMIT` (3101) was **not
produced in any of the four attempts**, including one built specifically to widen the certification
window.

### A table without a primary key

With `poliklinika.no_pk_demo (naziv VARCHAR(40), iznos INT)` present, `dba.checkInstanceConfiguration`
returns `{"status": "error"}`:

> ERROR: The following tables do not have a Primary Key or equivalent column: `poliklinika.no_pk_demo`
> Group Replication requires tables to use InnoDB and have a PRIMARY KEY or PRIMARY KEY Equivalent
> (non-null unique key). Tables that do not follow these requirements will be readable but not
> updateable when used with Group Replication.

Dropped again, the same call returns `{"status": "ok"}` / *"No incompatible tables detected"*.

## 6. `group_replication_consistency` — measured, not quoted

Single-primary. Two **persistent** sessions inside one MySQL Shell process: write on 3307, then read
the same row on secondary 3309 microseconds later. 40 iterations per level, each write a **5 000-row**
transaction so the apply window on the secondary is wide enough for a stale read to exist at all.

| Level | Stale reads | Stale % | Median commit | p95 | Mean |
|---|---|---|---|---|---|
| `EVENTUAL` (default) | **40 / 40** | **100 %** | **16 ms** | 22 ms | 15.8 ms |
| `AFTER` | 0 / 40 | 0 % | 29 ms | 32 ms | 26.2 ms |
| `BEFORE_AND_AFTER` | 0 / 40 | 0 % | 31 ms | 36 ms | 28.6 ms |

**+81 % and +94 % median commit latency respectively, in exchange for the anomaly disappearing
completely.** The cost falls on the writer, not the reader.

### The failed first attempt, which matters

The same experiment run as one `mysql.exe` process per statement gave **0 stale reads at every level
and no latency difference at all** (EVENTUAL 21.4 ms median vs AFTER 20.0 ms, 300 iterations). The
~20 ms of client process start-up between write and read was longer than the replication window, so
the measurement erased the very thing it was measuring. The anomaly is real but its window is short;
an instrument slower than the window cannot see it.

## 7. InnoDB ClusterSet

`removeInstance(3309)` → `createClusterSet('poliklinikaCS')` → `createReplicaCluster('drCluster')`.

```
domainName          : poliklinikaCS          status: HEALTHY — "All Clusters available."
poliklinikaCluster  : PRIMARY  (3307 R/W, 3308 R/O)
drCluster           : REPLICA  (3309 R/O)
   clusterSetReplicationStatus : OK
   source : 127.0.0.1:3307   receiver: ON   applier: APPLIED_ALL, 4 worker threads
   replicationSsl : TLS_AES_128_GCM_SHA256 TLSv1.3   (REQUIRED)
   transactionSetConsistencyStatus : OK   errantGtidSet : (empty)   missingGtidSet : (empty)
```

**A cluster may be single-member — that is the whole reason a one-machine ClusterSet is possible.**

| Action | Result |
|---|---|
| `INSERT` on the replica cluster (3309) | `ERROR 1290 … --super-read-only` |
| `SELECT` on the replica cluster | works — `patients = 90` |
| `setPrimaryCluster('drCluster')` | **478 ms**; 3307 → R/O, 3309 → R/W; write accepted on 3309, refused on 3307 |
| `setPrimaryCluster('poliklinikaCluster')` | **398 ms**; roles flip back |

### Emergency failover — 3307 and 3308 both killed

Before any operator action, the survivor 3309 had `super_read_only = 1`, **refused writes**, and the
ClusterSet reported `UNAVAILABLE — "Primary Cluster is not reachable from the Shell, assuming it to be
unavailable."` It did **not** promote itself.

`clusterSet.forcePrimaryCluster('drCluster')` — **23 064 ms**:

> None of the instances of the PRIMARY cluster 'poliklinikaCluster' could be reached.
> PRIMARY cluster failed-over to 'drCluster'. The PRIMARY instance is '127.0.0.1:3309'
> **Former PRIMARY cluster 'poliklinikaCluster' was INVALIDATED, transactions that were not yet
> replicated may be lost.**
> **In case of network partitions and similar, the former PRIMARY Cluster 'poliklinikaCluster' may
> still be online and a split-brain can happen.** To avoid it, use `<Cluster>.fenceAllTraffic()` to
> fence the Cluster from all application traffic, or `<Cluster>.fenceWrites()` to fence it from write
> traffic only.

After it: `super_read_only = 0` on 3309, write accepted, status `AVAILABLE`,
`drCluster` = PRIMARY / OK, `poliklinikaCluster` = REPLICA / **INVALIDATED**.

When the killed instances came back they stayed `INVALIDATED` / `OFFLINE` — they did not rejoin
by themselves.

### Repair

`dba.rebootClusterFromCompleteOutage('poliklinikaCluster')` →
*"Skipping rejoining remaining instances because the Cluster belongs to a ClusterSet and is
INVALIDATED"* → `clusterSet.rejoinCluster('poliklinikaCluster')` → `setPrimaryCluster` back.
End state `HEALTHY — All Clusters available`, primary = `poliklinikaCluster`. 3308 then rejoined
with `cluster.rejoinInstance()`.

## 8. Teardown and the sandbox's resting state

- `ClusterSet.dissolve()` **does not exist** in Shell 8.4.10: *"Unknown identifier: dissolve"*.
  `removeCluster(..., {force:true})` then `Cluster.dissolve({force:true})` works.
- `Cluster.dissolve()` **prompts interactively** (`Are you sure you want to dissolve the cluster?
  [y/N]:`) and a `--file` run hangs on it — one attempt was killed after 20 minutes at that prompt.
- Dissolve leaves these persisted in each node's `mysqld-auto.cnf`, among others:
  `super_read_only=ON`, `group_replication_group_name`, `group_replication_communication_stack=MYSQL`,
  `group_replication_consistency=BEFORE_ON_PRIMARY_FAILOVER`, `group_replication_start_on_boot=OFF`,
  `auto_increment_offset` (2 on node3). Only the read-only pair had to be cleared.
- `gtid_executed` after teardown: 3307 and 3308 at `…:1-564`, 3309 at `…:1-560` — 3309 left the
  ClusterSet four metadata transactions early. A **subset**, not errant, so `SOURCE_AUTO_POSITION = 1`
  closed the gap on its own.

Final verification: all three UP, `replication_connection_status` ON on 3308 and 3309, a test row on
3307 visible on all three, **3306 still listening and untouched**.
