# Chapter 5. Iterator model i pipeline operatora

Type: task
Status: resolved
Blocked by: 13c

## Question

Execution ticket - this map carries execution, so it resolves only when all four are done.

**Target length**: ~3 pages of `rad.md`.

**Scope**: Slide bullet: operator pipeline (iterator model). The Volcano model, MySQL's iterator executor, and how FORMAT=TREE output maps onto a tree of real iterators. Best taught by tracing a single query through its operators.

**Definition of done**:
1. The user has been taught this chapter via `/mattpocock-skills:teach` (they must invoke it
   themselves) and a lesson exists in `lessons/`.
2. Runnable SQL committed to `examples/`, and at least one captioned figure in `figures/`, per the
   strategy set in ticket 09.
3. Serbian prose appended to `rad.md` **using the `academic-research-writer` skill**, with IEEE
   citations added to `references.bib` as they are used.
4. A learning record written to `learning-records/`, and the work committed.

**Grounding**: research ticket 04, plus the lecture mapping from ticket 07 and the glossary
from ticket 08.

## Answer

Chapter 5 written and closed, §5.1-5.5, ~1.450 words plus two figures, **measured at exactly its
3-page budget** (export 19 -> 22 rendered pages).

**Spine.** The chapter opens on the puzzle rather than the definition, per the write-up note in
`.scratch/obrada-upita/measurements/0007-...`: the same scan under the same `LIMIT 10` reads ten rows
or five million, and the only difference is one `ORDER BY` clause. Everything after that is the
answer, in three moves plus a seam:

- **§5.1** the interface. `RowIterator` with `Init()` / `Read()` / `UnlockRow()`, the Volcano lineage
  via WL#11785, and the six abstractions it replaced. Two things the signature hides are written out:
  the row is **not** the return value, it goes into `table->records[0]`, so Volcano supplied the
  control flow and MySQL kept its own record-buffer convention; and an iterator may read from another
  iterator, which is why the plan is a **tree**, not a chain. The header's own admission that the
  abstraction "is not completely tight" (`read_set` stays on `TABLE`) is written in rather than
  smoothed over.
- **§5.2** the tree. `FORMAT=TREE` nodes *are* iterators (manual), indentation is parent/child, and
  the printed-string → class mapping is mechanics, not analogy: `explain_access_path.cc` and
  `access_path.cc` branch on the same `path->type`. LR-0007 (e)'s correction is carried into the
  paper: the `IndexScanIterator` template parameter is **`Reverse`**, not covering-ness. `-> Hash`
  gets its sentence as the one printed row that is not an iterator, recognisable without the source
  because it is the only row carrying no numbers.
- **§5.3** `loops`. Chapter 4's rule becomes a consequence: `IteratorProfiler::GetNumInitCalls()`
  counts `Init()` calls, so inner `loops` = outer `rows` = 584 active customers, and inner `rows` is a
  per-loop average, `26.8 × 584 ≈ 15.651` against the join's own 15.640.
- **§5.4** pipeline vs. blocking, where the opening puzzle is discharged: the scan is **not**
  "optimized to stop", it stops being called. The first-row-vs-last-row signature is given as a
  reader-usable test, with both signatures shown in the same plan (`Sort` first == last, `Filter`
  beneath it first ≪ last), plus the lists of which operators block and which do not, and why
  `Stream results` exists at all.
- **§5.5** the seam back to chapter 3. `AccessPath` corresponds 1:1 to iterators;
  `CreateIteratorFromAccessPath()` is where the plan becomes runtime. This retroactively answers
  §4.8's empty `join_execution` phase: execution makes no decision worth tracing. The
  `AccessPath`-vs-`pristupni put` trap (GLOSSARY §2f) is stated explicitly in the prose.

**Citations.** Two new entries, rendering IEEE [6] and [7]: `graefe1994` (the Volcano paper, this
chapter's one theory citation, since the lecture decks do not cover the iterator model at all) and
`mysqlwl11785`. The worklog page carries **no publication date**, so none is claimed in the entry;
it renders without one rather than with an invented year. Everything at the C++ level is
`mysqlsource84`, same constraint as chapter 2: the manual does not document these interfaces.

**Budget.** 22 pages measured. Chapter 6 (2.5) + chapter 7 (0.75) projects to **~25.25 against the
hard ≤25**, so there is no slack left and chapter 6 absorbs any overrun. Seventh clean pass of the
per-chapter loop.
