# 0007 — Group Replication: who decides the order, and who waits for visibility

Ticket 17 (lesson half), 2026-10-23. Lesson: `lessons/0005-group-replication.html`.
Reference: `reference/group-replication.html`. Scripts: `examples/01-group-replication/` (new: `41`, `42`).
Measurements and verified quotes: `.scratch/replikacija/measurements/0007-group-replication-lesson.md`.

## What was taught

Root: **one server orders conflicting writes by its row lock** (one decision point). Derived: two
leaders decide independently and both ack → divergence; the fix is agreement on order *before* OK.
R3 (given): XCom/Paxos delivers all messages to all members in one total order. → certification:
local execution, write-set at COMMIT, deterministic per-member verdict, first-in-order wins, no
voting; → PK required (live ER 3098), row-level (live pair), observable 1180. Quorum: no majority →
no slot in the order → minority blocks, no split brain (ticket 11 numbers). Single vs multi-primary.
Commit = majority received ≠ applied (decision ≠ visibility again) → two places to wait → levels
mapped onto ch. 2 models; `BEFORE` measured live.

## Where his edge was, and what moved

- **Multi-leader conflict: "don't know"** at probe; single-server case answered "replicas choose the
  value" while binlog replay itself was solid. Gap = *who orders concurrent writes on one server*.
  Fixed with R1; D1 Socratic step (agree before OK) derived correctly.
- **Quorum intersection held, but not applied**: thought the lone primary 3307 would commit "because
  it is still primary", while correctly saying a GR commit needs a majority. Dislodged by "role says
  where writes are accepted, not who decides"; 2/2 split of four answered correctly.
- Split brain, RYW (narrowest name), eventual = convergence only: held.
- **Session vs cross-client scope**: picked "eventual" as the weakest model forbidding another
  client's stale read; the gap was scope (session guarantees say nothing about client Y). Closed by
  the AFTER-on-writer / unmodifiable-reader question, answered correctly.
- **Misconception: multi-primary scales writes ~3×.** Persisted after the first explanation; the
  per-member work table (each writes 300 of 300) dislodged it; confirmed with the disk-at-100 % question.
  I had also overstated it ("throughput does not rise"): corrected live to "not proportionally —
  only statement execution is spread". Re-check at the start of the writing session.
- All certification steps, the 1180 meaning, D5 prediction and BEFORE-cost prediction: correct.

## Non-obvious for the writing session

- **8.4's default level is `BEFORE_ON_PRIMARY_FAILOVER`, not `EVENTUAL`** (8.4.0 release notes; live).
  0002 mislabelled it; corrected in place. In steady state it behaves as EVENTUAL (40/40 stale).
- **The mapping level → model is ours**; the refman never says "linearizable"/"read your writes".
  `BEFORE` ≈ strong for that read; `AFTER` = RYW for every reader of that write, **not**
  linearizability. Say "povezivanje je izvedeno".
- Closing the window costs ≈ one apply time either way; the knob chooses who pays (reader 0→14–16 ms
  under BEFORE, writer 16→29 ms under AFTER). This is the climax sentence.
- Do not write "async has no automatic failover": Asynchronous Connection Failover re-points
  automatically; the difference is who promotes the new source.
- "When multi-primary is justified" has no manual quote — it is memo 05's verdict, derived.

## What comes next

Ch. 5 writing session (ticket 17 prose). Spaced retrieval at its start: why the lone primary blocks;
why multi-primary does not scale writes; which level when the reader cannot be changed. Then ch. 6
(ClusterSet), whose contrast is the opposite CAP choice across clusters.

## Evidence

`.scratch/replikacija/measurements/0007-group-replication-lesson.md`
