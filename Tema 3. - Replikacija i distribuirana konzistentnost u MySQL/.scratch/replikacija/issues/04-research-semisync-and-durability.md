# Research: semisynchronous replication and what an acknowledgement means

Type: research
Status: resolved

## Question

The paper's sharpest available argument lives here: **asynchronous replication can tell a client its
transaction committed and then lose it.** This memo establishes exactly when that is true, what
semisynchronous replication changes, and — the part most treatments get wrong — what it still does
not guarantee.

Sources: the MySQL 8.4 reference manual, the `rpl_semi_sync_source`/`rpl_semi_sync_replica` component
documentation, and the worklogs behind `AFTER_SYNC`. Note that 8.4 ships the semisynchronous
replication **components** (`rpl_semi_sync_source`, installed via `INSTALL COMPONENT`), replacing the
old `semisync_master` plugin names most tutorials use.

Produce a memo at `../research/04-semisync-and-durability.md` answering:
1. **The failure story for asynchronous replication**, stated as a precise sequence: commit,
   acknowledge to client, primary dies before the event reaches any replica, failover, transaction
   gone. Name what the client was promised and by whom.
2. **`AFTER_SYNC` vs `AFTER_COMMIT`** — the single most important distinction in this chapter. What
   each waits for, at which point in commit the wait happens, and **which one can still expose a
   transaction to other clients that a failover will then erase** (phantom read of a lost
   transaction). Get this exactly right; it is the chapter's payload.
3. **What semisynchronous still does not give you**: it is not synchronous replication, the replica
   has received but not necessarily applied, and `rpl_semi_sync_source_timeout` silently degrades the
   whole thing back to asynchronous. How an operator would even notice that degradation.
4. **Installation and configuration on 8.4** as a command sequence, component names correct, for
   ticket 10.
5. **The cost**: what semisynchronous does to commit latency and throughput, and how that cost can be
   *measured* locally rather than asserted from the manual.
6. **Candidate figures** — the timeout degradation and the latency cost are both good candidates;
   say what each would actually show.

End with a list of claims that need the live topology, for ticket 10.

## Answer

Resolved at charting, 2026-09-17. Findings: [`research/04-semisync-and-durability.md`](../research/04-semisync-and-durability.md)

**Question 2 delivered the payload it was asked for.** `AFTER_SYNC` (the default) waits for the
replica acknowledgement *before* the storage-engine commit, so no other client can see the
transaction until it is safe. `AFTER_COMMIT` waits *after*, which opens a real window in which other
clients read a transaction that a subsequent failover erases. That asymmetry is the sharpest single
argument available to this paper, and it is a genuine consistency anomaly rather than a performance
footnote.

Also established: the precise asynchronous loss sequence; the three things semisync still does not
give you (it is not synchronous, receipt is not application, and `rpl_semi_sync_source_timeout`
**silently degrades the whole mechanism back to asynchronous**) plus seven observable signals by
which an operator could detect that degradation; and the latency cost with a locally measurable
method.

**Two corrections made before acceptance:**

- **The ticket was wrong**, and the memo was right to push back: MySQL 8.4 ships semisync as
  **plugins** (`INSTALL PLUGIN`), not as components. The ticket's `INSTALL COMPONENT` instruction was
  a charting error. Ticket 10 follows the memo, not the ticket.
- **The memo gave Unix library names** (`semisync_source.so`) for a Windows target. Verified against
  the 8.4 manual and **corrected in place to `.dll`**, with the `REPLICATION_SLAVE_ADMIN` privilege
  requirement added. Corrected in the command sequences and in the verification list.

7 claims flagged for live verification at ticket 10.
