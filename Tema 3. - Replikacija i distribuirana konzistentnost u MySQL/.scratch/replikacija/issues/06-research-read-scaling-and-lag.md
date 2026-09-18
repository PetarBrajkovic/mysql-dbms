# Research: read scaling with replicas, and replication lag

Type: research
Status: resolved

## Question

The professor's fifth bullet, and the one that touches an application developer most directly. The
interesting content is not "point reads at a replica" - it is **what breaks when you do**, and what
MySQL offers to fix it.

Sources: the MySQL 8.4 reference manual, MySQL Router documentation, and the consistency literature
for the anomaly names.

Produce a memo at `../research/06-read-scaling-and-lag.md` answering:

1. **What replication lag actually is**, and why `Seconds_Behind_Source` is a poor measure of it. The
   8.4 replication timestamps (`performance_schema.replication_applier_status_by_worker` and its
   siblings) and what they let you measure instead. This is the chapter's technical spine.
2. **The anomaly a read replica produces**, named precisely: a client writes, then reads its own write
   from a lagging replica and does not see it. Give it its literature name (read-your-writes /
   monotonic reads) and say what consistency model a stale read replica actually provides.
3. **What MySQL gives you to close it**: `WAIT_FOR_EXECUTED_GTID_SET()`, `SOURCE_POS_WAIT()`, and
   `group_replication_consistency` where a group is involved. Be exact about what each waits for, and
   what it costs.
4. **Read/write splitting**: how it is actually routed - MySQL Router's read-write split support and
   the honest statement that in most systems the application decides. One paragraph on Router, per
   the map's scope rules; no ProxySQL, no Vitess.
5. **Delayed replication** (`SOURCE_DELAY`) - its real purpose (protection from operator error), and
   its usefulness here as the one tool that can **manufacture** lag deterministically for a figure.
   This may be the topic's single most useful demo mechanic; say so if it is.
6. **What read scaling does and does not scale.** Reads scale, writes do not, and every replica pays
   the full write cost. Find whether the manual or the literature states that ceiling explicitly, so
   the chapter can cite it rather than assert it.
7. **Candidate figures** - a lag time-series and a staged read-your-writes violation are the obvious
   two; say what each would need in order to be reproducible rather than a race that sometimes fires.

End with a list of claims that need the live topology, for ticket 10.

## Answer

Resolved at charting, 2026-09-17. Findings: [`research/06-read-scaling-and-lag.md`](../research/06-read-scaling-and-lag.md)

`Seconds_Behind_Source` is established as an unreliable measure for three separate reasons -
network-dependence, clock sensitivity, and blindness to multi-threaded appliers - with the
`performance_schema` replication timestamp tables (`original_commit_timestamp` /
`immediate_commit_timestamp` across `replication_connection_status`,
`replication_applier_status_by_coordinator` and `..._by_worker`) as what to measure instead. That
contrast is itself a figure: the naive metric and the real one, on the same run.

The anomaly is named against the literature (read-your-writes and monotonic-reads violations under
eventual consistency), and the closing tools are stated precisely: `WAIT_FOR_EXECUTED_GTID_SET()`,
`SOURCE_POS_WAIT()`, and `group_replication_consistency`, each with its cost. MySQL Router kept to one
paragraph as scoped; no ProxySQL or Vitess.

**Confirms the mechanic ticket 08 needs**: `SOURCE_DELAY` is the way to manufacture deterministic,
reproducible lag for a figure, rather than hoping a load generator produces some. The scaling ceiling
is stated plainly - reads scale, writes do not, and every replica must absorb the full source write
rate. 7 claims flagged for ticket 10.
