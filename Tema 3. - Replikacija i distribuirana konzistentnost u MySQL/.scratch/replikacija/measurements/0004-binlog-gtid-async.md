# 0004 — measurements and verified sources for lesson 02 (ch. 3, part A)

Measured 2026-10-08 on MySQL 8.4.11, topology 3307/3308/3309 in the resting async state.

## Server settings (all three nodes identical)

`log_bin = 1`, `binlog_format = ROW`, `gtid_mode = ON`, `binlog_row_image = FULL`,
`replica_parallel_workers = 4`.

server_uuid: 3307 `92f36f51-b420-11f1-aa37-9c6b001d863b`, 3308 `93f81783-…`, 3309 `94f1b94d-…`.

`gtid_executed` identical on all three:
`0a312e41-b427-11f1-b130-9c6b001d863b:1-564:1000085-1000087, 92f36f51-…:1-16853 (→16854 after the
demo insert), a4d0522e-b428-11f1-ade0-9c6b001d863b:1-9`. The two foreign UUIDs come from the ticket-11
Group Replication / ClusterSet session (GR transactions carry the group's UUID) — to be confirmed
and explained in ch. 5, not ch. 3.

## Same GTID, different address (figure candidate for ch. 3)

One `INSERT INTO heartbeat` on 3307 → GTID `92f36f51-…:16854`.

| | file | Gtid event | Xid End_log_pos |
|---|---|---|---|
| 3307 | `node1-bin.000008` | Pos 294, End 373 | 640 |
| 3309 | `node3-bin.000010` | Pos 294, End 380 | 630 |

Event sequence on both: Format_desc → Previous_gtids → Gtid → Query(BEGIN) → Table_map
(poliklinika.heartbeat) → Write_rows → Xid. `Server_id` of the replicated events on 3309 is **1**
(origin). The Gtid event is 7 bytes longer on the replica.

## Unsafe statement

Session `binlog_format = STATEMENT`, inside a rolled-back transaction:
`UPDATE invoices SET paid_status='paid' WHERE tenant_id=1 LIMIT 5` → Note 1592 ("…unsafe because it
uses a LIMIT clause. This is unsafe because the set of rows included cannot be predicted.");
same without `LIMIT` → no warning.

## Threads

3307: two `Binlog Dump GTID` connections (one per replica).
3309: `replica_io`, `replica_sql`, 4× `replica_worker`. At rest
`LAST_QUEUED_TRANSACTION` = `LAST_APPLIED_TRANSACTION` (worker 1) = `…:16854`; workers 2–4 empty.

## Privileges

`SHOW BINLOG EVENTS` as `dbadmin` → ERROR 1227 (needs REPLICATION SLAVE). Lessons use root.

## Sources verified (researcher, 2026-10-08) — rung 1 unless noted

- binlog_format default ROW (5.7.7+), deprecated 8.0.34: refman replication-options-binary-log; relnotes 8.0.34.
- NOW() safe, timestamp in binlog; SYSDATE() unsafe (ignores SET TIMESTAMP): refman replication-features-functions.
- RAND() listed unsafe (seed replicated only inside stored functions): refman replication-rbr-safe-unsafe.
- MIXED: statement by default, switches to row "in particular cases": refman replication-formats.
- LIMIT without ORDER BY unsafe: refman replication-features-limit.
- binlog_row_image FULL; before+after images for UPDATE: refman replication-options-binary-log.
- Auto-positioning handshake = union of gtid_executed and received set; source sends the rest:
  refman replication-gtids-auto-positioning.
- Thread names: refman replication-threads.
- replica_parallel_workers default 4: refman replication-options-replica (the "since 8.0.27" date is unverified — do not write it).
- Rename: 8.0.22 / 8.0.23 / 8.0.26; removal in 8.4.0 (relnotes 8.4.0 — search excerpt, re-fetch before citing).
- Blog: Gryp, "MySQL Terminology Updates", 2020-07-01, dev.mysql.com/blog-archive/mysql-terminology-updates/ (rung 2).
- GTIDs "simplify … failover" (not "automatic"): refman replication-gtids-failover.
