# Chapter 4c. Trag optimizatora: ono što EXPLAIN ne pokazuje

Type: task
Status: open
Blocked by: 13b

## Question

Execution ticket, last of the three that deliver chapter 4. Split from the original ticket 13; see
13a for why.

**Target length**: ~1 page of `rad.md`. **Confirmed 2026-08-28**: chapter 4's budget was raised a
second time, 6 → 6.6 pages, precisely so this section keeps its full page instead of being cut to
~0,5. Do not trim it back. See `GLOSSARY.md` §4, second revision. Chapter 4's budget was raised from 4 to 6 pages on
2026-08-26, leaving ~3 pages for 13b and 13c together, so this section is **no longer forced to
fold into 4b to fit**.

**Resolved 2026-08-26: it does NOT fold**, and lesson 0006 (2026-08-28) confirmed why — see
`learning-records/0006-*.md`. The paragraph below is kept as the record of how that was decided.

**It may still fold, on its own merits.** `NOTES.md` flagged when the split was decided that 4c is
the thin one: the user has already read an optimizer trace twice (chapter 3, and once in passing
during lesson 4a), so the vocabulary is not new. **Decide at the start of the 13b session** whether
this is a separate lesson and section or a closing subsection of 4b, and decide it on whether there
is a lesson's worth of new material here, not on page count. If it folds in, close this ticket by
ruling it merged rather than leaving it open.

**Scope**: `optimizer_trace` and `EXPLAIN FOR CONNECTION` as the two windows `EXPLAIN` does not
open. The single claim worth the space: `EXPLAIN` prints the winner and says nothing about the
losers, while the trace prints the **rejected plans and their costs**, which is what turns "the
optimizer ignored my index" into a readable decision. Chapter 3 already used `cause: "cost"` as
evidence and 13a's §4.2 pointed back at it from the output side, so the material is set up.
`EXPLAIN FOR CONNECTION` is the other half: reading the plan of a statement that is running in
another session right now.

**Grounding**: research ticket 05 §4 and §5 (`optimizer_trace` structure, the tracing system
variables, `INFORMATION_SCHEMA.OPTIMIZER_TRACE`, `EXPLAIN FOR CONNECTION`).

**Definition of done**: the same four as 13a, adjusted if this folds into 4b (in which case the
lesson and the prose belong to 13b and this ticket only records the decision).

## Answer
