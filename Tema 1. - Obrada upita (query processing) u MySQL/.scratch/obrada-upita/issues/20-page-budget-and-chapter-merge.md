# Fit the paper to a page ceiling: measure it, then decide what gives

Type: grilling
Status: closed
Blocked by: none

## Question

Surfaced by the user on 2026-08-31, mid-session, before writing 4c: the DOCX was "already at 20
pages" with four of nine chapters written, and several chapters still to go. The user proposed
shortening the prose or removing a couple of figures.

The question the map actually had to answer: **what is the real page trajectory, and which lever
closes the gap?** The user's proposed remedy and the size of the problem had not been compared.

## Answer

### The measurement came first, and it reframed the problem

Rebuilt `rad.docx` and counted pages in Word (`ComputeStatistics(2)`) rather than trusting the
budget table. **20 pages, 5.857 words, chapters 1-4b.** Composition:

| Component | Pages |
|---|---|
| Title page | 1.0 |
| Reference list (5 entries) | ~0.5 |
| Figures + captions (36,6 in of image height, 11 figures) | ~4.5 |
| Prose + headings (~420 w/page) | ~14.0 |

Three findings the user did not have:

1. **Only ~1.5 pages are front/back matter**, not the 4-5 the user assumed. The 4.5 pages of figures
   *are* content, and `rad.md` has **zero code fences**, so every SQL statement and every `EXPLAIN`
   output in the paper exists only as a figure. Deleting figures deletes the evidence.
2. **The remedy was off by an order of magnitude.** A figure costs ~0.4 pages; the projection was
   31 pages at budget, ~34 at the observed 1,3x overrun rate. Removing four figures saves ~1.6.
3. **The page setup was never specified at all.** Neither the export nor the shared reference doc
   set `pgSz` or `pgMar`, so Word supplied its own defaults and the same file could paginate
   differently on the professor's machine. This was a latent correctness bug, found only because
   the budget forced a look at the layout.

### Decisions (grilling, two rounds)

- **Q1 — the ceiling.** "~20 strana" in `MISSION.md` treated as **soft; hard target ≤25 rendered
  pages**, title page and references included.
- **Q2 — written chapters.** Chapters 1-4 are **re-openable**; the user's own standing rule *"never
  trim written prose to make room"* is **suspended for this paper**, scoped to tightening
  redundancy, not to dropping taught material. Recorded in `GLOSSARY.md` §4; `../WRITING.md` keeps
  the rule as the course-wide default and now documents how a topic suspends it.
- **Q3 — layout.** Take the free win.
- **Q5 — structure.** **Old chapters 6, 7 and 8 merge into one**, chapter 6 *Gde MySQL ne prati
  obrazac*, with vectorization / parallelism / plan caching as §6.1-6.3; the conclusion becomes
  chapter 7. Zero content lost: the three were variations on one thesis, which is how `MISSION.md`
  phrases the success criterion in the first place. Research ticket 06 established the *claims*
  survive, never that they needed three chapters.
- **Q6 — depth of trim.** Light, concentrated on chapter 4, **keeping all 11 figures**.
- **Q7 — figures.** The ~13-figure budget goes from soft guidance to a **firm cap**: ch5 gets 2,
  ch6 gets 1, ch7 gets 0.
- **Q8 — 4c.** Keeps its full ~1 page. Chapter 4 keeps its 6.6 and was not cut.

### What actually reclaimed the pages

**20 -> 18 on layout alone, nothing removed:**
- Explicit `{width=...}` on the eight oversized figures. Worst case was Slika 2.1, rendering
  **5,21 x 5,55 in** (over half a page) purely because its source PNG is 500 px wide, so Pandoc used
  intrinsic size instead of scaling to text width.
- Paragraph spacing 10pt -> 6pt in `tools/build-reference-doc.py` (shared asset; only Tema 1 exists
  so far).

**Page setup pinned** to A4 with 2,5 cm margins in the same script. Page count unchanged, but the
export is now deterministic instead of depending on the reader's Word defaults.

**The light prose trim under-delivered, and that is worth recording.** The plan assumed ~2 pages
from chapters 1-4. A real editorial pass over chapter 4 found only ~90 words of genuine redundancy
(the clearest: §4.4 opened by restating §4.2's sentence about the `Extra` column) because the prose
is already dense. **Do not budget for a prose trim as if it were a reliable lever.** It is worth
~0,2 pages, not 2.

### Where it lands

19 pages with chapters 1-4 complete. Remaining allowance ~6 pages for chapters 5-7 against budgets
of 3 + 2,5 + 0,75, so the projection is **~25**. The margin is thin and depends on the figure cap
holding; `GLOSSARY.md` §4 says explicitly that if chapter 5 runs over 3, chapter 6 gives the page
back.

**The budget is now stated in rendered DOCX pages and must be re-measured after every chapter.**
That unit change is the durable fix: the old table's numbers were never checked against an export,
which is exactly why chapters 1-4 budgeted at 13.6 rendered at ~17 and nobody noticed until 20.
