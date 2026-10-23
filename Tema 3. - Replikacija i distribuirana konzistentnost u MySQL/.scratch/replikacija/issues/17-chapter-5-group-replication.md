# Chapter 5 - Group Replication: kvorum, certification i multi-primary

Type: task (execution - see the map's execution override)
Status: **closed** (2026-10-23) - lesson taught, examples run live, chapter written, measured and pushed
Blocked by: 11, 16

## Question

Write ch. 5, **~5 pages, deliberately the longest chapter**. It carries professor bullet #3 on its
own - both "Multi-Leader" and "Quorum-Based" - and ticket 09 kept it as **one** chapter because
splitting quorum from multi-primary would duplicate the certification machinery in both halves.
Backed by memo 05, the paper's likely centrepiece.

Must contain:

1. Certification with **skupovi upisa** and first-commit-wins. `certification` stays English, glossed
   once as *provera saglasnosti transakcija* (`GLOSSARY.md` section 1b) - do not write *sertifikacija*.
2. **Majority quorum, with the minority blocking rather than diverging** - i.e. the chapter's job is to
   say what does *not* happen, which is why `split brain` has to be introduced (glossed once) in order
   to be denied.
3. Single-primary vs multi-primary, with memo 05's honest verdict: multi-primary is justified only for
   high write availability with few conflicts.
4. **The closing payoff**: `group_replication_consistency`'s levels mapped one by one onto ch. 2's
   named models. This is the paper's direct bridge from the professor's vocabulary to a MySQL knob and
   the single strongest evidence for the spine - it is the chapter's climax, not a table dropped at the
   end.

Demos from ticket 08: the **conflict pair** (same invoice - one rolled back; two different invoices -
both commit, showing certification is row-level not table-level), the throwaway **`no_pk_demo`** table
rejected for lacking a primary key (created and dropped inside this chapter), and the second half of
the read-your-writes sequence, closed by `group_replication_consistency='BEFORE'`.

**Shape of a chapter ticket** (same as Temas 1 and 2, per the map's execution override): this ticket
is resolved only when **the lesson has been taught, the examples have been run against the live
topology, and the Serbian prose is appended to `rad.md`** - and the lesson and the writing happen in
**different sessions** (`../WORKFLOW.md`).

Binding on every session here: `GLOSSARY.md` (terms are locked - do not re-translate), the theory
budget in `GLOSSARY.md` section 3, the caption honesty rule in section 5, `academic-research-writer`
for all prose, `serbian-grammar` for every Serbian line, and the two research rules in
`../../NOTES.md` (**no unverified absence claim**, **walk the source ladder and record the rung**).

**Carried from ch. 3 writing (2026-10-09)**: refman 8.4 documents *Asynchronous Connection Failover*
(a replica re-points automatically to another source from a stored list; needs GTIDs and
`SOURCE_AUTO_POSITION`; also a Group-Replication-aware variant). It re-points a connection and is not
documented as promoting a replica. Any sentence here contrasting "automatic" group failover with
"manual" async failover must account for it (rule 1). Ch. 3 avoided the claim; see the HTML comment there.

## Progress

- **2026-10-23 — lesson taught** (lesson 0005, record 0007, reference `group-replication.html`).
  Live: conflict pair (1180, both-commit on different rows), `41-no-pk-live.js` (ER 3098),
  `42-ryw-before.js` (BEFORE closes RYW, reader pays). Found: 8.4 default level is
  `BEFORE_ON_PRIMARY_FAILOVER`; 0002 corrected. Remaining: the ch. 5 prose in a separate session.

## Resolution (2026-10-23, writing session)

Ch. 5 appended to `rad.md`: **~1590 words of prose, Slika 5.1, Tabela 5.1, Tabela 5.2, measured at
~4.4 rendered pages** (budget 5; nothing raised, nothing cut). Ch. 2-5 now ~3.6 + 4.8 + 3.0 + 4.4.
Spaced retrieval at the start (record 0007's three questions): **3/3**, and the multi-primary write-scaling
misconception did not come back.

- **Item 1 (certification)**: write-set as the refman defines it ("unique identifiers of the rows that were
  updated", summary page, verified this session), total order as *zajednički niz*, deterministic verdict
  with no voting, *first commit wins* glossed as *prvi po redosledu pobeđuje* with "first in the order, not
  by clock". The PK rule is demonstrated with `41-no-pk-live.js` (ER 3098) and the conflict pair: 1180/149,
  and the both-commit case shows the conflict is per row, not per table. The loser gets a general commit
  error and must retry. `COUNT_CONFLICTS_DETECTED` and bug 78705 were left out: this detail belongs in
  the lesson, not the paper.
- **Item 2 (quorum)**: Tabela 5.1 from measurement 0002 §4. The text says why a kill was needed rather than a
  clean stop (a graceful leave recomputes the majority). Split brain is glossed in order to be denied. In
  CAP terms the minority chooses C **for writes**, while reads are still served from its last state; this
  nuance is stated rather than claiming a pure CP. The forced-quorum repair is framed as the operator
  choosing A, with the suspended write that later committed as the evidence.
- **Item 3 (modes)**: single-primary default + `super_read_only` (verified, rung 1); the contrast with async
  is **who promotes**, with Asynchronous Connection Failover named (rule 1, HTML comment in `rad.md`).
  Multi-primary limits come from refman 20.3.2. The "does not scale writes" verdict is **stated as derived**.
  The refman makes no scaling claim; its only "write scale-out" line is about sharding (checked this
  session, kept as an HTML comment).
- **Item 4 (climax)**: Tabela 5.2 joins 0007 (default, EVENTUAL and BEFORE on the reader, two series) with
  0002 (AFTER and BEFORE_AND_AFTER on the writer, one series, reader time not measured). Its last column
  maps each level to a ch. 2 model and is labelled *izvedeno*. The climax sentence: closing the gap costs
  about one apply time, and the level chooses who pays. **New nuance found this session**: refman
  §20.5.3.2 Scenario 6 recommends `AFTER` when "strong consistency" is needed. The chapter argues that in
  ch. 2's sense it is not linearizable: members apply one after another while the writer waits, so it is
  read-your-writes for every reader of that write.
- **Slika 5.1**: the official `gr-replication-diagram.png` (refman summary page) was checked. It has
  English labels and shows one transaction's flow, not two conflicting ones resolved identically on every
  member, so we drew our own. The first draft was 3.9:1 (about 5 pt type at page width) and was redrawn
  top-to-bottom at 1.67:1, width 100 %. Tabela 5.2's columns had to be widened explicitly (pipe-table
  dash widths), because pandoc's default split words mid-cell.
- **No new bib entries**: `mysql84refman`, `mysqlshell84`, `mysql84relnotes` (8.4.0 default level) cover it.

