# Chapter 4. EXPLAIN i EXPLAIN ANALYZE

Type: task
Status: open
Blocked by: 12

## Question

Execution ticket - this map carries execution, so it resolves only when all four are done.

**Target length**: ~4 pages of `rad.md`.

**Scope**: Slide bullet: EXPLAIN and EXPLAIN ANALYZE analysis. The most hands-on chapter and the figure centrepiece. All three output formats, reading actual against estimated rows, optimizer trace, and Visual Explain. Should end by diagnosing one genuinely bad plan.

**Definition of done**:
1. The user has been taught this chapter via `/mattpocock-skills:teach` (they must invoke it
   themselves) and a lesson exists in `lessons/`.
2. Runnable SQL committed to `examples/`, and at least one captioned figure in `figures/`, per the
   strategy set in ticket 09.
3. Serbian prose appended to `rad.md` **using the `academic-research-writer` skill**, with IEEE
   citations added to `references.bib` as they are used.
4. A learning record written to `learning-records/`, and the work committed.

**Grounding**: research ticket 05, plus the lecture mapping from ticket 07 and the glossary
from ticket 08. Also see ticket 01's Answer for a live-server finding this chapter should use
directly: the `country_code` covering-vs-non-covering contrast on `wide_events`, including the
non-covering follow-up query (`SELECT notes FROM wide_events WHERE country_code = ...`) that
ticket 01 flagged but didn't run.

## Answer
