# 0003 — The pipeline has five phases, and every decision with an alternative is settled by cost — evidence

Detail split out of `learning-records/0003-five-phases-and-one-cost.md` so the record itself stays short.
Measured numbers, produced artifacts and write-up notes for that session. Read this only when writing or checking the chapter it belongs to, not when planning a lesson.

## Live run (2026-08-24, MySQL 8.4.11) — every number in the lesson is measured

| what | measured |
|---|---|
| Parse error precedes name resolution | `1064` before `1054` |
| Table-scan cost, `wide_events` | `578,220` (cold-pool arithmetic: `580,134`) |
| Range scan, `customer_id` ≤ 9,000 | `462,848`, `chosen: true` |
| Range scan, `customer_id` ≤ 12,000 | `660,854`, `chosen: false`, `cause: "cost"` |
| Access-path crossover | between N = 10,000 and N = 11,000 |
| Semijoin strategies costed | FirstMatch 18,124.9 / MaterializeLookup 2,027.95 / DuplicatesWeedout 18,350 |
| Six-table join, depth 62 vs depth 1 | ~150x cost, 5.76 ms vs 21.28 ms |
| Partial plans considered, prune 1 / 0 / depth 1 | 63 / 89 / 21 |
| `wide_events` PRIMARY pages in buffer pool | 2,651 (predicted ~2,552) |

## Artifacts produced

- `examples/03-od-sql-a-do-plana/01..05-*.sql`, all five smoke-tested against the live server.
- `figures/03-od-sql-a-do-plana-01-ukrstanje-cena.png` (+ `.svg`), a two-curve cost chart built from
  a 15-point sweep of the trace, by the new `tools/make-lesson03-cost-crossing.ps1`. This is the
  first figure in the workspace that myflames cannot produce: the teaching point is a pair of cost
  *curves*, and one plan tree is only ever one point on them.
- `figures/03-od-sql-a-do-plana-02/03-redosled-spoja-dubina-62/1.png` (+ `.svg`), via the new
  `tools/make-lesson03-joinorder-comparison.ps1` (same shape as the lesson-02 ICP script, because the
  "after" state needs a session-scoped `SET` alongside the `EXPLAIN ANALYZE`).
- `GLOSSARY.md` §2b: ~26 new terms, plus four recorded non-choices.

## Terminology decision worth remembering

**`poluspoj` / `antispoj`, written solid, not `polu-spoj` / `anti-spoj`.** Checked against the
orthography norm rather than guessed: the prefixoid `polu-` is written joined to its base
(`poluvreme`, `poluostrvo`, `polufinale`, `polukrug`), with a hyphen only before a capitalised proper
noun (`polu-Nemac`). `anti-` behaves the same way. `rad.md` never used the term. The two chapter-2
learning artifacts that said `semi-spoj` in a parenthetical (`lessons/0002-*.html`,
`reference/01-*.html`) were flagged rather than silently edited, and the user asked for them to be
corrected the same day, so the workspace is consistent with no grandfathered exceptions.

## Write-up (2026-08-24)

Chapter 3 prose written with `academic-research-writer` (+ `serbian-grammar`) and appended to
`rad.md`, ~3.5 pages across six subsections (3.1 five phases, 3.2 parser/resolution and the
transformation-vs-strategy line, 3.3 cost model, 3.4 access-path choice, 3.5 join-order search,
3.6 what is deferred). Two of the four lesson figures were carried into the paper, matching the
chapter's figure budget of 2:

- **Slika 3.1**, the five-phase pipeline diagram (`...-04-pet-faza-pregled`), rasterized SVG→PNG via
  headless Edge (the SVG had no PNG twin, since it is a hand-built conceptual diagram, not a myflames
  output). Two em dashes in the SVG text were removed first, per WORKFLOW rule 8 (applies to figure
  text too).
- **Slika 3.2**, the access-path cost crossover (`...-01-ukrstanje-cena`), the worked example the
  ticket demanded.

The two join-order figures (`...-02/03-redosled-spoja-dubina-62/1`) stayed in the lesson only; the
150:1 result is carried into §3.5 as cited prose to respect the 2-figure budget. `WL#7082` added to
`references.bib` as `mysqlwl7082` (a published MySQL worklog, citable; not a lecture deck). DOCX
export verified clean.

