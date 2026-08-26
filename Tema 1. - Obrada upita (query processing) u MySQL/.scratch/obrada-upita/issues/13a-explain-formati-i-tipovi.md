# Chapter 4a. EXPLAIN: formati ispisa i tipovi pristupa

Type: task
Status: closed
Blocked by: 12

## Question

Execution ticket, first of the three that together deliver chapter 4.

**Why this ticket is a third of a chapter.** Chapter 4 was budgeted at ~4 pages and always expected
to need 2-3 lessons (`WORKFLOW.md`, "How many lessons per chapter"). The split was decided on
2026-08-24 (`NOTES.md`, "Chapter 4 lesson breakdown") along research ticket 05's spine: **4a**
formats and access types, **4b** `EXPLAIN ANALYZE`, **4c** `optimizer_trace`. The original single
ticket 13 was split to match, so that each taught lesson has a ticket it can actually close instead
of leaving one mega-ticket two thirds done. Visual Explain, which the original ticket 13 listed in
scope, is dropped entirely: Workbench's Visual Explain stopped rendering on this machine and the
figure pipeline moved off Workbench (ticket 09, reopened 2026-08-22).

**Target length**: ~2 pages of `rad.md` (of chapter 4's ~4).

**Scope**: the three output formats (traditional, `FORMAT=JSON` versions 1 and 2, `FORMAT=TREE`) and
why the choice between them is not cosmetic; the twelve tabular columns and which four carry the
optimizer's decision; the twelve access `type` values, what their ranking is and what it is not; the
`Extra` values that make chapter 2's seam visible in one word. Explicitly **not** here:
`EXPLAIN ANALYZE`, estimated-vs-actual divergence, `optimizer_trace`, and the `wide_events` /
`country_code` worked example, which `NOTES.md` reserves for 4b.

**Definition of done** (unchanged from the original ticket 13):
1. The user has been taught this material via `/teach` (they invoke it themselves) and a lesson
   exists in `lessons/`.
2. Runnable SQL committed to `examples/`, and at least one captioned figure in `figures/`, per
   ticket 09.
3. Serbian prose appended to `rad.md` **using the `academic-research-writer` skill**, with IEEE
   citations added to `references.bib` as they are used.
4. A learning record written to `learning-records/`, and the work committed.

**Grounding**: research ticket 05 §1 (`EXPLAIN` output semantics), the lecture mapping from ticket
07, and the glossary from ticket 08, whose §2c is this material's own locked vocabulary.

## Answer

Written and closed. ~3 pages of `rad.md` (see the budget note below), in four subsections built on
one spine: **`EXPLAIN` prints an estimate, and the estimate has a shape**.

**4.1. Tri formata ispisa, dva oblika plana.** The chapter's opening move is that three formats are
only two shapes: the traditional format and `FORMAT=JSON` version 1 print **one row per table** (the
MySQL 5.6 plan representation, in which a filter has no row of its own), while `FORMAT=TREE` and
`FORMAT=JSON` version 2 print **one node per iterator**. Measured, not asserted: the same
`customer`/`payment` join is 2 rows against 4 nodes, and the bridge between the two shapes is
arithmetic the manual itself prescribes, `rows × filtered / 100` = 16.500 × 33,33% = 5.499, which is
exactly the `Filter` node's estimate and exactly what JSON v1 hands over as `rows_produced_per_join`.
Carries Slika 4.1 (`figures/04-explain-01-tri-formata-jedan-plan.png`).

**4.2. Kolone koje nose odluku.** Twelve columns, four of which carry the decision (`type`, `key`,
`rows`, `filtered`); the rest identify or describe. Three common misreadings written up as the
section's body: `key` and `key_len` answer different questions and only together say what the access
does (`film_actor` PRIMARY, `key_len` 2 vs 4, nineteen rows vs one); `possible_keys` naming an index
while `key` is `NULL` is not a missing index but chapter 3's `cause: "cost"` seen from the output
side; and the number flowing into the next table is the product `rows × filtered`, not `rows`
(same index, same 32 rows, `filtered` 100,00 → 33,33, `Extra` flipping `Using index` → `Using where`
at the same moment).

**4.3. Lestvica tipova pristupa.** Twelve values in the manual's best-to-worst order, all twelve
reproduced live on `sakila`, carrying Slika 4.2
(`figures/04-explain-02-lestvica-tipova-pristupa.png`). The section's argument is that **the ladder
is not a cost ranking**: `unique_subquery` (rank 8) returns at most one row, the same as `eq_ref`
(rank 3), five places higher, so the grouping by "how many rows can one access return" is not
contiguous in the manual's order. Defence line written into the prose: `range` over fifty rows beats
`ref` over five million, and `ALL` over a three-row table is the cheapest thing there is; the type
describes the *shape* of the access, the price is computed by chapter 3's cost model. The section
ends on the strongest continuity link in the paper so far: `unique_subquery` and `index_subquery`
cannot be seen at all with default settings, because the semijoin transformation rewrites the
subquery **in preparation**, before an access type is ever chosen. Chapter 3's finding, seen from the
other side.

**4.4. Kolona `Extra` i granica procene.** `Using index` / `Using index condition` / `Using where` as
the same check happening in three different places, which is chapter 2's seam made visible in one
word of output; then `Using temporary` and `Using filesort` as warnings, with the note that
`filesort` misnames itself. Closes by stating the limit that hands off to 4b and 4c: everything read
so far is an estimate, `EXPLAIN` over a `SELECT` does not execute the query, and the output shows
only the winner.

**Citations.** All manual-cited except one new entry: `mysqlblogjson` (Magnus Brevik, "New JSON
format for EXPLAIN", MySQL Server Team Blog, 2024), renders IEEE [5]. It was added because the
manual documents `explain_json_format_version` but not the field-level semantics of version 2, and
the paper makes a precise claim about those: `access_type` holds the **iterator kind** in v2 with the
traditional value moved to `index_access_type`, so any JSON quoted as evidence has to name its
version. Author and date verified against the post itself rather than guessed (WORKFLOW rule 6).

**Verified**: `tools/make-docx.ps1` builds clean; 8 inline figures in the DOCX (1 + 3 + 2 + 2),
citations render as IEEE [1]-[5] with the reference list intact, Serbian diacritics intact, zero em
dashes in `rad.md` (rule 8).

**Budget flag for 13b, worth not discovering late.** This half came out at ~1.440 words, which at
this paper's measured density (~430-450 words per page, figures included) is **~3 pages of chapter
4's ~4-page budget**. Nothing here is padding: the section covers three formats, twelve columns,
twelve access types and seven `Extra` values, and it is already the terser of the two halves. So 4b
and 4c have a real choice to make at write time, and it should be made deliberately: either they fit
`EXPLAIN ANALYZE` plus `optimizer_trace` into ~1 page together (roughly 450-650 words, which likely
means 4c folds into 4b as a short subsection, as `NOTES.md` already suspected it might), or chapter
4's budget is formally raised to ~5.5-6 pages and the ~21-page total in `GLOSSARY.md` §4 moves with
it. Do not silently trim the written half to make room; per ticket 08 the budget is soft guidance,
not a quota.

**Artifacts** (all pre-existing from the lesson session, verified in place, nothing regenerated):
`lessons/0004-explain-formati-i-tipovi-pristupa.html`,
`learning-records/0004-explain-formats-and-access-types.md`,
`reference/03-explain-formati-i-tipovi.html`, `examples/04-explain/01..03-*.sql`,
`figures/04-explain-01-*` and `-02-*` (PNG + SVG), built by
`tools/make-lesson04-three-formats.ps1` and `tools/make-lesson04-access-types.ps1`.
