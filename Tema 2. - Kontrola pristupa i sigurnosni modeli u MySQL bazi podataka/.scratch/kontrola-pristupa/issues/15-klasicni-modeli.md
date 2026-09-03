# Chapter 2. Klasični modeli kontrole pristupa

Type: task
Status: open
Blocked by: 02, 07, 09

## Question

Execution ticket - resolves only when all four Definition-of-Done items are done.

**Target length**: ~3.5 pages of `rad.md`.

**Scope**: The theory chapter every later chapter judges MySQL against. Follows the deck's own order
(`GLOSSARY.md` §2a): policy vs. mechanism, DAC (ownership, delegable privileges, cascading revoke),
the Trojan-horse argument as the DAC→MAC hinge (deck slide 15 — Dick and Justin, cited to R&G not the
deck), MAC and Bell–LaPadula with both properties stated formally, then extends past the deck with
RBAC-as-a-model (Sandhu 1996, Ferraiolo & Kuhn 1992, ANSI/INCITS 359-2004) and the least-privilege
principle's exact 1975 wording (Saltzer & Schroeder). One paragraph, no more, on the statistical
database / inference problem (deck slide 19). Closes by stating the paper's spine as a claim to be
tested in every chapter after this one.

**Definition of done**:
1. The user has been taught this chapter via `/teach` (they must invoke it themselves) and a lesson
   exists in `lessons/`.
2. Runnable SQL committed to `examples/` where the chapter has anything to run (this chapter is
   theory-heavy; a minimal DAC-vs-MAC illustration may be enough), and at least one captioned figure
   in `figures/` per the strategy set in ticket 12.
3. Serbian prose appended to `rad.md` **using the `academic-research-writer` skill**, with IEEE
   citations added to `references.bib` as they are used. Every deck-backed claim cites its published
   origin (R&G ch. 21), never the deck itself (`../../WORKFLOW.md` rule 7).
4. A learning record written to `learning-records/`, and the work committed.

**Grounding**: research memo 02 (the deck) and memo 07 (RBAC/ABAC theory, least privilege, the
Sandhu/NIST bibliography), plus the terminology and chapter notes in `../../GLOSSARY.md` §1–§2a.
