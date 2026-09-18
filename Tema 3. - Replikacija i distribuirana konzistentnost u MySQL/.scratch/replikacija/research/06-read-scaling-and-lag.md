# Research: Read Scaling with Replicas, and Replication Lag

## 1. What Replication Lag Actually Is, and Why Seconds_Behind_Source Is a Poor Measure

**Replication lag** is the time delay between when a transaction commits on the source and when it is fully applied on a replica. It is not simply a single number but a vector of different measurements depending on which part of the replication pipeline you observe: the I/O receiver thread (network lag), the applier thread (apply lag), or the end-to-end lag.

**Why `Seconds_Behind_Source` is misleading:**

The `Seconds_Behind_Source` field in `SHOW REPLICA STATUS` measures only the difference between the current timestamp on the replica and the original timestamp of the *event currently being processed* by the SQL (applier) thread. It has three critical flaws:

1. **Network-dependent:** It is useful only for fast networks. In slow networks, the receiver thread may lag significantly behind the source, but the applier thread catches up to the slow-reading receiver thread frequently, causing `Seconds_Behind_Source` to show 0 even when the replica is substantially behind. [MySQL 8.4 Reference Manual - SHOW REPLICA STATUS](https://dev.mysql.com/doc/refman/8.4/en/show-replica-status.html)

2. **Clock sensitivity:** It assumes clock skews between source and replica remain constant. NTP updates or other clock adjustments corrupt the measurement. [MySQL 8.4 Reference Manual - SHOW REPLICA STATUS](https://dev.mysql.com/doc/refman/8.4/en/show-replica-status.html)

3. **Multithreaded replica blind spot:** In multithreaded replicas, `Seconds_Behind_Source` is based on `Exec_Source_Log_Pos`, which may not reflect the position of the most recently committed transaction, leading to underestimated lag. [MySQL 8.4 Reference Manual - SHOW REPLICA STATUS](https://dev.mysql.com/doc/refman/8.4/en/show-replica-status.html)

**What the Performance Schema timestamp tables provide instead:**

MySQL 8.4 introduces two transaction-level timestamps that replace event-level timestamps:

- **`original_commit_timestamp`**: microseconds since epoch when the transaction was committed on the original source.
- **`immediate_commit_timestamp`**: microseconds since epoch when the transaction was committed on the immediate source (for replicas in a chain).

These timestamps are stored in three Performance Schema tables:

1. **`replication_connection_status`**: Shows the last and current transaction queued into the relay log by the receiver thread, including `LAST_SEEN_TRANSACTION_ORIGINAL_COMMIT_TIMESTAMP` and `LAST_SEEN_TRANSACTION_IMMEDIATE_COMMIT_TIMESTAMP`.

2. **`replication_applier_status_by_coordinator`** (multithreaded replicas only): Shows the coordinator thread's last buffered transaction.

3. **`replication_applier_status_by_worker`**: Shows per-worker status with precise timestamps for transaction application.

These allow precise measurement of receiver lag, applier lag, apply duration, and chained replication lag.

The recommended method to monitor replication delay in MySQL 8.4+ is using these Performance Schema tables. [MySQL 8.4 Reference Manual - Delayed Replication](https://dev.mysql.com/doc/refman/8.4/en/replication-delayed.html)

---

## 2. The Anomaly a Read Replica Produces: Read-Your-Writes and Monotonic Reads

**The anomaly:** A client performs a write on the source, then immediately issues a read routed to a lagging replica. If the replica has not applied the write, the client does not see its own write—a **stale read** or **read-your-writes violation**.

**Literature names:**

The anomaly violates two session guarantees from distributed systems literature:

1. **Read-Your-Writes Guarantee**: A client's read operations must reflect all of its prior writes.

2. **Monotonic Reads Guarantee**: Successive reads by a client must observe a non-decreasing set of writes.

**Consistency model:** A read replica in MySQL's asynchronous replication provides **eventual consistency**—transactions are externalized on the source, then asynchronously replicated with no synchronization point before serving reads.

[MySQL 8.4 Reference Manual - Using Replication for Scale-Out](https://dev.mysql.com/doc/refman/8.4/en/replication-solutions-scaleout.html)

---

## 3. What MySQL Offers to Close the Anomaly: Synchronization Functions

### `WAIT_FOR_EXECUTED_GTID_SET(gtid_set [, timeout])`

**What it waits for:** Blocks until the replica has applied all transactions in the GTID set.

**Cost:** Must be called explicitly; blocks client thread; can cause latency if replica is behind.

[MySQL 8.4 Reference Manual - GTID Functions](https://dev.mysql.com/doc/refman/8.4/en/gtid-functions.html)

### `SOURCE_POS_WAIT(log_name, log_pos [, timeout] [, channel])`

**What it waits for:** Blocks until replica has read and applied updates up to a binary log position.

**Cost:** Less accurate than GTID-based waiting; harder to use in complex topologies.

[MySQL 8.4 Reference Manual - Position-Based Synchronization Functions](https://dev.mysql.com/doc/refman/8.4/en/replication-functions-synchronization.html)

### `group_replication_consistency` (for Group Replication)

**Levels:** EVENTUAL, BEFORE_ON_PRIMARY_FAILOVER, BEFORE, AFTER, BEFORE_AND_AFTER

Each level increases latency and consistency guarantees. Can be set per-session or globally.

[MySQL 8.4 Reference Manual - Configuring Transaction Consistency Guarantees](https://dev.mysql.com/doc/refman/8.4/en/group-replication-configuring-consistency-guarantees.html)

---

## 4. Read/Write Splitting: MySQL Router and Application-Level Routing

**How MySQL Router works:**

MySQL Router classifies queries as read or write and routes accordingly. Writes go to read-write instances (primary/source); reads go to read-only instances (secondaries/replicas). Each session communicates with one read-write and one read-only destination.

However, Router cannot know application-level semantics. **In practice, most systems implement the application to decide**, routing read-your-writes-sensitive queries to the primary or waiting on replicas using synchronization functions, while routing pure reads to replicas.

[MySQL Router 8.4 Documentation - Read/Write Splitting](https://dev.mysql.com/doc/mysql-router/8.4/en/router-read-write-splitting.html)

---

## 5. Delayed Replication (SOURCE_DELAY): Protection and Deterministic Lag Manufacturing

**Real purpose:** Protects against human error. If an operator runs `DELETE FROM users;` accidentally, a delayed replica can be rewound using binary log position or GTID.

**How it works:** `CHANGE REPLICATION SOURCE TO SOURCE_DELAY=N` delays each transaction by at least N seconds after commit on the immediate source.

**Critical for figure reproducibility:** This is the single most useful demo mechanic. Without SOURCE_DELAY, replica lag varies with load, making results unreproducible. With it, lag is deterministic—essential for teaching figures.

[MySQL 8.4 Reference Manual - Delayed Replication](https://dev.mysql.com/doc/refman/8.4/en/replication-delayed.html)

---

## 6. What Read Scaling Does and Does Not Scale

**What scales:** Read throughput scales linearly with the number of replicas. Distributing SELECT queries across replicas allows ~10x read requests with 10 replicas.

**What does not scale:** Write throughput does not scale. Every replica must absorb the full write load. **Every replica must have write throughput ≥ the total write rate on the source.** If the source writes at 10,000 TPS but a replica handles only 5,000 TPS, that replica will lag indefinitely.

The manual states: "using replication for scale-out works best in an environment where you have a high number of reads and low number of writes/updates."

[MySQL 8.4 Reference Manual - Using Replication for Scale-Out](https://dev.mysql.com/doc/refman/8.4/en/replication-solutions-scaleout.html)

---

## 7. Candidate Figures: Reproducible Lag Scenarios

### Figure 1: Lag Time-Series

**Purpose:** Show how `Seconds_Behind_Source` fluctuates unpredictably while timestamp-based lag is stable.

**Rep
roducible approach:**
1. Set up source + 2 replicas (one with `SOURCE_DELAY=3`, one with `SOURCE_DELAY=0`).
2. Run sustained writes at constant rate (e.g., 100 inserts/sec for 60 seconds).
3. Poll `SHOW REPLICA STATUS` every 1 second, collecting `Seconds_Behind_Source` and `NOW() - LAST_APPLIED_TRANSACTION_ORIGINAL_COMMIT_TIMESTAMP`.
4. Plot both on same time-series graph.

**What it shows:** Delayed replica shows stable lag sawtooth at ~3 seconds. Non-delayed replica's `Seconds_Behind_Source` is erratic (spikes and drops to 0) while timestamp-based lag is smooth and near-zero.

### Figure 2: Staged Read-Your-Writes Violation

**Purpose:** Show exact moment a client's read misses its own write on a replica, and when synchronization tools resolve it.

**Reproducible approach:**
1. Set up source + 1 delayed replica with `SOURCE_DELAY=2`.
2. Perform `INSERT INTO users VALUES (42, 'Alice')` on source, capture GTID.
3. Immediately `SELECT FROM users WHERE id=42` on replica—returns empty (NO).
4. Wait 1 second, repeat—still returns empty (NO).
5. Wait until `SQL_Remaining_Delay` is 0—now SELECT returns row (YES).
6. Repeat 5 times to show reproducibility.

**What it shows:** Three states: write not yet delayed (SELECT empty), delay in progress (SELECT empty, delay > 0), delay elapsed (SELECT returns row).

Both figures require `SOURCE_DELAY` to be reproducible; without it, timing varies with load.

---

## Claims Requiring Live Topology Verification (Ticket 10)

1. **`Seconds_Behind_Source` is unreliable on slow networks**: Create 100ms latency between source and replica; show `Seconds_Behind_Source` frequently reads 0 while actual lag is much higher using Performance Schema timestamps.

2. **Performance Schema timestamps provide consistent lag measurement**: Query `replication_applier_status_by_worker` with slow network; show `NOW() - LAST_APPLIED_TRANSACTION_ORIGINAL_COMMIT_TIMESTAMP` is stable and accurate over time.

3. **Read-your-writes violations occur without synchronization**: Issue write on source, immediately read from 2-second-delayed replica, confirm write not visible. Verify GTID in `retrieved_gtid_set` but not applied.

4. **`WAIT_FOR_EXECUTED_GTID_SET()` closes the violation**: Repeat above with `SELECT WAIT_FOR_EXECUTED_GTID_SET(@gtid, 10)` on replica; confirm blocks ~2 seconds then SELECT sees write.

5. **`SOURCE_DELAY` creates deterministic lag**: Run write-and-read sequence 10 times with `SOURCE_DELAY=2`—write invisible until exactly after delay. Run 10 times without—visibility timing varies.

6. **`group_replication_consistency='BEFORE'` enforces read-your-writes in Group Replication**: On InnoDB Group Replication with multiple secondaries, issue write with BEFORE consistency, then read-only transaction on different member—confirm it waits for write to apply.

7. **Every replica must absorb full write rate or lag indefinitely**: Source 10,000 TPS, two replicas (one 10,000 TPS capacity, one 5,000 TPS). Run 8,000 TPS sustained writes. Fast replica stays caught up; slow replica's lag grows monotonically over 10 minutes.
