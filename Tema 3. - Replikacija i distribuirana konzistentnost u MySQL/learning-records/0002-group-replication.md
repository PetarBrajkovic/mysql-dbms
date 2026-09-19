# 0002 — Group Replication and InnoDB ClusterSet on the local topology

Ticket 11, 2026-09-19. Raw numbers: `.scratch/replikacija/measurements/0002-group-replication.md`.
Scripts: `examples/01-group-replication/`.

## The headline

**Everything works locally, including the ClusterSet.** Three-member group, quorum loss, multi-primary
conflicts, the `group_replication_consistency` levels, controlled switchover and emergency failover
across two clusters. Chapters 5 and 6 both have measurements behind them; **nothing in either has to
be written as theory-only.** The ticket's stop rule — document the failure rather than fight it — was
never needed.

That matters most for **chapter 6**, which exists only because ticket 09 re-took the
chapter-vs-section call after memo 07's "MySQL has no dedicated geo-distribution feature" turned out
to be false. The chapter now rests on a feature that was not merely documented but **run**.

## The insights worth revisiting

**1. A cluster may be single-member — that is what makes geo-distribution demonstrable on one
machine.** A ClusterSet needs two *clusters*, not six servers. Splitting 3307+3308 from 3309 produces
a genuine primary cluster and a genuine replica cluster with a real ClusterSet replication channel
between them. The only thing out of reach is inter-region latency, which is physics, not a missing
feature — and chapter 6 should say exactly that rather than apologising for the sandbox.

**2. The consistency levels are the paper's strongest single measurement.** Write on the primary, read
the same row on a secondary microseconds later, 40 times per level:

| Level | Stale reads | Median commit |
|---|---|---|
| `EVENTUAL` (default) | **100 %** | 16 ms |
| `AFTER` | 0 % | 29 ms (+81 %) |
| `BEFORE_AND_AFTER` | 0 % | 31 ms (+94 %) |

The anomaly is total at the default and gone at the stronger levels, and the price is paid **by the
writer**. This is the spine of the paper as a table: MySQL does not ship a consistency model, it ships
a knob, and the operator decides where on that scale the system sits. Chapter 5's climax is this
table, not a list of level names.

**3. The measurement nearly erased itself, and the failure is worth a paragraph.** Run with one
`mysql.exe` per statement, the same experiment showed **zero** stale reads at every level and no
latency difference — 20 ms of client start-up between write and read is longer than the replication
window. The anomaly is real but short-lived; an instrument slower than the window reports that the
window does not exist. Tema 1's lesson about measuring the measurer, in a new costume.

**4. Quorum loss is the cleanest demonstration in the whole paper.** Kill two of three; on the
survivor a read returns in **39 ms** and a write is **still blocked after 30 seconds** — and the
blocked row is invisible to the reader. Three outcomes in one screen: available for reads,
unavailable for writes, never divergent. That is CAP made concrete on a live server rather than
argued.

**5. The suspended write was not lost and not aborted — it committed two minutes later.** The row
issued at 14:40:56 under no quorum appears with that timestamp after `forceQuorumUsingPartitionOf`
ran at ~14:42, even though its client had been killed. The transaction sat inside commit awaiting a
decision the group could not take. **The operator's decision, not a timeout, determined its fate.**
This is the sharpest available illustration of "when may a writer be told its write succeeded".

**6. A clean shutdown is not a failure.** `topology.ps1 stop -Node 3` is a *graceful leave*: the
member vanishes from the view, the group reconfigures to two, majority is recalculated, and writes
continue. To lose majority you must kill the process. A chapter that demonstrates quorum with a clean
stop demonstrates nothing — and this is an easy figure to get wrong.

**7. The vendor takes opposite CAP positions at two scopes, and says so in its own output.** Inside a
cluster the minority blocks rather than diverge. Across clusters, `forcePrimaryCluster` prints:
*"transactions that were not yet replicated may be lost"* and *"a split-brain can happen"*, and offers
`fenceAllTraffic()`. Chapter 6's payoff can now quote the **tool's own runtime warning** alongside the
manual's *"prioritizes availability over data consistency"* — stronger than two manual quotations,
because one of them is the product speaking while doing the thing.

**8. Emergency failover is not automatic, and the asymmetry is the point.** The surviving DR cluster
sat at `super_read_only = 1` refusing writes and reporting `UNAVAILABLE` until a human ran
`forcePrimaryCluster` (23 s). Controlled switchover, by contrast, took **478 ms**. Same two clusters,
same machine: the planned path is three orders of magnitude cheaper and loses nothing. That pair is
chapter 6's structure.

## Correction filed against memo 05

**The error a losing transaction actually receives is not the one the certification story predicts.**
Across four different timings — staggered commits, simultaneous commits, duplicate-key inserts, and a
300 000-row transaction built specifically to widen the certification window — the loser **always**
got:

```
ERROR 1180 (HY000): Got error 149 - 'Lock deadlock; Retry transaction' during COMMIT
```

and `COUNT_CONFLICTS_DETECTED` stayed **0 on every member, every time**;
`COUNT_TRANSACTIONS_CHECKED` advanced by exactly one per case, the winner. The loser never reaches
certification: it is aborted locally when the winner's already-certified write-set meets its row lock.
`ER_TRANSACTION_ROLLBACK_DURING_COMMIT` (3101) was never produced.

Verified on the practitioner rung (the docs describe certification but not the client-visible error):
MySQL bug **78705, "Improve Client Error For Certification Failures"**, plus independent InnoDB
Cluster multi-primary reports of the same handler error 149. So this is normal behaviour, not a
sandbox artefact.

**What chapter 5 must therefore do**: keep certification as the *mechanism* — it is correct, and
first-commit-wins with row-level granularity was confirmed (same row → one loser; different rows →
both commit; all three members converged every time) — but state the *observable* honestly. An
application does not see "certification failed"; it sees a deadlock at commit time and is told to
retry. That gap between the architecture's vocabulary and the client's error message is a genuine
finding and belongs in the chapter, not in a footnote.

**Also confirmed, not overturned**: a PK-less InnoDB table makes the instance cluster-unready, with
the manual's own wording available verbatim from `dba.checkInstanceConfiguration` — so ticket 08's
`no_pk_demo` works exactly as planned, and needs no running group to demonstrate.

## What the next sessions inherit

- **Chapter 5** has: the membership view seen identically from three members, the graceful-leave vs
  kill distinction, quorum loss with reads-work/writes-block/nothing-visible, the repair and the
  suspended write's fate, the conflict pair with the 1180 correction, `no_pk_demo`, and the
  consistency-level table as its climax.
- **Chapter 6** has: a live ClusterSet, the replica cluster's write refusal, switchover at 478 ms vs
  forced failover at 23 s, `INVALIDATED`, and the split-brain warning as a quotation.
- **The sandbox has two states.** Async is the resting state; the group is brought up and torn down by
  script. `19-gr-down.ps1` must be run at the end of any group session or chapters 3, 4 and 7 will
  find a cluster where they expect asynchronous replication.
- **Memo 04 claims 2, 3 and 6 and memo 06 claims 6 and 7 are still untested.** They did not fit this
  ticket — claims 2/3 need a staged crash between `AFTER_SYNC` and `AFTER_COMMIT`, which belongs to
  chapter 4's own session with semisync running, not to a group session.
