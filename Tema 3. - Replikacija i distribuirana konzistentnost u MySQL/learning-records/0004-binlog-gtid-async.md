# 0004 — Binary log, formats, GTID, threads, async commit (lesson A of ch. 3)

Ticket 15 (lesson half, part A of two), 2026-10-08. Lesson: `lessons/0002-binarni-log-gtid-asinhrona.html`.
Reference: `reference/binarni-log-gtid-niti.html`. Examples: `examples/02-binlog-async/01..03`.
Measurements and verified sources: `.scratch/replikacija/measurements/0004-binlog-gtid-async.md`.

**Ch. 3 was split into two lessons** (his choice): A = this one (points 1, 3, 4 of the ticket);
B = durability (WAL, fsync, redo↔binlog two-phase commit, the `sync_binlog` ×
`innodb_flush_log_at_trx_commit` matrix). B is not taught yet.

## What was taught

Three roots: K1 log = append-only ordered sequence; K2 same start + same deterministic changes + same
order = same state; K3 the replica knows only what arrives as a message. Derived: replication = binlog
shipping + replay → STATEMENT/ROW/MIXED as cause vs effect → unsafe statements (+ the NOW() timestamp
trick, SYSDATE as a design decision) → file+offset is an address in one server's log → GTID as a name
that travels → `SOURCE_AUTO_POSITION` as set difference → receiver/relay/applier and why the applier
lags (one serial thread vs N concurrent source sessions) → source/replica rename (history) → async
commit = "OK" before any replica saw it, so a permanent source loss loses an acknowledged transaction.

## Where his edge was, and what moved

- **Spaced retrieval from 0003 held**: RYW vs monotonic and both PACELC questions 4/4, cold. Those two
  can be considered landed.
- **No log foundation at all at the probe**: did not know what replication ships, did not know WAL,
  had intuition but no mechanism for write≠fsync. Built from K1 up; everything derived after that went
  quickly. **WAL/fsync remain untaught** — lesson B starts there from zero.
- **Misconception: "filtering on a non-key column is unsafe."** He picked the LIMIT answer for the
  wrong reason (`tenant_id=1`). Dislodged with the "same set vs subset-by-order" contrast; held.
- **K3 wobbled because the three nodes share one machine.** He leaned toward "same computer, so it
  can read the source's disk". Fixed by "the connection matters, not the distance" (Beograd/Niš). It
  resurfaced at the end as "3308 fetches T from 3307's binlog after 3307 dies"; fixed by "fetching is
  a conversation with a live process, not reading a file". **Re-check K3 in lesson B** — it is the
  most fragile root.
- **"Same transactions → same log files/offsets."** Fixed with the notebook analogy, then confirmed;
  the live measurement (same GTID, different file and End_log_pos on 3307 vs 3309) is in the lesson.
- **"source = the server that takes writes."** Fixed with chained replication (3307→3308→3309).
- `NOW()` in STATEMENT: he said it replicates the replica's clock — the natural answer; the
  logged-timestamp trick was taught as a design patch, not derivable.
- Did not know what `SOURCE_AUTO_POSITION` *is* (the option name) even after deriving the mechanism.
  Show the two `CHANGE REPLICATION SOURCE TO` forms side by side; that fixed it.

## Non-obvious for the writing session

- **Memo 03 contradicts the refman on NOW()**: its format section lists `NOW()` as an example unsafe
  function; refman 8.4 says NOW() is safe because the binlog carries the timestamp. Memo 03 also
  says GTIDs make failover "automatic"; the refman says GTIDs *simplify* failover (positioning is
  automatic, choosing the new source is not). Neither error may reach ch. 3.
- 8.4 removed `SHOW MASTER STATUS` → `SHOW BINARY LOG STATUS`, `RESET MASTER` → `RESET BINARY LOGS
  AND GTIDS`, etc. (relnotes 8.4.0). Use only the new forms in `rad.md`.
- With `replica_parallel_workers = 4` the applier is a coordinator (`replica_sql`) plus 4
  `replica_worker` threads; the prose should not say "the SQL thread" as if it were one thread.
- The rename's reason, citable: Gryp, "MySQL Terminology Updates", MySQL Blog, 2020 — "change stream …
  does not imply what role a server should have". Add to `references.bib`.

## What comes next

Lesson B (durability) in a new session: start from RAM vs disk, write vs fsync, WAL, then two logs
(redo, binlog) and why they need two-phase commit, then the matrix with the 0001 latency table.
Re-check K3 and the async-loss window at its start (spaced retrieval). Then the ch. 3 writing session.
