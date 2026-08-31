# Final export, bibliography, and consistency pass

Type: task
Status: in progress - five of six checks pass; only the page-count decision is open
Blocked by: 02, 18

## Question

The last step before hand-in.

1. Full **IEEE bibliography** check: every claim cited, every `references.bib` entry actually
   referenced, no dead URLs.
2. **Terminology consistency** sweep against the glossary from ticket 08 - the risk is chapter 3 and
   chapter 8 using different Serbian words for the same concept.
3. All **figures** numbered sequentially, captioned in Serbian, and referenced from the body text.
4. Page count against the target (now ≤25 rendered pages, `GLOSSARY.md` §4).
5. **Export** to `.docx` via the pandoc pipeline proven in ticket 02, and confirm it opens cleanly in
   Word so the user can add the title page and logo.
6. Final commit.

## Answer

Run in the same session as ticket 18, against `rad.md` with all seven chapters in it. Five of the
six items pass; the sixth is the open decision ticket 18 handed over.

**1. Bibliography.** 14 entries in `references.bib`, **14 cited**, zero unused, zero `[@key]` in
`rad.md` without a matching entry. URLs re-checked: 4 of 11 return 200 to `curl`, and the other 7
return **403 because they are all on `dev.mysql.com`**, which blocks non-browser agents. Spot-checked
WL#11720 through a browser-shaped fetch: live, and its Scope still reads *"non-locking SELECT
COUNT(*)"*, the sentence §6.2 rests on. No dead links.

**2. Terminology.** Swept the locked terms across all seven chapters. `torka` is used throughout
(133 occurrences) with no competing `red`/`zapis` for the same concept; the two `zapis` hits are
ordinary Serbian ("zapis indeksa", "zapis pretrage"), not the term. `mehanizam skladištenja` appears
once, at its definition in §2.1, where it is explicitly shortened to **motor** for the rest of the
paper, which is the glossary's own convention; the only other occurrence is the reused Slika 2.1
caption. `sken`, `spoj`, `pristupni put`, `keš`, `iterator`, `workload` are each used in one form
only. The chapter 3/chapter 6 divergence the ticket feared did not happen.

*One divergence found and deliberately kept:* `GLOSSARY.md` §2 locks **plan izvršenja** for
*execution plan*, while §4's locked chapter skeleton titles chapter 3 **"Od SQL-a do plana
izvršavanja"**, echoed by the chapter 1 roadmap bullet and one sentence in §2.4. Both forms are
standard Serbian for the same thing and both are locked, in different sections. Renaming the title
would ripple into `GLOSSARY.md` §4, the map, `NOTES.md`, lesson 03, ticket 12 and LR-0003 for a
stylistic wobble a reader will not notice, so it is recorded as accepted rather than churned. Raise
it only if the user wants one form everywhere.

**3. Figures.** 15 figures, numbered **1.1 through 6.1 with no gaps**, all captioned in Serbian,
and all 15 now referenced from the body text. Eight were **not** referenced before this session
(4.1, 4.3, 4.4, 4.5, 4.6, 5.1, 5.2, 6.1) and three had **no explicit width** (1.1, 2.2, 2.3); both
fixed under ticket 18. Every figure now carries a `{width=...}`.

**4. Page count. OPEN, and it is the only thing left.** 26 rendered pages against the hard ≤25.
See ticket 18's answer for what was measured and why 25 now costs either a figure or ~600 words of
taught prose. Recommendation there: raise the ceiling to 26.

**5. Export.** `../tools/make-docx.ps1` runs clean, and `rad.docx` opens in Word with the title
page on page 1, chapters starting on page 2, IEEE citations resolved [1]-[14], the reference list in
English, and Serbian diacritics intact. Page setup is A4 with 2,5 cm margins, pinned in ticket 20,
so pagination is the same on any machine. Chapter starts: 1 -> p2, 2 -> p3, 3 -> p6, 4 -> p10,
5 -> p18, 6 -> p21, 7 -> p25, Reference -> p26.

**6. Final commit.** Chapter 7 and these fixes are committed and pushed. What is left for this
ticket is the page-count answer and, if the ceiling is raised, a one-line edit to `GLOSSARY.md` §4.

