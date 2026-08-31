# Glossary and skeleton — binding on every chapter

Label: `wayfinder:issue-08-answer` (mirrors `.scratch/obrada-upita/issues/08-terminology-and-skeleton.md`)

Terminology and chapter skeleton for **this topic only**. It exists so a term is decided once and
never re-translated later. Do not deviate from a term below without updating this file first and
noting why. The rules this vocabulary is *applied* under - language, voice, citations, the em-dash
ban, the lecture-deck policy - are shared by every paper in the course and live in `../WRITING.md`.

**How to read it cheaply:** §1 and §2 are the always-relevant term tables. Each `§2x` subsection
belongs to one chapter — read only the one you are working on. §4 (skeleton and page budget) matters
only when a chapter is being written; §3 only for chapter 6. The reasoning behind each locked
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

Note: *vectorized execution* and *parallel query execution* need no English gloss since they are the
section titles of chapter 6 in `rad.md` (§6.1 and §6.2, after the 2026-08-31 merge of the old
chapters 6-8) — introducing English there would be redundant, not clarifying.

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

### 2f. Iterator-model vocabulary (locked 2026-08-31, chapter 5)

§1 already has `pipeline / pipelined evaluacija`, `materijalizacija`, `operator`, `torka` and
`pristupni put`; §2 has `model iteratora`; §2c has `iterator` as one node of the tree; §2d has
`iteratorski izvršilac`. Only what those miss is here.

| Concept | Serbian term (first use) | After first use |
|---|---|---|
| Volcano model (the design) | Volcano model | Volcano model |
| Pull-based / demand-driven execution | izvršavanje na zahtev *(demand-driven)* | izvršavanje na zahtev |
| Iterator tree | stablo iteratora | stablo iteratora |
| Parent / child iterator | roditeljski iterator / iterator-dete | roditelj / dete |
| Root / leaf of the tree | koren stabla / list | koren / list |
| Blocking operator | blokirajući operator *(blocking operator)* | blokirajući operator |
| Pipelined operator | pipeline operator | pipeline operator |
| Record buffer | bafer torke *(record buffer)* | bafer torke |
| Time to first row | vreme do prve torke | vreme do prve torke |
| Early termination (of a scan) | rano zaustavljanje | rano zaustavljanje |
| Build phase (of a hash join) | faza gradnje | faza gradnje |
| Initialization call (`Init()`) | inicijalizacija | inicijalizacija |

**Locked non-choices** (reasoning: `.scratch/obrada-upita/terminology-rationale.md`):
**`AccessPath` is the C++ structure and stays verbatim in code font; `pristupni put` (§1) is the
concept.** They are not synonyms and must never be swapped — this is the trap §2e predicted for this
chapter. **`bafer torke`**, consistent with §1's `torka`, never `bafer sloga` — `slog` is not in this
paper's vocabulary at all. **`izvršavanje na zahtev`**, never *povlačenje* or *pull model*.
**`blokirajući operator`**, never *zaustavljajući* or *barijera*. Class and method names
(`RowIterator`, `Init()`, `Read()`, `UnlockRow()`, `TableScanIterator`, …) stay verbatim in code
font, exactly like `handler` in §2a. TREE node strings (`Nested loop inner join`, `Stream results`,
`Group aggregate`, …) stay verbatim, exactly like the `Extra` values in §2c.

### 2g. Vectorization, parallelism and caching vocabulary (locked 2026-08-31, chapter 6)

§2 already has `vektorizovano izvršavanje`, `paralelno izvršavanje upita`, `keš plana` and
`pripremljena naredba`; §1 has `klasterovani indeks`, `sken tabele`, `workload` and `torka`; §2a has
`nit` and `motor`; §2d has `iteratorski izvršilac`; §2e has `sesijski`. Only what those miss is here.

| Concept | Serbian term (first use) | After first use |
|---|---|---|
| Row-at-a-time execution | izvršavanje torku po torku | izvršavanje torku po torku |
| Batch / vector of rows | paket torki *(batch)* | paket torki |
| SIMD | SIMD *(jedna instrukcija, više podataka)* | SIMD |
| Columnar storage | kolonarno skladištenje *(columnar storage)* | kolonarno skladištenje |
| Interpretation overhead | režija interpretacije | režija interpretacije |
| Analytical workload | analitički workload (OLAP) | analitički workload |
| Transactional workload | transakcioni workload (OLTP) | transakcioni workload |
| Parallel clustered index read | paralelno čitanje klasterovanog indeksa | paralelno čitanje klasterovanog indeksa |
| Worker thread | radna nit | radna nit |
| Intra-operation parallelism | paralelizam unutar operacije | paralelizam unutar operacije |
| Query-level parallelism | paralelizam na nivou upita | paralelizam na nivou upita |
| Shared (cross-session) plan cache | deljeni keš plana | deljeni keš plana |
| Prepared-statement (parse-tree) cache | keš pripremljene naredbe | keš pripremljene naredbe |
| Repreparation | ponovna priprema | ponovna priprema |
| Query cache (removed in 8.0) | keš rezultata upita *(query cache)* | keš rezultata upita |
| Generic plan | generički plan | generički plan |
| Shared pool / library cache (Oracle) | deljeni pul *(shared pool)* | deljeni pul |

**Locked non-choices** (reasoning: `.scratch/obrada-upita/terminology-rationale.md`):
**`deljeni keš plana` (what MySQL does not have) and `keš pripremljene naredbe` (what it does have)
are two different objects and must never be merged or abbreviated to a bare `keš`** — that
distinction is this chapter's entire argument, see §3. **`izvršavanje torku po torku`**, never
*red po red* or *row-at-a-time* — `torka` is §1's word for a row and stays. **`paket torki`**, never
*grupa* or *serija*. **`radna nit`**, consistent with §2a's `nit`, never *worker*. **`ponovna
priprema`**, never *reprepariranje* or *repriprema*. System-variable, status-counter and error names
stay verbatim in code font exactly like §2c's `Extra` values: `innodb_parallel_read_threads`,
`Com_stmt_reprepare`, `optimizer_trace`, `PREPARE`/`EXECUTE`/`DEALLOCATE PREPARE`,
`ERROR 1243 (HY000)`. Product names (`DuckDB`, `ClickHouse`, `HeatWave`, `PostgreSQL`, `Oracle`) are
never translated or transliterated.

## 3. Hard constraint — plan cache vs. parse-tree cache (chapter 6, §6.3)

Research ticket 06 confirms, does not contradict, the assumption in ticket 17: MySQL has **no shared
execution plan cache** across sessions (Oracle-style), and the query cache was removed in 8.0. But
prepared statements **do** cache something — the parsed statement structure (parse tree, column
resolution, symbol table) — per session only, discarded when the session ends. §6.3 must state
this as its central move, explicitly distinguishing *deljeni keš plana* (which MySQL does not have)
from the per-session *keš pripremljene naredbe* (which it does have). Never write "MySQL doesn't
cache anything" — that's false and the whole point of the section is the more precise claim.

Lesson 08 measured the sharper version of the same claim: three `EXECUTE`s of one prepared statement
produce **three separate optimizer traces with three different row estimates and costs**, so the plan
is not merely un-shared, it is re-derived on every execution against the actual parameter value.

## 4. Chapter skeleton — top-level (locked)

Locked at the top level only (chapter list, order, page budget). Subheadings are deliberately **not**
locked here — they're a guess for chapters not yet researched-and-taught (especially 6–8), and this
ticket exists precisely so nothing gets fixed before it's known. Each chapter ticket's own
`academic-research-writer` pass produces subheadings naturally from the material at write time.

**Revised 2026-08-31** (page-ceiling session). Chapters 6, 7 and 8 are **merged into one chapter**,
and the budget is now stated in **rendered DOCX pages**, not in a private unit. That switch is the
point: the old table's numbers were never measured against an export, so chapters 1-4 budgeted at
13.6 rendered as ~17 pages of body and nobody noticed until the document hit 20.

| # | Chapter | Budget (rendered pages) |
|---|---|---|
| 1 | Uvod | 1.5 |
| 2 | Arhitektura obrade upita u MySQL-u | 2 |
| 3 | Od SQL-a do plana izvršavanja | 3.5 |
| 4 | EXPLAIN i EXPLAIN ANALYZE (4a + 4b + 4c) | 6.6 |
| 5 | Iterator model i pipeline operatora | 3 |
| 6 | Gde MySQL ne prati obrazac (6.1 vektorizacija, 6.2 paralelizam, 6.3 keširanje planova) | 2.5 |
| 7 | Zaključak | 0.75 |

**Hard target: ≤ 25 rendered pages**, title page and reference list included. Not the old "~20
nominal, a few over is fine" — the projection at the end of chapter 4 was 31-35 pages, which is
what forced this revision.

**Retired 2026-08-31, once the paper was finished.** The user raised the ceiling ("we can do even
26") and then made the call that settles it: **figure legibility outranks the page count.** The
5.0in -> 4.3in shrink that ticket 20 used to reclaim a page had left the figures unreadable, so
every figure was resized by how much height it actually costs, and the paper stands at **27 pages**.
The ≤25 number was the map's instrument for stopping drift, not a faculty rule (`MISSION.md` asks
for ~20), and it did its job: the trajectory it caught was 31-35. It is not a live constraint any
more, and figure width is **not** a lever to reach for again.

**Measured checkpoint (2026-08-31): 19 pages with chapters 1-4 complete, 22 pages with chapter 5
complete**, so chapter 5 came in at exactly its 3. Re-measure after every chapter with
`..\tools\make-docx.ps1`; the budget is only real if it is checked against the export.

**Measured again the same day, with chapter 6 complete: 26 pages, brought back to 25 by figure
sizing.** Chapter 6 did not absorb the overrun as planned; it *was* the overrun, rendering at **4
pages against its 2.5** with nothing padded and with its single figure. A redundancy-only prose trim
moved the count by zero, the second time that lever has under-delivered (ticket 20). Cutting every
figure's width, **5.0in → 4.3in and 4.6in → 4.1in**, took the paper 26 → 25 with nothing removed;
3.9in was measured too and buys no further page, so 4.3in is the floor worth having. The paper now
sits **exactly at the hard ceiling with chapter 7 (0.75) unwritten**, and that gap is an open
decision on ticket 18: raise the ceiling by about a page, or reclaim about a page from chapters 1-4
under the suspension below.

**Measured a third time, with chapter 7 complete and the paper finished: 26 pages.** The paper was
at exactly 25 with chapter 7 unwritten, so **any** conclusion puts it at 26; chapter 7 itself was
written at 593 words and tightened to 444 without dropping anything but redundancy. Two mechanics
worth keeping, both measured this session:

- **Text cut from chapter 7 is the only trim with a predictable effect**, because no figure stands
  between it and the reference list, so the bibliography moves up by the lines removed. It is what
  took the export 27 -> 26 (the last reference entry had been sitting alone on page 27).
- **Everywhere else, savings are absorbed by figure quantization.** Shrinking Slika 2.1 from 3.6in
  to 3.0in, 46 pt, moved the page count by zero, and so did putting it back. A saving upstream pays
  only if it lets a whole figure cross a page boundary.

Reaching 25 needs ~660 pt in one contiguous saving. Layout was taken in ticket 20, figure widths
bottomed out at 4.3in there, and the redundancy-only prose trim has now under-delivered three times,
so 25 costs either a figure (~0.4 pages, and every SQL statement in this paper *is* a figure) or
~600 words of taught prose. Neither is licensed by the suspension below.

**Resolved the same day, and the answer went the other way.** The user raised the ceiling and then
said the figures had become unreadable, which they had: 4.3in was the width the page count wanted,
not the width the reader needs. Resized per the policy above, the paper is **27 pages**, and the
ceiling is retired. Final composition: title page 1, chapters 24, reference list ~0.85.

**Figure cap, firm** (was "soft guidance" under ticket 09): chapter 5 gets **2** figures, chapter 6
gets **1**, chapter 7 gets **0**. The cap is on the **number** of figures, and it held. Their
**size** is a separate question and was got wrong in the other direction: see the sizing policy
below.

### Figure sizing policy (set 2026-08-31, replaces the 4.3in floor)

Width is chosen per figure, by how much page height its aspect ratio makes it cost, not by one
number for all of them. Total image height went 35.8in -> 45.3in and the paper grew by **one page**,
because most of the gain is in figures that are wide and short.

| Aspect ratio (h/w) | Width | Why |
|---|---|---|
| < 0.45 | **6.2in** | flame graphs, `FORMAT=TREE` output, the iterator tree. Nearly full text width costs almost no height and is where the small type was. |
| 0.45 - 0.70 | **5.5in** | the plotted comparisons. |
| ≥ 0.70 | **5.0in** | the tall ones, where width converts straight into page height. |
| any, low-resolution source | **4.0in** | only Slika 2.1, the reused official diagram: its source is 500 px, so enlarging it blurs rather than clarifies. |

Text width on A4 with 2,5 cm margins is 6.3in, which is the hard maximum. Always set a width
explicitly: three figures had none and rendered at whatever Word chose.

### The two standing rules, as they now stand

- **"Never trim written prose to make room"** is **suspended for this paper** (user's decision,
  2026-08-31, reversing their own earlier calls of 2026-08-26 and 2026-08-28). Chapters 1-4 are
  re-openable. The suspension is scoped to the page-ceiling problem: it licenses tightening
  redundancy and over-explanation, **not** dropping taught material, figures, or citations.
  `../WRITING.md` still carries the rule as the course-wide default.
- **"Do not trim pre-emptively"** stands. A chapter is still written to its natural length first and
  measured second.

Chapter 4's budget was raised twice by the user (4 -> 6 on 2026-08-26, 6 -> 6.6 on 2026-08-28) as
its three lessons turned out denser than planned; it keeps that 6.6 and was **not** cut in this
revision. Reasoning: `.scratch/obrada-upita/terminology-rationale.md`.

## 5. Voice and citation density

Not here: these are the same for every paper in this course and live in **`../WRITING.md`**
("Voice and citation density"). This section is kept only as a signpost, so a chapter written
against this file does not conclude the rules were never set.

---

Decided in a grilling session, 2026-08-21. Resolves
`.scratch/obrada-upita/issues/08-terminology-and-skeleton.md`.
