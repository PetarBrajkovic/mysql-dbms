# Chapter 7 - Skaliranje čitanja i kašnjenje replikacije

Type: task (execution - see the map's execution override)
Status: open
Blocked by: 18

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
