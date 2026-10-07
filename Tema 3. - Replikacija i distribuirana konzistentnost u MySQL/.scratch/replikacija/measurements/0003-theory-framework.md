# 0003 — Theory framework: sources checked, sandbox state, memo 07 corrections

Lesson `lessons/0001-teorijski-okvir.html`, learning record `learning-records/0003-theory-framework.md`.
For the ch. 2 writing session.

## Quotations verified verbatim (rung 3 unless marked)

| Claim | Source | How verified |
|---|---|---|
| G-L definitions of C, A, P; Theorem 1 | Gilbert & Lynch 2002, https://www.comp.nus.edu.sg/~gilbert/pubs/BrewersConjecture-SigAct.pdf | PDF fetched + pdftotext by the agent |
| PACELC definition; "present at all times … CAP only relevant in the arguably rare case of a network partition"; PA/EL = Dynamo, Cassandra, Riak; PC/EC = VoltDB/H-Store, Megastore | Abadi 2012, https://www.cs.umd.edu/~abadi/papers/abadi-pacelc.pdf | PDF fetched + pdftotext by the agent |
| **Dynamo-quorum ≠ linearizable**: "they cannot achieve full consistency as defined by Gilbert and Lynch, even if R + W > N" | Abadi 2012, same PDF | pdftotext by the agent. **The citable primary source for the ch. 2 quorum distinction.** |
| Linearizability "illusion … instantaneously … between its invocation and its response" | Herlihy & Wing 1990 | researcher subagent, PDF fetched |
| RYW / Monotonic Reads one-line definitions | Terry et al. 1994 | researcher subagent, PDF fetched |
| "The '2 of 3' formulation was always misleading" | Brewer 2012, IEEE Computer 45(2) 23-29, DOI 10.1109/MC.2012.37 | researcher, InfoQ reprint. **Not in 07b; add to references.bib.** |
| Raft three subproblems (§5), commit on majority (§5.3), election restriction (§5.4.1), one vote per term (§5.2) | Ongaro & Ousterhout 2014, raft.github.io/raft.pdf | researcher, PDF fetched |
| R+W>N "quorum-like system" (§4.5); sloppy quorum "first N healthy nodes" (§4.6) | DeCandia et al. 2007 | researcher, PDF fetched |
| "single-leader, multi-leader, and leaderless … Almost all distributed databases use one of these three" | Kleppmann 2017 ch. 5 | researcher, ScyllaDB-hosted excerpt. The ch. 9 "quorums not linearizable" passage was only seen as a secondary snippet; **cite Abadi for that claim instead.** |
| GR: "majority of the group have to agree on the order …" and "At the very core … Paxos algorithm" | refman 8.4 §20.1 Group Replication Background (rung 1) | fetched by the agent; the two sentences appear in that order on the page |
| "Consensus requires a majority … unable to progress and blocks" | refman 8.4 §20.7.8 (rung 1) | fetched by the agent |

## Absence claim checked (NOTES rule 1)

"No replication mode MySQL 8.4 Community documents is Dynamo-style leaderless."
- Rung 1 (refman ch. 19, 20): async, semisync, delayed, Group Replication single/multi-primary, all leader-based.
- Rung 2 (Shell 8.4: InnoDB Cluster, ReplicaSet, ClusterSet): all built on GR or async single-source.
- NDB Cluster is out of scope (MISSION) and is not Dynamo-quorum either; not asserted further.
Wording kept narrow ("documents", "Community", "Dynamo-style") on purpose.

## Memo 07 errors found (do not copy into ch. 2)

1. §1 GR consistency levels: names and semantics wrong. `BEFORE_ON_PRIMARY_FAILURE` does not exist
   (it is `BEFORE_ON_PRIMARY_FAILOVER`); `AFTER` is described as a reader wait (that is `BEFORE`).
   Ch. 5 must take the levels from refman, not from memo 07.
2. §2 "async replica during a partition can continue accepting writes (fork)": overstated. A replica
   diverges only if someone writes to it or promotes it. Note: in this sandbox `read_only = 0` on
   3308/3309 (status output), so a privileged client *could* write there — that is the honest version.
3. §3 "If W > N/2 … prevents split-brain" for Dynamo: false under sloppy quorum (§4.6).
4. §6 Lamport 2001 pages "18-25" — 07b has 51-58 (verified). Use 51-58.
5. §3 "Dynamo uses W=2, R=2, N=3" — the paper's common config is (N,R,W)=(3,2,2), as a configuration,
   not a fixed property.

## Sandbox state found and repaired

- After `topology.ps1 start`, **3308's channel was OFF** (receiver and applier). Cause:
  `skip_replica_start=ON` (and `skip_slave_start`) PERSISTed by `icadmin` (AdminAPI) on 3307 and 3308
  during ticket 11; `19-gr-down.ps1` re-created the channel at runtime but never cleared the persisted
  flag, so it silently stayed down from the next start onward. GTID sets on 3307/3308/3309 were
  identical, so nothing was lost.
- Fixed: `RESET PERSIST IF EXISTS skip_replica_start / skip_slave_start` on 3307 and 3308,
  `START REPLICA` on 3308, heartbeat insert seen on all three, then deleted.
  `19-gr-down.ps1` patched to RESET PERSIST both on all three nodes.
- Other GR residue is still persisted (group_replication_* variables, `auto_increment_offset=2`,
  `group_replication_consistency=BEFORE_ON_PRIMARY_FAILOVER`). Harmless while GR is not running;
  not touched.
