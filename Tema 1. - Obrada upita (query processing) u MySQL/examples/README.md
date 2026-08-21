# examples/

Runnable SQL for the paper, one subfolder per chapter so a reader can find the query behind any
figure or listing in `rad.md`.

- `00-setup/` - the Sakila load and the synthetic wide-table generator script from ticket 01. Not
  paper content; everything downstream depends on it having been run once.
- `NN-<chapter-slug>/` - one folder per chapter that needs runnable SQL (e.g. `03-sql-to-plan/`,
  `04-explain/`), created as that chapter is written. `NN` matches the chapter number in `rad.md`.

Generated data (`*.sql.gz`, `*.dump`, CSVs) is git-ignored; only the SQL scripts themselves are
committed.
