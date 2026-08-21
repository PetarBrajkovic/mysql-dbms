# Notes

Scratchpad for working notes and user preferences that come up mid-lesson. Not polished, not
graded - `MISSION.md` and `RESOURCES.md` are the documents that matter for planning.

- Serbian terminology per term is not locked yet - that is ticket 08
  (`.scratch/obrada-upita/issues/08-terminology-and-skeleton.md`), a grilling session blocked on
  the four research tickets, all now resolved. Do it before writing chapter 3 or later, since a
  term decided there should never be re-translated in a later chapter.
- Pandoc export quirk worth remembering while writing lesson exercises: `rad.md`'s front matter
  deliberately leaves `lang` unset so IEEE reference-list terms render in English rather than
  Serbian Cyrillic (see ticket 02's answer) - don't "fix" it to `lang: sr` later without re-reading
  why.
- **For chapter 4's lesson and worked example**: ticket 01's live `EXPLAIN` runs on `wide_events`
  disproved the setup's own prediction that a skewed index (`idx_country_code`, ~70% `'US'`)
  gets rejected for a table scan. It didn't - `EXPLAIN SELECT COUNT(*) ... WHERE country_code =
  'US'` still picked `type: ref` on the index, for both the common and rare value, because
  `COUNT(*)` is a covering query the index alone can answer. Selectivity only decides the access
  path once the query needs columns the index doesn't cover. Use this as the chapter's worked
  example: run the same filter as `SELECT notes FROM wide_events WHERE country_code = 'US'` vs
  `= 'JP'` (non-covering - forces a lookup into the wide row) to show selectivity actually
  flipping the plan, then contrast it with the `COUNT(*)` case above where it didn't. Full detail
  and the exact `EXPLAIN` output already captured are in ticket 01's Answer.
