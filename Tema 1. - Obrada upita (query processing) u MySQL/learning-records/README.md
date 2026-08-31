# Learning records — index

One record per taught lesson, in the teach skill's `LEARNING-RECORD-FORMAT.md`. **Read this index
first and open only the records it points you at** — reading all of them costs more context than any
one lesson needs.

Each record holds: what was taught (short), the non-obvious insights worth revisiting, and what
comes next. The measured numbers, produced artifacts and write-up notes are **not** here — they live
in `.scratch/obrada-upita/measurements/<same-filename>` and are only needed when writing or checking
a chapter, never when planning a lesson.

| # | Chapter | Headline | Open it when you are teaching / writing about |
|---|---|---|---|
| [0001](0001-query-processing-gap-and-two-levels.md) | 1 Uvod | Query processing is a gap crossed on two levels | the logical/physical split, cost as the shared objective, the roadmap |
| [0002](0002-server-engine-seam.md) | 2 Arhitektura | The architecture is a seam, and the seam is `handler` | server-vs-engine boundary, ICP, where statistics live, iterators calling `handler` |
| [0003](0003-five-phases-and-one-cost.md) | 3 Od SQL-a do plana | Five phases; every decision with an alternative is settled by cost | the pipeline, resolution-vs-optimization, cost constants, join-order search, pruning |
| [0004](0004-explain-formats-and-access-types.md) | 4a EXPLAIN | Two shapes, not three formats; the type ladder is not a cost ranking | `EXPLAIN` output, `FORMAT=TREE`/JSON versions, the 12 access types, `Extra` |
| [0005](0005-explain-analyze-estimate-vs-actual.md) | 4b EXPLAIN ANALYZE | A bad estimate is not a bad plan | measurement vs estimate, `loops`, divergence as a screening threshold, histograms |
| [0006](0006-optimizer-trace-and-for-connection.md) | 4c optimizer_trace | The bad plan was never costed against anything | `optimizer_trace`, rejected plans, `EXPLAIN FOR CONNECTION` |
| [0007](0007-iterator-model-and-pipeline.md) | 5 Model iteratora | A row exists only because someone above asked for it | `RowIterator`, TREE node → iterator class, `loops` as `Init()` calls, blocking vs pipelined, `AccessPath` |

## Standing constraints these records impose on every later chapter

Facts already settled, with the record that settled them. **Do not re-litigate or re-measure these.**

- Absolute costs wobble with buffer-pool residency; **quote ratios, not absolute numbers** (0003).
- Plan-search and partial-plan counts are **run-dependent**; give the direction, not the count (0003, 0006).
- `explain_json_format_version = 2` works on 8.4.11; `access_type` means a **different thing** in each
  version, so any quoted JSON must name its version (0004).
- Estimated-vs-actual divergence is a **screening threshold, not a verdict**: a measured 48x left a
  five-table join order unchanged (0005).
- `EXPLAIN ANALYZE` **never modifies data**, and takes only `SELECT`, `TABLE` and **multi-table**
  `UPDATE`/`DELETE`. Never tell the reader to wrap it in a rollback (0005).
- Histograms improve a skewed estimate only on a **non-indexed** column; with an index, the range
  optimizer's dive outranks the histogram (0005).
- The trace's three phases are **not** chapter 3's five stages: parsing finishes before the trace
  starts, and optimization and planning are one block in it (0006).
- Trace an `EXPLAIN` rather than the query when the query is slow — same `join_optimization`, nothing
  executed (0006).
- `loops` is the count of `iterator->Init()` calls, stated in the source; `rows` on an inner node is
  therefore a **per-loop average** and `rows × loops` reconstructs the join's row count (0007).
- `AccessPath` (the C++ struct) and `pristupni put` (the concept) are **not** synonyms and must never
  be swapped in the prose (0007, GLOSSARY §2f).
- `-> Hash` is **not** an iterator — it is an edge label on a hash join's build input, and it is the
  only tree row that carries no numbers (0007).

## Settled by research, before any lesson

From the closed research tickets in `.scratch/obrada-upita/research/`. Do not re-litigate these
mid-chapter either.

- MySQL has **five** pipeline stages, and transformations live inside **resolution**.
- The **hypergraph optimizer cannot run** on the stock 8.4 build installed here: it is compile-gated
  to debug builds. Teach it as a documented fact, never as a live demo.
- MySQL does **not** vectorize, and `innodb_parallel_read_threads` does **not** speed up an ordinary
  `SELECT`.
- MySQL has **no shared plan cache**, but it does cache prepared-statement **parse trees** per
  session. Chapter 8 turns on drawing that line precisely; never write "MySQL doesn't cache anything".
- `optimizer_search_depth` defaults to **62**.

## Corrections filed against the research memos

`.scratch/obrada-upita/research/04-sql-to-plan-and-iterator.md` has **two** errors found while
teaching chapter 5 (0007): §3.4's mapping table reads the `IndexScanIterator`/`RefIterator` template
parameter as "covering" when it is **`Reverse`**, and §3.1 paraphrases WL#11785's Volcano sentence
rather than quoting it (the worklog says "borrowed from the classic Volcano database system"). The
rest of that memo held up, including the whole `AccessPath`↔iterator account.

`.scratch/obrada-upita/research/05-explain-semantics.md` has **three** errors found by live testing;
do not quote it on these without checking: §2.5-2.6's `UPDATE`/`DELETE` claim (0005), the stale
`FORMAT=JSON` claim it inherits from the manual (0005), and §4.4's 16 KB default for
`optimizer_trace_max_mem_size` — 8.4.11 ships **1048576** (0006). The rest of that memo held up.
