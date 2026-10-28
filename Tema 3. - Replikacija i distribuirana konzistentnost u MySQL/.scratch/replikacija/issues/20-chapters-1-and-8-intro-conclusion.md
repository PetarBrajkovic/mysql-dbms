# Chapters 1 and 8 - Uvod i Zaključak

Type: task (execution - see the map's execution override)
Status: **closed** (2026-10-28) - Zaključak and Uvod both written, measured and pushed

**Shape decided by the user (2026-10-28)**: no lesson, per `../WORKFLOW.md` ("an introduction and a
conclusion need no teaching at all"), which overrides the generic chapter-ticket shape below. Two
writing sessions: **Zaklju\u010dak first** (the argument is now known), then **Uvod**, written
against it and reconciled with it. The ticket closes after the second session.
Assignee: Pex
Blocked by: 19 — closed

## Question

Write ch. 1 (**1 page**) and ch. 8 (**1 page**) last, when every body chapter exists and the
argument is known rather than predicted. Same as Temas 1 and 2.

**Uvod** states the spine (`GLOSSARY.md` section 0) as the paper's claim, frames the five areas the
paper covers, and says what the topology is - three local `mysqld` instances - so no reader mistakes
the measurements for a datacenter. It does **not** define theory terms; ch. 2 does that.

**Zaključak** collects the spine's thread: each chapter showed one knob and what the operator buys with
it, and the conclusion is where they are put in one table or one sequence. The strongest single piece
of evidence - the vendor taking opposite CAP positions at two scopes (ch. 5 vs ch. 6) - is restated
here, because it is the thing the professor is most likely to press on.

Neither chapter introduces a claim that no body chapter established.

**Shape of a chapter ticket** (same as Temas 1 and 2, per the map's execution override): this ticket
is resolved only when **the lesson has been taught, the examples have been run against the live
topology, and the Serbian prose is appended to `rad.md`** - and the lesson and the writing happen in
**different sessions** (`../WORKFLOW.md`).

Binding on every session here: `GLOSSARY.md` (terms are locked - do not re-translate), the theory
budget in `GLOSSARY.md` section 3, the caption honesty rule in section 5, `academic-research-writer`
for all prose, `serbian-grammar` for every Serbian line, and the two research rules in
`../../NOTES.md` (**no unverified absence claim**, **walk the source ladder and record the rung**).

**Carried from ch. 6 writing (2026-10-27)**: when restating the two-scope CAP evidence, use ch. 6's sharper
form, not ch. 5's closing sentence alone. Across clusters the replica cluster *refused writes* (C) until
the operator ran `forcePrimaryCluster()`, so the A choice is one operator command. That is the spine in its
strongest form ("konzistentnost je odluka operatera").

## Comments

- **Zaključak written (2026-10-28, session 1 of 2).** Appended to `rad.md` as `# 8. Zaključak`. It has
  **271 words of prose plus Tabela 8.1**, one row per body chapter 3-7: the knob, what it buys, and
  who pays and how. That is the ticket's "one table". It measured **~1.08 rendered pages** (Word COM,
  ch. 8 heading p. 24 y540 to Reference p. 25 y597, the same method that reproduces ch. 7's 3.5).
  The first draft was 400 words and ~1.5 pp, and was cut to budget under GLOSSARY §2b.
  - The two-scope CAP evidence is restated in **ch. 6's sharper form**, as this ticket required: the
    replica cluster stayed read-only until `forcePrimaryCluster()`, paired with forced quorum inside
    the group. So **availability is an operator command at both scopes**, which ends on the spine.
  - **No new claims and no new sources.** The two citations (`mysql84refman` for `AFTER`'s
    "strong consistency" recommendation, and `mysqlshell84` for ClusterSet's availability priority)
    are already used and fetched in chs. 5 and 6. "Narrower than their names" re-states only ch. 4's
    and ch. 5's established findings.
  - Limitation stated: everything was measured on one machine, so inter-location distance is derived,
    not measured (as in ch. 6). That is offered as further work.
  - **Terminology fix**: the GLOSSARY §0 spine said *operatora*, but `rad.md` uses *operater*
    throughout (16 times). The spine is now aligned to *operatera* before Uvod quotes it.
- **Next session: Uvod** (~1 page). State the spine (now worded as in ch. 8's last paragraph), frame
  the five areas, and say that the topology is three local `mysqld` instances. Then reconcile with
  ch. 8: the claims should match, and Uvod's chapter roadmap should match the table's row order.
  Close the ticket after that, then append both to the map's Decisions-so-far.
- **Uvod written (2026-10-28, session 2 of 2). Ticket closed.** Appended to `rad.md` as `# 1. Uvod`:
  **386 words, no figure, no citation**, measured at **~0.8 rendered pages** (Word COM, ch. 1 heading
  p. 2 y71 to ch. 2 heading p. 2 y617), under its 1-page budget. Total export: 28 pages including
  title page and references.
  - Four paragraphs: the question replication opens (failover, read scaling, another location all
    lead to "when may the writer be told, and what may a read elsewhere return"). Next, **the spine
    worded identically to ch. 8's last paragraph**, plus the mechanism (one binary log; only the
    acknowledgement point and who waits change) and a one-line pointer to the two-scope CAP evidence
    in chs. 5-6. Then the roadmap, and finally the topology disclaimer.
  - **Reconciled with ch. 8**: the mechanism sentence mirrors ch. 8's opening, and the roadmap of
    chs. 3-7 follows Tabela 8.1's row order. The topology paragraph matches ch. 8's limitation
    (three instances on one machine; distance is derived, not measured).
  - **No new claims.** One sentence from the first draft was removed during reconciliation:
    "all tools used are part of the free Community edition" is true, but no body chapter establishes
    it. The sub-millisecond round trip being shorter than a disk sync comes from ch. 4.
  - Terms as in `GLOSSARY.md`. *certification* is glossed on first use in document order, which is
    now ch. 1. Ch. 5's own gloss is left in place, so that chapter still reads on its own.
