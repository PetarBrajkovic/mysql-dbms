# 0005 — measurements and verified sources (ch. 3 lesson B, durability)

Taken 2026-10-08 (session date as for 0004) on MySQL 8.4.11, node1 (3307) as root, Windows,
`innodb_flush_method = unbuffered` (Windows default), `innodb_flush_log_at_timeout = 1`,
`innodb_redo_log_capacity = 104857600`, redo file `.\#innodb_redo\#ib_redo39`.
Script: `examples/02-binlog-async/04-postojanost.sql` (cleans up after itself; replicas verified
healthy and without `durability_lab` afterwards).

## Redo fsyncs per 100 single-row autocommit INSERTs (`Innodb_os_log_fsyncs` delta)

| run | mode | redo fsyncs / 100 | µs per commit |
|---|---|---|---|
| 1 | binlog on, 1/1 | 200 | 783 |
| 1 | binlog on, redo = 2 | 5 | 548 |
| 2 | `sql_log_bin = 0`, 1/1 | 135 | 376 |
| 2 | binlog on, 1/1 | 200 | 1019 |
| 3 | `sql_log_bin = 0`, 1/1 | 126 | 394 |
| 3 | binlog on, 1/1 | 199 | 933 |
| 4 (script) | `sql_log_bin = 0`, 1/1 | 127 | 355 |
| 4 (script) | binlog on, 1/1 | 200 | 932 |
| 4 (script) | binlog on, redo = 2 | 1 | 356 |

Reading: with the binlog participating, exactly ~2 redo fsyncs per commit; without it ~1 (+ background
flushes). Consistent with prepare + commit both flushed, **but the internal group-commit fsync layout
was not confirmed by a source** (researcher could not reach the group-commit page / source). The paper
reports it as a measurement, not as a mechanism claim. Note: `sql_log_bin = 0` on the source writes
rows the replicas never get — the script drops the database at the end for that reason.

## Verified quotes (refman 8.4 unless noted)

- innodb_flush_log_at_trx_commit: "The default setting of 1 is required for full ACID compliance.
  Logs are written and flushed to disk at each transaction commit." 2: "logs are written after each
  transaction commit and flushed to disk once per second." 0: "written and flushed to disk once per
  second." "For settings 0 and 2, once-per-second flushing is not 100% guaranteed." (innodb-parameters)
- innodb_flush_log_at_timeout: default 1; "any unexpected mysqld process exit can erase up to N
  seconds of transactions."
- sync_binlog=0: "in the event of a power failure or operating system crash, it is possible that the
  server has committed transactions that have not been synchronized to the binary log." sync_binlog=1:
  "transactions that are missing from the binary log are only in a prepared state. This permits the
  automatic recovery routine to roll back the transactions". (replication-options-binary-log)
- Default `sync_binlog=1` since 5.7.7 (relnotes 5.7.7).
- Recommendation: "For the greatest possible durability and consistency in a replication setup that
  uses InnoDB with transactions, use these settings: sync_binlog=1. innodb_flush_log_at_trx_commit=1."
- Recovery: "tells InnoDB to complete any prepared transactions that were successfully written to the
  binary log, and truncates the binary log to the last valid position." (binary-log)
- "Many operating systems and some disk hardware fool the flush-to-disk operation" — durability not
  guaranteed even at 1/1. Worth one sentence in ch. 3.
- Redo log: "used during crash recovery to correct data written by incomplete transactions";
  "oldest data is truncated as the checkpoint progresses". (innodb-redo-log, 17.6.5)
- fsync(2): "The call blocks until the device reports that the transfer has completed."

## Derived, not quoted (label as such in the paper)

- Row 2/1 of the matrix (binlog has T, redo lost the prepare → replicas have T, source does not).
- The "process crash loses nothing at 2 or sync_binlog=0" column — from write() → OS cache.
- "Two logs" history (server-level binlog over multiple engines) — standard, but no citation pulled yet;
  find one before ch. 3 states it.
