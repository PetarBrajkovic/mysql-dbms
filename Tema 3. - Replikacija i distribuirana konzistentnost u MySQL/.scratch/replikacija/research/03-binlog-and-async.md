# The Binary Log, GTIDs, and Asynchronous Replication in MySQL 8.4

Research memo for ticket 03. Primary source: MySQL 8.4 Reference Manual (dev.mysql.com). All commands use 8.4 syntax (SOURCE/REPLICA terminology).

## 1. The Binary Log

### What It Records

The binary log is the primary data structure for MySQL replication. It records "events" that describe all modifications to database contents—table creation, data inserts, updates, deletes—as well as metadata about execution (statement execution time).

The binary log **does not** record SELECT or SHOW statements because they modify neither data nor schema. By default, it **does** record statements that *could* have made changes but matched no rows (e.g., `DELETE` matching 0 rows), though this behavior depends on the logging format.

**Two critical purposes:**
- **For replication:** The source's binary log is the stream that replicas pull from. Replicas request a copy, pull it independently, and apply it at their own pace.
- **For recovery:** After a backup is restored, events in the binary log recorded after the backup are re-executed to bring the database forward to a specific point in time.

Binary logging is **enabled by default** in MySQL 8.4 (the `log_bin` system variable defaults to ON), enabled through `--log-bin` startup option.

### Three Formats: STATEMENT, ROW, MIXED

**STATEMENT format (statement-based logging):**
- Records the actual SQL statements executed on the source.
- Compact: statements are small.
- Vulnerable to nondeterminism: if a statement produces different results on the replica, replication breaks.
- Example unsafe statements: those using `RAND()`, `NOW()`, `UUID()`, `ROW_COUNT()`, `LAST_INSERT_ID()` in certain contexts, or involving triggers with AUTO_INCREMENT.
- Set with: `--binlog-format=STATEMENT`

**ROW format (row-based logging):**
- Records the individual row changes: which rows were inserted, what the old/new values were.
- More verbose, but completely deterministic—the replica executes exactly the same physical changes.
- Not vulnerable to unsafe functions; `RAND()` and `NOW()` are evaluated once on the source and the results are logged.
- **Default in MySQL 8.4.**
- Set with: `--binlog-format=ROW`

**MIXED format (mixed logging):**
- Uses statement-based logging by default, **automatically switches to row-based** for unsafe statements.
- Combines compactness (safe statements) with reliability (unsafe statements are row-logged).
- Set with: `--binlog-format=MIXED`

Set the format via `--binlog-format=type` at startup (affects only the source); it does not activate logging, only configures it when active.

### Unsafe Statements for Statement-Based Replication

A statement is **safe** if it is deterministic and will produce identical results on the replica. It is **unsafe** if it is nondeterministic or depends on state that may differ.

**Characteristics that make a statement unsafe:**

1. **System functions that return different values on the replica:** `FOUND_ROWS()`, `GET_LOCK()`, `IS_FREE_LOCK()`, `IS_USED_LOCK()`, `LOAD_FILE()`, `RAND()`, `RELEASE_LOCK()`, `ROW_COUNT()`, `SESSION_USER()`, `SLEEP()`, `SOURCE_POS_WAIT()`, `SYSDATE()`, `SYSTEM_USER()`, `USER()`, `UUID()`, `UUID_SHORT()`.

2. **Nondeterministic functions NOT considered unsafe:** `CONNECTION_ID()`, `CURDATE()`, `CURRENT_DATE()`, `CURRENT_TIME()`, `CURRENT_TIMESTAMP()`, `CURTIME()`, `LAST_INSERT_ID()`, `LOCALTIME()`, `LOCALTIMESTAMP()`, `NOW()`, `UNIX_TIMESTAMP()`, `UTC_DATE()`, `UTC_TIME()`, `UTC_TIMESTAMP()`. These are treated as safe because MySQL preserves their evaluation results through replication.

3. **References to system variables:** Most system variables are not replicated correctly in statement-based format (exceptions listed in the MIXED format documentation).

4. **Loadable functions:** Treated as unsafe because their behavior is not under MySQL's control.

5. **Fulltext plugin usage:** May behave differently on different servers.

6. **Trigger or stored program updating AUTO_INCREMENT columns:** Order of row updates may differ source/replica.

7. **INSERT ... ON DUPLICATE KEY UPDATE on tables with multiple unique/primary keys:** The key-checking order is nondeterministic.

8. **UPDATE statements with LIMIT:** Row retrieval order is unspecified.

9. **Accesses to log tables:** Contents differ between source and replica.

10. **Nontransactional operations after transactional ones:** Mixing MyISAM writes after InnoDB transactions within the same transaction is unsafe.

11. **Accesses to self-logging tables:** All reads/writes to self-logging tables are unsafe.

12. **LOAD DATA statements:** Always treated as unsafe, logged as ROW when `binlog_format=MIXED`.

13. **XA transactions:** Unsafe in statement format due to potential locking dependencies.

14. **DEFAULT clause with nondeterministic function:** Evaluated at table definition, results may differ.

**When a statement is flagged as unsafe:**
- **STATEMENT format:** MySQL logs it anyway but issues a warning (logged to error log and sent to client).
- **MIXED format:** The statement is automatically switched to row-based logging (no warning if properly handled).
- **ROW format:** No distinction; all changes are row-logged.

### Why ROW Became the Default

**Historical:** MySQL replication was originally statement-based (STATEMENT format). As applications grew more complex, unsafe statements became common, leading to silent replication failures—the source and replica would diverge without obvious errors.

**Modern reason:**
- Row-based logging is completely deterministic: whatever the source did physically is replayed physically.
- Avoids the complexity of tracking which statements are safe vs. unsafe.
- Handles triggers, stored procedures, and complex applications correctly without edge cases.
- Smaller replicas scale better with row-based + multi-threaded appliers (can parallelize based on row access).
- GTID-based replication (MySQL 8.4 standard) is best used with row-based logging.

The trade-off is binary log file size—but disk is cheap, compression is available, and correctness is paramount.

### Binary Log Event Structure

The binary log consists of a series of **events**. Each event has:

1. **Timestamp:** When the event was logged (UTC seconds).
2. **Server ID:** Identifies the originating server (prevents circular replication issues).
3. **Event type:** Format description, table map, write rows, update rows, delete rows, query, GTID, etc.
4. **Event length:** Total size in bytes.
5. **Position:** Byte offset in the current log file.

**Common event types:**
- `Format_description_event`: Appears at the start of every binary log file; describes the binary log format version.
- `Previous_gtids_log_event`: Lists GTIDs already executed (for GTID mode).
- `Gtid_log_event`: Identifies the GTID of a transaction.
- `Table_map_event` (row events): Defines the table structure for subsequent row events.
- `Write_rows_event`: Insertion (row-based).
- `Update_rows_event`: Modification (row-based).
- `Delete_rows_event`: Deletion (row-based).
- `Query_event`: Statement-based DDL or DML.
- `Xid_event`: Marks InnoDB transaction commit.

### mysqlbinlog Output and Structure

**mysqlbinlog** is the utility for reading binary log files. It displays events in readable form.

**Default output (statement-based or format description events):**
```
# at 218
#080828 15:03:08 server id 1  end_log_pos 258   Write_rows: table id 17 flags: STMT_END_F

BINLOG '
fAS3SBMBAAAALAAAANoAAAAAABEAAAAAAAAABHRlc3QAAXQAAwMPCgIUAAQ=
fAS3SBcBAAAAKAAAAAIBAAAQABEAAAAAAAEAA//8AQAAAAVhcHBsZQ==
'/*!*/;
```

Fields:
- `# at NNN`: Byte offset in the binary log file where this event starts.
- `#YYMMDD HH:MM:SS`: Timestamp of the event (when logged).
- `server id N`: Server ID that originated this transaction.
- `end_log_pos NNN`: Byte position of the end of this event.
- `Event_type`: Name of the event.
- `BINLOG '...'`: Base-64 encoded binary data (the actual event bytes).

**With `--verbose` (or `-v`):**
Displays row events as pseudo-SQL comments (lines beginning with `###`):
```
# at 218
#080828 15:03:08 server id 1  end_log_pos 258   Write_rows: table id 17 flags: STMT_END_F
### INSERT INTO test.t
### SET
###   @1=1
###   @2='apple'
###   @3=NULL
```

**With `--verbose --verbose` (or `-vv`):**
Adds metadata for each column (data type, nullability, storage format):
```
### INSERT INTO test.t
### SET
###   @1=1 /* INT meta=0 nullable=0 is_null=0 */
###   @2='apple' /* VARSTRING(20) meta=20 nullable=0 is_null=0 */
###   @3=NULL /* DATE meta=0 nullable=1 is_null=1 */
```

**With `--base64-output=DECODE-ROWS`:**
Omits BINLOG statements for row events, showing only the pseudo-SQL comments.

---

## 2. Durability Knobs: sync_binlog, innodb_flush_log_at_trx_commit, and Two-Phase Commit

### The Problem: Crash Consistency

A crash (unexpected shutdown) can occur between when MySQL writes to memory buffers and when it writes to disk. Without proper durability settings, the source and replicas can diverge:

1. If a transaction commits in MySQL's memory but the binary log is not yet on disk, the replica never sees it.
2. If the binary log is on disk but the InnoDB redo log is not, the source will roll back the transaction on recovery while the replica already has it.

**Goal:** Ensure that either a transaction is committed everywhere (source binary log + InnoDB tables) or nowhere (neither).

### sync_binlog System Variable

Controls how often the binary log is synchronized to disk.

**sync_binlog = 0 (default before 8.0, NOT recommended for replication):**
- MySQL writes to the OS buffer but does not call `fsync()`. The OS decides when to flush to disk.
- **Risk:** OS crash or power loss can lose the last N committed transactions from the binary log.
- Replicas can be ahead of the source (replica has more data than source).

**sync_binlog = 1 (recommended, **DEFAULT in MySQL 8.4**):**
- MySQL calls `fsync()` after every commit group is written to the binary log.
- **Cost:** High: every commit triggers a disk I/O.
- **Benefit:** The binary log is always synchronized to disk; no transactions are lost due to OS-level crashes.

**sync_binlog = N (N > 1):**
- MySQL calls `fsync()` after every N commit groups.
- **Trade-off:** Reduces disk I/O at the cost of potentially losing up to N-1 commit groups.
- Not recommended for critical replication setups.

### innodb_flush_log_at_trx_commit System Variable

Controls how often InnoDB's redo log (in-memory log buffer) is synchronized to disk.

**innodb_flush_log_at_trx_commit = 0:**
- InnoDB redo log buffer is flushed to disk every ~1 second by a background thread (not per commit).
- **Risk:** At crash, up to 1 second of transactions may be lost from InnoDB, even though they are in the binary log.

**innodb_flush_log_at_trx_commit = 1 (recommended, **DEFAULT in MySQL 8.4**):**
- InnoDB redo log buffer is written to disk (`fsync()`) at every transaction commit.
- **Cost:** Synchronous disk I/O per commit.
- **Benefit:** Combined with `sync_binlog=1`, ensures crash-safe replication.

**innodb_flush_log_at_trx_commit = 2:**
- InnoDB redo log is written to disk but not `fsync()`-ed; OS decides when to flush.
- **Risk:** OS crash can lose recent transactions.

### Two-Phase Commit (XA) Between InnoDB and Binary Log

MySQL uses XA (extended atomicity) transactions to coordinate between InnoDB's redo log and the binary log.

**The sequence (with `sync_binlog=1` and `innodb_flush_log_at_trx_commit=1`):**

1. **Execute phase:** Transaction statements are executed, changes buffered in memory (InnoDB write set, binary log cache).

2. **Prepare phase:**
   - InnoDB prepares the transaction: writes redo log entries to the log buffer and calls `fsync()` to disk.
   - Transaction is marked as "prepared" (can be committed or rolled back).

3. **Commit phase:**
   - All pending transaction events are written to binary log buffer.
   - Binary log buffer is flushed to disk with `fsync()`.
   - InnoDB's commit record is written to redo log and flushed.
   - At this point, transaction is durable on disk in **both** InnoDB and binary log.

4. **Consistency:** If the server crashes:
   - On recovery, InnoDB scans the binary log to find the last valid (completely written) transaction position.
   - InnoDB completes any prepared transactions that are in the binary log.
   - The binary log is truncated to the last valid position.
   - **Result:** InnoDB state and binary log state are guaranteed to match.

This mechanism is **always enabled in MySQL 8.4** (`InnoDB` support for two-phase commit is implicit).

### Which Combinations Are Crash-Safe?

**Fully crash-safe (recommended for critical replicas):**
- `sync_binlog = 1`
- `innodb_flush_log_at_trx_commit = 1`
- Binary logging enabled on source; `log_bin = ON`
- InnoDB as storage engine for replicated tables
- Metadata repositories using InnoDB (`relay_log_info_repository = TABLE`)

**In this configuration:** At crash, no transactions are lost, and the replica's binary log, InnoDB tables, and replication progress metadata are all consistent.

**What is lost by each relaxation:**

1. **Setting `sync_binlog > 1` (or 0):**
   - Up to N-1 (or an unbounded) number of commit groups can be lost from the binary log at crash.
   - Replica can be ahead of the source; failover is unsafe.

2. **Setting `innodb_flush_log_at_trx_commit = 2`:**
   - Up to ~1 second of InnoDB data can be lost at crash (though binary log records them).
   - On recovery, the binary log and InnoDB tables are inconsistent.
   - Replica must re-sync with source.

3. **Setting `innodb_flush_log_at_trx_commit = 0`:**
   - Up to ~1 second of InnoDB data can be lost (worse than level 2).

4. **Disabling binary logging:**
   - No replication possible.
   - Recovery to a point in time is not possible.

**Typical trade-offs (not recommended except for non-critical scenarios):**
- `sync_binlog = 1000`, `innodb_flush_log_at_trx_commit = 2`: Reduced I/O, acceptable data loss risk (seconds).
- Used in high-transaction scenarios where slight replication lag is tolerable.

---

## 3. GTIDs: Global Transaction Identifiers

### What a GTID Is

A **Global Transaction Identifier (GTID)** is a unique label assigned to each transaction committed on the source server. It serves as a "commitment certificate" that follows the transaction throughout the replication topology.

**Format:**
```
source_uuid:transaction_id
```

Where:
- `source_uuid`: The [`server_uuid`](replication-options.html#sysvar_server_uuid) of the server where the transaction originated (a 128-bit UUID, globally unique). Example: `73f86016-978b-11ee-ade5-8d2a2a562feb`.
- `transaction_id`: A monotonically increasing sequence number (1, 2, 3, ...) assigned to each client transaction committed on that source. **Cannot be 0.**

**Example:** `73f86016-978b-11ee-ade5-8d2a2a562feb:23` = the 23rd transaction committed on the source with UUID `73f86016-978b-11ee-ade5-8d2a2a562feb`.

**Tagged GTIDs (MySQL 8.4 enhancement):**
```
source_uuid:tag:transaction_id
```
The `tag` is a user-defined string (e.g., `Domain_1`, `Domain_2`) to group transactions by application or data domain. Example: `73f86016-978b-11ee-ade5-8d2a2a562feb:Domain_1:23`.

### GTID Assignment: Client vs. Replicated Transactions

**Client transaction (committed on the source):**
- Assigned a **new GTID** when committed (if binary logging is enabled and the transaction is not filtered out).
- GTIDs are monotonically increasing without gaps.
- If a transaction is read-only or filtered by `--binlog-ignore-db`, it is **not assigned a GTID**.

**Replicated transaction (applied on a replica):**
- **Retains the original GTID** from the source.
- The GTID is persisted even if:
  - The transaction is not written to the replica's binary log.
  - The transaction is filtered out (not applied).
- Stored in the `mysql.gtid_executed` system table.

### gtid_executed vs. gtid_purged

**`gtid_executed` (global system variable):**
- A **GTID set** (list of all GTIDs that have been committed on this server).
- Contains all GTIDs from:
  - Client transactions committed on this server (if it's a source).
  - Replicated transactions applied on this server (if it's a replica).
- Updated at transaction commit time.
- Stored persistently in:
  - The binary log (when binary logging is ON).
  - The `mysql.gtid_executed` table (always, for recovery after binary log purge).
- **View it:** `SHOW VARIABLES LIKE 'gtid_executed';` or `SELECT @@GLOBAL.gtid_executed;`

**`gtid_purged` (global system variable):**
- A **GTID set** of transactions that have been purged from the binary log and cannot be retrieved.
- Subset of `gtid_executed` (any GTID in `gtid_purged` is also in `gtid_executed`).
- Updated only when:
  - `PURGE BINARY LOGS` is executed.
  - `RESET BINARY LOGS AND GTIDS` is executed.
- **Purpose:** Informs replicas of "dead" GTIDs that they should not try to re-request from the source.
- **View it:** `SHOW VARIABLES LIKE 'gtid_purged';` or `SELECT @@GLOBAL.gtid_purged;`

**Example:**
```
gtid_executed: 73f86016-978b-11ee-ade5-8d2a2a562feb:1-100
gtid_purged:   73f86016-978b-11ee-ade5-8d2a2a562feb:1-50
```
Meaning: Transactions 1–100 have been committed; transactions 1–50 are gone from binary logs.

### GTID-Based Positioning vs. File-and-Offset Positioning

**File-and-offset (traditional, pre-GTID):**
- Replica knows its position by file name and byte offset: `binlog-file.000003:1045`.
- Position is relative to the source's binary log.
- **Problem:** If the source is lost and a new source is promoted, the file/offset becomes meaningless (different source has different log files).
- **Problem:** Finding the correct position for failover is manual and error-prone.

**GTID-based positioning:**
- Replica knows its position by the GTIDs it has applied: `73f86016-978b-11ee-ade5-8d2a2a562feb:1-100, 8d2a2a58-1234-...:1-50`.
- GTIDs are **source-agnostic**: they follow the transaction regardless of which server is the source.
- **Benefit:** Failover is automatic—any replica can be promoted to source without manual position calculation.
- **Benefit:** A replica can switch sources safely (as long as all needed GTIDs are available).

**Example transition:**
1. Source A is running; replicas B and C lag it.
2. Source A crashes; B and C have `gtid_executed = A:1-100`.
3. Promote B to be the new source.
4. C can connect to B (new source) and request GTIDs B already has (via `gtid_executed`).
5. B applies any missing GTIDs from A that it hasn't applied yet, then B's own new commits.
6. C's `gtid_executed` grows from `A:1-100` to `A:1-100, B:1-N` automatically.

### What GTID Makes Possible: AUTO_POSITION and Failover

**AUTO_POSITION (`SOURCE_AUTO_POSITION = 1`):**

In GTID replication, the replica doesn't need to know the exact binary log file/offset. Instead:

1. Replica connects to source and sends its `gtid_executed` (all GTIDs it has applied).
2. Source compares: "Here are the GTIDs you have. I have GTIDs 1-150. I'll send you 101-150."
3. Replica receives only the missing GTIDs.
4. No gaps, no missed events, no manual position calculation.

**Enables automatic failover and scaleout:**
- **Failover:** On source crash, promote a replica: it continues from its `gtid_executed` automatically.
- **Replica cloning:** A replica can be provisioned from a backup + binary logs without calculating exact positions.
- **Multi-source:** A replica can pull from multiple sources; GTIDs ensure no transaction is applied twice (auto-skip).

**File/offset positioning requires manual intervention:**
- Must find the exact binary log position of the old source.
- If position is wrong, replication skips data or duplicates it.
- Failover requires operator to manually calculate and set positions.

---

## 4. The Replication Threads

MySQL replication involves three main thread types, coordinating between source and replica.

### Replication I/O (Receiver) Thread

**Where it runs:** On the replica.

**What it does:**
1. Connects to the source server.
2. Requests the source's binary log, starting from a specified position (file/offset or GTID).
3. Continuously reads events from the source's binary log as they are generated.
4. Writes each received event to the replica's **relay log** (a local binary log-like file).
5. Updates the **connection metadata repository** (`mysql.slave_master_info` table) with the current read position.

**Output/state:**
- Relay log file(s) on the replica.
- Position in `mysql.slave_master_info`.
- Shown in `SHOW REPLICA STATUS` as `Replica_IO_Running` (Yes/No/Connecting).

**Where lag is generated:**
- If the source is receiving writes faster than the receiver thread can pull and write to disk, events accumulate in the relay log.
- High network latency or slow relay log disk writes cause the receiver to fall behind.

### Relay Log

**What it is:**
- A local binary log on the replica.
- Has the **same format** as the source's binary log (same event structure).
- Contains a copy of the source's binary log events (filtered by replication rules if configured).

**Purpose:**
- Decouples the I/O thread (pulling from source) from the SQL thread (applying to database).
- Allows the replica to keep up with the source in pulling events, even if applying is slow.
- Enables recovery: if a replica crashes, the relay log preserves unapplied events; on restart, the SQL thread continues from where it left off.

**Metadata:**
- File naming: `replica-relay-bin.000001`, `replica-relay-bin.000002`, etc.
- Position within file: byte offset where the SQL thread has read/applied.
- Stored in `mysql.slave_relay_log_info` table.

### Replication SQL (Applier) Thread

**Where it runs:** On the replica.

**What it does:**
1. Reads events from the relay log sequentially.
2. For each event, executes it on the replica's database (INSERT, UPDATE, DELETE, DDL, etc.).
3. Updates the **applier metadata repository** (`mysql.slave_relay_log_info` table) with the current applied position.
4. **Crucially:** Commits updates to the applier metadata together with the transaction commit, ensuring atomic consistency.

**Output/state:**
- Replica's database state (same as source, ideally
---

## 5. Setting Up a Two-Node Topology from Scratch

This procedure establishes a source-replica pair with GTIDs and asynchronous replication. Uses MySQL 8.4 syntax exclusively.

### Prerequisites

- Two MySQL 8.4 servers installed and running.
- **Source**: can accept connections.
- **Replica**: can connect to source.
- Network connectivity between them.

### Step 1: Configure the Source Server

**1a. Set server_id (unique per server):**

Add to source's config file (`/etc/mysql/my.cnf` or `~/.my.cnf`):
```ini
[mysqld]
server_id = 1
log_bin = /var/log/mysql/mysql-bin
binlog_format = ROW
gtid_mode = ON
enforce_gtid_consistency = ON
sync_binlog = 1
```

Or via SQL (if not in config file):
```sql
SET @@GLOBAL.server_id = 1;
SET @@GLOBAL.gtid_mode = OFF;  -- may be needed to change if gtid_mode was different
SET @@GLOBAL.gtid_mode = ON;   -- enable GTID mode
SET @@GLOBAL.enforce_gtid_consistency = ON;
```

**Note:** `server_id` must be restarted to take effect; `gtid_mode` changes may require restart depending on current state. Safest: set both in config and restart.

**1b. Create a replication user (on the source):**
```sql
CREATE USER 'repl'@'replica-host' IDENTIFIED BY 'password';
GRANT REPLICATION SLAVE ON *.* TO 'repl'@'replica-host';
FLUSH PRIVILEGES;
```

Or with a more specific host:
```sql
CREATE USER 'repl'@'192.168.1.100' IDENTIFIED BY 'strong_password';
GRANT REPLICATION SLAVE ON *.* TO 'repl'@'192.168.1.100';
```

**1c. Verify source is ready:**
```sql
SHOW MASTER STATUS;  -- shows current binary log file and position
SHOW VARIABLES LIKE 'server_id';
SHOW VARIABLES LIKE 'gtid_mode';
SHOW VARIABLES LIKE 'enforce_gtid_consistency';
```

Output should show:
- `log_bin` = ON
- `gtid_mode` = ON
- `server_id` > 0
- `enforce_gtid_consistency` = ON

### Step 2: Configure the Replica Server

**2a. Set server_id (unique, different from source):**

Add to replica's config file:
```ini
[mysqld]
server_id = 2
log_bin = /var/log/mysql/mysql-bin
binlog_format = ROW
gtid_mode = ON
enforce_gtid_consistency = ON
sync_binlog = 1
innodb_flush_log_at_trx_commit = 1
relay_log_info_repository = TABLE
relay_log_recovery = ON
```

Restart the replica server.

**2b. Verify replica is ready:**
```sql
SHOW VARIABLES LIKE 'server_id';
SHOW VARIABLES LIKE 'gtid_mode';
```

### Step 3: Take a Fresh Backup (Optional but Recommended)

If the source already has data:
- Take a backup of the source using `mysqldump` (fastest for new topologies):
  ```bash
  mysqldump -u root -p --all-databases --single-transaction --quick \
    --source-data=2 > backup.sql
  ```
- Or use Percona XtraBackup for large datasets.
- Restore on the replica:
  ```bash
  mysql -u root -p < backup.sql
  ```

If starting fresh (empty databases), skip this step.

### Step 4: Configure Replica to Use Source (CHANGE REPLICATION SOURCE TO)

**On the replica, execute:**
```sql
STOP REPLICA;  -- if it's already running

CHANGE REPLICATION SOURCE TO
  SOURCE_HOST = 'source-host',
  SOURCE_USER = 'repl',
  SOURCE_PASSWORD = 'password',
  SOURCE_AUTO_POSITION = 1;
```

Replace:
- `source-host`: hostname or IP of source (e.g., `192.168.1.50`, `source.example.com`).
- `password`: the password set for the `repl` user.

**If using file/offset positioning instead of GTID (not recommended, but for reference):**
```sql
CHANGE REPLICATION SOURCE TO
  SOURCE_HOST = 'source-host',
  SOURCE_USER = 'repl',
  SOURCE_PASSWORD = 'password',
  SOURCE_LOG_FILE = 'mysql-bin.000003',    -- from SHOW MASTER STATUS
  SOURCE_LOG_POS = 1045;
```

### Step 5: Start the Replica and Verify

**Start replication:**
```sql
START REPLICA;
```

**Check status:**
```sql
SHOW REPLICA STATUS\G  -- \G for vertical output
```

**Key fields to examine:**

| Field | Expected Value |
|-------|---|
| `Replica_IO_Running` | Yes |
| `Replica_SQL_Running` | Yes |
| `Seconds_Behind_Source` | 0 (once caught up) |
| `Replica_IO_State` | "Waiting for source to send event" |
| `Retrieved_Gtid_Set` | Same or superset of source's GTIDs |
| `Executed_Gtid_Set` | Same as source once caught up |
| `Auto_Position` | 1 (if using GTID auto-positioning) |
| `Last_Error` | (empty) |
| `Last_IO_Error` | (empty) |
| `Last_SQL_Error` | (empty) |

**If errors occur:**
- Check firewall rules (port 3306 or custom).
- Verify `repl` user exists and has REPLICATION SLAVE privilege.
- Check source's error log for connection issues.
- Verify `gtid_mode` is ON on both servers.

### Step 6: Verify Replication is Working

**On source, insert test data:**
```sql
CREATE DATABASE test_repl;
USE test_repl;
CREATE TABLE t (id INT AUTO_INCREMENT PRIMARY KEY, msg VARCHAR(100));
INSERT INTO t (msg) VALUES ('hello'), ('world');
COMMIT;
```

**On replica, verify data appeared:**
```sql
USE test_repl;
SELECT * FROM t;
```

Should see the inserted rows.

**Check GTID status:**
```sql
SHOW VARIABLES LIKE 'gtid_executed';
SHOW VARIABLES LIKE 'gtid_purged';
```

Both should show the same GTID range (source's UUID plus transaction numbers).

### Essential SHOW REPLICA STATUS Fields

These are the fields that actually indicate health and status:

1. **`Replica_IO_Running`:** Is the receiver thread pulling from source? `Yes` = connected, `Connecting` = trying to connect, `No` = stopped.
2. **`Replica_SQL_Running`:** Is the applier thread applying transactions? `Yes` = running, `No` = stopped.
3. **`Seconds_Behind_Source`:** Lag in seconds. 0 = caught up. NULL = thread stopped or no events being processed.
4. **`Executed_Gtid_Set`:** All GTIDs this replica has applied (should match source once caught up).
5. **`Retrieved_Gtid_Set`:** All GTIDs this replica has **received** (always >= Executed).
6. **`Last_Error`, `Last_IO_Error`, `Last_SQL_Error`:** Error messages. Should be empty if healthy.
7. **`Source_Host`, `Source_Port`, `Source_User`:** Connection parameters to source.
8. **`Auto_Position`:** 1 if using GTID auto-positioning (recommended).
9. **`Read_Source_Log_Pos`, `Exec_Source_Log_Pos`:** Current read/executed position in source's binary log (informational; less important with GTID).
10. **`Relay_Log_File`, `Relay_Log_Pos`:** Position in relay log (where applier is reading from).

**Less critical fields (mostly informational):**
- `Relay_Source_Log_File`, `Relay_Log_Space`: Relay log metadata.
- `Skip_Counter`: For SQL_REPLICA_SKIP_COUNTER (advanced troubleshooting).
- `Replicate_Do_DB`, `Replicate_Ignore_DB`: Database filters.
- SSL-related fields: Only relevant if using encrypted replication.

---

## 6. Candidate Measurements and Figures

### Visible, Measurable Facts (Not Settings Tables)

#### Replication Lag
- **Metric:** `Seconds_Behind_Source` from `SHOW REPLICA STATUS`.
- **Measurement:** Run `SHOW REPLICA STATUS\G` every N seconds, parse `Seconds_Behind_Source`.
- **Visible demonstration:** Insert rows with timestamps on source, observe delay in appearing on replica.
- **Graph:** Time series of lag over minutes/hours.

#### Binary Log Size Over Time
- **Metric:** Total size of binary log files on source.
- **Measurement:** Monitor disk space used by `/var/log/mysql/mysql-bin.*` over time.
- **Visible:** Compare purge rate vs. write rate; show how long it takes to fill 1 GB, 10 GB, etc.
- **Graph:** Cumulative binary log size over hours.

#### Relay Log Accumulation
- **Metric:** Size of relay log files on replica.
- **Measurement:** Monitor `/var/log/mysql/replica-relay-bin.*` size; indicates how far behind receiver thread is vs. applier thread.
- **Visible:** If relay log grows, applier is slower than receiver (I/O thread pulling faster than SQL thread applying).
- **Graph:** Relay log size over time; spikes = applier lag.

#### Transaction Throughput
- **Metric:** Transactions per second (TPS) on source vs. replica.
- **Measurement:** Use `SHOW GLOBAL STATUS LIKE 'Threads_connected'`, `Innodb_rows_inserted`, etc.
- **Visible:** Compare TPS source vs. replica; shows if replica is keeping up.
- **Graph:** Source TPS vs. Replica TPS (should be similar if lag is stable).

#### GTID Position Drift
- **Metric:** `Executed_Gtid_Set` gap between source and replica.
- **Measurement:**
  - On source: `SELECT @@GLOBAL.gtid_executed;`
  - On replica: `SELECT @@GLOBAL.gtid_executed;`
  - Compare (replica's should be >= source's when caught up).
- **Visible:** Show replicas at GTID `1-100` while source is at `1-150`; 50 GTIDs behind.
- **Graph:** GTID transaction count source vs. replica over time.

#### Connection Status Timeline
- **Visible:** Capture `Replica_IO_State` every second during a failover or network hiccup.
  - "Connecting to source" → "Reading event from the source" → "Waiting for source to send event"
  - Shows state transitions.

#### Event Propagation Latency
- **Measurement:** Timestamp an INSERT on source, measure when it appears on replica.
  - Use row's creation timestamp vs. current clock.
  - For row-based logging with `--verbose`, examine event timestamps.
- **Visible:** Show `mysqlbinlog` output with timestamps; measure wall-clock time for event to reach replica.

#### Multi-Threaded Applier Speedup
- **Metric:** Replica lag with `replica_parallel_workers = 0` vs. `replica_parallel_workers = 4`.
- **Measurement:** Let source load 1M rows; measure time to replicate on single-threaded vs. multi-threaded.
- **Visible:** Show lag dropping by 2–4x with parallel workers (assuming workload is parallelizable).

---

## Claims Needing Live Verification (Ticket 10)

1. **Binary log format:** `ROW` is the default in MySQL 8.4 when `log_bin=ON` and no `--binlog-format` option is given.

2. **STATEMENT format unsafety:** A statement using `RAND()` in a WHERE clause produces different results on source vs. replica when `binlog_format=STATEMENT`.

3. **Durability combination:** With `sync_binlog=1`, `innodb_flush_log_at_trx_commit=1`, and InnoDB storage, a transaction committed on the source is never lost after a crash (binary log and InnoDB remain consistent).

4. **GTID auto-skip:** A replica with `gtid_mode=ON` will skip (auto-ignore) any transaction with a GTID already in `gtid_executed`, even if the relay log contains it.

5. **AUTO_POSITION simplification:** With `SOURCE_AUTO_POSITION=1`, the replica does not need to know the source's binary log file name or position; GTID auto-positioning handles position calculation.

6. **Two-phase commit:** With `sync_binlog=1` and `innodb_flush_log_at_trx_commit=1`, a crash between the binary log fsync and InnoDB commit does not leave the source and replicas inconsistent; recovery reconciles them.

7. **I/O thread bottleneck indicator:** When `Relay_Log_Space` grows while `Seconds_Behind_Source` is constant or increasing, the applier thread (not the receiver) is the bottleneck.

8. **SQL thread is typical bottleneck:** In high-write scenarios, the single-threaded SQL applier is the first bottleneck (replica lag accumulates) before network/disk.

9. **Multi-threaded applier:** With `replica_parallel_workers=4` and `replica_preserve_commit_order=ON`, independent transactions (different tables/rows) apply in parallel, reducing lag by ~2–4x (workload-dependent).

10. **Relay log recovery:** After an unexpected replica halt, with `relay_log_recovery=ON` and `relay_log_info_repository=TABLE`, the replica automatically resumes from the last applied GTID without manual intervention.

11. **SHOW REPLICA STATUS field meanings:**
    - `Replica_IO_Running=Yes` means receiver thread is connected and pulling from source.
    - `Replica_SQL_Running=Yes` means applier thread is executing transactions from relay log.
    - `Seconds_Behind_Source=0` means applier is caught up (not that receiver is caught up).
    - `Retrieved_Gtid_Set >= Executed_Gtid_Set` always (receiver ahead of or equal to applier).

12. **File position mode:** Without GTIDs (`gtid_mode=OFF`), setting up a replica requires manually specifying `SOURCE_LOG_FILE` and `SOURCE_LOG_POS` from `SHOW MASTER STATUS` output; failover requires recalculating positions per replica.

13. **GTID mode incompatibility:** Once `gtid_mode=ON` is set, statements using `IGNORE_SERVER_IDS` in `CHANGE REPLICATION SOURCE TO` are rejected (GTIDs auto-skip duplicates).

14. **Row vs. STATEMENT crashes:** A row-based replicated INSERT (logged as individual row changes) is always consistent after crash, while a STATEMENT-based INSERT using `RAND()` can produce different row counts source vs. replica if crash occurs mid-execution.

15. **mysqlbinlog `-v` output:** The pseudo-SQL comments (lines starting with `###`) in `mysqlbinlog -v` output accurately represent the rows modified but use `@1, @2, ...` column references instead of original column names.

---

End of research memo. All commands and examples use MySQL 8.4 syntax (SOURCE/REPLICA). All findings derived from MySQL 8.4 Reference Manual (dev.mysql.com).
