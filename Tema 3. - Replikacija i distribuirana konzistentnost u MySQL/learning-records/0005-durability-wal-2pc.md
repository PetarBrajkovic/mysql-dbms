# 0005 — Durability: write vs fsync, WAL, two logs, two-phase commit, the matrix (lesson B of ch. 3)

Ticket 15 (lesson half, part B), 2026-10-08. Lesson: `lessons/0003-postojanost-wal-dvofazno-komitovanje.html`.
Reference: `reference/postojanost-matrica.html`. Example: `examples/02-binlog-async/04-postojanost.sql`.
Measurements and verified quotes: `.scratch/replikacija/measurements/0005-durability-wal-2pc.md`.

## What was taught

Roots: RAM volatile / disk durable (he had it); `write` lands in the OS cache, `fsync` waits for the
device, so a **process crash and an OS crash are different events**; the disk writes whole blocks, so
scattered page writes are expensive. Derived (Socratic): WAL = append a description + fsync the log,
pages later, replay after a crash → the redo log. Expository, flagged as a **design decision**: two
logs (binlog = server layer, replication; redo = InnoDB, recovery). Derived from K2: two independent
writes diverge source and replicas in either direction. Derived: two-phase commit with the binlog as the
single decision point; recovery rule. Matrix: each variable = "does this log get fsync at commit", with
the 0001 latency table.

## Where his edge was, and what moved

- **Spaced retrieval from 0004 held**: K3 (no reading the dead source's file) and the async loss window,
  2/2 cold. K3 can be considered landed.
- Edge at the probe: had RAM vs disk; **did not know** what `write()` does ("don't know"); missed the
  block-granularity question (picked "scattered is faster, the disk spreads into free blocks"), yet knew
  a row returns to its own page. Narrow gap, not a storage-model misconception; fixed by R3.
- **Misconception at 2PC: "a prepared transaction is always rolled back"** (safe for one server).
  Dislodged by drawing crash point A (before binlog) vs B (after binlog): the redo log looks identical,
  only the binlog tells them apart. Re-checked with crash-point-B question: correct.
- Derived WAL himself on the first try; matrix questions (2/1 under power loss, 0/2 under a process
  crash) both correct.

## Non-obvious for the writing session

- **Term locked: „dvofazno komitovanje“**, never „dvofazna potvrda“ (potvrda = acknowledgement). The
  live chat used „dvofazna potvrda“ before this was decided; the artifacts use the locked term.
- **Measured: with the binlog on, ~2 redo fsyncs per commit; with `sql_log_bin = 0`, ~1**; 1/1 commit
  ~930 µs vs ~360 µs. Report as a measurement; the internal fsync layout of group commit is unverified.
- Matrix row 2/1 and the process-crash column are **derived**, not quoted — label them so in ch. 3.
- "Two logs" is history; ch. 3 needs a citation for the server-level binlog / multiple engines point.
- The refman warns that OS/disk hardware can "fool the flush-to-disk operation": one sentence in ch. 3.

## What comes next

The ch. 3 writing session (lesson A + B are both taught). Next lesson after that: ch. 4 semisync —
it builds directly on this one (`AFTER_SYNC` waits after the binlog fsync, the decision point).
Spaced retrieval at its start: the 2PC recovery rule (crash point A vs B) and process vs OS crash.

## Evidence

`.scratch/replikacija/measurements/0005-durability-wal-2pc.md`
