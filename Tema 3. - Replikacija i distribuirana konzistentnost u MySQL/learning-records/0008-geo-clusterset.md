# 0008 — Geo-distribution: GR cannot stretch, ClusterSet sidesteps, and the same product flips its CAP choice

Ticket 18 (lesson half), 2026-10-27. Lesson: `lessons/0006-geo-clusterset.html`.
Reference: `reference/clusterset.html`. Scripts: `examples/01-group-replication/` (new: `43`; re-run 20, 38, 39, 40).
Measurements and verified quotes: `.scratch/replikacija/measurements/0008-geo-clusterset.md`.

## What was taught

Roots: total order / quorum exists only inside one group; an async channel never waits for the receiver;
signal ≈ 200 km/ms in fibre (new). Derived: GR across regions pays ≥ one inter-region RTT per commit
(waits for the nearest member completing the majority) and expels healthy members after 5 s detection +
5 s `member_expel_timeout` → ClusterSet = GR per DC + async `clusterset_replication` between, one writer
cluster, replicas `super_read_only` (conflict prevented, not resolved) → OK covers the primary cluster's
majority only; in-flight = loss window → switchover (old alive, locked, drained) vs forced failover
(manual, INVALIDATED, split-brain warning, fence) run live → CAP per scope: C inside, A across, in the
vendor's own words; the A choice is one operator command.

## Where his edge was, and what moved

- **CAP applied to GR minority: picked "availability"** (reads still worked) while the abstract
  definition and "refused write = A sacrificed" were solid. Gap = CAP is judged **per operation**. Fixed in
  D5; the 2|3 five-member variant answered correctly.
- **Composition GR-inside + async-across: "don't know"** while the plain async loss window was solid.
  Closed by D3 (what OK covers); same question re-asked → correct.
- **GR commit cost across regions: "commit doesn't wait, apply is async"** while "OK = majority received"
  was solid. A true sentence misapplied (apply vs ordering). Fixed via R3 + the 90/160 ms question.
- Switchover/failover definition, cross-cluster split brain, INVALIDATED reason, who chooses A: correct.

## Non-obvious for the writing session

- **The A choice is the operator's**: before `forcePrimaryCluster` the replica cluster refuses writes
  (C). Strongest form of the spine in the paper; say it.
- Shell `8.4` doc URLs currently serve 26.7 content; re-verify quote wording before citing.
- `super_read_only` on replica clusters is **measured** (ERROR 1290), not quoted; the manual says
  only "the replica clusters do not [accept writes]".
- Expel timeout 5 s is a design default, not derived. Minority-read staleness is our derivation.
- Teaching protocol changed this session: explanation → he types "next" → quiz (`../TEACHING.md`).

## What comes next

Ch. 6 writing session (ticket 18 prose, ~3 pages, ≤ ~450 words/page after figures). Spaced retrieval at
its start: why a cross-region group pays per commit; what OK covers in a ClusterSet; which CAP choice for
a write on a GR minority, and why reads working does not change it. Then ch. 7 (read scaling, ticket 19).

## Evidence

`.scratch/replikacija/measurements/0008-geo-clusterset.md`
