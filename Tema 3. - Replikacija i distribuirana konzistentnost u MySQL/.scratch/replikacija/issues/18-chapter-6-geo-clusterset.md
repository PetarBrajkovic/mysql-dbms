# Chapter 6 - Geo-distribuirana replikacija i InnoDB ClusterSet

Type: task (execution - see the map's execution override)
Status: open
Blocked by: 11, 17

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
