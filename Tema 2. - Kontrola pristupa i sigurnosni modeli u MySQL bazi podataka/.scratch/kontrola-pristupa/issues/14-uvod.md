# Chapter 1. Uvod

Type: task
Status: closed
Blocked by: 08, 09

## Question

Execution ticket - this map carries execution, so it resolves only when all four Definition-of-Done
items are done.

**Target length**: ~1 page of `rad.md`.

**Scope**: Frame the problem: what access control means for a DBMS, the paper's spine (`GLOSSARY.md`
§0 — MySQL is DAC-only, everything modern is composed from that or absent), and a one-sentence
roadmap per chapter (2–8). Written early, then revisited once the conclusion (ch. 8) exists, per
Tema 1's own note that an intro and conclusion should be reconciled together.

**Definition of done**:
1. The user has been taught this chapter via `/teach` (they must invoke it themselves) and a lesson
   exists in `lessons/`, if a lesson is warranted at all — `../../WORKFLOW.md` notes an intro needs
   no teaching; use judgment.
2. Runnable SQL committed to `examples/` if the chapter uses any (an intro may not), and at least one
   captioned figure in `figures/` if the figure strategy (ticket 12) calls for one here.
3. Serbian prose appended to `rad.md` **using the `academic-research-writer` skill**, with IEEE
   citations added to `references.bib` as they are used.
4. A learning record written to `learning-records/` if a lesson was taught, and the work committed.

**Grounding**: the running example (ticket 08) for what the paper's scenario is, and the glossary
(ticket 09) for the spine and the chapter roadmap.

## Resolution (2026-09-03)

No lesson taught, per `../../WORKFLOW.md`'s note that an intro needs no teaching — judgment used as
instructed. No SQL and no figure: an intro has neither, and ticket 12's figure budget allocates 0
figures to Uvod/Zaključak.

Serbian prose written directly into `rad.md` § 1 with the `academic-research-writer` skill, checked
against `serbian-grammar`: three paragraphs, ~500 words. Frames DAC vs. MAC and policy-vs-mechanism
(cited to Ramakrishnan & Gehrke, since the deck itself is never cited per rule 7), states the paper's
spine verbatim from `GLOSSARY.md` §0 (MySQL is DAC-only, everything modern composed-from-DAC or
absent), then a one-sentence roadmap per chapter 2–8. RBAC named against Sandhu et al. 1996 in the
ch. 3 roadmap sentence, since ch. 3 judges MySQL's roles against that model by name.

`references.bib` seeded with three entries: `ramakrishnan2003` (reused verbatim from Tema 1's own
entry, same key), `mysql84refman`, and `sandhu1996` (full use deferred to ch. 3, memo 07's entry 1).

Exported via `../tools/make-docx.ps1` to confirm the pipeline still runs clean on this topic's first
chapter; word count is in budget for the ~1 page target. No learning record: no lesson was taught.

No revisit yet against ch. 8 (Tema 1's own note that intro and conclusion should be reconciled
together) — ch. 8 does not exist yet; flagged for whoever writes it.
