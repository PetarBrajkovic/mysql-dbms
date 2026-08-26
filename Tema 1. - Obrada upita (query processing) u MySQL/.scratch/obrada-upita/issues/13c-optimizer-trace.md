# Chapter 4c. Trag optimizatora: ono što EXPLAIN ne pokazuje

Type: task
Status: open
Blocked by: 13b

## Question

Execution ticket, last of the three that deliver chapter 4. Split from the original ticket 13; see
13a for why.

**This ticket may not survive as its own section, and that is fine.** `NOTES.md` flagged when the
split was decided that 4c is the thin one and may fold into 4b, and 13a's budget flag makes that
more likely, not less: the user has already read an optimizer trace twice (chapter 3, and once in
passing during lesson 4a), so the vocabulary is not new. **Decide at the start of the 13b session**
whether this is a separate lesson and section or a closing subsection of 4b. If it folds in, close
this ticket by ruling it merged rather than leaving it open.

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
