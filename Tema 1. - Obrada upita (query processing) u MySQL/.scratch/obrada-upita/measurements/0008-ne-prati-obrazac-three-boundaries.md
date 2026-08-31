# Measurements — lesson 08 / chapter 6 (Gde MySQL ne prati obrazac)

Sidecar to `learning-records/0008-ne-prati-obrazac-three-boundaries.md`. Needed when **writing**
chapter 6, not when planning a lesson. Server: MySQL **8.4.11**, `innodb_buffer_pool_size` = **128
MB** against a **1394 MB** table, so every scan is I/O-bound and re-reads from disk — which is why
the runs are so repeatable and why only **ratios** are quoted in prose (standing constraint, LR-0003).

## Environment

| | |
|---|---|
| Table | `obrada_upita.wide_events`, 4.909.177 rows per `information_schema` estimate, **5.000.000** exact |
| Data length | 1394 MB |
| `innodb_buffer_pool_size` | 128 MB |
| `innodb_parallel_read_threads` | default **4**; setting 1024 → server reports **256** (clamped) |
| Figure script | `tools/make-lesson08-ne-prati-obrazac.ps1` (builds both figures, self-asserting) |

## Figure 01 — parallel-read boundary

`figures/06-gde-mysql-ne-prati-obrazac-01-paralelni-sken-granica.png` (+ `.svg`). Median of 3.

| threads | A: `COUNT(*) FORCE INDEX(PRIMARY)` | B: same + `WHERE amount > 100` |
|---|---|---|
| 1 | 1483 ms | 1582 ms |
| 2 | 1023 ms | 1568 ms |
| 4 | 732 ms | 1571 ms |
| 8 | 551 ms | 1575 ms |
| 16 | 508 ms | 1574 ms |
| **1 → 16** | **2.92×** | **1.01×** |

Script asserts A ≥ 2.0× and B ≤ 1.20×, and throws otherwise. It also asserts that the *default*
`COUNT(*)` plan uses a **secondary** index and that `FORCE INDEX(PRIMARY)` uses `PRIMARY` — if either
flips, the figure's premise is gone.

**Why `FORCE INDEX(PRIMARY)` is mandatory.** Default plan: `key: idx_is_flagged`, `type: index`,
`Extra: Using index`, `rows: 4909177`. Without forcing, the sweep is flat at ~440 ms for every thread
count — a false negative. With forcing, `key: PRIMARY`, `key_len: 8`.

**Discarded first attempt.** `SELECT COUNT(*)` with no `FORCE INDEX` at threads 1/2/4/8: 441/438/445/439 ms.
Looks like "parallelism does nothing"; it is actually "the plan never touched the clustered index".

## Figure 02 — per-row expression cost (lesson-only figure)

`figures/06-gde-mysql-ne-prati-obrazac-02-cena-po-torki.png` (+ `.svg`). Median of 3, threads = 1.

| predicates | time |
|---|---|
| 0 | 1483 ms |
| 1 | 1603 ms |
| 2 | 1712 ms |
| 4 | 1854 ms |
| 6 | 2108 ms |

Derived: **(2108 − 1603) ms / (5.000.000 rows × 5 predicates) = 20.2 ns** per row per predicate.
Script asserts monotonicity (allowing 3% noise) and that 6 predicates > 0 predicates.

**Selectivity control**, same shape, threads = 1: `WHERE amount > 999999` (matches ~nothing)
**1595 ms** vs `WHERE amount > 100` (matches most) **1603 ms**. Within noise of each other — the
predicate costs the same whether or not it passes, which is the point.

## §6.3 — plan cache vs. statement cache

**Three `EXECUTE`s, one prepared statement.** `PREPARE s FROM 'SELECT SUM(amount) FROM wide_events WHERE country_code = ?'`:

| param | trace bytes | est. rows | cost | result |
|---|---|---|---|---|
| `DE` | 7889 | 203730 | 213078 | 27194208.02 |
| `US` | 7403 | 2454590.0 | 494949 | 893108543.46 |
| `JP` | 7889 | 213948 | 221109 | 27280002.32 |

`QUERY` column shows the parameter **already substituted** (`... country_code = 'DE'`).
`country_code` distribution: `US` 3.500.177 (71%), every other code ~107.000 (~2.2%).

**Trace-capture trap.** `optimizer_trace_offset = -3, optimizer_trace_limit = 3` and *all* `SET @var`
statements before `enabled=on` — `SET` is itself traced and evicts the traces you came for. First
attempt returned only the `JP` trace. This is the same trap already logged in `tools/FIGURES.md`.

**Cross-session.** Session 1 `PREPARE s1 FROM 'SELECT 1'; EXECUTE s1;` → `1`.
Session 2 `EXECUTE s1;` → `ERROR 1243 (HY000): Unknown prepared statement handler (s1) given to EXECUTE`.

**Reprepare.** On throwaway `t_reprepare(id, a)`: `PREPARE p FROM 'SELECT * FROM t_reprepare'`,
`EXECUTE p` → 2 columns, `Com_stmt_reprepare` = **0**; `ALTER TABLE ... ADD COLUMN b INT`;
`EXECUTE p` → **3** columns, `Com_stmt_reprepare` = **1**. Table dropped afterwards.
`wide_events` was deliberately **not** used here, to avoid perturbing statistics that chapters 3-5
measurements rest on.

## Sources fetched this session (verbatim, for `references.bib` at write time)

- **WL#11785** — `Read()`: "Reads a single row, putting rows into the record buffers. Like the
  existing read_record() abstraction, returns -1 (EOF), 0 (OK) or 1 (error)."
- **WL#11720**, Scope — "Read the sub trees of an index in parallel only if the request is a
  non-locking SELECT COUNT(*)." Also: "We will not implement any locking by the parallel read threads."
- **8.4 manual, CHECK TABLE** — "InnoDB supports parallel clustered index reads, which can improve
  CHECK TABLE performance. … The innodb_parallel_read_threads session variable must be set to a value
  greater than 1 for parallel clustered index reads to occur. The actual number of threads used to
  perform a parallel clustered index read is determined by the innodb_parallel_read_threads setting or
  the number of index subtrees to scan, whichever is smaller."
- **8.4 manual, Caching of Prepared Statements and Stored Programs** — "The server maintains caches
  for prepared statements and stored programs on a per-session basis. Statements cached for one
  session are not accessible to other sessions. When a session ends, the server discards any
  statements cached for it." / "the server converts the statement to an internal structure and caches
  that structure to be used during execution." / "the server detects these changes and automatically
  reprepares the statement when it is next executed. That is, the server reparses the statement and
  rebuilds the internal structure." / "The server attempts reparsing up to three times. An error
  occurs if all attempts fail." / "Metadata changes occur for DDL statements … Table content changes
  (for example, with INSERT or UPDATE) do not change metadata, nor do SELECT statements."

**Not obtained:** the prose paragraph under `innodb_parallel_read_threads` in `innodb-parameters.html`.
That page is too long for WebFetch and truncates before reaching it, twice. The "does not apply to
secondary index scans" sentence is therefore **not** quoted in the lesson — it is carried by the
measurement in (b) instead. If a citation for it is wanted at write time, fetch the page in another
way rather than quoting it from a search snippet (LR-0006's discipline).

## Comparative figures used in the lesson

From research memo 06, vendor documentation, all secondary to the MySQL claims and used only for
contrast — each needs its own citation at write time:
DuckDB `STANDARD_VECTOR_SIZE` = 2048 · ClickHouse 1024–4096 rows per operator call, AVX2/AVX-512 ·
PostgreSQL also row-at-a-time but with optimizer-chosen parallel plans · HeatWave columnar +
vectorized + up to 512 nodes · Oracle shared pool / library cache is the cross-session plan cache
MySQL lacks · query cache deprecated 5.7.20, removed 8.0.
