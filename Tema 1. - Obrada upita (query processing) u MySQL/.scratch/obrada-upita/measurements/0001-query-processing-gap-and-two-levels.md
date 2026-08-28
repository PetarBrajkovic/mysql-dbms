# 0001 — Query processing is a gap crossed on two levels — evidence

Detail split out of `learning-records/0001-query-processing-gap-and-two-levels.md` so the record itself stays short.
Measured numbers, produced artifacts and write-up notes for that session. Read this only when writing or checking the chapter it belongs to, not when planning a lesson.

## Grounding / sources

Primary: Prof. Stoimenov decks 03_Optimizacija p. 2–3, 02_Evaluacija p. 2–4 (extracted verbatim via
`pdftotext`, not paraphrase). External cross-check added to `RESOURCES.md`: R&G 3ed open-access
slides, Ch. 12 "Overview of Query Evaluation".

## Live run (2026-08-22) — the demo, corrected against the real server

Ran the §4 example live. The original prediction (free choice → table scan) was **wrong** and got
corrected in the lesson:

- Free choice **keeps the index** (`Index lookup … idx_country_code`, `cost≈513107`); forbidding it
  with `IGNORE INDEX` gives the **table scan** (`cost≈580134`). The scan is *dearer* because the row
  is wide (~2.1 GB table), so the index wins even at 70% selectivity. Clean "one statement, two plans,
  different cost, optimizer keeps the cheaper" — just with the index as winner, not loser.
- Estimate story (the Chapter-4 seed): **no histogram** on `country_code`; index **Cardinality = 14**
  ⇒ flat estimate 5M/14 ≈ **350,656** (used by `FORCE INDEX` and the scan's filter node); free plan
  estimates **2.45M** via **index dive**; **actual = 3.5M** (`EXPLAIN ANALYZE`). Estimates are
  approximate and disagree most on a skewed column — exactly Chapter 4's diagnostic.
- The §4 demo was switched from `FORCE INDEX` to `IGNORE INDEX` (the former just re-picks the same
  index with a skew-blind estimate — confusing; the latter reveals the genuine alternative plan).
- Insight worth carrying: this **contradicts** ticket 01 / `NOTES.md`, which predicted the
  non-covering `'US'` filter would flip to a scan. It doesn't. Correction filed in `NOTES.md`;
  ticket 01's Answer still needs updating.

