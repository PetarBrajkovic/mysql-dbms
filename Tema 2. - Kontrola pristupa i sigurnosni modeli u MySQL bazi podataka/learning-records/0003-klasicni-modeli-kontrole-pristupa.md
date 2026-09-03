# 0003 — Klasični modeli kontrole pristupa (chapter 2)

Date: 2026-09-04 · Lesson: `lessons/0001-klasicni-modeli-kontrole-pristupa.html` ·
Reference card: `reference/01-modeli-kontrole-pristupa.html` ·
Example: `examples/02-klasicni-modeli/01-dac-kaskadno-oduzimanje.sql`

## What was taught

The theory chapter's whole dependency graph, taught live before the artifacts were written:
the (subject, object, operation) triple as the common frame → policy vs. mechanism → DAC as
"the owner decides", with delegation, dependent privileges and grant-only *derived* from that
one sentence rather than listed → the Trojan horse as the structural limit (access is checked
at access time, leakage happens after) → MAC with both Bell–LaPadula properties derived, not
memorised → RBAC as an orthogonal axis with the Sandhu RBAC₀–₃ scale → least privilege in
Saltzer & Schroeder's exact 1975 wording.

## Where his edge was, before the lesson

Probed with five graded questions. **Floor**: authentication vs. authorization (clean), and he
reconstructed the Trojan-horse argument cold, without a single term. **Ceiling**: the definition
of DAC and the semantics of a single `GRANT` — both answered "I don't know", with the note *"the
db example was created by AI"*. So: strong reasoning, no stored formal apparatus, and the
sandbox from record 0001 is not yet his in any felt sense.

Consequence, and it should shape every later lesson: **teach the name onto a scenario he has
already reasoned through**, never the scenario onto a name. Expository definitions bounce off;
derivations stick.

## Misconceptions found and corrected

1. **"Owner decides" read as "only the owner ever decides."** He picked the restrictive option
   for the delegation question. Fixed by showing that such a restriction would itself be a rule
   the *system* imposes on the owner — i.e. a sliver of mandatory control — which makes
   `WITH GRANT OPTION` a consequence rather than a feature.
2. **Bell–LaPadula assumed symmetric.** He chose $class(S) \geq class(O)$ for the write rule,
   reasoning by symmetry with the read rule. Fixed by running his own rule against the Trojan
   horse leak and watching it permit exactly the write it was meant to stop.
3. **Overcorrection: "any crossing of a class boundary is forbidden."** Two questions in a row
   missed on this. This was the hard node of the session. Fixed with a drawn figure
   (`figures/02-klasicni-modeli-01-bell-lapadula.png`) whose arrows show *information flow*, not
   the user's action: all green arrows point up, all red ones down. The blocking intuition
   underneath was "how can I write into something I may not read?" — dissolved by naming the
   blind write and stating that **BLP protects confidentiality, not integrity** (Biba is the
   dual). Only after that did it land.

Post-fix retrieval was clean on all three.

## Non-obvious insights worth revisiting

- **The triple explains the RLS chapter three chapters early.** Since the literal value in
  `UPDATE ... SET status='otkazan'` is not part of (S, O, op), no triple-based model can express
  a content-dependent rule. Chapter 4 should reuse this instead of re-motivating RLS from scratch.
- **Saltzer & Schroeder's "fail-safe defaults" (principle b) describes MySQL's grant-only model
  verbatim** — *"Base access decisions on permission rather than exclusion"*. Found while
  verifying the least-privilege quote; not in memo 07, which cites only principle f. Lets the
  paper source the grant-only design to 1975 rather than to the manual.
- **"Operate using", not "may".** Least privilege is about privileges in force at a moment, which
  is precisely why RBAC₀ requires sessions. This is the joint that connects ch. 2's principle to
  ch. 3's `SET ROLE` and ch. 7's connection pooling.
- MAC's real cost is not implementation effort but daily absurdity (no public memo from a
  top-cleared subject; trusted subjects exist as the escape hatch). Worth one sentence in the
  chapter — it is why commercial DBMSs skipped MAC.

## Correction filed against the live teaching

Mid-lesson I asserted that cascading revoke follows from the model *and holds in MySQL*. The
model half is right; the MySQL half is wrong, and I corrected it in the session from the manual.
See the standing constraint added to `README.md`.

## What comes next

Chapter 2's remaining DoD items: run
`examples/02-klasicni-modeli/01-dac-kaskadno-oduzimanje.sql` against the live server (**not yet
executed** — the "what you should see" block in the lesson states the manual's expectation, not a
measurement), then write the chapter with `academic-research-writer`. The `references.bib` entries
this chapter needs beyond `ramakrishnan2003`: Sandhu 1996, ANSI/INCITS 359-2004, Saltzer &
Schroeder 1975, Bell & LaPadula 1973/1976.
