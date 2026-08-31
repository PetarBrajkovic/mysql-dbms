# Chapter 7. Paralelno izvrsavanje upita

Type: task
Status: closed - superseded
Blocked by: 15

**Merged into [chapter 6](21-gde-mysql-ne-prati-obrazac.md) as §6.2 on 2026-08-31**, with tickets 15
and 17, under the ≤25-page target. Scope is unchanged and carried over verbatim; only the chapter
boundary moved. Nothing here was cut.

## Question

Execution ticket - this map carries execution, so it resolves only when all four are done.

**Target length**: ~2 pages of `rad.md`.

**Scope**: Slide bullet: parallel query execution. What is actually parallel in stock MySQL 8.4 versus Postgres and Oracle. Should demonstrate InnoDB parallel read threads against the synthetic table, where the effect is measurable.

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
