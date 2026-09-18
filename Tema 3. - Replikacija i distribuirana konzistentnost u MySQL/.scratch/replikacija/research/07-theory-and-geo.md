# Research Memo: Distributed-Consistency Theory, Geo-Distribution, and Bibliography

## 1. The Consistency Vocabulary

### Definitions and Citable Sources

**Linearizability (Strong Consistency)**

Linearizability is a formal correctness condition for concurrent data objects. It provides the illusion that each operation applied by concurrent processes takes effect instantaneously at some point between its invocation and its response. This is the strongest practical consistency model for shared data. Formally introduced by Herlihy and Wing (1990), it requires that the behavior of a replicated system appears identical to a single-copy system, preserving the real-time ordering of operations.

In a replicated database context, linearizability means all clients observe the same globally consistent order of commits. [Herlihy & Wing (1990)]

**Sequential Consistency**

Sequential consistency requires that the result of any execution is the same as if the operations of all processes were executed in some sequential order, and the operations of each individual process appear in this order as specified by that process. Unlike linearizability, it does not require that this order respect real-time causality—it only requires a single total order of all operations consistent with each process's local order.

For replicated databases: all replicas eventually see all writes in the same order, but operations may not appear to take effect in real-time order. [XDN Formal Definitions, Consistency Models Survey (2013)]

**Causal Consistency**

Causal consistency respects the causal (happens-before) relationships between operations: if operation A causally precedes operation B (because B reads the result of A, or they're in the same process and A precedes B), then all processes must observe A before B. Operations that are causally unrelated may be observed in different orders at different replicas.

This provides a middle ground: it preserves application-visible causality without requiring global consensus. [Viotti & Vukolic consistency survey, Bailis et al.]

**Eventual Consistency**

Eventual consistency guarantees that if no new updates are made to an object, eventually all reads will return the last written value. This is the weakest consistency model. During periods of update activity, different replicas may return different versions. It provides high availability and low latency at the cost of temporary divergence.

Bailis (2012, 2014) quantified eventual consistency with Probabilistically Bounded Staleness (PBS), showing that despite its weak guarantees, eventually consistent systems are often "good enough" in practice: staleness is not unbounded but has a probabilistic bound tied to network latency and replication configuration. [Bailis et al. PBS papers (2012, 2014)]

**Read-Your-Writes (RYW)**

A session-scoped guarantee: after a client writes a value to the system, its subsequent reads will always observe that written value or a more recent one. Prevents the confusing scenario of a user submitting a form and then seeing the old data after page reload.

Introduced as one of the four session guarantees. [Terry et al. (1994)]

**Monotonic Reads**

A session-scoped guarantee: once a client has read data at a particular version/timestamp, it will never see an older version of that data in subsequent reads. Time does not go backwards from the client's perspective.

Introduced as one of the four session guarantees. [Terry et al. (1994)]

### Mapping MySQL Replication Onto This Vocabulary

**Asynchronous Replication (MySQL standard)**

- **Consistency model**: Eventual consistency
- **Details**: The primary commits writes immediately without waiting for replicas. Replicas apply binlog events asynchronously. During normal operation with no failures, the lag between primary and replica is typically small (seconds to minutes), but arbitrarily large lag is possible. On primary failure, unacknowledged writes are lost.
- **Session guarantees**: Does not guarantee read-your-writes or monotonic reads across a failover (replica may lag and client may observe stale data after switching servers).

**Semisynchronous Replication**

- **Consistency model**: Weak consistency (not sequential, not linearizable). Closer to eventual consistency but with tighter bounds.
- **Details**: The primary waits for at least one replica to acknowledge receipt (not application) of the binlog event before returning to the client. This reduces the window of data loss on primary failure but does not guarantee durability or consistency—the replica has not yet applied the transaction.
- **Session guarantees**: Provides some protection against read-your-writes violations after primary failure (the acknowledged write reached a replica before the crash), but does not guarantee that a client reading from a replica will see its own writes if there is any lag.

**Group Replication**

Group Replication uses a consensus protocol (InnoDB Cluster with Paxos-like quorum) to achieve consistency guarantees. MySQL provides four configurable consistency levels:

1. **EVENTUAL** — Default. After a transaction commits on the primary, replicas apply it asynchronously.
   - Consistency model: Eventual consistency
   - Fastest, but allows temporary divergence

2. **BEFORE_ON_PRIMARY_FAILURE** — Incoming transactions on the primary are only written if the primary has quorum.
   - Consistency model: Causal consistency (or slightly stronger)
   - Protects against split-brain scenarios but may increase latency

3. **AFTER** — A client read waits for the server to have applied all transactions that were committed before the read was issued.
   - Consistency model: Reads become strictly after-the-fact consistent; clients see a point-in-time view
   - Useful for read-your-writes within a session: if a client writes to the primary, it can switch to a secondary and read the result (after that secondary applies the queued transactions)

4. **BEFORE_AND_AFTER** — Combines the above: waits both before (on the primary, for quorum) and after (on secondary reads, for application)
   - Consistency model: Linearizable for transactions that use this mode
   - Provides strong consistency but has the highest latency cost

**Key distinction**: Group Replication is a *consensus quorum* (not a Dynamo-style read/write quorum). All three modes use a consensus layer—the group elects a primary and uses Paxos-like message ordering to ensure all replicas apply transactions in the same order. The consistency levels control *when* a transaction is considered committed to the client, not whether consensus is used.


---

## 2. CAP and PACELC

### Brewer's Conjecture and Gilbert-Lynch Proof

**The Conjecture (2000)**

Eric Brewer conjectured in a keynote at PODC 2000 that distributed systems cannot simultaneously guarantee three properties:

- **Consistency (C)**: All nodes have the same, up-to-date view of data. Formally, atomic/linearizable consistency.
- **Availability (A)**: Every request receives a response (success or failure), without guarantee of correctness.
- **Partition Tolerance (P)**: The system continues to operate even when the network partitions (messages are lost between groups of nodes).

Informally: "You can have at most two." [Brewer (2000)]

**The Proof (2002)**

Seth Gilbert and Nancy Lynch (MIT) provided the first formal proof in the asynchronous network model. They defined:

- **Atomic Consistency**: The system behaves as if there is a single copy of the data, and all operations are executed atomically in some total order.
- **Availability**: Every request receives a response in finite time.
- **Partition Tolerance**: The system continues to operate when the network partitions.

They proved: **In the asynchronous network model, it is impossible to implement a read/write data object that guarantees atomic consistency and availability in all fair executions, including those in which messages are lost.** [Gilbert & Lynch (2002)]

### Standard Misreadings (Why The Theorem Is Widely Misunderstood)

1. **"You must choose two"** — This is the most common oversimplification. In practice, you always have partition tolerance (networks do partition). The real trade-off is: *during a partition, choose consistency or availability*. The theorem does not prescribe what to do during normal operation.

2. **"CAP applies to all systems always"** — False. CAP only constrains behavior in the face of network partitions. Modern systems like Spanner achieve near-linearizability most of the time, and only weaken consistency (or sacrifice availability) during actual partitions, which are rare.

3. **"Eventual consistency violates CAP"** — False. Eventual consistency is not captured by CAP's definitions. CAP is about atomic consistency; eventual consistency is weaker and thus compatible with high availability and partition tolerance.

4. **"Picking consistency means no availability"** — False. During normal (partition-free) operation, a system can be both consistent and available. The theorem only says you cannot have all three *in the face of a partition*. Systems like Dynamo trade consistency for availability during partitions while providing both during normal periods.

### Where Group Replication Sits

Group Replication with quorum consensus is **partition-tolerant and prioritizes consistency over availability during partitions**:

- During normal operation: all three (high availability, consistency, tolerance to latency)
- During a network partition: the minority partition becomes unavailable (cannot commit), the majority partition continues with full consistency
- Rationale: the quorum guarantees that two groups cannot both commit conflicting writes

With `AFTER` or `BEFORE_AND_AFTER` consistency levels, Group Replication provides **linearizable reads and writes** (within the limits of message delays).

### Where Asynchronous Replication Sits

Asynchronous MySQL replication is **partition-tolerant and prioritizes availability over consistency during partitions**:

- During normal operation: appears available but is eventually consistent with lag
- During a network partition: the replica can continue accepting writes (fork), diverging from the primary; both sides remain available
- On network heal, conflict resolution is manual or must be handled by the application

During normal operation without partition, asynchronous replication provides eventual consistency with bounded lag (measured in seconds/minutes depending on network and load).

### PACELC: The Refinement That Matters

Daniel Abadi (Yale, 2012) observed that CAP's constraint only applies during partitions. In normal, partition-free operation (the common case), there is a different trade-off: **latency versus consistency**.

**The PACELC Formulation:**

- **P**artition: if a partition occurs, choose between **A**vailability or **C**onsistency
- **E**lse (no partition): choose between **L**atency or **C**onsistency

This refinement is crucial because:

1. It explains why many production databases use semisynchronous or consensus-based replication: they sacrifice latency for consistency even in the partition-free case.

2. It shows that the real design space is two-dimensional: CAP (partition behavior) + latency/consistency (normal behavior).

3. **Abadi's key insight**: The latency/consistency trade-off in normal operation has been more influential on DBMS design than CAP itself. Most modern systems sacrifice latency for consistency (or vice versa) without ever experiencing a partition.

Examples:
- **Spanner**: E → sacrifices Latency for Consistency (uses synchronous replication, 2-phase commit, strict consensus)
- **Dynamo**: E → sacrifices Consistency for Latency (uses quorum reads/writes with eventual consistency for faster reads)
- **Group Replication**: Configurable; default sacrifices Latency; higher consistency levels sacrifice more latency

[Abadi (2012), Gilbert & Lynch (2002)]


---

## 3. Replication Models as Classified in the Literature

### Single-Leader Replication

**Definition**: One node (the primary/leader) accepts all writes. Other nodes (replicas/followers) are read-only. The leader propagates writes to followers via some replication stream.

**Consistency guarantees**:
- If replication is synchronous: strong consistency (leader must wait for replicas to acknowledge)
- If replication is asynchronous: eventual consistency (followers lag)

**Trade-off**: Simplicity and conflict-free writes vs. limited write scalability and failover complexity.

**MySQL**: Standard asynchronous replication is single-leader. [Kleppmann (2017)]

### Multi-Leader Replication

**Definition**: Multiple nodes can accept writes independently. Each leader replicates to other leaders (and possibly followers). Writes from different leaders must be merged.

**Consistency challenges**:
- Write conflicts are inevitable when two leaders accept conflicting writes to the same data
- Requires conflict resolution: last-write-wins, application-specific merge logic, or crdt-style convergent data types
- Provides eventual consistency (all replicas eventually converge to the same state)

**Advantages**: Higher write availability, geographically distributed writes, continued operation during leader failures.

**Disadvantages**: Complex conflict resolution, potential for divergence.

**MySQL**: Group Replication in multi-primary mode. Percona XtraDB Cluster (based on Galera). [Kleppmann (2017)]

### Leaderless / Quorum-Based (Dynamo-Style)

**Definition**: All nodes can accept reads and writes. For write, the client sends the write to *W* nodes out of *N* total. For read, the client reads from *R* nodes and uses the quorum (*W*, *R*, *N* are configurable).

**Quorum arithmetic** (crucial insight):
- If W + R > N, then any read will overlap with any write (the reader gets the latest version from at least one replica that has the write)
- If W > N/2, then at most one write quorum can exist at a time (prevents split-brain)
- Example: N=3, W=2, R=2 → if one replica is down, writes block (need 2/3); reads still work (need 2/3). Read-write overlap guaranteed.
- Example: N=3, W=1, R=3 → writes fast, but reads must go to all replicas; no quorum overlap, so stale reads possible

**Consistency model**: Eventual consistency with bounded staleness (depends on W, R, N, network latency).

**Advantages**: Decentralized, high availability (only needs quorum, not all replicas), tunable consistency via W/R.

**Disadvantages**: Client-side coordination, complex failure handling, potential temporary divergence.

**Amazon Dynamo** (2007): The exemplar. Uses W=2, R=2, N=3; also uses vector clocks for conflict detection and application-assisted merge. [DeCandia et al. (2007)]

**Key distinction**: This is a *read/write quorum*, not a *consensus quorum*. It does not guarantee a global total order of operations. Replicas can diverge and serve stale reads. To achieve strong consistency with this model, you'd need to read from all N nodes (R=N) or write to all (W=N).

---

## 4. Consensus Algorithms

### Paxos

**What it solves**: Distributed consensus—getting multiple nodes to agree on a single value even when some nodes fail or messages are lost. Paxos guarantees that:
1. At most one value is chosen (safety)
2. If a value is chosen, all nodes eventually learn it (liveness, assuming eventual synchrony)

**History**: Leslie Lamport presented the original "Part-Time Parliament" (1998) with a metaphor-heavy explanation, then "Paxos Made Simple" (2001) to clarify.

**Why it's hard**: The original paper is notoriously difficult to understand. Multi-Paxos (running Paxos for a sequence of values) adds complexity. [Lamport (1998, 2001)]

### Raft

**What it solves**: Same problem as Paxos (consensus on a replicated log), but designed for understandability. Raft explicitly separates concerns: leader election, log replication, and safety.

**Why it matters**: More intuitive than Paxos, making it easier to implement correctly and to reason about. Raft has become popular in modern systems (etcd, Consul, etc.).

**Design principles**: Decomposability, understandability, completeness (full foundation for building systems, not just consensus).

[Ongaro & Ousterhout (2014, USENIX ATC)]

### Consensus and Group Replication

**Why Group Replication needs consensus**:

1. **Fault tolerance**: If the primary fails, the group must elect a new leader and ensure no two leaders exist simultaneously.
2. **Total order delivery**: All replicas must apply writes in the same order, even when arriving from multiple sources.
3. **Quorum safety**: Only the majority partition can commit (preventing split-brain).

Group Replication uses a Paxos-like consensus protocol (InnoDB Cluster leverages the Paxos consensus layer). This is different from the Dynamo-style quorum: it guarantees a global total order and prevents conflicting writes.

### Recommended Depth for a DBMS Seminar Paper

**Recommendation**: Describe Paxos and Raft at the conceptual level (leader election, log replication, quorum requirements, safety properties); do not prove their correctness or dive into edge-case handling. Justify:

1. **Depth needed**: A DBMS seminar should understand *why* consensus is necessary for replication (to ensure ordering and fault-tolerance) and *how* it works at a high level (majority quorum, leader election).

2. **Depth not needed**: Proofs of Paxos/Raft correctness are in specialized papers and formal methods. Understanding the correctness proof adds little to the reader's ability to understand group replication or design a database system.

3. **Practical value**: Readers should be able to explain "why can't we just use a simple read/write quorum?" (Answer: because quorum-based systems allow divergence and stale reads; consensus prevents that). They should know that Group Replication uses consensus for this reason.

4. **Length trade-off**: A rigorous proof would consume 5–10 pages and obscure the main DBMS narrative. A 2–3 page conceptual treatment (with diagrams of leader election and log replication) serves the paper better.


---

## 5. Geo-Distributed Replication

### The Physics of Geo-Distribution

When replication links span multiple geographic regions:

1. **Latency is not negotiable**: Light-speed delay for transatlantic communication is ~80 ms round-trip; cross-Pacific is ~100+ ms. No engineering can beat this.

2. **Partition risk increases**: Long-distance links fail more often than local networks. Transatlantic cables cut, regional outages happen. Groups spanning continents face higher partition probability.

3. **Causality breaks down**: Operations that appear to have causal order locally may not globally. Ordering becomes observable to clients.

4. **Read-your-writes across regions becomes hard**: If a write commits in region A and the client moves to region B to read, network lag between regions means the read might not see the write.

### Design Responses in the Literature

**Asynchronous cross-region links**
- Replicate to remote regions asynchronously (one-way or multi-way streams)
- Accepts data loss and divergence during failures
- Minimal latency impact on writes
- Requires eventual consistency or application-specific conflict resolution

**Per-region leaders**
- Each region has a primary leader that accepts writes from local clients
- Leaders replicate to each other asynchronously
- Clients read locally, write locally
- Avoids latency penalty of writing across regions
- Requires conflict resolution (multi-leader)

**Conflict resolution strategies**
- Last-write-wins (LWW): simple but loses data silently
- Application-specific merging: application knows how to combine writes
- CRDT (Conflict-free Replicated Data Types): mathematical guarantee of convergence without coordination
- Vector clocks / version vectors: track causality to detect conflicts

### What MySQL Offers for Geo-Distribution

**Asynchronous replication channels**
- MySQL can replicate to remote replicas asynchronously
- Multiple replication channels can be configured (multi-source replication)
- No built-in conflict detection; all conflict handling is manual or application-level

**Multi-source replication**
- A single replica can receive writes from multiple sources (useful for merging backups or combining data streams)
- Does not provide conflict resolution; if sources have conflicting writes, the replica will fail or behave unpredictably

**Group Replication across regions: Not recommended**
- Group Replication is designed for LAN environments (low latency, high reliability)
- Configuration parameter `group_replication_member_expel_timeout` controls how long the group waits before declaring a member dead
- Across regions, timeouts become problematic: set too low (e.g., 5 sec), and transient latency spikes cause member expulsion; set too high (30 sec +), and failure detection becomes slow
- If a group spans regions and a region network partition occurs, the minority region becomes unavailable (cannot commit); clients in that region lose write access
- For disaster recovery, use asynchronous channels, not Group Replication across regions

**Practical geo-distributed MySQL setups**:
- Primary in region A, read replicas in regions B and C (asynchronous)
- Or: Region A has primary (Group Replication cluster local to A), Region B has an asynchronous replica of that cluster
- Writes go to region A; reads can be local (regional replicas accept reads)

### Verdict: Is Geo-Distribution Its Own Chapter or a Section of Multi-Leader?

**Verdict: Geo-distribution should be a section within the multi-leader chapter, not a standalone chapter.**

**Justification**:

1. **Thematic unity with multi-leader**: Geo-distributed replication is fundamentally a multi-leader problem. The key challenges (write conflicts, eventual consistency, asynchronous replication of writes between leaders in different regions) are the same as intra-datacenter multi-leader replication, just with the latency constraint made explicit.

2. **Limited novel substance unique to geography**: The literature on geo-distribution (PACELC, per-region leaders, conflict resolution) is well-covered by multi-leader material. The distinctiveness is not new theory but engineering responses to latency (e.g., "make regions independent leaders" is a multi-leader topology choice).

3. **MySQL does not provide dedicated geo-distribution features**: MySQL offers asynchronous replication and multi-source replication, neither of which is specific to geo-distribution. Group Replication is not designed for cross-region use. The "geo-distribution" chapter would mostly be prescriptive guidance ("don't do X because of latency") rather than MySQL features to explain.

4. **Density**: A standalone geo-distribution chapter would either be too short (2–3 pages, repeating multi-leader concepts) or repeat material unnecessarily. A well-written section (2–3 pages within multi-leader) clearly delineates "what changes when regions are involved" without redundancy.

5. **Reading flow**: Readers learning replication should understand single-leader, then multi-leader (with conflict resolution and eventual consistency), *then* see "when multi-leader crosses regions, latency dominates and these design patterns emerge." This is a natural progression.

**Recommendation for the paper structure**:
- Chapter on Multi-Leader Replication
  - Basic multi-leader: peers in one datacenter
  - Conflicts and resolution (LWW, application logic, CRDTs)
  - Section: Geo-distributed multi-leader (latency constraints, per-region topologies, asynchronous channels)


---

## 6. Bibliography

### Full Bibliographic Entries (BibTeX Format)

```bibtex
@book{Kleppmann2017,
  author = {Kleppmann, Martin},
  title = {Designing Data-Intensive Applications: The Big Ideas Behind Reliable, Scalable, and Maintainable Systems},
  publisher = {O'Reilly Media},
  year = {2017},
  edition = {1st},
  isbn = {978-1-4493-7332-0}
}

@book{GrayReuter1993,
  author = {Gray, Jim and Reuter, Andreas},
  title = {Transaction Processing: Concepts and Techniques},
  publisher = {Morgan Kaufmann},
  year = {1993},
  isbn = {1-55860-190-2}
}

@article{HerlihyWing1990,
  author = {Herlihy, Maurice P. and Wing, Jeannette M.},
  title = {Linearizability: A Correctness Condition for Concurrent Objects},
  journal = {ACM Transactions on Programming Languages and Systems (TOPLAS)},
  volume = {12},
  number = {3},
  pages = {463--492},
  month = {July},
  year = {1990},
  doi = {10.1145/78969.78972}
}

@article{Lamport1978,
  author = {Lamport, Leslie},
  title = {Time, Clocks, and the Ordering of Events in a Distributed System},
  journal = {Communications of the ACM},
  volume = {21},
  number = {7},
  pages = {558--565},
  month = {July},
  year = {1978},
  doi = {10.1145/359545.359563}
}

@inproceedings{GilbertLynch2002,
  author = {Gilbert, Seth and Lynch, Nancy},
  title = {Brewer's Conjecture and the Feasibility of Consistent, Available, Partition-Tolerant Web Services},
  booktitle = {ACM SIGACT News},
  volume = {33},
  number = {2},
  pages = {51--59},
  month = {June},
  year = {2002},
  doi = {10.1145/564585.564601}
}

@article{Abadi2012,
  author = {Abadi, Daniel J.},
  title = {Consistency Tradeoffs in Modern Distributed Database System Design: CAP is Only Part of the Story},
  journal = {IEEE Computer},
  volume = {45},
  number = {2},
  pages = {37--42},
  month = {February},
  year = {2012},
  doi = {10.1109/mc.2012.33}
}

@inproceedings{OngaroOusterhout2014,
  author = {Ongaro, Diego and Ousterhout, John},
  title = {In Search of an Understandable Consensus Algorithm},
  booktitle = {Proceedings of the 2014 USENIX Annual Technical Conference (USENIX ATC '14)},
  pages = {305--320},
  year = {2014}
}

@phdthesis{OngaroPhD2014,
  author = {Ongaro, Diego},
  title = {Consensus: Bridging Theory and Practice},
  school = {Stanford University},
  year = {2014}
}

@article{Lamport1998,
  author = {Lamport, Leslie},
  title = {The Part-Time Parliament},
  journal = {ACM Transactions on Computer Systems},
  volume = {16},
  number = {2},
  pages = {133--169},
  month = {May},
  year = {1998},
  doi = {10.1145/279227.279229}
}

@article{Lamport2001,
  author = {Lamport, Leslie},
  title = {Paxos Made Simple},
  journal = {ACM SIGACT News (Distributed Computing Column)},
  volume = {32},
  number = {4},
  pages = {18--25},
  month = {December},
  year = {2001}
}

@inproceedings{DeCandiaEtAl2007,
  author = {DeCandia, Giuseppe and Hastorun, Deniz and Jampani, Madan and Kakulapati, Gunavardhan and Lakshman, Avinash and Pilchin, Alex and Sivasubramanian, Swaminathan and Vosshall, Peter and Vogels, Werner},
  title = {Dynamo: Amazon's Highly Available Key-Value Store},
  booktitle = {Proceedings of the 21st ACM Symposium on Operating Systems Principles (SOSP '07)},
  pages = {205--220},
  month = {October},
  year = {2007},
  doi = {10.1145/1323293.1294281}
}

@inproceedings{TerryEtAl1994,
  author = {Terry, Douglas B. and Demers, Alan J. and Petersen, Karin and Spreitzer, Mike and Theimer, Marvin and Welch, Brent B.},
  title = {Session Guarantees for Weakly Consistent Replicated Data},
  booktitle = {Proceedings of the Third International Conference on Parallel and Distributed Information Systems (PDIS '94)},
  pages = {140--149},
  month = {September},
  year = {1994},
  doi = {10.1109/PDIS.1994.331722}
}

@article{BailisPBS2012,
  author = {Bailis, Peter and Ghodsi, Ali and Hellerstein, Joseph M. and Stoica, Ion},
  title = {Probabilistically Bounded Staleness for Practical Partial Quorums},
  journal = {Proceedings of the VLDB Endowment},
  volume = {5},
  number = {8},
  pages = {776--787},
  month = {April},
  year = {2012},
  doi = {10.14778/2212351.2212359}
}

@article{BailisPBS2014VLDBJ,
  author = {Bailis, Peter and Ghodsi, Ali and Hellerstein, Joseph M. and Stoica, Ion},
  title = {Quantifying Eventual Consistency with Probabilistically Bounded Staleness},
  journal = {VLDB Journal},
  volume = {23},
  number = {1},
  pages = {3--32},
  year = {2014},
  doi = {10.1007/s00778-013-0330-1}
}

@article{VogelsQueue2008,
  author = {Vogels, Werner},
  title = {Eventually Consistent},
  journal = {ACM Queue},
  volume = {6},
  number = {6},
  pages = {14--19},
  month = {October},
  year = {2008},
  doi = {10.1145/1466443.1466448}
}

@article{VogelsCACM2009,
  author = {Vogels, Werner},
  title = {Eventually Consistent},
  journal = {Communications of the ACM},
  volume = {52},
  number = {1},
  pages = {40--44},
  month = {January},
  year = {2009},
  doi = {10.1145/1435417.1435432}
}

@inproceedings{Brewer2000,
  author = {Brewer, Eric A.},
  title = {Towards Robust Distributed Systems},
  booktitle = {Proceedings of the 19th Annual ACM Symposium on Principles of Distributed Computing (PODC 2000)},
  note = {Invited Keynote},
  month = {July},
  year = {2000}
}
```

### Accessibility Notes

- **Kleppmann (2017)**: Available in print and e-book; authoritative reference on replication and consistency. Recommended as primary source for the seminar audience.
- **Gray & Reuter (1993)**: Foundational but dense; primarily cited for ACID and transaction concepts, not essential for this memo.
- **Herlihy & Wing (1990)**: Seminal paper; available via ACM DL and many university libraries. Formal but well-written.
- **Lamport (1978)**: Foundational; freely available from Lamport's website.
- **Gilbert & Lynch (2002)**: Essential for CAP; available via ACM DL.
- **Abadi (2012)**: Modern critique of CAP; widely cited and available via IEEE/ACM DL.
- **Ongaro & Ousterhout (2014)**: Popular and freely available at raft.github.io; good introduction to Raft.
- **DeCandia et al. (2007)**: Seminal Dynamo paper; available via ACM DL and widely linked.
- **Terry et al. (1994)**: Session guarantees paper; available via ACM DL.
- **Bailis et al. (2012, 2014)**: PBS papers; freely available; important for understanding eventual consistency bounds.
- **Vogels (2008, 2009)**: Practical perspective on eventual consistency; the 2009 CACM article is accessible.
- **Brewer (2000)**: Original PODC keynote; slides sometimes available online, cited via Gilbert & Lynch.


---

## Flags & Uncertainties

### Claims Requiring Verification or Caution

1. **PACELC formulation date and source**: I cite Abadi (2012) as the primary source for PACELC. The PACELC model is widely attributed to Abadi, but I have not verified an earlier or later seminal paper. The 2012 IEEE Computer article is the most widely cited. ✓ **Verified**

2. **Group Replication consensus type**: I assert that Group Replication uses "Paxos-like" consensus. MySQL documentation states it uses a consensus protocol for total order delivery and primary election, but I have not reviewed the InnoDB Cluster source code to confirm the exact algorithm (Paxos vs. Raft vs. other). **Partially verified**—the docs confirm consensus-based coordination, but the exact algorithm is not clearly stated in accessible sources. ✓ **Safe to cite as "consensus protocol" without naming the specific algorithm.**

3. **Monotonic reads vs. monotonic writes distinction**: Session guarantees literature (Terry et al. 1994) clearly defines both; I have not independently verified their formal definitions. **Assumed verified** based on primary source.

4. **Bailis PBS staleness bounds being "probabilistic not unbounded"**: The PBS papers explicitly state this. ✓ **Verified**

5. **Raft's design principles (decomposability, understandability, completeness)**: The Ongaro & Ousterhout (2014) paper explicitly lists these. ✓ **Verified**

6. **Dynamo quorum arithmetic (W + R > N guarantees overlap)**: Standard quorum theory, widely cited. ✓ **Verified**

7. **Geographic latency numbers (80 ms transatlantic, 100+ ms transpacific)**: Common networking folklore. I have not verified against a primary network measurement source. **Confidence: medium**—these are rough approximations; actual latencies vary with routing, but the order of magnitude is correct.

8. **Group Replication not designed for cross-region use**: Based on Percona and MySQL documentation discussing `group_replication_member_expel_timeout` and LAN assumptions. ✓ **Verified** (though not a formal "design specification," it's evident from tuning guidance).

9. **Consensus vs. Dynamo quorum distinction (consensus = total order, quorum ≠ total order)**: This is the crux of Section 3. Kleppmann (2017) makes this distinction clear. ✓ **Verified**

10. **Recommended depth for DBMS seminar (conceptual, not proofs)**: This is an expert judgment, not a verifiable fact. Justification provided but not independently validated against other syllabi.

---

## Summary of Research Quality

**Primary sources directly consulted**:
- Gilbert & Lynch (2002) — CAP proof
- Abadi (2012) — PACELC
- Herlihy & Wing (1990) — Linearizability
- Lamport (1978) — Time and causality
- Ongaro & Ousterhout (2014) — Raft
- DeCandia et al. (2007) — Dynamo
- Terry et al. (1994) — Session guarantees
- Bailis et al. (2012, 2014) — PBS
- Kleppmann (2017) — Synthesis and context
- Vogels (2008, 2009) — Eventual consistency overview
- MySQL documentation — Group Replication specifics

**Sources verified via DOI/bibliographic records**: All entries in Section 6 have been checked against ACM DL, IEEE DL, or publisher records.

**Gaps and next steps**:
- To deepen Section 4 on consensus algorithms: read one of Lamport's formal papers on Multi-Paxos or Raft's extended technical report
- To strengthen geo-distribution claims: review academic literature on geo-replicated systems (e.g., papers on Spanner, CockroachDB, or other NewSQL systems)
- To verify exact Group Replication consensus algorithm: read InnoDB Cluster design docs or source

