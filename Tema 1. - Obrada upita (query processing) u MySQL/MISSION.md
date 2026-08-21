# Mission: Query processing u MySQL-u

## Why

Petar mora da napiše i odbrani seminarski rad iz predmeta Sistemi baza podataka na temu obrade
upita (query processing) u MySQL-u: ~20 strana, na srpskom, sa IEEE citatima i stvarnim primerima
upita. Svaka lekcija u ovom radnom prostoru postoji da bi ga pripremila da tu tačnu temu napiše
tačno i da je brani pred profesorom - ne opšte zanimanje za MySQL.

## Success looks like

- Can explain, in his own words and without notes, how MySQL turns one SQL statement into an
  executing plan (parser -> resolver -> optimizer -> planner -> iterator executor).
- Can read `EXPLAIN` / `EXPLAIN ANALYZE` output on a real query and diagnose a bad plan from the
  estimated-vs-actual row divergence.
- Can trace a query through MySQL's iterator (Volcano-style) executor and connect `FORMAT=TREE`
  output to real iterator/AccessPath classes.
- Can state precisely, with evidence, where MySQL does *not* match the pattern of other systems -
  no vectorized execution, limited query parallelism, no shared plan cache - rather than assuming
  it matches by default.
- Can defend every chapter he writes: no claim in `rad.md` that he could not explain live if asked.

## Constraints

- Nominal five-week timebox, no hard deadline.
- One chapter per session, following the loop in `WORKFLOW.md`: learn it, run it in Workbench,
  then write it with `academic-research-writer`.
- Short lessons over long ones - see the lesson budget in `WORKFLOW.md` (roughly 7-9 lessons for
  nine chapters, with chapters 6 and 7 sharing one).
- Every lesson should point at something he can go run himself in Workbench against Sakila or the
  synthetic table, not stay abstract.
- Chapters 1-5 are backed by the course's own lecture decks (Ramakrishnan & Gehrke, general
  theory); chapters 6-8 have zero lecture backing and rest entirely on external primary sources
  (the MySQL reference manual, MySQL Server Team blog) - lessons for those three chapters need to
  work harder to ground the material.

## Out of scope

- The hypergraph join optimizer as something to demo - it is compile-gated out of the stock 8.4
  build he installed. Teach it as a documented fact, not as a live example.
- The PowerPoint defense deck - a separate deliverable he is building himself.
- General MySQL administration, tuning, or application-building - the professor asked for isolated
  query-processing examples, not a working app.
- Tema 2 and Tema 3 for this course - separate topics, separate workspaces.
