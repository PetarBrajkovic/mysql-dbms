# Research: the binary log, GTIDs, and asynchronous replication

Type: research
Status: resolved

## Question

The mechanical foundation the whole paper stands on: **what MySQL actually ships between servers**.
Every later chapter is a modification of this one machine, so this memo has to be precise rather than
broad.

Sources: the MySQL 8.4 reference manual first, worklogs and the source tree where the manual is
silent. **MySQL 8.4 removed `MASTER`/`SLAVE` syntax in favour of `SOURCE`/`REPLICA`** — use current
vocabulary and note where the literature's older terms name the same thing.

Produce a memo at `../research/03-binlog-and-async.md` answering:
1. **The binary log**: what it records, the three formats (`STATEMENT`, `ROW`, `MIXED`), what makes a
   statement unsafe for statement-based replication, and why `ROW` became the default. Include the
   event structure at enough depth that `mysqlbinlog` output can be read in a lesson.
2. **Durability knobs**: `sync_binlog`, `innodb_flush_log_at_trx_commit`, and the two-phase commit
   between InnoDB's redo log and the binary log. Exactly which combination is crash-safe, and what is
   lost by each relaxation. This is the hinge the semisynchronous chapter (ticket 04) turns on.
3. **GTIDs**: what a GTID is, `gtid_executed` vs `gtid_purged`, how GTID-based positioning differs
   from file-and-offset, and what it makes possible that file/offset did not (failover, `AUTO_POSITION`).
4. **The replication threads**: the receiver (I/O) thread, the relay log, the applier (SQL) thread,
   and multi-threaded applier settings (`replica_parallel_workers`, `replica_preserve_commit_order`).
   Where lag is actually generated, and which of these is the usual culprit.
5. **Setting a two-node topology up from scratch**, as a command sequence: `server_id`, `log_bin`,
   replication user and its privileges, `CHANGE REPLICATION SOURCE TO`, `START REPLICA`,
   `SHOW REPLICA STATUS` and which of its fields actually mean something. Ticket 10 executes this,
   so it must be complete and 8.4-current, not copied from an 8.0 tutorial.
6. **Candidate measurements and figures** — what can be shown that is a visible fact rather than a
   settings table.

End with a list of claims that need the live topology to confirm, for ticket 10.

## Answer

Resolved at charting, 2026-09-17. Findings: [`research/03-binlog-and-async.md`](../research/03-binlog-and-async.md)

The largest memo of the six (~35 KB), 8.4-current throughout with `SOURCE`/`REPLICA` vocabulary. All
six questions answered: binary log contents and the three formats with the unsafe-statement rules and
readable `mysqlbinlog` output; the durability matrix over `sync_binlog` and
`innodb_flush_log_at_trx_commit` including the InnoDB-redo/binlog two-phase commit and what each
relaxation actually loses; GTIDs with `gtid_executed` vs `gtid_purged` and what `AUTO_POSITION` makes
possible; the receiver/relay-log/applier pipeline with the multi-threaded applier settings; and a
complete, executable two-node setup sequence ready for ticket 10.

**Most useful single finding for the paper**: lag is attributed overwhelmingly to the applier rather
than the receiver, which tells the read-scaling chapter where to point. **15 claims flagged for live
verification** at ticket 10 - the largest verification list of the six memos, which is appropriate
since this is the memo everything else is built on.
