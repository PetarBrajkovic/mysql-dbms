# How the paper is written in this course

Shared by every topic. Read this when writing chapter prose. The topic's `GLOSSARY.md` holds the
terminology and chapter skeleton that this file's rules are applied to.

---

## Rules that do not bend

1. **The paper is written with the `academic-research-writer` skill.** Every time. Not hand-written
   and tidied up afterwards.
2. **Serbian prose, written as you go.** Never draft in English intending to translate later.
3. **Every term follows the topic's `GLOSSARY.md`.** Never re-translate a term already in there, and
   never invent a new one without adding it first.
4. **Every substantive chapter needs at least one figure**, per `tools/FIGURES.md` and the topic's
   own `figures/README.md`. Most figures are generated from live output with the script behind them
   committed to `examples/`; a purely conceptual figure may instead be a reused official diagram
   (cited) or an original one — never a stock generic image passed off as either.
5. **Citations go into `references.bib` as you use them**, never retrofitted at the end.
6. **Never invent a citation.** Leaving a claim uncited is fine; a fabricated reference is not.
   **Fetch a page before quoting it**, every time — this applies to `.slide` quotation blocks in
   lessons exactly as it applies to the paper.
7. **Never cite the university-provided lecture decks or PDFs** (`Predavanja/`, the Stoimenov SUBP
   slides). They are for *learning* only. When a claim comes from a deck, cite its published origin
   instead — Ramakrishnan & Gehrke for general database theory, the vendor's own manual for anything
   product-specific. Slide numbers help you *find* the passage to cite; they never enter
   `references.bib`.
8. **Never use the em dash (—)** anywhere in the paper or its figures. Use a comma, colon, or
   parentheses, or restructure the sentence. Applies to `rad.md` and to figure text.

## Voice and citation density

- **Voice**: impersonal *se*-construction throughout ("posmatra se", "analizira se", "prikazuje se").
  Not first person plural ("mi pokazujemo") — the plural of modesty reads oddly for a single-author
  seminar paper, and impersonal *se* is the more conservative default for Serbian faculty
  submissions.
- **Citation density**: cite at the end of any paragraph making a factual or technical claim
  (per-paragraph, not per-section). A paragraph with no factual claim — a transition, or a worked
  example already covered by an earlier citation — does not need one bolted on just to have one. Err
  toward citing when in doubt: these papers lean on primary sources for claims that are easy to get
  subtly wrong.

## Numbers in prose

Measured values drift between runs, and a figure rebuild re-measures everything it prints.

- **Quote ratios, not absolute numbers**, wherever the argument allows it. An absolute cost or timing
  needs the conditions it was measured under attached.
- **Prefer rounded values in prose** so the next rebuild does not desync a sentence.
- **After any figure rebuild, grep `rad.md` for the absolute numbers that figure prints.**

## Page budgets

Each topic's `GLOSSARY.md` carries its chapter skeleton and a per-chapter page budget. Two standing
rules, both the user's own decisions:

- **Never trim written prose to make room.** If a chapter outgrows its budget, raise the budget.
- **Do not trim pre-emptively.** A chapter's real length is only known once it is written; a few
  pages over the nominal total is not a problem.

Both are defaults, and a topic may **suspend the first one** if it hits a real page ceiling. Record
the suspension in that topic's `GLOSSARY.md` §4, with the date and what it does and does not
license; do not silently override the rule here. Tema 1 suspended it on 2026-08-31.

**State the budget in rendered DOCX pages, and re-measure after every chapter.** A budget in any
other unit drifts unnoticed: Tema 1's chapters 1-4 were budgeted at 13.6 and rendered at ~17 before
anyone counted. Export with `..\tools\make-docx.ps1` and read the page count in Word.

**Size figures explicitly.** An image with no `{width=...}` renders at its intrinsic pixel size, so a
low-resolution PNG can eat half a page for no reason (Tema 1's 500 px architecture diagram rendered
5.2 x 5.6 in). Capping the tall figures and tightening paragraph spacing reclaimed two full pages
there with nothing removed, which is the first lever to reach for.

**But size them by aspect ratio, not by one number.** Tema 1 capped every figure at one width to buy
a page and made them all unreadable; the fix was to choose width per figure by how much page height
its ratio makes it cost. A wide, short figure (a flame graph, `FORMAT=TREE` output) can go to nearly
the full text width for almost no height, and that is exactly where the unreadably small type is; a
figure taller than it is wide converts width straight into pages. Tema 1's table is in its
`GLOSSARY.md` §4. Enlarging a low-resolution source blurs rather than clarifies, so leave those
small. **A page reclaimed by shrinking a figure the reader then cannot read is not a page
reclaimed.**

## Export

```powershell
# from inside the topic folder
..\tools\make-docx.ps1
```

Always this script, never `pandoc rad.md ...` by hand: the title page lives in `naslovna.md` and must
be prepended, and the script also suppresses `rad.md`'s own YAML title block so a second
pandoc-generated title does not land on top of the custom one. It pulls the shared `ieee.csl` and
`assets/reference-paper.docx` from the course level and everything else from the topic folder.

Two quirks worth not "fixing":

- **`rad.md`'s front matter deliberately leaves `lang` unset**, so IEEE reference-list terms render in
  English rather than Serbian Cyrillic. Setting `lang: sr` forces the bibliography into Cyrillic.
- **Figure captions are numbered by hand** in the caption text (`Slika N.N: ...`); pandoc does not
  auto-number them in the DOCX export.

After opening in Word: set the body's proofing language to Serbian (Latin) once, so the spell-checker
stops flagging every word. The English reference list is correct as it stands.

**Do the Word hand-finish last, and only once.** The seals, the table of contents and the proofing
language live in the `.docx`, not in `rad.md`, so from that point on the document is **no longer
reproducible from the source**: re-running the export overwrites it and throws all of that away.
Finish the prose first, export, then hand-finish. If a chapter has to change afterwards, expect to
redo the hand-finish, and commit the hand-finished file so the work is not lost to one stray export.

To change the Word styling itself, edit and re-run `tools/build-reference-doc.py`, which rebuilds the
shared `assets/reference-paper.docx`. That file is shared, so a change there affects all three papers.
