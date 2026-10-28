# 0009 — Read scaling and replication lag: measurements (ticket 19, lesson half)

2026-10-28, MySQL 8.4.11 Community, three instances on one Windows machine (one clock: clock skew is
zero by construction, not measured). Topology in async resting state; restored at the end of every
script (node3 `replica_parallel_workers = 4`, `SOURCE_DELAY = 0`, seed counts unchanged: visits 180/180).

## 1. One transaction, three timestamps (performance_schema), SOURCE_DELAY 0

GTID `92f36f51-b420-11f1-aa37-9c6b001d863b:17704`, one `heartbeat` INSERT on 3307, read on 3309:

| point | column | value |
|---|---|---|
| t0 | LAST_QUEUED_TRANSACTION_ORIGINAL_COMMIT_TIMESTAMP | 15:33:28.241950 |
| t1 | LAST_QUEUED_TRANSACTION_END_QUEUE_TIMESTAMP | 15:33:28.242674 |
| t2 | LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP (worker 1) | 15:33:28.248325 |

receive 0.724 ms, apply 5.651 ms, total 6.375 ms (≈ 89 % apply).

## 2. The natural burst (Slika 7.1 data) — NATURAL lag, no SOURCE_DELAY

`examples/04-read-scaling/10-lag-burst.ps1 -Sessions 4 -RowsPerSession 500` → CSV
`figures/raw/07-skaliranje-01-kasnjenje.csv` (360 samples, 250 ms nominal). node3 pinned to 1 worker.
`python tools/make-lag-plot.py` assertions all passed:

- source committed **2 000 transactions in 598 ms** (≈ 3 300 tx/s, 4 sessions, group commit)
- idle baseline real lag **2.1 ms**; peak **31.02 s at t = 35.5 s**; drained to ~2 ms by t ≈ 37.9 s
  (≈ 33 s of apply → ≈ 60 tx/s on one worker; the ~16 ms per `visits` row was not explained)
- `Relay_Log_Space` 285 651 → 968 650 B by t = 4.5 s, then only +333 B per heartbeat row: receiver done
- max |SBS − real| = **4.21 s** (during the drain SBS over-reports, e.g. 14 vs 11.46 s)
- SBS ≥ 1 while real lag < 10 ms in **31 / 360** samples (caught-up replica, runs of several seconds)
- while lag rises, SBS tracks real lag within ~1 s (whole-second floor)

Hypothesis for SBS = 1 at 2 ms (NOT verified): whole-second event timestamps in the binlog header
explain part; the MTS coordinator checkpoint (`replica_checkpoint_period` 300 ms; 8.4's one worker
still runs with a coordinator) may explain the rest. The paper may state the measurement, not a mechanism.

Smoke run first (2 × 300 rows) produced the same shape (peak ≈ 9 s, SBS = 1 flickers when caught up);
not used for the figure.

## 3. RYW / monotonic reads / closing tools — INDUCED lag (SOURCE_DELAY = 3 on node3)

`examples/04-read-scaling/20-ryw-async.js`, two runs, identical outcome
(raw: `raw/0009-ryw-async-run1.txt`, `raw/0009-ryw-async-run2.txt`):

| step | run 1 | run 2 |
|---|---|---|
| A. write v=1, read 3309 at once | v = 0; received true, applied false; SQL_Remaining_Delay = 4 | same |
| B. write v=2; read 3308 then 3309 | 2 then 1 | 2 then 1 |
| C. `WAIT_FOR_EXECUTED_GTID_SET(g, 1)` | 1 after 1 001 ms; read stale (v=2 for write v=3) | 1 after 1 002 ms; stale |
| D. `WAIT_FOR_EXECUTED_GTID_SET(g, 10)` | 0 after 4 009 ms; v = 4 | 0 after 4 004 ms; v = 4 |
| E. `SOURCE_POS_WAIT(file, pos, 10)` | 1 (events) after 4 312 ms; v = 5 | 1 after 4 309 ms; v = 5 |

Observation: `SOURCE_DELAY = 3` produced ≈ 4.0 s of wait, consistent with the manual's "at least N
seconds"; the extra second is not explained.

GTID capture: `GTID_SUBTRACT(gtid_executed after, before)` on 3307 (exact, single writer). An
earlier version used the whole `@@global.gtid_executed`, which contains group UUIDs never received
on the async channel, so `GTID_SUBSET(g, RECEIVED_TRANSACTION_SET)` was false — fixed.

## 4. Applier stopped (manual check)

`STOP REPLICA SQL_THREAD` on 3309, one write on 3307:
- `WAIT_FOR_EXECUTED_GTID_SET(g, 3)` → waited 16:19:39.292 → 16:19:42.288 (full timeout), returned **1**
  (first attempt used NOW(3), which is constant within a statement; redone with SYSDATE(3))
- `SOURCE_POS_WAIT('node1-bin.000017', 4, 3)` → **NULL** immediately (matches refman)
- timeout 0 was **not** run (would hang); "hangs forever" is derived from this + refman text

## Verified quotes (researcher, 2026-10-28; fetched via answer-mode extraction — spot-check before citing)

- SHOW REPLICA STATUS: definition; "useful only for fast networks"; clock difference "computed when the
  replica receiver thread starts, remains constant"; MTS "based on Exec_Source_Log_Pos, and so may not
  reflect the position of the most recently committed transaction"; NULL conditions; idle → 0.
- GTID functions: WAIT_FOR_EXECUTED_GTID_SET waits until `GTID_SUBSET(..., @@GLOBAL.gtid_executed)`;
  0 success / 1 timeout; default timeout 0 = always waits; monitors all GTIDs incl. all channels.
- Synchronization functions: SOURCE_POS_WAIT "blocks until the replica has read and applied all updates
  up to the specified position in the source's binary log"; returns events waited, -1 timeout, NULL if
  SQL thread not started / stops.
- Delayed Replication §19.4.11: "not executed until at least N seconds later than its commit on the
  immediate source"; purposes: user mistakes, test lag, inspect the past.
- Scale-Out §19.4.5: "high number of reads and low number of writes/updates".
- replica_parallel_workers default 4; replica_preserve_commit_order default ON.
- Router 8.4 §3.5.1: `access_mode=auto`; `wait_for_my_writes` — "read-only queries wait for the last
  written transaction of the session"; `wait_for_my_writes_timeout` default 1, then falls back to a
  read_write destination. (Router rung, not refman.)
- NOT FOUND in refman: that SBS clamps negative to 0 (source code: `max(0, time_diff)` — not cited);
  microsecond resolution statement; a "read-your-writes" sentence for the GTID function.
