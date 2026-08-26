# Glossary and skeleton — binding on every chapter

Label: `wayfinder:issue-08-answer` (mirrors `.scratch/obrada-upita/issues/08-terminology-and-skeleton.md`)

This file is what `academic-research-writer` is held to on every chapter, from ticket 10 onward. It
exists so a term is decided once and never re-translated later — see `WORKFLOW.md` rule set. Do not
deviate from a term below without updating this file first and noting why.

---

## 1. Terminology — deck-derived (locked, use as-is)

These come directly from Prof. Stoimenov's SUBP lecture decks (research ticket 07,
`.scratch/obrada-upita/research/07-lecture-decks.md` §1) and back chapters 1–5. Serbian only — no
English needed in parentheses, since these are the professor's own course vocabulary and traceable to
specific slides. (Note, policy set 2026-08-22: the decks anchor the *terminology* and the learning,
but are **never cited** in the paper — see WORKFLOW.md rule 7. Slide numbers help locate the
Ramakrishnan & Gehrke passage to cite; they don't go into `references.bib`.)

| Concept | Serbian term |
|---|---|
| Execution plan | plan izvršenja |
| Query optimizer | optimizator upita |
| Cost (of operations) | cena |
| Selectivity | selektivnost |
| Access path | pristupni put |
| Index scan | sken preko indeksa |
| Table scan / File scan | sken tabele / sken fajla |
| Nested Loop Join | spoj sa ugnježdenom petljom |
| Simple Nested Loops Join | jednostavni spoj ugnježdenim petljama |
| Index Nested Loops Join | spoj sa ugnježdenom petljom korišćenjem indeksa |
| Block Nested Loops Join | spoj blokova sa ugnježdenim petljama |
| Sort-Merge Join | Sort-Merge spoj |
| Hash Join | Hash spoj / heširanje za spoj |
| Relation | relacija |
| Operator | operator |
| Tuple / Row | torka |
| Attribute / Column | atribut / kolona |
| Index | indeks |
| B+ tree | B+ stablo |
| Hash index | Hash indeks |
| Clustered index | klasterovani indeks |
| Non-clustered index | neklasterovani indeks |
| Search key | ključ traženja |
| Data entry | data entry |
| Reduction factor | faktor redukcije (RF) |
| Cardinality | kardinalnost |
| Query block | blok upita |
| Pipeline / Pipelined evaluation | pipeline / pipelined evaluacija |
| Materialization | materijalizacija |
| Left-deep tree | left-deep stablo |
| Join order | redosled spoja |
| Physical design | fizičko projektovanje |
| Tuning | tuning |
| Workload | workload |

## 2. Terminology — no deck precedent (locked, new coinage)

These are post-2016 / MySQL-specific and the decks are silent on them (research ticket 06 and 07 both
confirm the gap for chapters 6–8). One consistent pattern across all six: **Serbian term, with the
English original in parentheses on first use only, Serbian-only after that.** Chosen over a mixed
per-term rule because it is mechanically easy for `academic-research-writer` to enforce.

| Concept | Serbian term (first use) | After first use |
|---|---|---|
| Iterator model | model iteratora *(iterator model)* | model iteratora |
| Plan cache | keš plana *(plan cache)* | keš plana |
| Vectorized execution | vektorizovano izvršavanje | vektorizovano izvršavanje |
| Parallel query execution | paralelno izvršavanje upita | paralelno izvršavanje upita |
| Prepared statement | pripremljena naredba *(prepared statement)* | pripremljena naredba |
| Cost-based optimizer | optimizator upita zasnovan na ceni *(cost-based optimizer)* | optimizator (or optimizator upita, per §1) |

Note: *vectorized execution* and *parallel query execution* need no English gloss since they're
already the exact chapter titles in `rad.md` (chapters 6 and 7) — introducing English there would be
redundant, not clarifying.

### 2a. Architecture terms (locked 2026-08-24, chapter 2)

Added while teaching chapter 2 (lesson `0002`). Same pattern as §2: Serbian term, English original in
parentheses on first use only. The decks describe a generic DBMS architecture (Parser, Optimizator,
Evaluator plana, Katalog — 03_Optimizacija p. 3) but have **no** vocabulary for MySQL's
server/engine split, so these are new coinage.

| Concept | Serbian term (first use) | After first use |
|---|---|---|
| Storage engine | mehanizam skladištenja *(storage engine)* | motor |
| Server layer | serverski sloj | serverski sloj |
| Storage engine layer | sloj mehanizma skladištenja | sloj motora |
| Pluggable storage engine architecture | modularna arhitektura motora *(pluggable storage engine architecture)* | modularna arhitektura motora |
| Handler API | `handler` API | `handler` API |
| Connection | konekcija | konekcija |
| Session | sesija | sesija |
| Thread | nit | nit |
| Thread-per-connection | jedna nit po konekciji | jedna nit po konekciji |
| Buffer pool | bafer pul *(buffer pool)* | bafer pul |
| Tablespace | tabelarni prostor *(tablespace)* | tabelarni prostor |
| Data dictionary | rečnik podataka *(data dictionary)* | rečnik podataka |
| Index Condition Pushdown | spuštanje uslova u indeks *(index condition pushdown, ICP)* | spuštanje uslova u indeks (ICP) |
| Histogram | histogram | histogram |
| Row-level locking | zaključavanje na nivou torke | zaključavanje na nivou torke |
| MVCC | MVCC *(viševerzijska kontrola konkurentnosti)* | MVCC |

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

### 2b. Pipeline and optimizer terms (locked 2026-08-24, chapter 3)

Added while teaching chapter 3 (lesson `0003`). Same pattern as §2: Serbian term, English original in
parentheses on first use only. The decks name the generic components (Parser, Optimizator, Evaluator
plana) but have **no** vocabulary for MySQL's phase boundaries, its cost model tables, or its
join-order search, so most of these are new coinage.

| Concept | Serbian term (first use) | After first use |
|---|---|---|
| Parse tree / AST | stablo raščlanjivanja *(parse tree, AST)* | stablo raščlanjivanja |
| Resolution / preparation phase | razrešavanje *(resolution)* | razrešavanje (or: priprema) |
| Resolver (the component) | resolver | resolver |
| Planner (the component) | planer | planer |
| Executor (the component) | izvršilac | izvršilac |
| Query transformation | transformacija upita | transformacija |
| Permanent transformation | trajna transformacija | trajna transformacija |
| Semijoin | poluspoj *(semijoin)* | poluspoj |
| Antijoin | antispoj *(antijoin)* | antispoj |
| Decorrelation | dekorelacija *(decorrelation)* | dekorelacija |
| Derived table | izvedena tabela | izvedena tabela |
| Subquery | podupit | podupit |
| Equality propagation | propagacija jednakosti | propagacija jednakosti |
| Optimizer trace | trag optimizatora *(optimizer trace)* | trag optimizatora |
| Cost model | model cene *(cost model)* | model cene |
| Cost constant | konstanta cene | konstanta cene |
| Join-order search | pretraga redosleda spoja | pretraga redosleda spoja |
| Search depth | dubina pretrage | dubina pretrage |
| Plan pruning | odsecanje planova *(pruning)* | odsecanje |
| Greedy search | pohlepna pretraga *(greedy search)* | pohlepna pretraga |
| Exhaustive search | iscrpna pretraga *(exhaustive search)* | iscrpna pretraga |
| Partial plan | delimični plan | delimični plan |
| Range scan | sken opsega | sken opsega |
| Index dive | zaron u indeks *(index dive)* | zaron u indeks |
| Hypergraph join optimizer | hipergrafski optimizator spoja *(hypergraph join optimizer)* | hipergrafski optimizator |

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

### 2c. EXPLAIN vocabulary (locked 2026-08-24, chapter 4)

Added while teaching chapter 4, first lesson (lesson `0004`). Same pattern as §2: Serbian term,
English original in parentheses on first use only. The decks have *pristupni put* and *sken preko
indeksa* (§1), but nothing for `EXPLAIN`'s own output vocabulary, so the rest is new coinage.

| Concept | Serbian term (first use) | After first use |
|---|---|---|
| Access type (the `type` column) | tip pristupa *(access type)* | tip pristupa |
| Output format (of `EXPLAIN`) | format ispisa | format ispisa |
| Tabular / traditional format | tabelarni format | tabelarni format |
| Covering index | pokrivajući indeks *(covering index)* | pokrivajući indeks |
| Index lookup | pretraga po indeksu *(index lookup)* | pretraga po indeksu |
| Index merge | spajanje indeksa *(index merge)* | spajanje indeksa |
| Key length | dužina ključa (`key_len`) | dužina ključa |
| Leftmost prefix (of a key) | levi prefiks ključa | levi prefiks |
| Row estimate | procena broja torki | procena broja torki |
| Temporary table | privremena tabela | privremena tabela |
| Join buffer | bafer spoja *(join buffer)* | bafer spoja |
| Full-text index | `FULLTEXT` indeks | `FULLTEXT` indeks |
| Iterator (one node of the tree) | iterator | iterator |

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

## 3. Hard constraint — plan cache vs. parse-tree cache (chapter 8)

Research ticket 06 confirms, does not contradict, the assumption in ticket 17: MySQL has **no shared
execution plan cache** across sessions (Oracle-style), and the query cache was removed in 8.0. But
prepared statements **do** cache something — the parsed statement structure (parse tree, column
resolution, symbol table) — per session only, discarded when the session ends. Chapter 8 must state
this as its central move, explicitly distinguishing *keš plana* (which MySQL does not have, shared)
from the per-session parse-tree/statement cache (which it does have). Never write "MySQL doesn't
cache anything" — that's false and the whole point of the chapter is the more precise claim.

## 4. Chapter skeleton — top-level (locked)

Locked at the top level only (chapter list, order, page budget). Subheadings are deliberately **not**
locked here — they're a guess for chapters not yet researched-and-taught (especially 6–8), and this
ticket exists precisely so nothing gets fixed before it's known. Each chapter ticket's own
`academic-research-writer` pass produces subheadings naturally from the material at write time.

| # | Chapter | Page budget |
|---|---|---|
| 1 | Uvod | 1.5 |
| 2 | Arhitektura obrade upita u MySQL-u | 2 |
| 3 | Od SQL-a do plana izvršavanja | 3.5 |
| 4 | EXPLAIN i EXPLAIN ANALYZE | 6 |
| 5 | Iterator model i pipeline operatora | 3 |
| 6 | Vektorizovano izvršavanje | 2 |
| 7 | Paralelno izvršavanje upita | 2 |
| 8 | Keširanje i ponovna upotreba planova | 2 |
| 9 | Zaključak | 1 |

Total ≈ 23 pages against the map's nominal "~20 pages" — accepted; a few pages over is not a problem.
Do not trim pre-emptively; a chapter's real length is only known once it's written.

**Revision (2026-08-26, user's decision): chapter 4 raised from 4 to 6 pages**, total from ≈21 to
≈23. Chapter 4 is taught as three lessons and written as three tickets (13a/13b/13c), and 13a alone
— three output formats, twelve columns, twelve access types, the `Extra` values — came out at ~3
pages of dense, unpadded prose. The alternative was squeezing `EXPLAIN ANALYZE` and the optimizer
trace into ~1 shared page, which would have gutted the chapter's actual centrepiece
(estimated-vs-actual row divergence). The chapter is the paper's most hands-on one and the figure
centrepiece, so it gets the pages. 13b and 13c now have ~3 pages between them.

## 5. Voice and citation density

- **Voice**: impersonal *se*-construction throughout ("posmatra se", "analizira se", "prikazuje se").
  Not first person plural ("mi pokazujemo") — the plural of modesty reads oddly for a single-author
  seminar paper, and impersonal *se* is the more conservative default for Serbian faculty submissions.
- **Citation density**: cite at the end of any paragraph that makes a factual or technical claim
  (per-paragraph, not per-section) — but a paragraph with no factual claim (e.g. a transition sentence
  or a worked-example walkthrough already covered by an earlier citation) does not need one bolted on
  just to have one. Err toward citing when in doubt; this paper leans on primary sources (MySQL docs,
  worklogs) for claims that are easy to get subtly wrong — see §3 above for the sharpest example.

---

Decided in a grilling session, 2026-08-21. Resolves
`.scratch/obrada-upita/issues/08-terminology-and-skeleton.md`.
