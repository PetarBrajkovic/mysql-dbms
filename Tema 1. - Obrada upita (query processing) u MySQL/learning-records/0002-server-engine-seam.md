# 0002 — MySQL's architecture is a seam, and the seam is the `handler` class

**Date:** 2026-08-24
**Chapter:** 2 (Arhitektura obrade upita u MySQL-u)
**Lesson:** `lessons/0002-arhitektura-serverski-sloj-i-motor.html`
**Reference card:** `reference/01-arhitektura-serverski-sloj-i-motor.html`
**Status:** taught (lesson delivered; quiz not yet taken by the user at time of writing)

## What was taught

Chapter 2's spine, sitting directly on chapter 1's logical/physical frame:

1. **Two layers with a documented interface.** Server layer understands SQL; storage engine understands rows and pages.
2. **The membership test is falsifiable:** does the feature change if you swap the engine? Manual table 18.1 marks only replication and backup/PITR as server-implemented.
3. **The seam is a C++ class, not a metaphor.** `handler` / `handlerton`. Load-bearing sentence, verified in `sql/iterators/basic_row_iterators.cc`: executor iterators never read pages, they call handler methods.
4. **The path with real 8.4 names:** `do_command()` -> `dispatch_command()` -> `dispatch_sql_command()` -> parser -> resolver -> optimizer/planner -> executor -> `handler` -> InnoDB. `THD` carries session state.
5. **Two deliberate leaks in the abstraction**, both demonstrable live: ICP (`idx_cond_push`) and statistics (index cardinality is the engine's, column histograms the server's).

## Non-obvious insights to revisit

**(a) `mysql_parse()` no longer exists in 8.4.** It is `dispatch_sql_command()`. Verified absent from
both `sql/sql_parse.h` and `sql/sql_parse.cc` at tag `mysql-8.4.6`. Older blog posts and lecture
material still name it, so this is an easy citation error to inherit. Do not write it.

**(b) The 8.4 Reference Manual never mentions `handler`, `handlerton`, or "handler API" anywhere.**
Every handler-level claim in Chapter 2 must cite the **source tree**, not the manual. This is a real
constraint on how the chapter is written, not a stylistic preference.

**(c) There is no official MySQL 8.4 figure of the query-processing pipeline.** Figure 18.3
("MySQL Architecture with Pluggable Storage Engines",
<https://dev.mysql.com/doc/refman/8.4/en/images/mysql-architecture.png>, verified reachable) is a
layered *component* diagram only. So Chapter 2 either reuses Figure 18.3 with an IEEE citation, or
uses an original diagram. The lesson's `.arch` component is that original diagram and can be
rasterized for `figures/`.

**(d) The statistics split is the sharpest single teaching point in the chapter.** Mnemonic:
*index statistics belong to the engine; column histograms belong to the server.* Histograms exist
precisely to give selectivity for columns that are **not** indexed.

## Next

Per WORKFLOW's per-chapter loop: the user runs the three scripts in `examples/02-arhitektura/`
himself (step 2), then Chapter 2's prose is written with `academic-research-writer` (step 3),
with one figure — either Figure 18.3 reused under an IEEE citation, or the lesson's `.arch` diagram
rasterized. Chapter 3 ("Od SQL-a do plana izvršavanja") reuses the `ol.stages` component and should
zoom into stages 3–5 rather than re-introducing them.

## Evidence

Measured numbers, artifacts and write-up notes for this session: `.scratch/obrada-upita/measurements/0002-server-engine-seam.md`.
