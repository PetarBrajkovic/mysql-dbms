# Research: mine the lecture decks for required content and terminology

Type: research
Status: resolved

## Question

The professor's own material is the paper's structural spine, and the Serbian terminology should match
what was taught rather than being invented. **Use the `pdf-reader` skill** - the user requires it for
all PDFs in this project.

Read, in `C:\Faks\Sistemi Baza\Predavanja\`:
- `02_Evaluacija rel operatora 2016.pdf` (28 pp) - core
- `03_Optimizacija upita 2016.pdf` (31 pp) - core
- `01_Skladistenje i Indeksi 2016.pdf` (27 pp) - prerequisite background only
- `04_Tuning 2016.pdf` (32 pp) - skim for query-processing overlap only

Ignore `05_Oporavak` and `06_Sigurnost`; they are out of scope.

Produce:
1. A **Serbian term list** as used in the decks - the professor's own words for join algorithms,
   access paths, cost, selectivity, execution plan, and so on. This seeds the glossary.
2. A map of **which deck slides back which of our nine chapters**, precise enough to cite.
3. **Gaps**: what our topic needs that 2016 slides cannot cover (the iterator executor, EXPLAIN
   ANALYZE, HeatWave), which is where external sources take over.

## Answer

Findings: [`research/07-lecture-decks.md`](../research/07-lecture-decks.md)

**The decks are general database theory, not MySQL.** They are Prof. dr Leonid Stoimenov's SUBP
2015/2016 lectures, explicitly built on Ramakrishnan & Gehrke, *Database Management Systems* (3rd
ed.). That textbook is itself a citable IEEE reference and should go into `references.bib`.

**Coverage is sharply split.** Chapters 1-5 are well backed by the decks, with precise slide
citations available (deck 03 for optimization, cost, query blocks, left-deep trees and pipelined
evaluation; deck 02 for selection, projection and the join algorithms; deck 01 for index structures).
Chapters 6, 7 and 8 have **zero** coverage - vectorization, parallelism and plan caching are simply
absent from a 2016 course. Chapter 4 is partial: the conceptual foundation is there, but `EXPLAIN
FORMAT=TREE` and `EXPLAIN ANALYZE` are post-2016 MySQL features.

**A ~40-term Serbian glossary was extracted with slide references**, including *plan izvršenja*,
*optimizator upita*, *cena*, *selektivnost*, *pristupni put*, *spoj sa ugnježdenom petljom*,
*faktor redukcije*, *blok upita* and *left-deep stablo*. This is the seed for ticket 08.

**Two things to carry forward:**
- **Terminology divergence.** The decks say *plan izvršenja*; the chapter titles drafted during
  charting say *plan izvršavanja*. Ticket 08 must pick one and apply it everywhere. The professor's
  own wording is the stronger default.
- **Unverified nuance.** Hash join is cited at deck 02 p. 20 as *hashing for projection*, which
  suggests the deck may not present hash join as a join algorithm at all. Re-check that specific
  slide before citing it as such in chapter 3.
