# Chapter 3 - Binarni log, GTID i asinhrona replikacija

Type: task (execution - see the map's execution override)
Status: open
Blocked by: 10, 12, 14

## Question

Write ch. 3, **~4.5 pages**, the mechanism chapter and the longest of the non-Group-Replication
chapters. Covers professor bullets #1 and #2. Backed by memo 03 (the foundation memo, and the one with
15 claims flagged for live verification - **verify them at ticket 10 before writing, not after**).

Must contain:

1. What actually ships between servers: the binary log, its formats (`STATEMENT` / `ROW` / `MIXED`)
   and unsafe statements - the running example gives this for free via `UPDATE ... LIMIT` on `invoices`
   (ticket 08).
2. The durability matrix: `sync_binlog` against `innodb_flush_log_at_trx_commit` over the redo-binlog
   two-phase commit. This is where the deck's *postojanost* and *oporavak* are reused in a replication
   setting.
3. GTIDs and `SOURCE_AUTO_POSITION`; the receiver/relay/applier pipeline, with **lag attributed
   overwhelmingly to the applier, not the receiver** (memo 03) - a forward pointer ch. 7 collects.
4. **The vocabulary switch, stated in the text** (`GLOSSARY.md` section 1d): from here on the paper
   says *izvor* and *replika*, and it says why - MySQL renamed the roles. One footnote on
   *master/slave*, never mentioned again.

The spine's first concrete instance lands here: asynchronous replication is the setting where the
writer is told "committed" before anyone else has seen the transaction.

**Shape of a chapter ticket** (same as Temas 1 and 2, per the map's execution override): this ticket
is resolved only when **the lesson has been taught, the examples have been run against the live
topology, and the Serbian prose is appended to `rad.md`** - and the lesson and the writing happen in
**different sessions** (`../WORKFLOW.md`).

Binding on every session here: `GLOSSARY.md` (terms are locked - do not re-translate), the theory
budget in `GLOSSARY.md` section 3, the caption honesty rule in section 5, `academic-research-writer`
for all prose, `serbian-grammar` for every Serbian line, and the two research rules in
`../../NOTES.md` (**no unverified absence claim**, **walk the source ladder and record the rung**).
