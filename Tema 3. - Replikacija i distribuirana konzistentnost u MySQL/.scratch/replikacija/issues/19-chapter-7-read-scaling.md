# Chapter 7 - Skaliranje čitanja i kašnjenje replikacije

Type: task (execution - see the map's execution override)
Status: **closed** (2026-10-28) - lesson taught, examples run live, chapter written, measured
Assignee: Pex
Blocked by: 18 — closed

## Question

Write ch. 7, **~3.5 pages**. Covers professor bullet #5 ("Skaliranje čitanja korišćenjem replika
(Read Replicas)"). Backed by memo 06.

Must contain:

1. **`Seconds_Behind_Source` is unreliable on three counts**, against the `performance_schema`
   replication timestamps as the real measure. Memo 06 notes the contrast is itself a figure - the same
   moment measured both ways.
2. **kašnjenje replikacije** defined and demonstrated, with the applier (not the receiver) as its
   source, collected from ch. 3's forward pointer.
3. The anomaly named against the literature: **read-your-writes** violated on an async replica, plus
   monotona čitanja. This is the first half of ticket 08's twice-run sequence; ch. 5 already closed it
   with `group_replication_consistency='BEFORE'`, so this chapter states the anomaly and points forward.
4. The closing tools stated precisely: `WAIT_FOR_EXECUTED_GTID_SET()`, `SOURCE_POS_WAIT()`.
5. **What read scaling does not scale** - writes, and the applier's own throughput.
6. **MySQL Router: at most one paragraph** (map scope rule). Application-level sharding, Vitess and
   ProxySQL are out of scope entirely.

Measurement mechanics from ticket 08: lag is induced with `SOURCE_DELAY` by default and **every such
caption says so in Serbian**; **exactly one figure** shows natural lag (burst into `visits`, applier
pinned to one worker) and its caption says that too. The `heartbeat` table is what the time-series
samples.

**Shape of a chapter ticket** (same as Temas 1 and 2, per the map's execution override): this ticket
is resolved only when **the lesson has been taught, the examples have been run against the live
topology, and the Serbian prose is appended to `rad.md`** - and the lesson and the writing happen in
**different sessions** (`../WORKFLOW.md`).

Binding on every session here: `GLOSSARY.md` (terms are locked - do not re-translate), the theory
budget in `GLOSSARY.md` section 3, the caption honesty rule in section 5, `academic-research-writer`
for all prose, `serbian-grammar` for every Serbian line, and the two research rules in
`../../NOTES.md` (**no unverified absence claim**, **walk the source ladder and record the rung**).

## Comments

- **From ticket 12:** `pip install --user matplotlib`, then write `tools/make-lag-plot.py`: one natural-burst chart with both lag series overlaid, asserting that they diverge. Sampler output goes to `figures/raw/<figure-base>.csv`. Spec in `figures/README.md`.

- **Lesson half done (2026-10-28):** `lessons/0007-skaliranje-citanja.html`, record 0009, measurements 0009. Slika 7.1 generated and asserting (`tools/make-lag-plot.py`); scripts in `examples/04-read-scaling/`. Tabela 7.1's async half: measurements 0009 §3; GR half: 0007 (`42-ryw-before.js`).

## Resolution (writing session, 2026-10-28)

Ch. 7 appended to `rad.md`: **~1390 words of prose, Slika 7.1 + Tabela 7.1, measured at ~3.5 rendered
pages** (Word COM, same method as ch. 5 and 6; budget 3.5, on it). Over the §2b word cap by ~190 words,
accepted since the rendered count is the final word. Spaced retrieval 2/3 at the start: missed
*which SBS weakness performance_schema keeps* (chose the MTS one); repaired with the "what it looks at vs
who writes the timestamp" split, and the clock-skew variant was then answered correctly.

- **Item 1 (SBS vs performance_schema)**: the three weaknesses come from refman's own definition, quoted
  per sentence (rung 1, researcher 2026-10-28). performance_schema is cited as the manual's *recommended*
  method (§19.4.11 "Monitoring Replication Delay"). Rule 1 was checked twice and recorded in an HTML
  comment: no refman sentence says SBS includes receive time, and no clock-synchronization sentence exists
  for the timestamps. So "performance_schema keeps clock skew" is stated as **derived** from the column
  definitions, and the one-clock sandbox is named as the reason the skew is zero here.
- **Item 2 (lag, applier as source)**: lag is defined per transaction, t2 − t0, with both phases counted.
  The single-transaction split (≈ 9/10 apply) and the burst (relay log final in < 1 s, lag ~30 s more)
  collect ch. 3's forward pointer.
- **Item 3 (anomalies)**: RYW and monotonic reads on `SOURCE_DELAY = 3`, each said to be induced.
  Diagnosed as received-not-applied.
- **Item 4 (tools)**: `WAIT_FOR_EXECUTED_GTID_SET` (0/1, timeout 0 = forever) and `SOURCE_POS_WAIT`
  (events/-1/NULL), stated exactly. Tabela 7.1 holds the async rows plus ch. 5's `BEFORE` row (0007).
  The point the chapter leads with is that a returned 1 leaves the read stale, so the app must check it.
  "Timeout 0 hangs" is labelled derived, not measured.
- **Item 5 (what does not scale)**: W > A backlog per replica, derived, illustrated by the burst
  (~3 300 tx/s vs ~60 tx/s). Parallel applier: 8.4 default 4 workers + writeset dependencies (8.4.0
  relnotes). The ticket-10 8.2× number was **left out**: its own caveat makes it an upper bound, and it
  cost words.
- **Item 6 (Router)**: one paragraph on read/write splitting + `wait_for_my_writes` /
  `_timeout` (default 1 s, fallback to the write instance), from the **Router 8.4 manual (rung 2)**. New
  bib entry `mysqlrouter84`. Router was not run, and the text says so.
- Spine: replica = EL in PACELC; consistency is the reader's decision, bought with the reader's wait.
- Table layout: column widths set by separator dashes after the DOCX check (code cells were wrapping
  mid-identifier).
