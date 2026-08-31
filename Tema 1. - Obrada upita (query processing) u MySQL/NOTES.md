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
  `optimizer_trace`) and is now written end to end, §4.1-4.9. Its page budget was raised twice by
  the user, 4 → 6 → 6.6, rather than squeezing 4c, and it kept that 6.6 through the page-ceiling
  revision.
- **The paper is now seven chapters, not nine.** Old chapters 6, 7 and 8 merged into one, chapter 6
  (*Gde MySQL ne prati obrazac*), with the three as subsections 6.1-6.3; the conclusion is now
  chapter 7. Decided 2026-08-31 under a hard ≤25 rendered-page target. See `GLOSSARY.md` §4, which
  now also carries a **firm** figure cap and a measured page checkpoint.
- **Chapter 5 (iterator model) is taught and written**, §5.1-5.5, with its 2 figures.
- **Chapter 6 is taught and written**, §6.1-6.3, with its one figure. It has zero lecture-deck
  coverage, so every claim in it rests on a primary source or on this session's own measurements.
- **All seven chapters are written and the paper is finished**, at **27 rendered pages**. Chapter 7
  (Zaključak) needed no lesson, per `../WORKFLOW.md`, and carries no figure. The ≤25 ceiling is
  **retired** (`GLOSSARY.md` §4): the user raised it and then found the figures unreadable, so
  figure width is now chosen per figure by aspect ratio and is not a lever to shrink again.
- **`SELECT COUNT(*)` never reads the clustered index** (every index is covering for it), so any
  parallel-read example in this topic needs `FORCE INDEX(PRIMARY)` or it measures the wrong plan.
  This bit once and is worth keeping in front of mind; the measured detail is in LR-0008.
- **Edit `rad.md` with Python or the editor tools, never PowerShell `Set-Content -Encoding utf8`** —
  it writes a UTF-8 BOM into the file. Pandoc tolerates it; a stricter tool would read the YAML
  block as body text. Bit once on 2026-08-31 and was stripped.
