# 0008 — ClusterSet live re-run and verified quotes (ticket 18, lesson half)

2026-10-27. MySQL 8.4.11 servers, MySQL Shell 8.4.10, one machine. Raw output in `raw/0008-*.txt`.
3306 untouched; sandbox returned to async with `19-gr-down.ps1` at the end (all three UP, channels ON,
"3306 still listening - untouched").

## Runs

| Step | Script | Result |
|---|---|---|
| async → cluster → ClusterSet | `10-gr-up.js`, `20-clusterset-up.js` | `HEALTHY — All Clusters available`; primary `poliklinikaCluster` (3307 R/W, 3308 R/O), replica `drCluster` (3309) |
| status + write probe | `43-clusterset-status.js` (new) | 3307 INSERT accepted; 3308 and 3309 refused, `--super-read-only` (ERROR 1290); 3309 channels: `clusterset_replication` ON, `group_replication_applier` ON, `group_replication_recovery` OFF |
| switchover A→B | `38` | **539 ms**; then 3307 refused, 3309 accepted |
| switchover B→A | `38` | **444 ms** |
| kill 3307+3308, before operator | `39` | 3309 `super_read_only = 1`, write refused, `UNAVAILABLE — Primary Cluster is not reachable from the Shell, assuming it to be unavailable.` (after 20 s) |
| `forcePrimaryCluster('drCluster')` | `39` | **21 617 ms**; `INVALIDATED … may be lost`; split-brain warning + `fenceAllTraffic()`/`fenceWrites()`; 3309 write accepted; status `AVAILABLE — Primary Cluster available, there are issues with a Replica cluster.` |
| dead DC returns | `39` | `poliklinikaCluster` REPLICA / INVALIDATED / OFFLINE — no self-rejoin |
| repair | `40` + ad hoc `rejoinInstance(3308)` | reboot message *"Skipping rejoining remaining instances because the Cluster belongs to a ClusterSet and is INVALIDATED"*; `rejoinCluster`; switch back; 3308 was `(MISSING)` until `rejoinInstance`; end `HEALTHY`. Row `dr-after` (written on 3309 while it was primary) present on all three → the old cluster took the new history |

Comparison with ticket 11 (0002): switchover 478 / 398 ms, failover 23 064 ms. Same order of magnitude;
quote ratios ("tens of times faster"), not absolute ms, in prose.

Switchover steps printed by Shell (the "old source alive hands everything over" mechanism):
`Waiting for the promoted cluster to apply pending received transactions` → `Synchronizing transaction
backlog` → `Acquiring global lock at PRIMARY` / `SECONDARIES` → `Synchronizing remaining transactions at
promoted primary`. Failover step: `Checking whether target cluster has the most recent GTID set` (among
the reachable clusters only).

## Verified quotes (researcher, rung 2 = MySQL Shell manual, rung 1 = refman 8.4)

Caveat: the Shell `8.4` URLs currently serve **Shell 26.7** content (version menu: "does not exist in
version 8.4"). Re-check wording against an 8.4/8.0 Shell page or PDF before the paper cites it.

- Intro (Shell, innodb-clusterset.html): *"MySQL InnoDB ClusterSet provides disaster tolerance for InnoDB
  Cluster deployments by linking a primary InnoDB Cluster with one or more replicas of itself in alternate
  locations, such as different datacenters."*
- Same page: *"It is important to know that InnoDB ClusterSet prioritizes availability over data
  consistency in order to maximize disaster tolerance."*
- Same page: *"There is no guarantee that data will be preserved in the event of an emergency failover."*
  Preceded by: *"…any unreplicated or divergent transactions are at risk of being lost, and can only be
  recovered and reconciled manually (if they can be accessed at all)."*
- Same page: channel *"named clusterset_replication"*; *"Asynchronous replication channels replicate
  transactions from the primary cluster to the replica clusters."*; *"only the primary server of the
  primary InnoDB Cluster accepts write traffic … The replica clusters do not."* — the strings
  `super_read_only`/`read-only` were **not found** there; the read-only state is our measurement (rung 5).
- Same page: *"the original primary cluster is marked as invalidated during the failover process."*
- Failover page (innodb-clusterset-failover.html): procedure is manual `forcePrimaryCluster()`; Router
  follows automatically if `target_cluster = primary`; *"you have to fence the cluster either from write
  traffic or all traffic."* `fenceWrites`/`fenceAllTraffic` names come from the live Shell output, not the
  page.
- Refman GR Requirements: *"MySQL Group Replication is designed to be deployed in a cluster environment
  where server instances are very close to each other."* / *"The performance and stability of a group can
  be impacted by both network latency and network bandwidth."*
- Refman GR system variables: `group_replication_member_expel_timeout` default **5**; quote in lesson.
  No separate failure-detection variable; the 5 s detection period is stated inside that text.
- Refman GR Background: *"If there is a network partition, resulting in a split where members are unable
  to reach agreement, then the system does not progress until this issue is resolved."*

## Absence-claim check (NOTES rule 1)

"ClusterSet does not fail over between clusters automatically": rung 2 documents only the manual
`forcePrimaryCluster()` procedure; rung 5: 3309 stayed read-only/UNAVAILABLE for 20 s with no operator
(two runs). Write it as "the manual describes emergency failover as an operator procedure, and the
replica cluster did not promote itself", not as a bare "has no automatic failover".

## Not demonstrable locally (say so in ch. 6)

Inter-region latency and the expel behaviour under a slow WAN link: theory from refman + physics
(~200 km/ms in fibre). The RTT values 90/160 ms in the lesson are illustrative assumptions, labelled so.

## Lesson figures

`viz/viz-l06-gr-preko-regiona-1793110703190.png`, `viz-l06-izbacivanje-clana-1793110694964.png`,
`viz-l06-clusterset-arhitektura-1793110711500.png`, `viz-l06-switchover-vs-failover-1793110688074.png`
(the measured chart), `viz-l06-cap-dva-nivoa-1793110732604.png` (the payoff; strong candidate for the
ch. 6 Slika).
