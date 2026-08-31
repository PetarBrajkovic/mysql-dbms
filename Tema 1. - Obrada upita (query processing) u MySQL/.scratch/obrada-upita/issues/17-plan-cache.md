# Chapter 8. Kesiranje i ponovna upotreba planova

Type: task
Status: closed - superseded
Blocked by: 16

**Merged into [chapter 6](21-gde-mysql-ne-prati-obrazac.md) as §6.3 on 2026-08-31**, with tickets 15
and 16, under the ≤25-page target. Scope is unchanged and carried over verbatim, including the
`GLOSSARY.md` §3 hard constraint on plan cache vs parse-tree cache; only the chapter boundary moved.

## Question

Execution ticket - this map carries execution, so it resolves only when all four are done.

**Target length**: ~2 pages of `rad.md`.

**Scope**: Slide bullet: plan cache and reuse. Framing depends on the research: expected to be why MySQL has no plan cache, why the query cache was removed in 8.0, and what prepared statements actually reuse. Reframe the chapter if research contradicts this.

**Definition of done**:
1. The user has been taught this chapter via `/mattpocock-skills:teach` (they must invoke it
   themselves) and a lesson exists in `lessons/`.
2. Runnable SQL committed to `examples/`, and at least one captioned figure in `figures/`, per the
   strategy set in ticket 09.
3. Serbian prose appended to `rad.md` **using the `academic-research-writer` skill**, with IEEE
   citations added to `references.bib` as they are used.
4. A learning record written to `learning-records/`, and the work committed.

**Grounding**: research ticket 06, plus the lecture mapping from ticket 07 and the glossary
from ticket 08.

## Answer
