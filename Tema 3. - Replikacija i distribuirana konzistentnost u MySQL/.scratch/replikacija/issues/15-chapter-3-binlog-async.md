# Chapter 3 - Binarni log, GTID i asinhrona replikacija

Type: task (execution - see the map's execution override)
Status: open - **writing half claimed** (new session after lesson B)

Progress (2026-10-08): the lesson half is split into two lessons, **both taught**. Lesson A
(`lessons/0002-binarni-log-gtid-asinhrona.html`, record 0004: items 1, 3, 4 and the async-commit
window); lesson B (`lessons/0003-postojanost-wal-dvofazno-komitovanje.html`, record 0005: item 2,
durability). Remaining: the writing half.

Progress (2026-10-09, writing session): **ch. 3 drafted and appended to `rad.md`** (6 sections,
16 paragraphs, footnote on master/slave, Slika 3.1 pipeline + Slika 3.2 unsafe `UPDATE ... LIMIT`
from live output). **Measured ~5.8 rendered pages against the 4.5 budget.** The user chose to
**tighten the prose himself** rather than raise the budget or drop Slika 3.2. **Open until**: his cuts
are in, the chapter is re-measured, the budget line in `GLOSSARY.md` §2 is set to the measured value,
and the chapter is pushed. Then close and add the map's Decisions-so-far entry.

Writing-session findings worth keeping:
- **Rule 1 caught a live trap**: refman 8.4 has *Asynchronous Connection Failover* (a replica
  re-points to another source from a stored list, GTID + auto-positioning). Any "async replication has
  no automatic failover" sentence would be false; ch. 3 states only the manual's positive procedure
  (19.4.8: the operator picks the new source). Check recorded in an HTML comment in `rad.md`.
- "Two logs" got its citation without a history claim: refman 17.19 lets InnoDB on the source
  replicate to MyISAM on the replica, which shows the binlog is engine-independent.
- `storage engine` borrowed from Tema 1's locked table (`GLOSSARY.md` §1b⁗).
- Layout: at 90% width Slika 3.2 does not fit the remainder of its page and jumps, leaving ~1/3 page
  blank. Left alone on purpose: ch. 1 will shift every break; fix at the final Word pass.
- Shared tool fixed: `../tools/make-table-figure.ps1` now polls for Edge's screenshot (it returned
  before the file existed) and sizes `-Raw` figures to the text instead of a fixed 1400 px canvas.
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
