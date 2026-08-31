# Query processing u MySQL-u Resources

Read this when you need a source. It is not part of the per-lesson read set — see the reading
protocol in `NOTES.md`.

## Knowledge

- [MySQL 8.4 Reference Manual](https://dev.mysql.com/doc/refman/8.4/en/)
  The primary source for everything version-specific: optimizer switches, `EXPLAIN` formats, storage
  engine behaviour. Use for: any factual claim that needs a citable, current source. **Fetch the page
  before quoting it** — a quotation written from memory has already been wrong once (LR-0006).
- [MySQL Server Blog](https://dev.mysql.com/blog-archive/)
  Engineering-team posts on the iterator executor, the hypergraph optimizer, and other internals the
  manual documents only at surface level. Use for: chapters 5-8, where the manual runs thin.
- [Ramakrishnan & Gehrke, *Database Management Systems* 3ed — open-access slides](https://pages.cs.wisc.edu/~dbbook/openAccess/thirdEdition/slides/slides3ed-english/)
  The textbook the course decks are drawn from, in its citable English original. Most relevant to
  chapter 1: [Ch. 12 — Overview of Query Evaluation](https://pages.cs.wisc.edu/~dbbook/openAccess/thirdEdition/slides/slides3ed-english/Ch12_Overview_Query_Evaluation.pdf).
  Use for: an external cross-check of anything the Serbian decks compress, chapters 1-5.
- G. Graefe, „Volcano — An Extensible and Parallel Query Evaluation System", *IEEE Trans. Knowl.
  Data Eng.*, vol. 6, no. 1, pp. 120–135, 1994, doi: 10.1109/69.273032.
  The citable origin of the iterator model. Use for: chapter 5's one theory citation — the decks do
  not cover the iterator model at all, so R&G cannot carry it.
- Lecture decks in `../../Predavanja/` (Stoimenov, SUBP).
  Use for: chapters 1-5's theoretical grounding and the Serbian terminology in `GLOSSARY.md` §1.
  Give **zero** coverage of chapters 6-8. **Never cited in the paper** (`WORKFLOW.md` rule 7) — cite
  the published origin instead: R&G for theory, the MySQL manual for anything MySQL-specific.
- Internal research memos, one per closed research ticket, in `.scratch/obrada-upita/research/`:
  `04-sql-to-plan-and-iterator.md` (five-stage pipeline, iterator executor, `optimizer_search_depth`,
  why the hypergraph optimizer cannot be demoed), `05-explain-semantics.md` (`EXPLAIN` /
  `EXPLAIN ANALYZE` output formats), `06-vectorized-parallel-plancache.md` (why MySQL does not
  vectorize, what `innodb_parallel_read_threads` parallelizes, plan cache vs parse-tree cache),
  `07-lecture-decks.md` (what the decks do and do not cover), `11-server-engine-architecture.md`.
  Already vetted for citability; check here before searching the open web again. **Three errors are
  on file against `05-explain-semantics.md`** — see `learning-records/README.md`.

### Chapter 4 pages worth having by name

- [Tracing the Optimizer](https://dev.mysql.com/doc/refman/8.4/en/optimizer-tracing.html) and
  [the `OPTIMIZER_TRACE` table](https://dev.mysql.com/doc/refman/8.4/en/information-schema-optimizer-trace-table.html).
  Descriptive, not promotional: the page never claims the trace shows rejected plans, so that claim
  has to be carried by measured output rather than by a quotation. One value in it is stale against
  this server (`optimizer_trace_max_mem_size`) — see `learning-records/README.md`.
- [Obtaining Execution Plan Information for a Named Connection](https://dev.mysql.com/doc/refman/8.4/en/explain-for-connection.html).
  Use for: accepted statement types, the `PROCESS` privilege, `Com_explain_other`, and the sentence
  "If the named connection is not executing a statement, the result is empty" — a different case from
  `ERROR 3012`, and easy to conflate.

## Wisdom (Communities)

Not applicable to this mission. The deliverable is a cited academic paper, so claims need
primary/documented sources, not forum consensus. The user has not opted into any community.

## Gaps

- **Chapters 6-8 have no verified primary source** beyond the two research memos above. Every claim
  in those chapters still needs its own citation hunted down at write time. This is the one open gap.
