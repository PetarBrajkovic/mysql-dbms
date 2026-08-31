# Chapter 7. Zakljucak

Type: task
Status: closed
Blocked by: 21

**Renumbered 9 -> 7 on 2026-08-31** when old chapters 6/7/8 merged into chapter 6; blocker moved from
ticket 17 to [ticket 21](21-gde-mysql-ne-prati-obrazac.md). **Target length cut to ~0.75 rendered
pages** under the ≤25-page target (`GLOSSARY.md` §4), and it gets **no figure**.

## Question

Execution ticket. ~1 page. Synthesise rather than summarise: what MySQL's choices around
row-at-a-time iteration, limited parallelism and absent plan caching add up to, where that design
serves it well, and where modern analytical systems have moved past it.

Also the moment to **revisit chapter 1**, which was written before any of this existed, so that the
introduction promises what the paper actually delivered.

Written with the `academic-research-writer` skill, in Serbian.

**Budget, as measured on 2026-08-31 after chapter 6:** the paper is at **exactly 25 rendered pages**,
which is the hard ceiling, and this chapter is not written yet. Figure widths were already cut
5.0in -> 4.3in to reclaim the page chapter 6 overran by, and a further shrink buys nothing. So the
first thing this ticket needs is a decision: **raise the ceiling by ~1 page, or reclaim ~1 page from
chapters 1-4** under the trim suspension in `../../../GLOSSARY.md` section 4, which licenses cutting
redundancy but never taught material, figures or citations. The chapter 1 revisit this ticket already
calls for is the natural place to look for some of it.

## Answer

Chapter 7 written and closed, ~440 words, no subsections and no figure, at the firm ch7 figure cap
of 0. It **synthesises rather than summarises**, in five moves: the thread from chapter 1 restated
as the mechanism the paper actually built (two layers with a `handler` seam, five phases and one
cost line, estimate beside measurement, the iterator tree); then the chapter's real payload, that
**chapter 6's three negative claims are one decision seen from three sides**, derived rather than
listed (`Read()` returns at most one row, so no vectorization; the predicate is decided above the
seam, so rows cross it one at a time and parallelism stops at the first `WHERE`; optimization runs
per execution against the actual parameter, so there is no plan to keep); the trade-off stated in
both directions (first-row latency, small memory, a plan fitted to the actual parameter, cores left
to other connections, all of which suit OLTP, against ~20 ns per row per predicate that has no
batch to amortize over on the analytic end); where the others went (vectorized executors,
PostgreSQL's `Gather`, Oracle's shared pool), with the point that **none of them started somewhere
else**, since the model MySQL keeps *is* Volcano and vectorized executors change it in exactly one
place; and a closing methodological note, that `EXPLAIN` becomes a diagnosis only beside a
measurement and that 2,9x against 1,01x is why a negative claim needs its conditions. **No new
citations**: all seven keys it uses were already in `references.bib`.

### The chapter 1 revisit the ticket asked for

Done, and it found two roadmap bullets that promised something the paper did not deliver, both
written before their chapters existed. Chapter 2's bullet listed the components (*parser,
optimizator, izvršni mehanizam i katalog*) when chapter 2 is actually about **two layers and a
documented seam**; chapter 3's bullet promised *preformulacija relacione algebre* as the spine when
chapter 3's spine is **five phases and the cost line**, with transformations living inside
resolution. Both rewritten to what was delivered. Chapter 6's bullet, three sentences describing
three chapters that are now three subsections, collapsed into one that names the framing the
chapter actually has (each negative claim taken to its boundary), and chapter 7's bullet now says
what this chapter does. Net effect on length is a small saving, which is a side effect, not the
reason.

### Also fixed, found by the ticket-19 checks run in the same session

- **Eight figures were never referenced by number in the body** (4.1, 4.3, 4.4, 4.5, 4.6, 5.1, 5.2,
  6.1). Added as short parentheticals, `(Slika N.N)`, on the sentence each figure illustrates, so
  all 15 figures are now cross-referenced.
- **Three figures had no `{width=...}`** (Slika 1.1, 2.2, 2.3) and so rendered at whatever width
  Word chose, which is the exact bug `../../../WRITING.md` warns about. All now explicit; every
  figure in the paper is sized.
- A **UTF-8 BOM** got written into `rad.md` by a PowerShell `Set-Content -Encoding utf8` during the
  page-count work, and was stripped. Pandoc tolerates it, but it would break the YAML block on a
  stricter tool. Edit `rad.md` with Python or the editor tools, not `Set-Content`.

### The budget decision this ticket was blocking on: still the user's, and the ground has moved

**Measured: 26 rendered pages** against the hard ≤25 (`GLOSSARY.md` §4). Chapter 7 was budgeted at
0.75 and lands at ~1.1, but that is not what the extra page is: the paper was **already at exactly
25 with chapter 7 unwritten**, so any conclusion at all puts it at 26. The two options the ticket
named are therefore still the two options, and only one of them is cheap.

What was measured on the way, so it is not re-tried:

- Chapter 7 was drafted at 593 words and tightened twice, to 485 then 444, with nothing dropped
  that was not redundant. Each round moved the export by roughly the lines it removed, because
  **there is no figure between chapter 7 and the reference list**, so text cut there moves the
  bibliography directly. That is the only place in the paper where a small trim is predictable.
- Everywhere else, trims get **absorbed by figure quantization**: shrinking Slika 2.1 from 3.6in to
  3.0in (46 pt) changed the page count by **zero**, and so did reverting it. A saving upstream only
  pays if it lets a whole figure move across a page boundary.
- The reference list is **0.85 of a page** and its last entry is what tips 26 into 27; it sat on
  page 27 alone until ~25 words came out of chapter 7. It cannot be cut (rule 5 of `WRITING.md`).
- Reaching **25 needs ~660 pt, about 0.94 of a page, in one contiguous saving**. Nothing content-
  neutral is left: layout was taken in ticket 20 (20 -> 18), figure widths bottomed out at 4.3in
  there, and the redundancy-only prose trim has now under-delivered three times. At this point 25
  costs either **a figure** (~0.4 pages each, and every SQL statement in the paper is a figure) or
  **~600 words of taught prose**, neither of which the suspension in `GLOSSARY.md` §4 licenses.

**Recommendation: raise the ceiling to 26.** `MISSION.md` asks for *~20 strana* and ≤25 was the
map's own instrument for stopping drift, not a faculty rule; the document is a title page, 24 pages
of chapters, and a bibliography. Trading a figure or a taught paragraph for one page is a worse
paper. The alternative, if the user wants 25 exactly, is to drop one figure, and the cheapest one
is **Slika 2.3** (the ICP-off half of a pair whose point survives in 2.2 plus the prose).


### Resolved the same day, and not the way this ticket recommended

The user raised the ceiling, and then said the thing that actually settled it: *"the pictures are
way too small now, not readable."* Correct, and it is what ticket 20's page cost. The 5.0in -> 4.3in
cap sized every figure to what the **page count** wanted, in a paper whose figures are its evidence.
Refixed by sizing each figure by how much page height its aspect ratio makes it cost (table in
`GLOSSARY.md` section 4), which took total image height 35.8in -> 45.3in for **one page**. The paper
is finished at **27 pages** and the ceiling is retired. Slika 2.3 was not dropped; nothing was.
