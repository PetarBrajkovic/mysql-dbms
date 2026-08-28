# Glossary and skeleton — binding on every chapter

Label: `wayfinder:issue-08-answer` (mirrors `.scratch/obrada-upita/issues/08-terminology-and-skeleton.md`)

Terminology and chapter skeleton for **this topic only**. It exists so a term is decided once and
never re-translated later. Do not deviate from a term below without updating this file first and
noting why. The rules this vocabulary is *applied* under - language, voice, citations, the em-dash
ban, the lecture-deck policy - are shared by every paper in the course and live in `../WRITING.md`.

**How to read it cheaply:** §1 and §2 are the always-relevant term tables. Each `§2x` subsection
belongs to one chapter — read only the one you are working on. §4 (skeleton and page budget) matters
only when a chapter is being written; §3 only for chapter 8. The reasoning behind each locked
non-choice lives in `.scratch/obrada-upita/terminology-rationale.md`; the one-line rule here is the
binding part.

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

Post-2016 / MySQL-specific terms the decks are silent on. **Convention for §2 and every §2x
subsection: Serbian term, English original in parentheses on first use only, Serbian-only after
that.**

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

New coinage: the decks have no vocabulary for MySQL's server/engine split.

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

**Locked non-choices** (reasoning: `.scratch/obrada-upita/terminology-rationale.md`):
`pluggable` is carried by the noun phrase *modularna arhitektura motora*, never `priključivi motori`;
`handler` stays untranslated in code font, as a class name; *storage engine* is
*mehanizam skladištenja* on first use and the short form **motor** everywhere after, never
`skladišni motor` and never `mehanizam` throughout.

### 2b. Pipeline and optimizer terms (locked 2026-08-24, chapter 3)

Mostly new coinage: the decks name the generic components but not MySQL's phase boundaries, cost
model tables, or join-order search.

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

**Locked non-choices** (reasoning: `.scratch/obrada-upita/terminology-rationale.md`):
**`poluspoj`/`antispoj` written solid**, never `semi-spoj` or `polu-spoj`; trace keys
(`optimizer_trace`, `cause: "cost"`, …) stay verbatim in code font; **cena**, never *trošak* or
*cost*; **odsecanje**, never *orezivanje*.

### 2c. EXPLAIN vocabulary (locked 2026-08-24, chapter 4)

New coinage beyond §1's `pristupni put` and `sken preko indeksa`: the decks have nothing for
`EXPLAIN`'s own output vocabulary.

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

**Locked non-choices** (reasoning: `.scratch/obrada-upita/terminology-rationale.md`):
**`tip pristupa`**, never `tip spoja`, even though the manual calls the `type` column a "join type";
**`pretraga po indeksu` (lookup) and §1's `sken preko indeksa` (scan) are different terms and must
not be merged**; `filesort` stays untranslated; **column names and `Extra` values stay verbatim in
code font** (`type`, `key`, `key_len`, `rows`, `filtered`, `possible_keys`, `Using index`,
`Using index condition`, `Using where`, `Using temporary`, `Using filesort`).

### 2d. EXPLAIN ANALYZE vocabulary (locked 2026-08-26, chapter 4b)

§2c covers a plan that was never run; this covers the second set of numbers that appears once it is.

| Concept | Serbian term (first use) | After first use |
|---|---|---|
| Estimated-vs-actual row divergence | odstupanje procene od stvarnog broja torki | odstupanje procene |
| Actual (measured) row count | stvarni broj torki | stvarni broj torki |
| Loop iteration (what `loops` counts) | ponavljanje | ponavljanje |
| Per-loop average | prosek po ponavljanju | prosek po ponavljanju |
| Histogram bucket | korpa *(bucket)* | korpa |
| Equi-height histogram | histogram jednakih visina | histogram jednakih visina |
| Range optimizer | optimizator opsega *(range optimizer)* | optimizator opsega |
| Iterator executor | iteratorski izvršilac | iteratorski izvršilac |
| Skew (of a column's distribution) | neravnomernost raspodele | neravnomernost |

**Locked non-choices** (reasoning: `.scratch/obrada-upita/terminology-rationale.md`):
`actual time`, `rows`, `loops`, `(never executed)` stay verbatim (`rows` appears in both brackets and
is disambiguated in prose as *procena* vs *stvarni broj torki*, never renamed); **ponavljanje**, not
*iteracija*; **korpa**, not *razred*/*interval*/*kanta*; **optimizator opsega**, not
*opsežni optimizator*; **odstupanje**, not *divergencija*/*razlaženje*.

### 2e. Optimizer-trace vocabulary (locked 2026-08-28, chapter 4c)

Short by design: §2b already locked `trag optimizatora`, `odsecanje planova`, `delimični plan` and
`pretraga redosleda spoja`, and §1 has `pristupni put`. Only what those miss is here.

| Concept | Serbian term (first use) | After first use |
|---|---|---|
| Considered plan (`considered_execution_plans`) | razmatran plan | razmatran plan |
| Rejected plan (`"chosen": false`) | odbačen plan | odbačen plan |
| Trace phase (`join_optimization` etc.) | faza traga | faza traga |
| Index-ordering override | naknadna zamena plana zbog redosleda | naknadna zamena plana |
| Truncated trace | krnj trag | krnj trag |
| Named connection | imenovana veza *(named connection)* | imenovana veza |
| Connection id | broj veze (`connection_id`) | broj veze |
| Status counter (`Com_explain_other`) | brojač | brojač |
| Session-scoped (of a variable or of state) | sesijski | sesijski |

**Locked non-choices** (reasoning: `.scratch/obrada-upita/terminology-rationale.md`):
**`pristupni put` (§1), never `put pristupa`** — a near-miss that had to be reverted across a whole
lesson, and the false analogy with `tip pristupa` will be tempting again in chapter 5;
**odbačen plan** (optimizer rejects an alternative) is distinct from **odbijanje** (server refuses a
statement); **razmatran plan**, not *kandidat-plan*; **faza traga (three) is not a pipeline phase
(five)** and the two must never be merged; all trace keys stay verbatim in code font.

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
| 4 | EXPLAIN i EXPLAIN ANALYZE | 6.6 |
| 5 | Iterator model i pipeline operatora | 3 |
| 6 | Vektorizovano izvršavanje | 2 |
| 7 | Paralelno izvršavanje upita | 2 |
| 8 | Keširanje i ponovna upotreba planova | 2 |
| 9 | Zaključak | 1 |

Total ≈ 23.6 pages against the map's nominal "~20 pages" — accepted; a few pages over is not a problem.
Do not trim pre-emptively; a chapter's real length is only known once it's written.

Chapter 4's budget was raised twice by the user (4 -> 6 on 2026-08-26, 6 -> 6.6 on 2026-08-28) as
its three lessons turned out denser than planned. The standing rule from both decisions:
**never trim written prose to make room** — raise the budget instead. Reasoning:
`.scratch/obrada-upita/terminology-rationale.md`.

## 5. Voice and citation density

Not here: these are the same for every paper in this course and live in **`../WRITING.md`**
("Voice and citation density"). This section is kept only as a signpost, so a chapter written
against this file does not conclude the rules were never set.

---

Decided in a grilling session, 2026-08-21. Resolves
`.scratch/obrada-upita/issues/08-terminology-and-skeleton.md`.
