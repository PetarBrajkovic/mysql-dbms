# Research: Group Replication, quorum, and multi-primary

## 1. What Group Replication Actually Is

Group Replication is a plugin for MySQL that implements fault-tolerant, highly-available replication through a group communication system. It consists of three core components:

**The Group Communication System (XCom):** Group Replication builds on XCom (eXtended COMmunications), a homegrown Paxos variant consensus protocol. XCom is responsible for:
- **Ordered delivery**: Guarantees all members receive the same transactions in the same order (total order broadcast)
- **Dynamic membership**: Manages entry and exit of group members
- **Failure detection**: Identifies and ejects failed members

XCom uses a multi-proposer variant of Paxos to avoid bottlenecking on a single leader. Each member owns reserved slots in the message stream (`g * n + member_id` where g is group size and n is a counter), allowing members to propose transactions independently to their own slots. This avoids the scalability problems of single-leader Paxos.

**What a Group Agrees On:** The group reaches consensus on:
1. Which transactions should be ordered in the total order
2. Who the current group members are (view changes)
3. Which member is the primary (in single-primary mode)

**Transaction Flow from Client to Commit:**
1. Client issues a read/write transaction to any member
2. The member executes the transaction optimistically, creating a write-set (row identifiers that were updated)
3. At commit time, the member atomically broadcasts the write-set to all members via XCom's total order protocol
4. All members receive the write-set in the same order; certification checks if it conflicts with concurrent transactions
5. If certified (no conflicts), all members commit the transaction to their own data
6. If conflict detected, only the originating server rolls back the transaction; other members drop it
7. The client receives acknowledgment from the originating member once certified

[Source](https://dev.mysql.com/doc/refman/8.4/en/group-replication-summary.html)

---

## 2. Certification-Based Conflict Detection

**The Mechanism:** Certification is a row-level conflict detection algorithm that compares write-sets. When a read/write transaction is ready to commit:
- Its write-set (the set of unique row identifiers it modified) is extracted
- This is compared against write-sets of all other in-flight transactions across the group
- If two concurrent transactions (executed on different members) modified the same row, a conflict exists

**Why It's Optimistic:** Transactions execute without prior coordination. Members do not require group approval before execution — they optimistically commit, then check conflicts at broadcast time. This avoids the round-trip latency of pessimistic locking but requires rollback capability.

**Write-Set Definition:** The write-set is the set of unique row identifiers (primary key values) that a transaction modified. Group Replication requires every table in a replicated database to have a primary key or primary key equivalent (non-null unique key) so rows can be uniquely identified for conflict detection.

**Conflict Resolution (First-Commit-Wins):** When two transactions conflict:
- The transaction ordered first by Paxos consensus commits on all members
- The transaction ordered second is rolled back on its originating server and dropped by all other servers
- Example: if t1 and t2 both modify row X, and t2 is ordered before t1 in the consensus, t2 wins and t1 is rolled back on its origin

**Why This Matters for Multi-Primary:** Certification makes multi-primary possible because:
- Multiple members can accept writes without pre-coordination
- Conflicts are detected and resolved deterministically across the group
- No split-brain is possible because Paxos consensus determines a total order, and all members apply the same order
- The database eventually converges

[Source](https://dev.mysql.com/doc/refman/8.4/en/group-replication-summary.html)

---

## 3. Quorum: Majority Rule and Minority Partition Behavior

**Why a Majority:** Group Replication requires a majority (quorum) of members to be reachable to proceed. This is the fundamental principle from distributed consensus: only a majority can make coordinated decisions without risk of two isolated groups (split-brain).

**Minority Partition Behavior:** When a member (or group of members) loses contact with a majority:
- It **cannot commit new transactions**. Read-only queries are still served, but reads may return stale data.
- It does **not diverge**. The minority members enter an ERROR state and transactions block, waiting for quorum recovery.
- They are **not expelled automatically** unless a timeout is configured.

**Quorum Loss Timeout (`group_replication_unreachable_majority_timeout`):** By default, no timeout. To automate:
- Set `group_replication_unreachable_majority_timeout` to seconds
- After losing majority contact for this duration, the member enters ERROR state
- All pending transactions in the minority are rolled back
- The member then follows the exit action policy

**Exit State Action (`group_replication_exit_state_action`):** When a member is expelled or times out in a minority:
- `READ_ONLY` (default): Sets `super_read_only=ON`, allowing stale reads but preventing writes
- `OFFLINE_MODE`: Sets `offline_mode=ON` and `super_read_only=ON`. Disconnects existing clients
- `ABORT_SERVER`: Shuts down MySQL entirely

**Split-Brain in Group Replication:** Unlike traditional multi-leader systems:
- Split-brain is **prevented by quorum rule** — only the majority partition can write
- The minority partition is **blocked, not diverged**

[Sources](https://dev.mysql.com/doc/refman/8.4/en/group-replication-responses-failure-partition.html)

---

## 4. Single-Primary vs Multi-Primary Mode

**Single-Primary Mode (Default, `group_replication_single_primary_mode=ON`):**
- Exactly one member is designated PRIMARY and set to read/write mode
- All other members are SECONDARY and set to `super_read_only=ON`
- Primary is elected automatically if the current primary fails
- Writes go only to the primary; reads can load-balance across secondaries
- **Default because**: Simpler to reason about, no multi-writer conflicts, DDL is safe

**Multi-Primary Mode (`group_replication_single_primary_mode=OFF`):**
- All members can be read/write, even if writes are concurrent
- Any member can accept writes; conflicts are resolved via certification
- No automatic primary election

**Concrete Restrictions in Multi-Primary Mode:**

1. **Foreign Keys with Cascading Actions:** Transactions with foreign key cascades are rejected at commit time. Why: a cascading action on one member might affect rows that another concurrent transaction is modifying.

2. **SERIALIZABLE Isolation Level:** Transactions at `SERIALIZABLE` isolation fail at commit when synchronizing with the group. Why: SERIALIZABLE requires range locks, which cannot be distributed across the group without pessimistic locking.

3. **Concurrent DDL:** Data definition statements implicitly commit any active transaction. In multi-primary, if schema changes and data changes for the same table occur on different members concurrently, inconsistency can result.

**Honest Verdict on Multi-Primary:** Multi-primary is operationally justified only when high write availability is critical and the workload has few conflicts. For most deployments, single-primary with automatic failover is simpler and safer.

[Sources](https://dev.mysql.com/doc/refman/8.4/en/group-replication-single-primary-mode.html)

---

## 5. Consistency Levels and Their Mapping to Named Models

`group_replication_consistency` controls how transactions synchronize across the group.

### EVENTUAL
- **What it waits for:** Nothing
- **Distributed model:** Eventual Consistency

### BEFORE_ON_PRIMARY_FAILOVER
- **What it waits for:** After primary election, transactions wait until the new primary applies backlog from old primary
- **Distributed model:** Eventual Consistency with strong failover guarantees

### BEFORE
- **What it 

---

## 6. Licensing and Community Availability

**All core components are Community Edition (GPL):**
- MySQL Group Replication: Free, included in all MySQL 8.4 Community distributions
- InnoDB Cluster: Free, built on top of Group Replication
- MySQL Shell: Free, the administrative tool for InnoDB Cluster
- MySQL Router: Free, the connection router and failover proxy

**Nothing is restricted to Enterprise Edition.**

[Source](https://www.mysql.com/products/community/)

---

## 7. Standing Up a Three-Member Group on One Host (Windows)

### 7a. Manual Configuration Path

**Step 1: Initialize Three Data Directories**

```bash
mysql-8.4\bin\mysqld --initialize-insecure --basedir=%CD%\mysql-8.4 --datadir=%CD%\data\s1
mysql-8.4\bin\mysqld --initialize-insecure --basedir=%CD%\mysql-8.4 --datadir=%CD%\data\s2
mysql-8.4\bin\mysqld --initialize-insecure --basedir=%CD%\mysql-8.4 --datadir=%CD%\data\s3
```

**Step 2: Create Configuration Files**

**For s1 (s1.ini):**
```ini
[mysqld]
disabled_storage_engines="MyISAM,BLACKHOLE,FEDERATED,ARCHIVE,MEMORY"
server_id=1
gtid_mode=ON
enforce_gtid_consistency=ON
plugin_load_add='group_replication.so'
group_replication_group_name="aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
group_replication_start_on_boot=off
group_replication_local_address="127.0.0.1:24901"
group_replication_group_seeds="127.0.0.1:24901,127.0.0.1:24902,127.0.0.1:24903"
group_replication_bootstrap_group=off
datadir=C:\path\to\data\s1
basedir=C:\path\to\mysql-8.4
port=24801
report_host=127.0.0.1
```

**For s2 and s3:** Change `server_id`, `port`, `datadir`, and `group_replication_local_address` accordingly.

**Step 3: Start All Three Instances**

```bash
mysql-8.4\bin\mysqld --defaults-file=s1.ini
mysql-8.4\bin\mysqld --defaults-file=s2.ini
mysql-8.4\bin\mysqld --defaults-file=s3.ini
```

**Step 4: Bootstrap the Group (on s1)**

```bash
mysql -u root -h 127.0.0.1 -P 24801

mysql> SET GLOBAL group_replication_bootstrap_group=ON;
mysql> START GROUP_REPLICATION;
mysql> SET GLOBAL group_replication_bootstrap_group=OFF;
```

**Step 5: Create Replication User (on s1)**

```sql
CREATE USER rpl_user@'%' IDENTIFIED BY 'password';
GRANT REPLICATION SLAVE ON *.* TO rpl_user@'%';
GRANT CONNECTION_ADMIN ON *.* TO rpl_user@'%';
GRANT BACKUP_ADMIN ON *.* TO rpl_user@'%';
GRANT GROUP_REPLICATION_STREAM ON *.* TO rpl_user@'%';
FLUSH PRIVILEGES;
```

**Step 6: Add s2 and s3**

Connect to s2 (port 24802):
```sql
SET SQL_LOG_BIN=0;
CREATE USER rpl_user@'%' IDENTIFIED BY 'password';
GRANT REPLICATION SLAVE ON *.* TO rpl_user@'%';
GRANT CONNECTION_ADMIN ON *.* TO rpl_user@'%';
GRANT BACKUP_ADMIN ON *.* TO rpl_user@'%';
GRANT GROUP_REPLICATION_STREAM ON *.* TO rpl_user@'%';
FLUSH PRIVILEGES;
SET SQL_LOG_BIN=1;
START GROUP_REPLICATION USER='rpl_user', PASSWORD='password';
```

Repeat the same for s3 (port 24803).

**Step 7: Verify**

```sql
SELECT * FROM performance_schema.replication_group_members;
```

Should show three ONLINE members.

[Source](https://dev.mysql.com/doc/refman/8.4/en/group-replication-deploying-locally.html)

### 7b. MySQL Shell dba.createCluster() Path

**Step 1-3:** Same as manual configuration (initialize and start instances).

**Step 4: Connect MySQL Shell to s1**

```bash
mysqlsh --uri root@localhost:24801
```

**Step 5: Create the Cluster**

```javascript
mysql-js> dba.createCluster('testCluster')
```

MySQL Shell will automatically validate the instance, configure Group Replication, bootstrap the group, and create metadata tables.

**Step 6: Add Instances**

```javascript
mysql-js> cluster.addInstance('root@127.0.0.1:24802')
mysql-js> cluster.addInstance('root@127.0.0.1:24803')
```

MySQL Shell will prompt for passwords and configure each instance automatically.

**Step 7: Verify**

```javascript
mysql-js> cluster.status()
```

### Which Path is More Likely to Work on Windows?

**The dba.createCluster() path is more robust on Windows because:**

1. Handles all configuration automatically without manual INI file errors
2. Creates admin users and sets all required privileges (including GROUP_REPLICATION_STREAM, which manual config often misses)
3. Validates instance compatibility before applying changes
4. Detects and resolves loopback interface issues (common on Windows)
5. Avoids file path and INI parsing issues that Windows sometimes introduces
6. Validates configuration end-to-end before returning success

**Recommendation:** Use **dba.createCluster()** for any Windows deployment. It is the official path endorsed by Oracle and handles the operational complexity and Windows-specific issues that the manual path requires.

---

## 8. Candidate Figures and Staging Quorum Loss Locally

**Candidate Figures:**

1. **Three-Member Group with Quorum:** Diagram showing three members (s1, s2, s3) forming a majority. Label: "Majority can commit transactions. Consensus achieved."

2. **Minority Member Blocked:** Same three-member group, partitioned. Two members (s1, s2) isolated from s3. Label: "Minority member (s3) cannot commit new transactions. Reads return stale data. No data divergence. Waiting for reconnection or timeout."

3. **Transaction Certification Flow:** Client → Member Execute → Write-set Extraction → XCom Broadcast (Total Order) → Certification (Conflict Detection) → Commit or Rollback → Response to Client.

4. **Consistency Levels Timeline:** A timeline diagram showing:
   - Local Commit Point
   - XCom Broadcast Point
   - Application on Other Members Point
   - Response to Client Point
   - Annotations showing where BEFORE, AFTER, BEFORE_AND_AFTER waits occur

5. **Paxos Slot Allocation (XCom Multi-Proposer):** Diagram of the message stream showing slots allocated to each member: member 0 gets 0, 3, 6, 9...; member 1 gets 1, 4, 7, 10...; member 2 gets 2, 5, 8, 11.... Show how this allows parallel proposing.

**Staging Quorum Loss Locally (by stopping members, not partitioning network):**

1. **Start three members** all ONLINE:
```bash
mysql-8.4\bin\mysqld --defaults-file=s1.ini
mysql-8.4\bin\mysqld --defaults-file=s2.ini
mysql-8.4\bin\mysqld --defaults-file=s3.ini
```

2. **Stop s2 and s3 gracefully:**
```bash
mysql -u root -h 127.0.0.1 -P 24802 -e "STOP GROUP_REPLICATION;"
mysql -u root -h 127.0.0.1 -P 24803 -e "STOP GROUP_REPLICATION;"
```

3. **At this point, s1 is in a minority** (alone) and cannot commit new transactions.

4. **Observe the behavior:**
```sql
-- On s1
SELECT * FROM performance_schema.replication_group_members;
-- Shows s2 and s3 as UNREACHABLE

-- Try to write (will block)
INSERT INTO test_table VALUES (1);  -- Blocks indefinitely or until timeout
```

5. **Optional: Set timeout to automate exit to ERROR state:**

Before step 2, on s1:
```sql
SET GLOBAL group_replication_unreachable_majority_timeout=10;
SET GLOBAL group_replication_exit_state_action='READ_ONLY';
```

After losing majority contact for 10 seconds, s1 will automatically exit the group, enter ERROR state, and set `super_read_only=ON`.

6. **Recover the group:** Restart s2 and s3 (or restart s1 and bootstrap a new group).

---

## Claims Requiring Live Topology Verification (For Ticket 11)

The following claims should be verified against a running three-member Group Replication cluster on Windows with MySQL 8.4-current:

1. **XCom Multi-Proposer Ordering:** When three members (s1, s2, s3) propose transactions concurrently, verify that the total order respects the Paxos slot allocation formula (`g*n + member_id`). Monitor using `Gr_all_consensus_proposals_count` and `Gr_consensus_bytes_received_sum` status variables during concurrent write load.

2. **Certification Rollback on Conflict:** Issue write transactions that conflict on two members concurrently (both UPDATE the same primary key row). Verify exactly one transaction commits on all members and the other is rolled back on its originating member. Confirm rolled-back transaction does not appear in originating member's binary log.

3. **Minority Member Blocks on Write:** Stop s2 and s3. Verify s1 blocks on write (does not commit and does not hang forever). Observe timeout behavior if `group_replication_unreachable_majority_ti
