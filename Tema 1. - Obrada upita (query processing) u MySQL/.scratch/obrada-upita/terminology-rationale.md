# Terminology rationale and budget history

Split out of `GLOSSARY.md` so the glossary itself stays cheap to read every lesson. `GLOSSARY.md`
carries the **binding one-line rule** for each decision below; this file carries the reasoning behind
it. Read this only when you are tempted to change a locked term, or when the user asks why a word was
chosen.

## §2a — architecture terms

Three deliberate non-choices, recorded so they are not "fixed" later:

- **"pluggable" is not translated adjectivally.** `priključiv` / `priključni` is not well attested in
  standard Serbian for this sense, so the concept is carried by the noun phrase *modularna
  arhitektura motora* plus one explanatory clause on first use ("motor se priključuje i
  menja, a serverski sloj ostaje isti"). Do not swap in `priključivi motori` later.
- **`handler` stays in code font, untranslated.** It is a C++ class name (`sql/handler.h`), not a
  concept word — translating it would break the link to the source the chapter cites. Same rule as
  SQL keywords under the lesson-language preference in `NOTES.md`.
- **"storage engine" is not translated as `skladišni motor`, even though that is the literal
  word-for-word rendering.** `skladišni` collocates with physical storage space in standard Serbian
  (`skladišni prostor`, `skladišna hala`), not with a mechanical/software engine — the compound
  parses but reads like "warehouse engine." Same class of problem as the `pluggable` non-choice
  above: a literal per-word translation that fails the collocation test. Fixed 2026-08-24: the
  definition uses *mehanizam skladištenja (storage engine)* on first use; everywhere after that,
  including headings and titles, the short form *motor* carries the concept alone — the lesson body
  already used `motor` on its own successfully dozens of times, including with agentive verbs
  ("motor procenjuje", "motor kaže da...") that would read stiffer with `mehanizam`. Do not swap in
  `skladišni motor` later, and do not replace the short form `motor` with `mehanizam` throughout —
  only the first-use definition needed fixing.

## §2b — pipeline and optimizer terms

Four deliberate non-choices, recorded so they are not "fixed" later:

- **"poluspoj", written solid, not "semi-spoj" and not "polu-spoj".** Two separate points. (a) The
  prefix `polu-` is the standard Serbian calque of `semi-` (`poluprovodnik`, `poluprečnik`), whereas
  `semi-` is an unassimilated borrowing. (b) `polu-` is written **joined** to its base
  (`poluvreme`, `poluostrvo`, `polufinale`, `polukrug`), taking a hyphen only before a capitalised
  proper noun (`polu-Nemac`); `anti-` behaves identically, hence `antispoj`. Checked against the
  orthography rule, not guessed. `rad.md` never used the term, and the two chapter-2 learning
  artifacts that said *semi-spoj* in a parenthetical (`lessons/0002-...html`,
  `reference/01-...html`) were corrected on the user's instruction 2026-08-24, so the workspace is
  consistent with no exceptions.
- **`optimizer_trace`, `cause: "cost"` and other trace keys stay verbatim, in code font.** They are
  JSON keys the reader must recognise in real output, not concept words. Same rule as `handler` in §2a.
- **"cena" is never rendered as *trošak* or *cost*.** §1 already locked *cena*, and the whole chapter
  turns on it being one consistent word.
- **"pruning" is not translated as *orezivanje*.** *Orezivanje* collocates with plants; *odsecanje*
  is what the search actually does to a branch of the plan tree, and it reads as a search-algorithm
  term rather than a gardening one.

## §2c — EXPLAIN vocabulary

Four deliberate non-choices, recorded so they are not "fixed" later:

- **"access type" is `tip pristupa`, not `tip spoja`, even though the manual's own column
  documentation calls `type` the "join type".** The value describes how *one* table is reached, not
  how *two* tables are joined, and `tip spoja` would collide head-on with §1's join algorithms
  (*spoj sa ugnježdenom petljom* and the rest). The manual's name is a historical artifact; using it
  in Serbian would import a confusion that the English does not force on a careful reader.
- **`pretraga po indeksu` (index lookup) is a different term from §1's `sken preko indeksa`
  (index scan), and the two must not be merged.** A lookup is one targeted probe that lands on a
  key; a scan reads a run of entries. Chapter 4 turns on exactly that difference (`ref`/`eq_ref`
  against `index`/`range`), so collapsing them into one Serbian word would erase the chapter's
  point.
- **`filesort` stays untranslated, in code font.** It is the literal string MySQL prints in
  `Extra`, and every plausible translation (*sortiranje u fajl*) asserts something false: MySQL
  sorts in memory whenever the result fits and only spills to disk when it does not. Same class of
  decision as `handler` in §2a: a name, not a concept word.
- **Column names and `Extra` values stay verbatim, in code font**, and are never translated:
  `type`, `key`, `key_len`, `rows`, `filtered`, `possible_keys`, `Extra`, `Using index`,
  `Using index condition`, `Using where`, `Using temporary`, `Using filesort`. Same rule as the
  `optimizer_trace` keys in §2b: the reader has to recognise these strings in real output, so a
  translation would break the link to what the server actually prints. Serbian prose explains them,
  it does not replace them.

## §2d — EXPLAIN ANALYZE vocabulary

Five deliberate non-choices, recorded so they are not "fixed" later:

- **`actual time`, `rows`, `loops` and `(never executed)` stay verbatim, in code font**, exactly as
  §2c's rule for column names. `rows` in particular appears in **both** brackets of the same line
  and means a different thing in each; Serbian prose disambiguates by calling one *procena* and the
  other *stvarni broj torki*, never by renaming the key.
- **"ponavljanje", not *iteracija*, for one pass of a looped node.** *Iterator* is already locked in
  §2c as one node of the tree, so *iteracija* would be read as something the iterator does rather
  than as one execution of the whole subtree. *Ponavljanje* has no such collision and is what
  `loops` literally counts.
- **"korpa", not *razred*, *interval*, or *kanta*, for a histogram bucket.** *Razred* and *interval*
  are the statistics words for a class interval, and they assert something false about MySQL's
  `singleton` histograms, where a bucket holds exactly **one value**, not a range. *Korpa* is the
  established Serbian rendering of *bucket* in the hashing sense and carries no interval claim.
  The type names themselves (`singleton`, `equi-height`) stay verbatim, since they are the strings
  `COLUMN_STATISTICS` prints.
- **"optimizator opsega", not *opsežni optimizator*, for the range optimizer.** *Opsežan* means
  extensive/comprehensive, so *opsežni optimizator* says "the thorough optimizer", which is not what
  the component is. It is the part that plans a *sken opsega* (§2b), so the genitive construction is
  the one that keeps the two terms visibly related.
- **"odstupanje", not *divergencija* or *razlaženje*.** *Odstupanje* is the ordinary Serbian word for
  a measured value missing a predicted one, which is exactly the relation here. The other two are
  either a bare anglicism or suggest two things drifting apart over time, which estimates and
  measurements do not do.

## §2e — optimizer-trace vocabulary

Five deliberate non-choices, recorded so they are not "fixed" later:

- **`pristupni put` (§1) was NOT re-coined as *put pristupa*.** Lesson 0006 originally wrote
  *put pristupa* throughout, by analogy with §2c's `tip pristupa`, and it was caught and reverted
  across the lesson, the reference card, the figure script and the examples before the chapter was
  written. §1's deck-derived term wins; the near-miss is recorded because the analogy with
  `tip pristupa` is genuinely tempting and will be tempting again in chapter 5.
- **"odbačen plan" (optimizer) is kept distinct from "odbijanje" (server).** The optimizer
  *odbacuje* an alternative it costed and lost; the server *odbija* a statement it will not run and
  returns an `ERROR`. Chapter 4c uses both in the same lesson, a few paragraphs apart, so one word
  for the two would make the section unreadable.
- **"razmatran plan", not *kandidat-plan* or *predložen plan*.** The trace's own key is
  `considered_execution_plans`, and not every considered plan was ever viable: some are abandoned
  mid-way by pruning. *Kandidat* asserts a completeness the trace does not.
- **"faza traga" is not the same object as the pipeline phases of §2b, and the two must not be
  merged.** The trace has **three** phases (`join_preparation`, `join_optimization`,
  `join_execution`); the pipeline has **five**. Parsing is finished before the trace starts, and
  optimization and planning are one block in it. Any sentence implying the trace prints the five
  phases is false, and lesson 0006 had to be corrected on exactly that point.
- **`considered_execution_plans`, `cost_for_plan`, `chosen`, `cause`, `pruned_by_cost`,
  `plan_changed`, `steps` and every other trace key stay verbatim, in code font.** This is not a new
  rule, just §2b's `optimizer_trace`-keys rule applied to the keys chapter 4c actually quotes; the
  reader has to recognise them in real JSON.

## §4 — page-budget revisions

**Revision (2026-08-26, user's decision): chapter 4 raised from 4 to 6 pages**, total from ≈21 to
≈23. Chapter 4 is taught as three lessons and written as three tickets (13a/13b/13c), and 13a alone
— three output formats, twelve columns, twelve access types, the `Extra` values — came out at ~3
pages of dense, unpadded prose. The alternative was squeezing `EXPLAIN ANALYZE` and the optimizer
trace into ~1 shared page, which would have gutted the chapter's actual centrepiece
(estimated-vs-actual row divergence). The chapter is the paper's most hands-on one and the figure
centrepiece, so it gets the pages. 13b and 13c now have ~3 pages between them.

**Second revision (2026-08-28, user's decision): chapter 4 raised again from 6 to 6.6 pages**,
total from ≈23 to ≈23.6. Measured after 13a and 13b were written, the chapter had used ~5.6 of
its 6, leaving ~0.4 for a 13c budgeted at ~1. The trade was: let the chapter run ~0.6 over, or cut
13c in half and drop either the `film` / `cause: "cost"` example or `EXPLAIN FOR CONNECTION`.
Lesson 0006 (LR-0006) turned up what is arguably the chapter's strongest single finding — the bad
plan of §4.7 was never costed against anything, and `EXPLAIN`'s `0,838` is a consequence of the
swap rather than its reason — which is exactly the material a squeeze would have cost. Consistent
with the standing rule from the first revision: **do not trim written prose to make room.**

