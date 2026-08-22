# Chapter 1. Uvod

Type: task
Status: resolved
Blocked by: 03, 08

## Question

Execution ticket - this map carries execution, so it resolves only when all four are done.

**Target length**: ~1.5 pages of `rad.md`.

**Scope**: Frame the problem: what query processing is, why the gap between a declarative SQL statement and its physical execution matters, and what the paper covers. Written early, then revisited once the conclusion exists.

**Definition of done**:
1. The user has been taught this chapter via `/mattpocock-skills:teach` (they must invoke it
   themselves) and a lesson exists in `lessons/`.
2. Runnable SQL committed to `examples/`, and at least one captioned figure in `figures/`, per the
   strategy set in ticket 09.
3. Serbian prose appended to `rad.md` **using the `academic-research-writer` skill**, with IEEE
   citations added to `references.bib` as they are used.
4. A learning record written to `learning-records/`, and the work committed.

**Grounding**: research ticket -, plus the lecture mapping from ticket 07 and the glossary
from ticket 08.

## Answer

Resolved 2026-08-22. All four Definition-of-Done items complete; Chapter 1 (Uvod) written.

1. **Taught.** Lesson `lessons/0001-uvod-the-gap-and-two-levels.html` (the gap + two levels of one
   problem, cost as the shared objective). Learning record
   `learning-records/0001-query-processing-gap-and-two-levels.md`.
2. **SQL + figure.** `examples/01-uvod/01-jedan-upit-dva-plana.sql` (one query → two plans via
   `IGNORE INDEX`); captioned figure `figures/01-uvod-01-jedan-upit-dva-plana.png` (side-by-side
   A/B comparison, generated for this chapter — over the soft "0 figures" budget guess for ch.1,
   which the strategy explicitly permits).
3. **Serbian prose in `rad.md`** via `academic-research-writer` + `serbian-grammar`. ~1.5 pages,
   impersonal *se*-voice, glossary-locked terms. Four sources added to `references.bib` and cited
   per-paragraph: the two Stoimenov decks (`03_Optimizacija`, `02_Evaluacija`), Ramakrishnan &
   Gehrke 3ed, and the MySQL 8.4 Reference Manual. Chapter closes with the one-sentence-per-chapter
   roadmap (ch. 2–9).
4. **Verified + committed.** `pandoc --citeproc` renders all four citations as IEEE [1]–[4] with a
   clean reference list, exit 0, no undefined keys.

**Note for the revisit pass:** ticket said "written early, then revisited once the conclusion
exists." The roadmap and the closing thread should be reconciled against Chapter 9 when it lands.

**Figure numbers** shown are the live `EXPLAIN ANALYZE FORMAT=JSON` costs on the figure
(≈499373 index vs ≈575645 table scan); the lesson/SQL comments quote a slightly different run
(≈513107 vs ≈580134). Prose quotes the figure's numbers so text and image agree.
