# Final export, bibliography, and consistency pass

Type: task
Status: closed
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

**4. Page count. Answered, and the answer reframed the question.** The measurement was 26 against
the hard ≤25, and the recommendation was to raise the ceiling to 26. The user did raise it, and then
said the thing that actually settled it: *"the pictures are way too small now, not readable."* They
were right, and it exposes what ticket 20's win cost. The 5.0in -> 4.3in cap reclaimed a page by
making every figure the width the **page count** wanted, and this paper's figures are its evidence:
`rad.md` has zero code fences, so every SQL statement, every `EXPLAIN` output and every flame graph
is a figure. A page bought by making the evidence unreadable is not a page bought.

Refixed by sizing each figure by **how much page height its aspect ratio makes it cost**, rather
than by one number for all fifteen (table in `GLOSSARY.md` §4): under 0.45 goes to 6.2in, near the
6.3in text width, since a wide short figure gains the most legibility for almost no height and is
where the small type was; 0.45-0.70 goes to 5.5in; 0.70 and above to 5.0in; and Slika 2.1 stays at
4.0in because its source is 500 px and enlarging it blurs. **Total image height 35.8in -> 45.3in
for one page**, and the paper stands at **27**. The ≤25 ceiling is retired in `GLOSSARY.md` §4; it
did its job, catching a 31-35 page trajectory, and is not a live constraint any more.

Final composition: title page 1, chapters 24, reference list ~0.85. Chapter starts: 1 -> p2,
2 -> p3, 3 -> p6, 4 -> p10, 5 -> p19, 6 -> p22, 7 -> p26, Reference -> p26.

**5. Export.** `../tools/make-docx.ps1` runs clean, and `rad.docx` opens in Word with the title
page on page 1, chapters starting on page 2, IEEE citations resolved [1]-[14], the reference list in
English, and Serbian diacritics intact. Page setup is A4 with 2,5 cm margins, pinned in ticket 20,
so pagination is the same on any machine.

**6. Final commit.** Committed and pushed in two commits: chapter 7 with these checks, then the
figure resize with the ceiling retired. **The paper is finished.** What remains is the user's own
read-through, and in Word: set the body's proofing language to Serbian (Latin), and paste the
faculty seals into the band at the top of the title page.
