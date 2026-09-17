# Final export, bibliography, and consistency pass

Type: task
Status: resolved
Blocked by: 12, 14, 15, 16, 17, 18, 19, 20, 21

## Question

The last ticket, now that ticket 09 has graduated the chapter tickets (14 through 21) and wired
them into this line.

When every chapter is written:
1. **Bibliography**: every entry cited at least once, every citation resolving to an entry, no dead
   links, IEEE rendering correct. Note Tema 1's finding — `dev.mysql.com` returns 403 to plain
   fetches because it blocks bots, which is not a dead link; check through a browser-shaped fetch
   before deleting anything.
2. **Terminology sweep** across every chapter against this topic's `GLOSSARY.md`. Record accepted
   divergences rather than triggering a six-file rename for a wobble no reader notices.
3. **Figures**: numbered without gaps, every one captioned, every one referenced by number in the
   text, every one with an explicit width chosen for readability. Tema 1 found eight unreferenced
   figures and three unsized ones at this stage — look for exactly that.
4. **Export** with `..\tools\make-docx.ps1` and measure the rendered page count against the soft
   ~20–25 target. If it is over, that is information, not an emergency: the map's length policy
   forbids shrinking unreadable figures to buy a page.
5. **Hand off what only the user can do**: reading the finished paper end to end (which is also
   defense preparation), setting the body's proofing language to Serbian (Latin) in Word, and pasting
   the faculty seals into the title page. Once he has hand-finished the DOCX, **the file is no longer
   reproducible from `rad.md`** — record that in `NOTES.md` and never re-run the export without
   asking, exactly as on Tema 1.
6. Commit and push.

## Resolution

All six steps done. Three real defects found and repaired; the rest of the paper passed clean.

**1. Bibliography.** 15 entries, 15 cited, **no dangling citations and no uncited entries**. The two
apparent stray `@`-tokens (`@localhost`, `@tenant_id`) are both inside backticks, so citeproc never
sees them — false positives, confirmed by inspection. Link check with a browser user-agent: five
URLs return 200; `dev.mysql.com` and `bugs.mysql.com` return **403 to `curl` but fetch fine through a
browser-shaped request**, exactly the Tema 1 finding this ticket warned about — not dead, not deleted.

**Two bibliography defects repaired:**
- **`mysqlbug41354` had a paraphrased title.** The entry read "Column Privileges not Honored for
  SELECT *"; the report's actual title, fetched from the tracker, is "Access control is bypassed when
  all columns of a view are selected by * wildcard". Corrected to the real title.
- **`nistsp80092` and `nistsp80053r5` rendered as "National Institute of Standards; Technology"** in
  the IEEE reference list — BibTeX had split "Standards and Technology" into two names on the `and`.
  Fixed by brace-protecting the institution; both now render correctly.

**2. The substantive defect — a claim tested against the wrong object.** Chasing the bug title above
exposed a genuine error in ch. 4. Bug #41354 is about column privileges on a **`SQL SECURITY DEFINER`
view**; ch. 4 tested the claim against a **base table** and reported it "not reproduced". Testing the
adjacent case is not testing the claim. Retested on the live server against the object the bug
actually names: a definer view with a single-column grant. **The bug still does not reproduce on
8.4.11** — `SELECT *` fails with `ERROR 1143` naming the first ungranted column, while the granted
column reads fine. The paragraph was rewritten to describe the bug correctly, report the view result
as the primary measurement, and keep the base-table result as a secondary case, noting *why* the
error number differs (1142 = no table-level privilege at all, so the check stops before reaching the
columns; 1143 = a column privilege exists, so the check gets that far). New script:
`examples/04-fgac-i-rls/04-bug41354-na-pogledu.sql`. The test view and account were dropped
afterwards, so the sandbox is left exactly as ticket 10 built it.

**3. Terminology sweep.** Consistent across all eight chapters. Three divergences from `GLOSSARY.md`
found, judged, and **kept** rather than triggering a six-file rename; each is recorded with its
reasoning in `NOTES.md` (fine-grained access control rendered as `fino-granularna kontrola pristupa`
rather than the deck's narrower `sigurnost na nivou polja`; `princip najmanjih privilegija` carrying
Saltzer & Schroeder's quoted wording instead of an English parenthetical; ch. 6's audit gloss in
Serbian-first order). Case-inflected forms of every locked term check out.

**4. Figures.** Clean, no repairs needed. 8 figures, numbered 2.1 / 3.1 / 3.2 / 4.1 / 4.2 / 5.1 / 6.1
/ 7.1 — **no gaps**, every one captioned, every one referenced by number in the body text, every one
carrying an explicit width. Widths track aspect ratio as ticket 12 required (the one tall figure,
3.2 at ratio 0.93, is the narrowest at 55%; the wide log extract at ratio 5.07 sits at 90%).
Per-chapter counts match `figures/README.md`'s budget **exactly**: 0/1/2/2/1/1/1/0 = 8. None of
Tema 1's failure mode (eight unreferenced, three unsized) is present here.

**5. Export.** `../tools/make-docx.ps1`, clean. **23 rendered pages, 9,824 words** — inside the
~20–25 soft target, so the length policy was never put under pressure and no figure was shrunk. All
15 references render in IEEE order, no `???` markers, no unresolved keys.

**6. Handed off** — the three Word-only steps, and the warning that the DOCX stops being reproducible
once they are done, are recorded in `NOTES.md` under "Export state". Committed and pushed.
