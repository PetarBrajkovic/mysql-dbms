# Raw measurements — ticket 10, three-instance topology

MySQL 8.4.11 Community, Win64, three loopback instances on one machine. Commit-latency cells are
300 single-row `INSERT`s into `poliklinika.heartbeat` through a server-side loop, timed with `NOW(6)`,
divided by 300. Every number below is a real reading, none is modelled.

## 1. Commit latency: durability × acknowledgement mode (µs per commit)

| `sync_binlog` | `innodb_flush_log_at_trx_commit` | async | semisync (`AFTER_SYNC`) |
|---|---|---|---|
| 1 | 1 | 764 | 978 |
| 1 | 2 | 355 | 406 |
| 0 | 1 | 634 | 533 |
| 0 | 2 | 61 | 124 |

Repeatability check at `sync_binlog=1, flush=1`, three alternating pairs (semisync / async):
914 / 899, 912 / 913, 915 / 926 µs. The semisync–async difference is inside the noise at full
durability; at `0,2` it is a clean 2×.

## 2. Semisynchronous timeout degradation

`rpl_semi_sync_source_timeout = 1000` ms, both receivers stopped (`STOP REPLICA IO_THREAD`).

| Event | Value |
|---|---|
| first commit after receivers lost | **1 004 293 µs**, committed successfully |
| second commit | **782 µs** |
| `Rpl_semi_sync_source_status` | ON → **OFF** |
| `Rpl_semi_sync_source_clients` | 2 → **0** |
| `Rpl_semi_sync_source_no_tx` | 0 → **2** |
| `Rpl_semi_sync_source_yes_tx` | 2 400 (unchanged during the outage) |
| after `START REPLICA IO_THREAD` on both | status **ON** again, clients 2, `no_tx` stays 2 |

## 3. Natural lag with a single applier worker

node2, `replica_parallel_workers = 1`, 4 000 single-row transactions on node1, sampled once per second.

| t | applied lag (ms) | `Relay_Log_Space` (B) | `Seconds_Behind_Source` |
|---|---|---|---|
| 1 s | 826 | 2 038 519 | 1 |
| 2 s | 1 764 | 2 508 963 | 2 |
| 3 s | 2 795 | 2 924 295 | 3 |
| 4 s | 3 806 | 2 924 295 | 4 |
| 5 s | 4 823 | 2 924 295 | 5 |
| 6 s | 5 842 | 2 924 295 | 6 |
| 7 s | 6 850 | 2 924 295 | 7 |
| 8 s | 7 863 | 2 924 295 | 8 |
| 9 s | 8 867 | 2 924 295 | 9 |
| 10 s | 9 880 | 2 924 295 | 9 |

`Relay_Log_Space` is flat from t+3 s: the receiver finished in three seconds, the applier did not.

## 4. Applier parallelism

Time for node2 to drain 4 000 transactions **after** the source had finished writing them,
measured with `WAIT_FOR_EXECUTED_GTID_SET`:

| `replica_parallel_workers` | drain |
|---|---|
| 1 | **40 507 ms** |
| 4 | **4 950 ms** |

Caveat: the 1-worker run started with residual backlog from the previous burst, so 8.2× is an
optimistic upper bound. Re-measure with a script for the ch. 7 figure.

## 5. Lag measured two ways at the same moment (node3, `SOURCE_DELAY = 2`, idle and caught up)

| Measure | Reading |
|---|---|
| `Seconds_Behind_Source` | **3** |
| `SQL_Delay` | 2 |
| `SQL_Remaining_Delay` | NULL |
| `Replica_SQL_Running_State` | "Replica has read all relay log; waiting for more updates" |
| `performance_schema` end-to-end (`ORIGINAL_COMMIT_TIMESTAMP` → `END_APPLY_TIMESTAMP`) | **3 006.25 ms** |

## 6. Read-your-writes on the delayed replica

| Step | Result |
|---|---|
| `INSERT` on 3307, GTID | `92f36f51-…:4837` |
| immediate `SELECT` on 3309 | **0 rows** |
| `replication_connection_status.RECEIVED_TRANSACTION_SET` on 3309 | `…:4837` (received) |
| `@@global.gtid_executed` on 3309 | `…:1-4836` (not applied) |
| `WAIT_FOR_EXECUTED_GTID_SET(gtid, 10)` | returned 0 after **2 976 ms** |
| `SELECT` after the wait | **1 row** |

## 7. Convergence check after the whole session

All three instances at `92f36f51-b420-11f1-aa37-9c6b001d863b:1-16839`, 16 805 `heartbeat` rows each.
Port 3306 (Tema 2) still listening, service `MySQL84` Running, `poliklinika.patients` = 90 rows.
