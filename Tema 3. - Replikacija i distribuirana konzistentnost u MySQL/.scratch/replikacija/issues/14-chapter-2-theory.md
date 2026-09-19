# Chapter 2 - Teorijski okvir: modeli konzistentnosti, CAP/PACELC i konsenzus

Type: task (execution - see the map's execution override)
Status: open
Blocked by: 09, 12

## Question

Write ch. 2, **~3 pages / 10-12 paragraphs** (`GLOSSARY.md` section 3 - this is the chapter the
budget exists to constrain). Backed by memo 07 and the verified bibliography in
`../research/07b-bibliography-verified.md`.

Must contain:

1. The consistency vocabulary: **konačna / stroga / uzročna konzistentnost**, read-your-writes, monotona čitanja - each defined once, here, so no later
   chapter re-defines them.
2. CAP with Gilbert-Lynch, and **PACELC as the refinement that matters** for this paper, since the
   else-branch (latency vs consistency with no partition) is what every MySQL knob actually trades.
   Memo 07 lists four standard misreadings of CAP - avoid all four, and say explicitly that CAP is not
   "pick two".
3. The replication models: single-leader, multi-leader, leaderless. **This chapter uses
   *leader/follower* and *single-/multi-leader* in English** (`GLOSSARY.md` section 1d); the switch to
   *izvor/replika* happens in ch. 3, not here.
4. Consensus **at conceptual depth only** - leader election, log replication, quorum safety. No proofs
   (memo 07's recommendation, adopted at ticket 09).
5. **The consensus-quorum vs Dynamo-quorum distinction, stated explicitly.** Non-optional: the
   professor's own bullet says "Quorum-Based sistemi", which invites exactly that confusion, and this
   is the chapter that has to prevent it.

Also seeds `references.bib` from `../research/07b-bibliography-verified.md` (17 entries, every one with
a fetched URL). Note the recorded ambiguity: **Gray & Reuter is cited as 1993**.

No MySQL feature is explained here, and the chapter does not open the spine's argument - it supplies
the vocabulary the spine is argued in.

**Shape of a chapter ticket** (same as Temas 1 and 2, per the map's execution override): this ticket
is resolved only when **the lesson has been taught, the examples have been run against the live
topology, and the Serbian prose is appended to `rad.md`** - and the lesson and the writing happen in
**different sessions** (`../WORKFLOW.md`).

Binding on every session here: `GLOSSARY.md` (terms are locked - do not re-translate), the theory
budget in `GLOSSARY.md` section 3, the caption honesty rule in section 5, `academic-research-writer`
for all prose, `serbian-grammar` for every Serbian line, and the two research rules in
`../../NOTES.md` (**no unverified absence claim**, **walk the source ladder and record the rung**).
