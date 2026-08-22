# Query processing u MySQL-u Resources

## Knowledge

- [MySQL 8.4 Reference Manual](https://dev.mysql.com/doc/refman/8.4/en/)
  The primary source for everything version-specific: optimizer switches, `EXPLAIN` formats,
  storage engine behaviour. Use for: any factual claim that needs a citable, current source.
- [MySQL Server Blog (dev.mysql.com/blog-archive)](https://dev.mysql.com/blog-archive/)
  Engineering-team posts on the iterator executor, the hypergraph optimizer, and other internals
  the reference manual only documents at a surface level. Use for: chapters 5-8, where the manual
  runs thin.
- Lecture decks in `../../Predavanja/` (Ramakrishnan & Gehrke, general database theory, not
  MySQL-specific). Use for: chapters 1-5's theoretical grounding, orientation, and the Serbian
  terminology in `GLOSSARY.md`. Give **zero** coverage of chapters 6-8 (confirmed by research ticket
  07 - see `.scratch/obrada-upita/research/07-lecture-decks.md`).
  **Never cited in the paper (policy set 2026-08-22):** these are the user's own university course
  material, provided for *learning*, not a citable source. When a claim comes from a deck, cite its
  published origin instead - Ramakrishnan & Gehrke (next entry) for the theory, or the MySQL manual
  for anything MySQL-specific. The slide numbers stay useful for *finding* the R&G passage, they just
  never appear in `references.bib`.
- [Ramakrishnan & Gehrke, *Database Management Systems* 3ed — open-access slides](https://pages.cs.wisc.edu/~dbbook/openAccess/thirdEdition/slides/slides3ed-english/)
  The textbook the course decks are literally drawn from (Stoimenov's slides cite it by name). The
  English original of the same figures and framing, freely linkable. Most relevant to chapter 1:
  [Ch. 12 — Overview of Query Evaluation](https://pages.cs.wisc.edu/~dbbook/openAccess/thirdEdition/slides/slides3ed-english/Ch12_Overview_Query_Evaluation.pdf).
  Use for: an external, citable cross-check of anything the Serbian decks compress, chapters 1-5.
- Internal research reports already produced while charting this effort, one per closed research
  ticket in `.scratch/obrada-upita/research/`:
  - `04-sql-to-plan-and-iterator.md` - the five-stage pipeline, the iterator executor,
    `optimizer_search_depth`, why the hypergraph optimizer can't be demoed.
  - `05-explain-semantics.md` - `EXPLAIN` / `EXPLAIN ANALYZE` output formats, the estimated-vs-actual
    divergence heuristic (flagged for live-server verification).
  - `06-vectorized-parallel-plancache.md` - why MySQL doesn't vectorize, what
    `innodb_parallel_read_threads` actually parallelizes, and the plan-cache-vs-parse-tree-cache
    distinction.
  These are already vetted for citability; check here before searching the open web again.

## Wisdom (Communities)

Not applicable to this mission. The deliverable is a cited academic paper, so claims need
primary/documented sources, not forum consensus - see `WORKFLOW.md` rule 5 on never inventing or
leaning on an uncitable claim.

## Gaps

- No primary source yet verified for chapters 6-8 beyond the two research reports above; each new
  claim in those chapters still needs its own citation hunted down at write time.
- The "estimates off by 3x" rule of thumb and whether `explain_json_format_version = 2` works on
  8.4 are both unverified against the live server (see `WORKFLOW.md`) - resolve before citing
  either in chapter 4.
