# 0003 — Theory framework: consistency models, CAP/PACELC, replication models, two quorums

Ticket 14 (lesson half), 2026-10-07. Lesson: `lessons/0001-teorijski-okvir.html` (first taught
lesson of Tema 3). Reference: `reference/modeli-konzistentnosti.html`. Sources, memo errors and the
sandbox repair: `.scratch/replikacija/measurements/0003-theory-framework.md`.

## What was taught

Seven nodes from three roots (messages take time or get lost; silence cannot tell dead from slow;
two majorities intersect): consistency models as a nested ladder → CAP derived as a thought
experiment on 3307/3309 → the four misreadings → PACELC as "what waiting costs when the network
works" → single/multi/leaderless by "who accepts writes" → consensus (election, log, safety, all
from intersection) → consensus-quorum vs Dynamo-quorum.

## Where his edge was, and what moved

- **Strong at derivation from intersection.** Majority, W+R>N, commit-on-majority and Raft's election
  restriction were all answered correctly in the probe, cold. Quorum/consensus needed no teaching,
  only naming.
- **Vocabulary was the gap.** Consistency models, session guarantees, PACELC and the three
  replication models were unknown at the probe. CAP held as "pick two" — dislodged by deriving the
  theorem himself (got it first try).
- **RYW vs monotonic reads did not stick from examples.** He understood every scenario but could not
  map names to meanings. Fix that worked: **the name is the trigger** (writes → your write; monotonic →
  your previous read), plus the nested ladder so "strong also forbids it" stops being a trap. Ask
  for the *weakest* model that forbids X. Later interleaved check: correct.
- **PACELC letters were the blocker, not the concept.** He got "latency, not availability" once the
  bounded-vs-unbounded wait table was shown, but PA/EL notation confused him repeatedly. Taught as
  **two plain questions** (partition: answer or refuse? healthy: wait or not?); letters demoted to
  shorthand. Use the two questions in ch. 2 prose too.
- **The two-quorum distinction needed a worked example.** He picked "Dynamo also agrees on order
  when W+R>N" once, after having answered the abstract version right in the probe — recognition, not
  understanding. The r1/r2/r3 concurrent-write example fixed it; the defense sentence is in the lesson.

## Non-obvious for the writing session

- **Abadi 2012 is the citation for "Dynamo quorums are not linearizable"** (verbatim, verified) —
  better than Kleppmann ch. 9, whose text was not fetched.
- Brewer 2012 ("2 of 3 … always misleading") is not in 07b; add it to `references.bib`.
- Memo 07 has five errors (measurements file). Its GR consistency-level section is wrong and must
  not leak into ch. 5.

## What comes next

Writing session for ch. 2 (ticket 14 stays open). Then ch. 3: the role vocabulary switches to
izvor/replika there. Re-check RYW/monotonic and the two PACELC questions at the start of the next
lesson (spaced retrieval) — they were the weakest landings.
