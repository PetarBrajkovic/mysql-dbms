# examples/

Runnable SQL for the paper, one subfolder per chapter so a reader can find the query behind any
figure or listing in `rad.md`.

- `00-setup/` - the Sakila load and the synthetic wide-table generator script from ticket 01. Not
  paper content; everything downstream depends on it having been run once.
- `NN-<chapter-slug>/` - one folder per chapter that needs runnable SQL (e.g. `03-sql-to-plan/`,
  `04-explain/`), created as that chapter is written. `NN` matches the chapter number in `rad.md`.

Generated data (`*.sql.gz`, `*.dump`, CSVs) is git-ignored; only the SQL scripts themselves are
committed.

## Figure linkage (ticket 09)

Every figure in `figures/` that comes from a live query has its script here under a mirrored
filename, e.g. `figures/04-explain-01-visual-explain.png` <->
`examples/04-explain/01-visual-explain.sql`. The script's first line is a comment naming the
figure it produces, so the pairing is greppable in both directions. Non-SQL figures (architecture
diagrams, reused-official diagrams) have no script and are exempt from this rule - see
`figures/README.md`.
