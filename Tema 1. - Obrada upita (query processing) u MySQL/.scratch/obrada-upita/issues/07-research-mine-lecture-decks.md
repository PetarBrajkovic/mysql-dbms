# Research: mine the lecture decks for required content and terminology

Type: research
Status: open

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
