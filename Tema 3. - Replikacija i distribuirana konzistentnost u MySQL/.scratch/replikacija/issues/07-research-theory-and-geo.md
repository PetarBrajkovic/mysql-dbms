# Research: distributed-consistency theory, geo-distribution, and the bibliography

Type: research
Status: resolved

## Question

The professor's bullets are written in the vocabulary of the distributed-systems literature, not of
the MySQL manual. This memo supplies that vocabulary, its citable sources, and the judgement call on
whether geo-distribution can carry a chapter. It is also the memo that must come back with **full
bibliographic detail ready for `references.bib`** - Tema 2's equivalent ticket did exactly this and it
was the single most reusable thing it produced.

Produce a memo at `../research/07-theory-and-geo.md` answering:

1. **The consistency vocabulary**, defined precisely and each tied to a citable source: strong
   consistency / linearizability, sequential consistency, causal consistency, eventual consistency,
   read-your-writes and monotonic reads. Then place MySQL's asynchronous replica, a semisynchronous
   setup, and each Group Replication consistency level on that map.
2. **CAP and PACELC**: Brewer's conjecture, Gilbert and Lynch's proof, and Abadi's PACELC refinement -
   with the standard misreadings called out, because a seminar paper that loosely repeats "pick two"
   invites exactly the question the professor will ask. Where Group Replication sits, and where
   asynchronous replication sits; they are not the same answer.
3. **Replication models as the literature classifies them**: single-leader, multi-leader, and
   leaderless / quorum-based (Dynamo-style, R + W > N). Enough of the quorum arithmetic to make
   majority non-magical. **Note explicitly** that Group Replication's quorum is a *consensus* quorum,
   not a Dynamo-style read/write quorum - a confusion the bullet list's phrasing makes easy to fall
   into.
4. **Consensus, at the right depth**: Paxos and Raft named, what they solve, why Group Replication
   needs one. The map's open question is how deep to go - recommend a depth for a DBMS seminar paper
   and justify it. Do not write a proof.
5. **Geo-distributed replication**: what changes when the link is slow - the physics of it, the design
   responses (asynchronous cross-region links, per-region leaders, conflict resolution), and what
   MySQL actually offers (asynchronous replication channels, multi-source replication,
   `group_replication_member_expel_timeout`, and why a group is not meant to span regions). **Then the
   verdict this ticket owes the map: is geo-distribution its own chapter, or a section of the
   multi-leader chapter?** One machine and one network means nothing here is measurable; say whether
   there is enough citable substance for a standalone chapter regardless.
6. **The bibliography**: full entries - authors, title, publisher or venue, year, edition, DOI or ISBN
   - for everything worth citing. Expect Kleppmann's *Designing Data-Intensive Applications*, Gray and
   Reuter, Lamport on Paxos, Ongaro and Ousterhout on Raft, Brewer, Gilbert and Lynch, Abadi,
   DeCandia et al. on Dynamo, and Bailis on eventual consistency. Verify each against a real
   bibliographic record rather than reconstructing it from memory.

Flag any claim you are less than fully confident in. Tema 2's equivalent memo shipped one false claim
that had to be corrected in place after it had already been accepted.

## Answer

Resolved at charting, 2026-09-17. Findings: [`research/07-theory-and-geo.md`](../research/07-theory-and-geo.md)

**The verdict this memo delivered has since been WITHDRAWN. Read this before using the memo.**

As delivered, the memo ruled that geo-distribution is a section of the multi-leader chapter rather
than a chapter of its own, resting on three reasons - thematic overlap with multi-leader, nothing
measurable on one machine, and **"MySQL does not provide dedicated geo-distribution features."**

**That third reason is false, and it was the load-bearing one.** MySQL ships **InnoDB ClusterSet**:
a primary InnoDB Cluster linked to replica clusters *"in alternate locations, such as different
datacenters"* (MySQL Shell 8.4 manual, ch. 8), with a dedicated replication channel, read-only
non-diverging replica clusters, controlled switchover and emergency failover - all Community/GPL via
AdminAPI. The memo never mentions it. Caught when the user asked whether MySQL can do
geo-distribution at all; verified against the manual before the memo was corrected in place.

**Two consequences:**
- **The chapter-vs-section verdict is reopened** and is now an open decision for ticket 09, which must
  re-take it knowing a concrete free MySQL feature exists to explain. Reasons 1, 2, 4 and 5 still
  stand and may still carry it.
- **Demonstrability improved.** A ClusterSet needs two *clusters*, but a cluster may be single-member,
  so two or three local instances can form a real one. Controlled switchover and emergency failover
  look demonstrable locally, pending ticket 11. Only the *latency* is undemonstrable, and that is
  physics, not a missing feature.

**The memo's best single find, added during the correction**: the manual states that *"InnoDB
ClusterSet prioritizes availability over data consistency in order to maximize disaster tolerance"*
and that *"there is no guarantee that data will be preserved in the event of an emergency failover."*
So the same product is consistency-favouring **inside** a cluster (Group Replication quorum) and
availability-favouring **between** clusters, and says so in its own documentation. That is the
paper's cleanest bridge from CAP/PACELC to a named MySQL feature.

The consistency vocabulary is defined and each MySQL mode placed on it. CAP and PACELC are covered
with **four standard misreadings explicitly called out**, which is exactly the defensive work a
seminar paper needs, since a loose "pick two" invites the question the professor would ask. Group
Replication and asynchronous replication are placed differently, as they should be. The
**consensus-quorum vs Dynamo-quorum distinction is stated explicitly** - the confusion the
professor's own bullet phrasing invites. Recommended consensus depth for a DBMS seminar: conceptual
(leader election, log replication, quorum safety), no proofs.

**~12 bibliography entries verified against primary records** and ready for `references.bib`:
Kleppmann, Gray & Reuter, Herlihy & Wing, Lamport, Gilbert & Lynch, Abadi, Ongaro & Ousterhout,
DeCandia et al., Terry et al., Bailis et al., Vogels, Brewer. 10 claims carry explicit confidence
flags; the geographic latency figures are marked as order-of-magnitude approximations rather than
citable numbers. Tema 2's lesson applies - its equivalent memo shipped one false claim - so ticket 09
should treat the flagged items as unsettled.
