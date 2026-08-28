# 0004 — EXPLAIN has two shapes, not three formats, and the access-type ladder is not a cost ranking — evidence

Detail split out of `learning-records/0004-explain-formats-and-access-types.md` so the record itself stays short.
Measured numbers, produced artifacts and write-up notes for that session. Read this only when writing or checking the chapter it belongs to, not when planning a lesson.

## Live run (2026-08-24, MySQL 8.4.11, `sakila`) — every number in the lesson is measured

| what | measured |
|---|---|
| `explain_json_format_version`, default / working | `1` / `2` |
| Same plan: tabular rows vs. tree nodes | `2` / `4` |
| `rows × filtered` = `Filter` node estimate | `16500 × 33.33% = 5499` |
| `film_actor` PRIMARY, leftmost prefix vs. whole key | `key_len 2` (`ref`, 19 rows) / `key_len 4` (`const`, 1 row) |
| `payment.rental_id`, `INT` nullable | `key_len 5` |
| Costed-but-rejected index | `film`: `possible_keys=idx_fk_original_language_id`, `key=NULL`, `type=ALL` |
| Same index, one extra predicate | `filtered` 100.00 → 33.33, `Extra` `Using index` → `Using where` |
| `IN (SELECT ...)`, defaults vs. `semijoin=off` | `SIMPLE` (`ref`+`eq_ref`) / `DEPENDENT SUBQUERY` (`unique_subquery`) |
| Access types reproduced live | **12 of 12** |

## Artifacts produced

- `examples/04-explain/01-tri-formata-jedan-plan.sql`,
  `02-lestvica-tipova-pristupa.sql`, `03-kolone-i-extra.sql` — all three smoke-tested against the
  live server, no errors or warnings.
- `figures/04-explain-01-tri-formata-jedan-plan.png` (+ `.svg`), via the new
  `tools/make-lesson04-three-formats.ps1`: the same query run through all three formats and laid
  out in three panels, with the three bridging numbers coloured wherever they appear.
- `figures/04-explain-02-lestvica-tipova-pristupa.png` (+ `.svg`), via the new
  `tools/make-lesson04-access-types.ps1`: twelve live `EXPLAIN` runs rendered as a ranked ladder.
  **The script is self-verifying** — each entry declares the access type it must produce and the
  script throws if the server produces anything else, so a stale query breaks the build instead of
  silently printing a wrong figure. Worth copying that pattern in later chapters.
- `assets/lesson.css`: `table.exp` unscoped from `.try` (lesson 04 needs the same two-column table
  in the body, for `EXPLAIN`'s columns and `Extra` values); body-level variant gets a wider first
  column.
- `GLOSSARY.md` §2c: 13 new terms plus four recorded non-choices.

## Terminology decisions worth remembering

**`tip pristupa`, not `tip spoja`, for the `type` column** — even though the manual's own
documentation calls it the "join type". The value describes how one table is reached, not how two
are joined, and `tip spoja` would collide with §1's join algorithms. The manual's name is a
historical artifact; carrying it into Serbian would import a confusion the English does not force
on a careful reader.

**`pretraga po indeksu` (index lookup) is kept distinct from §1's `sken preko indeksa` (index
scan).** A lookup is one targeted probe; a scan reads a run of entries. Chapter 4 turns on exactly
that difference (`ref`/`eq_ref` against `index`/`range`), so one shared Serbian word would erase
the chapter's point.

**`filesort` stays untranslated.** Every plausible rendering (`sortiranje u fajl`) asserts
something false: MySQL sorts in memory whenever the result fits. Same class of decision as
`handler` in §2a.

