# Chapter 6 - Geo-distribuirana replikacija i InnoDB ClusterSet

Type: task (execution - see the map's execution override)
Status: **closed** (2026-10-27) - lesson taught, examples run live, chapter written, measured
Assignee: Pex
Blocked by: 11, 17 — both closed

## Question

Write ch. 6, **~3 pages**. Covers professor bullet #4. This chapter exists because ticket 09
**re-took** the chapter-vs-section call from scratch after memo 07's demotion was withdrawn - its
load-bearing reason ("MySQL has no dedicated geo-distribution feature") was **false**.

Must contain:

1. **InnoDB ClusterSet** as the named, free, Community feature: a primary cluster linked to replica
   clusters *"in alternate locations, such as different datacenters"*, its dedicated ClusterSet
   replication channel, and replica clusters that are **read-only and therefore cannot diverge** -
   MySQL's architectural sidestep of cross-region multi-leader conflict.
2. **Controlled switchover vs emergency failover**, using the pair defined in ch. 4, plus the manual's
   own warning that *"there is no guarantee that data will be preserved"* on emergency failover.
3. **The CAP/PACELC payoff of the whole paper**, which ticket 09 placed here rather than in ch. 2: the
   vendor's own *"InnoDB ClusterSet prioritizes availability over data consistency in order to maximize
   disaster tolerance"* set against Group Replication's consistency-favouring behaviour inside a
   cluster. **The same product takes opposite CAP positions at two scopes, in its own words** - quote
   both, side by side.
4. Why Group Replication across regions is not the answer (member expel timeouts), and the physics of
   geo-distribution in one paragraph - no more, per the theory budget.

What ticket 11 establishes as demonstrable locally goes in as a real figure; whatever is not is
**named explicitly as theory from primary sources**, never approximated silently. Renting real
geo-distributed infrastructure is out of scope.

**Shape of a chapter ticket** (same as Temas 1 and 2, per the map's execution override): this ticket
is resolved only when **the lesson has been taught, the examples have been run against the live
topology, and the Serbian prose is appended to `rad.md`** - and the lesson and the writing happen in
**different sessions** (`../WORKFLOW.md`).

Binding on every session here: `GLOSSARY.md` (terms are locked - do not re-translate), the theory
budget in `GLOSSARY.md` section 3, the caption honesty rule in section 5, `academic-research-writer`
for all prose, `serbian-grammar` for every Serbian line, and the two research rules in
`../../NOTES.md` (**no unverified absence claim**, **walk the source ladder and record the rung**).

## Progress

- **2026-10-27 — lesson taught** (lesson 0006, record 0008, reference `clusterset.html`). Live re-run of
  20, 38, 39, 40 (+ new `43-clusterset-status.js`): switchover 539/444 ms, forced failover 21 617 ms,
  replica cluster did not self-promote, INVALIDATED until `rejoinCluster`; 3308 needed `rejoinInstance`.
  All four "Must contain" items taught; quotes verified (Shell `8.4` URLs serve 26.7 content: re-check
  wording at writing). Sandbox returned to async, 3306 untouched. Remaining: the ch. 6 prose in a
  separate session.

**Carried from ch. 3 writing (2026-10-09)**: refman 8.4 documents *Asynchronous Connection Failover*
(a replica re-points automatically to another source from a stored list; needs GTIDs and
`SOURCE_AUTO_POSITION`; also a Group-Replication-aware variant). It re-points a connection and is not
documented as promoting a replica. Any sentence here contrasting "automatic" group failover with
"manual" async failover must account for it (rule 1). Ch. 3 avoided the claim; see the HTML comment there.

## Resolution (2026-10-27, writing session)

Ch. 6 appended to `rad.md`: **~1110 words of prose, Slika 6.1, Tabela 6.1, measured at ~3.15 rendered
pages** (Word COM, same method as ch. 5's 4.4; budget 3, 0.15 over, nothing cut). Spaced retrieval at the
start (record 0008's three questions): **3/3**, including CAP judged per operation, the gap the lesson closed.

- **Item 1 (ClusterSet)**: primary cluster + replica clusters, `clusterset_replication` async, one writer,
  single-primary required (all rung 2, verified this session). Conflict across locations is *prevented by
  architecture* rather than resolved by certification. `super_read_only` on 3308/3309 stated as measured
  (ERROR 1290), not quoted. What OK covers (primary cluster's majority) and the loss window in the channel
  are in the text and on Slika 6.1.
- **Item 2 (switchover vs forced failover)**: Tabela 6.1 from measurement 0008 (444/539 ms vs 21.6 s, with
  ticket 11's 0.48 s / 23 s in the caption). The switchover mechanism is told from Shell's own printed
  steps (old cluster locked and drained). The failover is told as measured: 3309 did not promote itself
  and refused writes for 20 s, and the manual describes `forcePrimaryCluster()` as an operator procedure.
  That is the rule 1 form recorded in measurement 0008, kept as an HTML comment. `INVALIDATED`, the
  split-brain warning, fencing and "no guarantee that data will be preserved" are included. Router gets one
  sentence: it re-routes automatically if it follows the primary, so routing is automatic and promotion is not.
- **Item 3 (CAP payoff)**: the Shell manual's two consecutive sentences (ClusterSet *prioritizes availability*
  / consistency within each cluster *guaranteed by* Group Replication) are quoted verbatim in English and
  glossed, set against the refman's "does not progress until this issue is resolved". **The chapter's strongest
  move, from record 0008**: before `forcePrimaryCluster()` the replica cluster chose C. So A across clusters
  is the operator's single command, not a system property. PACELC else-branch: EL.
- **Item 4 (why not GR across regions)**: physics paragraph on ITU-T G.114 (**new bib entry `itug114`**).
  The researcher read the fibre row as 6 us/km, next to a 5 us/km row, so the text says "a few us/km" and
  "at least ~10 ms RTT per 1000 km", true for either. The derived dilemma: either pay an inter-location RTT
  per commit, or put the majority in one location and lose quorum with it. It is labelled derived. Expel:
  5 s detection + 5 s default `member_expel_timeout`, from the refman. Not demonstrable locally, and said so.
- **Quotes**: all Shell quotes re-verified this session. The `8.4` URLs serve Shell 26.7, but the wording is
  identical on the `8.0` pages, which closes the lesson's caveat. A separate controlled-switchover page does
  not exist (404).
- **Slika 6.1**: the official `innodb_clusterset_main.png` was checked: English labels, it shows no locations,
  and it does not mark the OK scope or the loss window. A Mermaid draft came out 4.4:1, so it was redrawn
  as SVG at 2:1 (`figures/06-geo-01-clusterset.svg`). Smallest text is about 6 pt at page width; ticket 13 should re-check it.
