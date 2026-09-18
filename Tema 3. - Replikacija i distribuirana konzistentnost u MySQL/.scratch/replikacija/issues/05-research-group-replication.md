# Research: Group Replication, quorum, and multi-primary

Type: research
Status: resolved

## Question

Covers two of the professor's five bullets at once - **multi-leader** and **quorum-based** - and is
the most likely centrepiece of the paper. It is also the place where MySQL comes closest to the
distributed-systems literature the bullet list is written in, so it needs both halves: what MySQL
does, and what it is an instance of.

Sources: the MySQL 8.4 reference manual's Group Replication chapter first; the Group Replication
worklogs and the XCom documentation where the manual is silent.

Produce a memo at `../research/05-group-replication.md` answering:

1. **What Group Replication actually is**: the group communication system (XCom, a Paxos variant),
   what a "group" agrees on, and how a transaction flows from client to certification to commit.
2. **Certification-based conflict detection** - the mechanism, why it is optimistic, what a write-set
   is, and how a conflicting transaction is rolled back on one member. This is what makes
   multi-primary possible at all, and it is the honest answer to "how does MySQL handle multi-leader
   write conflicts".
3. **Quorum**: why a majority, what happens to a minority partition (blocked, not diverged), the
   `group_replication_unreachable_majority_timeout` and `group_replication_exit_state_action`
   behaviours, and what "split brain" means here compared to what it means in multi-leader systems
   generally.
4. **Single-primary vs multi-primary mode** - the default, why the default is what it is, and the
   concrete restrictions multi-primary imposes (foreign keys with cascading actions, `SERIALIZABLE`,
   concurrent DDL). The honest verdict on whether multi-primary is a good idea is a finding, not a
   diplomatic hedge.
5. **The consistency levels**: `group_replication_consistency` (`EVENTUAL`, `BEFORE`, `AFTER`,
   `BEFORE_AND_AFTER`), what each one waits for, and how they map onto named consistency models in
   the literature. This is the paper's direct bridge between MySQL's knobs and the professor's
   vocabulary - treat it as high-value.
6. **How much of it is free**: confirm Group Replication, InnoDB Cluster, MySQL Shell and MySQL
   Router are all Community. Flag anything that is not.
7. **Standing up a three-member group on one host**, as a command sequence, 8.4-current - both the
   manual configuration path and the MySQL Shell `dba.createCluster()` path. Say which is more likely
   to work on Windows with three local instances, since ticket 11 has to execute it.
8. **Candidate figures**, and how a quorum loss could be *staged* locally (stopping members, not
   partitioning a network).

End with a list of claims that need the live topology, for ticket 11.

## Answer

Resolved at charting, 2026-09-17. Findings: [`research/05-group-replication.md`](../research/05-group-replication.md)

All eight questions answered from the 8.4 manual's Group Replication chapter. XCom and the
transaction flow through certification; write-sets and first-commit-wins as the optimistic, row-level
mechanism that makes multi-primary possible at all; majority quorum with the minority **blocking
rather than diverging**, which is the precise sense in which Group Replication does not split-brain
the way generic multi-leader systems do; single- vs multi-primary with the concrete restrictions
(cascading foreign keys, `SERIALIZABLE`, concurrent DDL) and an honest verdict rather than a hedge.

**Highest-value output, as hoped**: the `group_replication_consistency` levels mapped one by one onto
named models in the literature - `EVENTUAL`, `BEFORE_ON_PRIMARY_FAILOVER`, `BEFORE`, `AFTER`,
`BEFORE_AND_AFTER` against eventual, session-causal and strong consistency, in a summary table. That
table is the paper's direct bridge from the professor's vocabulary to a MySQL knob, and is likely to
survive into the paper nearly unchanged.

**Free-only rule confirmed clean**: Group Replication, InnoDB Cluster, MySQL Shell and MySQL Router
are all Community/GPL, with no Enterprise gate. **Ticket 11 gets a recommendation**: use MySQL
Shell's `dba.createCluster()` rather than manual configuration on Windows, because it handles the
privilege setup, loopback addressing and option-file parsing that are the usual Windows failure
points. Quorum loss is staged by stopping members, never by partitioning a network. 10 claims flagged
for ticket 11.
