# Decide the running example and workload the whole paper is built on

Type: grilling
Status: closed
Assignee: Pex
Blocked by: 03, 05, 06 — all closed

## Question

Temas 1 and 2 each had one schema every chapter measured against. Replication needs something
different from a security paper: the schema matters less, and **the workload matters much more**,
because lag, conflicts and acknowledgement latency are only visible under one.

Decide:

1. **The schema.** Reuse a shape the user already knows (Tema 2's `poliklinika`, rebuilt fresh on the
   new instances), or build something purpose-made. A replication demo wants a table that is cheap to
   write to in volume and has an obvious read side.
2. **The write workload that generates visible lag** on a single machine where all three instances
   share one disk. This is the genuinely hard part: if the applier keeps up effortlessly, half the
   paper's figures have nothing to show. Decide how lag is produced - real load, artificial
   `SOURCE_DELAY`, a deliberately constrained applier, or a mix - and settle the honesty rule now:
   the paper states plainly which figures use induced lag rather than naturally occurring lag.
3. **The conflict scenario** for the multi-primary chapter: the smallest concrete pair of transactions
   on two primaries that certification will reject, phrased so a reader sees why it *must* be
   rejected.
4. **The read-your-writes scenario**: the smallest sequence that demonstrates the anomaly, made
   reproducible rather than a race that fires sometimes.
5. **Whether the examples are SQL-only or need a script.** Temas 1 and 2 were SQL plus PowerShell.
   Anything involving concurrent sessions or timing loops needs more than a `.sql` file; decide the
   shape now so `examples/` stays consistent, and so ticket 12 knows what it is drawing figures from.

Give the user a sketch to react to, not a menu of open questions.

---

## Resolution (2026-09-18)

### 1. Schema: reuse `poliklinika`, plus two instruments

Reuse was accepted **conditionally** — only if it can demonstrate everything — so the schema was
audited demo by demo instead of assumed. It passes on every count but one.

| Demo the paper needs | Source | Verdict on `poliklinika` |
|---|---|---|
| Unsafe statement under `STATEMENT`/`MIXED` | memo 03 §Unsafe, item 8 | **Yes, unchanged.** `UPDATE invoices SET paid_status='paid' WHERE tenant_id=1 LIMIT 5` is unsafe because row-retrieval order is unspecified — and it is a sentence the domain would actually say. `RAND()`/`UUID()` variants available as backups. |
| GTID / `AUTO_POSITION` async replication | memo 03 | Yes — schema-agnostic. |
| Durability matrix, redo/binlog two-phase commit | memo 03 | Yes — any write. |
| Semisync `AFTER_SYNC` vs `AFTER_COMMIT` visibility window | memo 04 | Yes — any single-row write plus a read on the other node. |
| GR write-set certification, first-commit-wins | memo 05 | Yes. **Every table has a primary key** (GR's hard requirement for write-set extraction) and **zero cascading foreign keys** (`grep -ci cascade` → 0), the one thing that would have barred multi-primary. Plain non-cascading FKs are permitted. |
| All-InnoDB requirement | memo 05 | Yes — all six tables are `ENGINE = InnoDB`. |
| **GR rejecting a table with no primary key** | memo 05 | **No — the one gap.** Poliklinika is uniformly well-keyed, so it cannot fail. Resolved by a throwaway table created live in the GR chapter (see below). |
| Volume writes producing applier-side lag | memo 06 | Yes. `visits` carries three FK constraints, so each applied row costs parent lookups on the replica too — which *helps*, since the goal is an applier that falls behind. |
| Read-your-writes anomaly | memo 06 | Yes — insert a visit, read it on the replica. |
| Read scaling / routing | memo 06 | Yes — `patients` + `visits` joins are the natural read side. |
| InnoDB Cluster / ClusterSet topology | memo 07 + the ClusterSet correction | Yes — schema-agnostic. |

**Decision: reuse `poliklinika`, rebuilt fresh on 3307 from Tema 2's `examples/00-setup/01-schema.sql`
and `02-seed.sql`** (copied into this topic's own `examples/00-setup/`, never read across folders at
runtime, and never touching 3306). Two additions, both explicitly *instruments* rather than domain:

- **`heartbeat`** (`id BIGINT UNSIGNED PK AUTO_INCREMENT`, `ts DATETIME(6)`, `node VARCHAR(16)`) — no
  foreign keys, so a ticker can write to it at a fixed rate without FK cost distorting the
  measurement. This is what the lag time-series is sampled from.
- **`no_pk_demo`** — a two-column table with **no primary key**, created and dropped *inside* the
  Group Replication chapter purely to show GR refusing it. It is the negative demo the clinic schema
  is too well-designed to provide, and it stays out of `00-setup` so the sandbox is never left holding
  a table that breaks the group.

Schema identifiers stay English (as on Temas 1 and 2); only prose and captions are Serbian.

### 2. Lag: induced by default, natural exactly once, labelled always

- **Default: `SOURCE_DELAY=N`.** Memo 06 is explicit that this is the single most useful demo
  mechanic — without it lag varies with load and no figure reproduces.
- **Exactly one natural-lag figure**, so the induced ones are visibly modelling something real: a bulk
  `INSERT … SELECT` burst into `visits` against an applier pinned to `replica_parallel_workers=1`,
  measured with the `performance_schema` replication timestamps, **not** `Seconds_Behind_Source`
  (memo 06 establishes it as unreliable on three counts; the contrast is itself a figure).
- **Honesty rule, binding on every figure in this paper:** a caption whose lag was induced says so in
  the caption, in Serbian, naming `SOURCE_DELAY` and its value. Induced lag is never presented as
  measured.

### 3. Conflict scenario: one row, two members — *with a control*

The conflicting pair is the smallest possible write-set overlap: two members concurrently run
`UPDATE invoices SET paid_status='paid' WHERE invoice_id=42`. Certification's first-commit-wins
commits one everywhere and rolls the other back **on its originating member only**; memo 05 adds the
check that the loser never reaches that member's binary log.

**Chosen over** an auto-increment `INSERT` collision (a different mechanism — auto-increment offsets —
which would teach the wrong lesson) and over anything cascading (rejected outright by GR in
multi-primary).

**Teaching addition, and the reason this beats the bare version:** the demo runs as a **pair** — the
same two transactions against the *same* invoice (one rolled back) and against *two different*
invoices (both commit). Without the control a reader concludes certification serialises the table;
with it, they see it is row-level and understand *why* the write-set is a set of primary keys. Two
transactions of extra cost, and it converts a demonstration into an explanation.

### 4. Read-your-writes: async anomaly first, then the Group Replication knob

One narrative in two movements:

1. **Async replica.** `INSERT` a visit on 3307 → immediately `SELECT` on 3308 with `SOURCE_DELAY=2` →
   absent → GTID present in `retrieved_gtid_set` but not applied (the precise diagnosis) →
   `WAIT_FOR_EXECUTED_GTID_SET()` → present. Deterministic by construction, not a race.
2. **Group Replication.** The same sequence with `group_replication_consistency='BEFORE'`, where the
   read waits instead of lying.

This is the paper's strongest sequence: memo 05 identified the consistency levels as the direct bridge
from the professor's vocabulary to a MySQL knob, and this shows the anomaly and the knob back to back
on one schema.

### 5. Shape: SQL plus PowerShell

Same as Temas 1 and 2, and here it is forced rather than chosen — a heartbeat ticker, a timed burst,
and two simultaneous primaries cannot live in a `.sql` file. Convention:

- `examples/NN-<chapter>/*.sql` — everything declarative, runnable by hand, one concern per file.
- `examples/NN-<chapter>/*.ps1` — anything needing two sessions, a clock, or a sampling loop; writes
  its output to `.scratch/replikacija/measurements/` as CSV/text for ticket 12 to draw from.
- Every folder gets a `README.md` with a run-order table and which node each script runs against —
  Tema 2's pattern, now with a node column.
- Consequence for ticket 12: **figures are drawn from script output, never from a terminal
  screenshot.**
