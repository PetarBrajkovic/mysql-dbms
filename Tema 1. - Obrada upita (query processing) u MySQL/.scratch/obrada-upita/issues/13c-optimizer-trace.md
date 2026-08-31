# Chapter 4c. Trag optimizatora: ono što EXPLAIN ne pokazuje

Type: task
Status: closed
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

**Written and closed 2026-08-31.** It did not fold: §4.8 and §4.9 of `rad.md`, ~590 words plus one
figure, closing chapter 4 at §4.9 and keeping the ~1 page the 6 -> 6.6 budget raise was made to
protect. Chapter 4 is now written end to end.

**The spine is LR-0006's headline finding, and it is stronger than the ticket's own scope.** The
ticket asked for "`EXPLAIN` prints the winner and says nothing about the losers." The trace delivers
that (the `film` / `idx_fk_original_language_id` case from §4.2 is now shown entering
`range_scan_alternatives`, getting a cost, and losing with `"cause": "cost"` — measured, no longer
inferred), but §4.8's centre of gravity is the bad plan from §4.7: `considered_execution_plans`
costs **exactly one** access path for `wide_events`, the table scan at ≈578.000, and
`idx_created_at` **never appears there at all**. The later
`reconsidering_access_paths_for_index_ordering` step flips the plan with an **empty `"steps"`
array**, so no cost was computed. The plan `EXPLAIN` reports at 0,846 was **installed by a rule, not
won in a comparison**, and that 0,846 is a consequence computed *after* the swap. `LIMIT` is the
trigger, verified by removing it (`plan_changed: false`, `type: ALL`, `Using filesort`) and by
`LIMIT 10000` (fires again — existence, not size). This retroactively explains §4.7's histogram
result: the decision was never made from an estimate, so correcting the estimate could not move it.

**Written honestly about what the trace is not**: `"chosen": true` means "best so far", not the
winner; pruned partial plans survive only as `"pruned_by_cost": true`; the trace is session-scoped
and truncates via `MISSING_BYTES`. §4.9 gives `EXPLAIN FOR CONNECTION` the other half of the
two-window framing (deep but session-bound, against shallow but cross-session), with the 1235 and
3012 outcomes written as **measured on 8.4.11**, never as the manual's wording, per the LR-0005/0006
handling rule.

No new citations; everything is `mysql84refman`. Terminology from `GLOSSARY.md` §2e (`faza traga`,
`odbačen plan`, `razmatran plan`, `naknadna zamena plana`, `krnj trag`, `sesijski`, `broj veze`),
including `pristupni put` rather than the tempting `put pristupa`. Sixth clean pass of the
per-chapter loop.

**Numbers deliberately quoted as the figure prints them**, not as `.scratch/.../measurements/` has
them: the figure says ≈578.000 and 0,846 where the measurement table says ≈574.800 and 0,838, run
variance that §4.7 already flags in prose. Per `WRITING.md`, prose matches the figure beside it.
