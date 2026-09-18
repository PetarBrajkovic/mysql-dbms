# Research: Semisynchronous Replication and Durability

## 1. The Failure Story for Asynchronous Replication

**The precise sequence:**

1. A client issues a transaction (e.g., INSERT, UPDATE, DELETE).
2. The source executes the transaction and writes it to its binary log.
3. The source **acknowledges to the client: "OK, your transaction is committed"**.
4. The client receives this acknowledgment and **believes the transaction is durable.**
5. The source continues to send the binary log event to replicas asynchronously.
6. **Before any replica receives the event**, the source hardware fails or crashes.
7. The events never reach any replica; they are lost.
8. Failover occurs to a replica (which did not receive the event).
9. **The transaction the client believed was committed is now gone.**

**What the client was promised:** That the transaction was committed and durable — it would survive a crash. This promise came from the MySQL source server (via the COMMIT response).

**Who made the promise:** The source server's commit logic, which returns success to the client immediately after writing to the binary log and flushing to disk on the *source side only* — without waiting for replica acknowledgment.

**The core problem:** Asynchronous replication makes no guarantee that a committed transaction will reach any replica before the source dies.

---

## 2. AFTER_SYNC vs AFTER_COMMIT — The Critical Distinction

This is the highest-value distinction in semisynchronous replication durability.

### AFTER_SYNC (the default)

**Wait point in commit sequence:**
1. Source writes transaction to binary log.
2. Source syncs binary log to disk.
3. **Source waits for replica acknowledgment** ← wait happens here
4. Upon receiving acknowledgment from required replica(s), source commits transaction to storage engine.
5. Source returns result to committing client.

**Visibility guarantee:**
- All clients see the committed transaction **at the same time** — after replica has acknowledged and storage engine has committed.
- No other client sees the transaction before the committing client.

**Failover behavior:**
- If source crashes after returning OK, transaction **has already been acknowledged by replica and is in its relay log.**
- Failover to replica is **lossless** — replica has the transaction.
- No phantom reads of lost transactions.

### AFTER_COMMIT (less common, higher performance)

**Wait point in commit sequence:**
1. Source writes transaction to binary log.
2. Source syncs binary log to disk.
3. Source commits transaction to storage engine.
4. **Source waits for replica acknowledgment** ← wait happens here
5. Source returns result to committing client.

**Visibility guarantee:**
- Transaction is visible to other clients **immediately after step 3** — before committing client receives COMMIT response.
- Second client can read the transaction.
- First client doesn't get return value yet.

**This creates a race condition:**
- **After commit, before replica acknowledgment,** other clients can see the transaction.
- If replica doesn't process transaction and source crashes:
  - Replica is promoted (missing this transaction).
  - Other clients that read the transaction **see data that no longer exists after failover.**
  - This is a **phantom read of a lost transaction.**

### Which one exposes a phantom read?

**AFTER_COMMIT is the vulnerable configuration.**

The exact phantom scenario:
1. Client A commits: INSERT INTO accounts (balance) VALUES (100).
2. AFTER_COMMIT mode: transaction is now in storage engine and visible to all clients.
3. Client B reads from source and sees the account with balance 100.
4. Client B's application processes a withdrawal based on this data.
5. Replica has not yet acknowledged the transaction (still in flight).
6. Source crashes.
7. Failover to replica occurs.
8. Replica never received the transaction.
9. Account does not exist on replica.
10. Client B searches for account and it is gone — phantom read of a lost transaction.

With AFTER_SYNC, steps 2–4 cannot happen until replica has already acknowledged.

---

## 3. What Semisynchronous Still Does Not Guarantee

### It is not synchronous replication

Semisynchronous waits for **receipt and relay-log flushing,** not for execution/application. Replica has received the transaction but may not have applied it yet.

### Replica has received but not necessarily applied

The semisync acknowledgment means:
- ✓ Replica's I/O (receiver) thread has written the event to relay log.
- ✓ Relay log has been flushed to disk on replica.
- ✗ Replica's SQL (applier) thread has not necessarily applied the transaction yet.

### rpl_semi_sync_source_timeout silently degrades to asynchronous

If source does not receive acknowledgment within rpl_semi_sync_source_timeout milliseconds (default: 10,000 ms):
- **Stops waiting** and commits the transaction anyway.
- Reverts to asynchronous replication.
- Continues in async mode until semisync replica catches up.

This is a **silent degradation.** Client sees no error.

### How an operator would notice the degradation

**Observable signals:**

1. **Check Rpl_semi_sync_source_status:**
   - If ON, semisync is active
   - If OFF, degraded to asynchronous

2. **Monitor Rpl_semi_sync_source_timeouted counter:**
   - Increments with each timeout

3. **Check Rpl_semi_sync_source_yes_tx status:**
   - Flat or slow-rising counter during high write volume suggests timeouts

4. **Monitor replica lag (Seconds_Behind_Source):**
   - Growing lag indicates degradation

5. **Examine slow query log:**
   - Sudden commit latency spikes indicate timeout-induced fallback

---

## 4. Installation and Configuration on MySQL 8.4

**Important note:** MySQL 8.4's semisynchronous replication uses **plugins** (`INSTALL PLUGIN`), not components. This memo's ticket asserted the opposite; the ticket was wrong and has been corrected. **On Windows the library is `.dll`, not `.so`** - this memo originally gave the Unix names throughout and was corrected in place, since the target machine is Windows. `INSTALL PLUGIN` requires the `REPLICATION_SLAVE_ADMIN` privilege. The old master/slave terminology is replaced with source/replica, but installation method is plugin-based.

### Plugin names for MySQL 8.4:
- **Source server:** rpl_semi_sync_source (library: semisync_source.so on Unix, .dll on Windows)
- **Replica servers:** rpl_semi_sync_replica (library: semisync_replica.so on Unix, .dll on Windows)

### Command sequence for setup:

**On the source server:**

```sql
INSTALL PLUGIN rpl_semi_sync_source SONAME 'semisync_source.dll';
SET GLOBAL rpl_semi_sync_source_enabled = ON;
SET GLOBAL rpl_semi_sync_source_timeout = 10000;
SET GLOBAL rpl_semi_sync_source_wait_point = 'AFTER_SYNC';
SET GLOBAL rpl_semi_sync_source_wait_for_replica_count = 1;
SHOW VARIABLES LIKE 'rpl_semi_sync_source%';
```

**On each replica server:**

```sql
INSTALL PLUGIN rpl_semi_sync_replica SONAME 'semisync_replica.dll';
SET GLOBAL rpl_semi_sync_replica_enabled = ON;
STOP REPLICA IO_THREAD;
START REPLICA IO_THREAD;
SHOW VARIABLES LIKE 'rpl_semi_sync_replica%';
```

**For persistence (in my.cnf):**

```ini
[mysqld]
rpl_semi_sync_source_enabled = ON
rpl_semi_sync_source_timeout = 10000
rpl_semi_sync_source_wait_point = AFTER_SYNC
rpl_semi_sync_replica_enabled = ON
```

---

## 5. The Cost: Latency and Throughput Impact

### Latency cost

**Amount of slowdown:** At least the **TCP/IP roundtrip time** (RTT) between source and replica, including relay log flush time.

Typical breakdown:
- Network latency (both directions): ~1–20 ms (LAN) to 100+ ms (geographically distributed).
- Relay log flush time on replica: ~0.5–5 ms.
- **Total per transaction: 2–5 ms (LAN) to 150+ ms (distant).**

**Impact on commit latency:**
- Asynchronous replication: ~0.1–1 ms (local disk write only).
- Semisynchronous replication: ~2–200 ms (roundtrip + replica I/O).
- **Overhead: 10–1000x slower per transaction commit.**

### Throughput cost

**Throughput reduction:** Inversely proportional to latency increase.

Example:
- Asynchronous: 10,000 transactions/second (0.1 ms per commit).
- Semisynchronous (5 ms RTT): ~2,000 TPS.
- **Throughput drops by 80%.**

### How to measure this locally

**Latency measurement:**

1. Create test script measuring commit time for 10,000 transactions.
2. Baseline with semisync disabled: record average latency (e.g., 0.2 ms).
3. Enable
 semisync and re-measure: record average latency (e.g., 5 ms).
4. Calculate overhead: (5 - 0.2) / 0.2 * 100% = 2400%.

**Throughput measurement:**

```bash
sysbench oltp_prepare --mysql-host=localhost --db-size=1000000 prepare

# Baseline: async
SET GLOBAL rpl_semi_sync_source_enabled = OFF;
sysbench oltp_read_write --mysql-host=localhost --threads=16 --time=60 run
# Record TPS (e.g., 5,000)

# Test: semisync
SET GLOBAL rpl_semi_sync_source_enabled = ON;
sysbench oltp_read_write --mysql-host=localhost --threads=16 --time=60 run
# Record TPS (e.g., 800)
# Throughput reduction: (5000 - 800) / 5000 = 84%
```

**Status variable monitoring:**

```sql
SHOW STATUS LIKE 'Rpl_semi_sync%';
-- Rpl_semi_sync_source_yes_tx: transactions that received ack
-- Rpl_semi_sync_source_no_tx: transactions that timed out
-- Rpl_semi_sync_source_timeouted: timeout count
```

---

## 6. Candidate Figures

### Figure 1: Timeout Degradation Behavior

**What it shows:** When and how often semisync degrades to async due to timeout.

**Visual:** Timeline showing three parallel signals:
1. Semisync status (ON/OFF)
2. Timeout counter (Rpl_semi_sync_source_timeouted)
3. Replica lag (Seconds_Behind_Source)

During normal operation, status is ON, counter is stable, lag is low. At timeout trigger, status drops to OFF, counter increments, lag grows. When replica catches up, status returns to ON.

**Why valuable:** Demonstrates timeouts are real and detectable. Operators must monitor to catch silent failures of semisync guarantees.

---

### Figure 2: Commit Latency Cost (Async vs Semisync)

**What it shows:** Per-transaction latency overhead from semisynchronous replication.

**Visual:** Side-by-side latency histograms:
- Left (Asynchronous): tight distribution 0.1–0.5 ms, median ~0.2 ms, P99 < 1 ms.
- Right (Semisynchronous): broad distribution 3–20 ms, median ~5 ms, P99 ~15 ms.

**Why valuable:** Visually demonstrates the real durability cost. Shift in both median and tail shows semisync fundamentally changes latency profile.

---

### Figure 3 (Optional): Throughput Reduction

**What it shows:** Inverse relationship between latency cost and throughput capacity.

**Visual:** Dual-axis bar chart (TPS) + line graph (latency):
- Async bar: tall (5,000 TPS), latency point: 0.2 ms.
- Semisync bar: short (800 TPS), latency point: 5 ms.

**Why valuable:** Quantifies practical impact on application SLA. Helps decision-making on cost-benefit.

---

## Claims Requiring Live Topology Verification (for Ticket 10)

1. **Installation syntax is correct:**
   - INSTALL PLUGIN rpl_semi_sync_source SONAME 'semisync_source.dll' succeeds on source.
   - INSTALL PLUGIN rpl_semi_sync_replica SONAME 'semisync_replica.dll' succeeds on replica.
   - Both appear in INFORMATION_SCHEMA.PLUGINS with status ACTIVE.

2. **Semisync blocks correctly with AFTER_SYNC (default):**
   - Client blocks until replica acknowledges.
   - Replica relay log is flushed before source returns to client.
   - Other clients don't see transaction until committing client receives OK.

3. **AFTER_COMMIT creates phantom-read window:**
   - Transaction is visible to other clients before replica acknowledges.
   - Second client can read data first client committed.
   - If source crashes before replica ack, second client sees data lost after failover.

4. **Timeout degradation is detectable:**
   - When timeout is set < network RTT, transactions timeout and fall back to async.
   - Rpl_semi_sync_source_status changes from ON to OFF.
   - Rpl_semi_sync_source_timeouted counter increments.
   - Rpl_semi_sync_source_no_tx counter is non-zero.

5. **Latency cost is measurable locally:**
   - Async baseline: ~0.1–1 ms per commit.
   - Semisync: at least RTT + relay flush (~2–10 ms on LAN).
   - Throughput reduction is proportional.

6. **Failed source should not be reused:**
   - After failover to replica, old source cannot rejoin as replica.
   - Causes replication errors due to unacknowledged transactions in old source's binary log.

7. **Wait point configuration is dynamic:**
   - SET GLOBAL rpl_semi_sync_source_wait_point = 'AFTER_SYNC' takes immediate effect.
   - SET GLOBAL rpl_semi_sync_source_wait_point = 'AFTER_COMMIT' takes immediate effect.
   - No server restart required.
