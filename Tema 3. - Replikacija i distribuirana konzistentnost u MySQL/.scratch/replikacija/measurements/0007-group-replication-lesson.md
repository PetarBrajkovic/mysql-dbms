# 0007 — Group Replication lesson: live runs, verified quotes

Taken live during lesson 0005 (ticket 17, lesson half), 2026-10-23, MySQL 8.4.11 Community, Win64,
MySQL Shell 8.4.10, topology 3307/3308/3309, loopback. Raw outputs in `raw/0007-*.txt`.

## Sandbox state, declared and checked

- Start: all three DOWN → `topology.ps1 start` → **async** verified (3308/3309 channel ON, no group).
- `10-gr-up.js` → cluster, 8.5 s, "Cluster is ONLINE and can tolerate up to ONE failure", single-primary.
- `34a-to-multi-primary.js` for the conflict pair; `34b-to-single-primary.js` for 42.
- End: `19-gr-down.ps1` → **async** verified: channels ON/ON on 3308 and 3309, `super_read_only = 0`
  everywhere, no ONLINE group members, identical `gtid_executed` on all three, no
  `skip_replica_start` in any `mysqld-auto.cnf`, 3306 still listening and untouched.
- `invoices` rows 1 and 2 restored by hand after the conflict pair (−1099 / −999) to
  1244.05 / 1079.31, the values found at the start; checked on 3309.

## 1. `group_replication_consistency` default — correction to measurement 0002

Live on all three members after `10-gr-up.js`: `@@group_replication_consistency` =
`@@global…` = **`BEFORE_ON_PRIMARY_FAILOVER`** (`variables_info.VARIABLE_SOURCE = DYNAMIC`; the
AdminAPI persisted it in `mysqld-auto.cnf` at ticket 11). Rung 1:

> "The default value of the group_replication_consistency system variable is now
> BEFORE_ON_PRIMARY_FAILOVER; previously, this was EVENTUAL." — 8.4.0 release notes,
> https://dev.mysql.com/doc/relnotes/mysql/8.4/en/news-8-4-0.html

So 0002 §6's "`EVENTUAL` (default)" was wrong as a label; its EVENTUAL numbers stand (it set the
level explicitly). 0002 corrected in place.

Also live: `group_replication_unreachable_majority_timeout = 0`, `group_replication_exit_state_action
= OFFLINE_MODE` (8.4 default, refman sysvar page).

## 2. Conflict pair (multi-primary), `34-conflict-pair.ps1` → `raw/0007-conflict-pair.txt`

| Case | A (3307) | B (3308) | Result |
|---|---|---|---|
| same row `invoice_id = 1`, A opens t=0 commits t=6 s, B commits t=2 s | `ERROR 1180 (HY000) … Got error 149 - 'Lock deadlock; Retry transaction' during COMMIT` (6041 ms) | committed (32 ms) | 2243.05 on all three (only B's +999) |
| different rows 1 / 2, same timing | committed (6026 ms) | committed (27 ms) | both values on all three |

`COUNT_CONFLICTS_DETECTED` = 0 on 3307 and 3308 (checked 84 / 17). Fifth timing confirming 0002's
correction: 1180/149, never 3101.

## 3. PK-less table inside a running group, `41-no-pk-live.js` → `raw/0007-no-pk-live.txt`

- `CREATE TABLE poliklinika.no_pk_demo (label VARCHAR(40) NOT NULL, amount INT NOT NULL)` — **accepted**.
- `INSERT` — `ERROR 3098 (HY000): The table does not comply with the requirements by an external plugin.`
  (code confirmed with `mysql.exe`; mysqlsh JS reports no code.)
- `dba.checkInstanceConfiguration` → `status = error` with the manual's wording ("readable but not
  updateable"); after `DROP` → `status = ok`. Table dropped; absent at end.

## 4. Read-your-writes closed by `BEFORE`, `42-ryw-before.js` → `raw/0007-ryw-before-run{1,2}.txt`

Single-primary; writer on 3307 at session default; **only the reader's (3309) session level
changes**; 5 000-row INSERT per iteration, read of its last row immediately after OK; 40 iterations;
held sessions in one mysqlsh process.

| Reader level | Stale run 1 | Stale run 2 | Writer median (p95) ms r1 · r2 | Reader median (p95) ms r1 · r2 |
|---|---|---|---|---|
| `BEFORE_ON_PRIMARY_FAILOVER` | 40/40 | 40/40 | 16 (32) · 16 (29) | 0 (12) · 0 (0) |
| `EVENTUAL` | 39/40 | 40/40 | 16 (35) · 15 (25) | 0 (0) · 0 (8) |
| `BEFORE` | **0/40** | **0/40** | 16 (32) · 16 (32) | **16 (21) · 14 (26)** |

First `BEFORE` measurement on this topology (0002 measured EVENTUAL / AFTER / BEFORE_AND_AFTER, with
the level set on the **writer**: 16 / 29 / 31 ms median, 40 / 0 / 0 stale). Together: closing the
window costs ≈ one apply time (~13–16 ms here); the level chooses who pays.

## 5. Verified quotes and absence checks (researcher, rung 1 unless noted)

- Certification: "conflict detection is carried out at row level … the transaction that was ordered
  first commits on all servers, and the transaction ordered second aborts" / "distributed first commit
  wins rule" — refman §20.1.1.2 group-replication-summary.html.
- Total order: "atomic message and total order message delivery" (§20.1.1.2); "XCom, a Paxos variant"
  (§20.3.2 limitations); "GCS protocols that implement the Paxos algorithm" (§20.5.3.1).
- PK: "must have a defined primary key, or primary key equivalent where the equivalent is a non-null
  unique key" (§20.3.1).
- Minority: "the group is unable to progress and blocks because it cannot secure majority or quorum"
  (§20.7.8). Timeout 0 = "wait forever"; with a timeout, pending transactions rolled back, ERROR state
  (sysvar page). "Pending transactions blocked" in those words: **not found**.
- Levels: AFTER "A read/write transaction waits until its changes have been applied to all of the
  other members. This value has no effect on read-only transactions"; BEFORE "A read/write
  transaction waits for all preceding transactions to complete before being applied. A read-only
  transaction waits for all preceding transactions to complete before being executed" (§20.5.3.2).
  AFTER sysvar: "any subsequent transaction reads the value written or a more recent value on any
  group member".
- **Absence: "linearizable" / "read your writes"** do not appear on the consistency pages; "strong
  consistency" only in §20.5.3.2 Scenario 6. The level→model mapping is therefore ours (derived).
- **Absence: a manual recommendation of when to use multi-primary** — not found on the modes or
  limitations pages. The verdict is memo 05's, derived in the lesson.
- Multi-primary limits: SERIALIZABLE refused, CASCADE FKs unsupported, concurrent DDL+DML on same
  object from different servers unsupported (§20.3.2).
- Primary election automatic (§20.1.3.1). **Asynchronous Connection Failover** re-points a replica's
  connection to a new source automatically (§19.4.9); not documented as promoting a replica. So no
  sentence may say "async has no automatic failover"; say who promotes.
- Shell `createCluster` `consistency` option: defaults to BEFORE_ON_PRIMARY_FAILOVER on ≥ 8.4.0
  (Shell API Dba reference).

## Derived, not measured (say so in the chapter)

- Multi-primary write throughput does not scale with member count (full replication: every member
  writes every row; only statement execution is spread).
- AFTER is not linearizability (members apply one by one while the writer waits).
