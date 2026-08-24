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
| Storage engine | skladišni motor *(storage engine)* | skladišni motor (or just motor) |
| Server layer | serverski sloj | serverski sloj |
| Storage engine layer | sloj skladišnog motora | sloj motora |
| Pluggable storage engine architecture | modularna arhitektura skladišnih motora *(pluggable storage engine architecture)* | modularna arhitektura skladišnih motora |
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

Two deliberate non-choices, recorded so they are not "fixed" later:

- **"pluggable" is not translated adjectivally.** `priključiv` / `priključni` is not well attested in
  standard Serbian for this sense, so the concept is carried by the noun phrase *modularna
  arhitektura skladišnih motora* plus one explanatory clause on first use ("motor se priključuje i
  menja, a serverski sloj ostaje isti"). Do not swap in `priključivi motori` later.
- **`handler` stays in code font, untranslated.** It is a C++ class name (`sql/handler.h`), not a
  concept word — translating it would break the link to the source the chapter cites. Same rule as
  SQL keywords under the lesson-language preference in `NOTES.md`.

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
| 4 | EXPLAIN i EXPLAIN ANALYZE | 4 |
| 5 | Iterator model i pipeline operatora | 3 |
| 6 | Vektorizovano izvršavanje | 2 |
| 7 | Paralelno izvršavanje upita | 2 |
| 8 | Keširanje i ponovna upotreba planova | 2 |
| 9 | Zaključak | 1 |

Total ≈ 21 pages against the map's nominal "~20 pages" — accepted as close enough; a page or two over
is not a problem. Do not trim pre-emptively; a chapter's real length is only known once it's written.

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
