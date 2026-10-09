# Chapter 3 - Binarni log, GTID i asinhrona replikacija

Type: task (execution - see the map's execution override)
Status: **closed** (2026-10-09) - lesson taught, chapter written, cut, measured and pushed

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

Progress (2026-10-09, later session): **scope of the cut widened to ch. 2 as well.** The user found
the paper too text-heavy after two chapters (~10 pp, 3 figures). Decided: `../WRITING.md`'s
"never trim" rule is **suspended for this topic** (`GLOSSARY.md` §2b); ch. 2 is cut to **~3 pp**, ch. 3
to **~3.5 pp** (~35 % by pages, more by words, because figures do not shrink); ch. 4-8 get a
**~450 words/page** cap plus at least one visual per ~1.5 pages. **The user still does the cuts by
hand.** Prose-to-visual swaps proposed, awaiting his pick: CAP thought experiment (ch. 2), the
Dynamo-vs-consensus quorum worked example (ch. 2, no picture exists yet), two-phase commit with
crash points A/B (ch. 3), the durability matrix as a Tabela (ch. 3). **Open until**: cuts in, both
chapters re-measured, budgets set to measured values, pushed.

Progress (2026-10-09, same session, user reversed himself: "you cut it, I review"): **cut done by
the agent, uncommitted, awaiting the user's review.** Words: ch. 2 2130 -> 1416, ch. 3 2600 -> 1689
(both about -34 %); all 16 citation keys still used; no em dash. All four visuals added: Slika 2.1
CAP, Slika 2.3 Dynamo vs consensus quorum, Slika 3.2 two-phase commit, Tabela 3.1 durability
matrix (qualitative; ch. 4 keeps the latency matrix). Figures renumbered in reading order (old 2.1 ->
2.2, old 3.2 -> 3.1, old 3.1 -> 3.3), files and the `05-slika-nesiguran-iskaz.ps1` script
renamed to match. Pre-cut text kept at `.scratch/rad-before-cut.md`. **Measured in the export:
ch. 2 ~3.6 pp (budget 3), ch. 3 ~4.8 pp (budget 3.5)**, total 11 pp with title and references
(was 12). Ch. 3 is over because the new figure and table add ~0.6 pp, and Slika 3.1 still jumps
and leaves its blank third of p. 6. Dropped outright: NOW()/SYSDATE() mechanism, the 100-commit
fsync measurement (ch. 4 measures it), the file/position numeric example, Abadi's PA/EL system
list, sloppy quorum, Raft vote details beyond one sentence each. Native table renders without
borders (the figures/README first-use check; fix in `build-reference-doc.py`).

## Resolution (2026-10-09)

User reviewed the exported document ("looks good") and accepted the measured lengths: **ch. 2 ~3.6 pp,
ch. 3 ~4.8 pp**, set as the budgets in `GLOSSARY.md` section 2 (paper total 24.9). Final review fixes:
Tabela 3.1 row 1 softened from "ništa se ne gubi" to the manual's own "najveća postojanost i
konzistentnost"; Slika 3.2's official-diagram check done (refman 8.4 sections 7.4.4, 17.6.5 and 17.18.2: text
only, no figure), recorded in `figures/README.md`. Table borders fixed the same day: pandoc
ignores the reference doc's `Table` style, so `../tools/make-docx.ps1` now runs
`../tools/style-docx-tables.py` on the exported file (Temas 1 and 2 not re-exported, they carry
hand edits). Slika 3.1's page jump is left for the final Word pass.

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
