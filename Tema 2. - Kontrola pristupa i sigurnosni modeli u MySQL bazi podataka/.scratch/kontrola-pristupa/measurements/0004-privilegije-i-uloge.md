# Measurements and artifacts — 0004, chapter 3 (privilegije i uloge)

## Status

**Nothing measured yet.** The three example scripts were authored in the teaching session but not
executed. Every "expected" line in them is sourced from the MySQL 8.4 manual, not observed. Do not
cite any of it as measured until this file records real output.

## Artifacts produced

| Path | What it is |
|---|---|
| `lessons/0002-privilegije-i-uloge.html` | the lesson |
| `reference/02-privilegije-i-uloge.html` | reference card 02 |
| `examples/03-privilegije-i-uloge/01-nivoi-i-ili-sastavljanje.sql` | OR-composition, two probe accounts |
| `examples/03-privilegije-i-uloge/02-uloge-hijerarhija-i-aktivacija.sql` | role hierarchy + `SET ROLE` |
| `examples/03-privilegije-i-uloge/03-partial-revokes.sql` | partial revokes, **root only** |
| `examples/03-privilegije-i-uloge/README.md` | which script needs which connection, and why |

## To verify live (ticket 16 DoD item 4)

Fill in observed output under each heading as it is run.

### 01 — OR-composition
- [ ] `probe_wide` reads `diagnosis_text` despite holding only `SELECT (icd_code)` at column level
- [ ] `probe_narrow` fails with `ERROR 1143` on the same statement
- [ ] `SHOW GRANTS` for `probe_wide` lists the db-level and column-level lines as separate entries

### 02 — roles (the claim the map flagged as needing the live server)
- [ ] `CURRENT_ROLE()` on fresh login shows `role_doctor` only, not the newly granted `role_senior_doctor`
- [ ] `SELECT` on `invoices` fails before `SET ROLE`, succeeds after
- [ ] `SET ROLE role_senior_doctor` **replaces** the active set (i.e. `role_doctor` disappears from `CURRENT_ROLE()`)
- [ ] `diagnoses` still readable after that, proving inheritance across two `role_edges` hops
- [ ] `SET ROLE NONE` → `CURRENT_ROLE()` = `NONE`, `diagnoses` fails with `ERROR 1142`
- [ ] `SHOW GRANTS FOR CURRENT_USER() USING role_senior_doctor` resolves the graph

### 03 — partial revokes (root)
- [ ] `REVOKE SELECT ON poliklinika.* ` fails with `ERROR 1141` while `partial_revokes` is `OFF`
- [ ] exact `User_attributes` JSON after the revoke
- [ ] exact `SHOW GRANTS` rendering of the restriction
- [ ] table-level grant inside the restricted schema still works (the key claim)
- [ ] `SET PERSIST partial_revokes = OFF` fails while the restricted account still exists

## Figure to build afterwards

Role-graph diagram from live `mysql.role_edges` content: `doc_bar` → `role_senior_doctor` →
`role_doctor`, with the `tables_priv` rows drawn hanging off the two role nodes and **no** row on
the account node. Caption must state that no `tables_priv` row has `User='doc_bar'`. Per
`tools/FIGURES.md`; data pulled with `mysql-credentials.cnf`, never credentials on the CLI.

## Write-up notes for `rad.md`

- Lead the chapter with the grant tables as a data model; derive the level count from naming arity
  rather than listing the tables. The derivation is what makes the RLS gap in ch. 4 free.
- Quote the manual's boolean sentence verbatim for OR-composition — it is short and decisive.
- Frame `partial_revokes` and `mandatory_roles` together as "written outside the model".
- The RBAC verdict must use memo 07's **corrected** paragraph. Explicit prohibition: do not write
  that MySQL lacks `SET ROLE` or role inheritance.
- Prefer "RBAC₁ delimično, jer graf nije parcijalno uređenje" over "nema hijerarhije".
