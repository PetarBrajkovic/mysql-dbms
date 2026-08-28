# Notes — Obrada upita (query processing) u MySQL-u

Subject-specific working notes. **The process is not here.** How lessons are built and which files to
read per lesson is `../TEACHING.md`; how the paper is written is `../WRITING.md`; the figure pipeline
is `../tools/FIGURES.md`. Nothing in those is restated here, and nothing here overrides them.

Session findings do not belong here either — they go into a learning record, and
`learning-records/README.md` is the index where they are looked up. **Never append a correction under
a stale claim; correct it in place.** That habit is what made an earlier version of this file
unaffordable to read (archived at `.scratch/obrada-upita/notes-archive-2026-08-28.md`).

## Subject quirks

- **`rad.md`'s front matter deliberately leaves `lang` unset**, so IEEE reference-list terms render in
  English rather than Serbian Cyrillic. Do not "fix" it to `lang: sr` without reading ticket 02.
- **Locked anglicisms from the lecture decks stay as they are** — `sken`, `heš`, `pipeline` — per
  `GLOSSARY.md`. The `serbian-grammar` skill does not know about this exception and will flag them.
- **`table.exp` in `assets/lesson.css` is not scoped to `.try`** — it is the two-column term/meaning
  table anywhere in a lesson body. That stylesheet is shared with the other topics, so a change to it
  changes their lessons too.
- **The hypergraph join optimizer is compile-gated out of the stock 8.4 build** installed here. Teach
  it as a documented fact; never plan a live demo.

## Chapter planning

- **Chapter 4 was taught as three lessons** (4a formats/types, 4b `EXPLAIN ANALYZE`, 4c
  `optimizer_trace`) and is now taught end to end. Its page budget was raised twice by the user,
  4 → 6 → 6.6, rather than squeezing 4c.
- **Chapter 5 (iterator model) is next**, and it inherits a ready-made hook: lesson 0006 established
  that the trace stops at `join_optimization` and that `join_execution` is empty, so "what actually
  runs" has now been deferred twice. Chapter 5 is where the iterators get named.
- **Chapters 1-5 are backed by the course lecture decks; chapters 6-8 have zero deck coverage** and
  rest entirely on external primary sources. Lessons for those three have to work harder to ground
  the material — see the one open gap in `RESOURCES.md`.
