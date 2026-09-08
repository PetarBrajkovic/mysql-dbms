# Measurements and artifacts — 0004, chapter 3 (privilegije i uloge)

## Status

`01` and `02` **run by the user on 8.4.11**, same session, Workbench, two connections. `03` not yet
run (needs root). Everything below marked measured is real output; the rest is still manual-sourced.

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

### 01 — OR-composition — MEASURED
- [x] `probe_wide` returned all five `diagnosis_text` values ("Nalaz za posetu #1" … "#5") while
      holding only `SELECT (icd_code)` at column level. The db-level grant alone carried it.
- [x] `probe_narrow`, with the **identical** column privilege and nothing wider, failed:
      `ERROR 1143. SELECT command denied to user 'probe_narrow'@'localhost' for column
      'diagnosis_id' in table 'diagnoses'`
- [ ] `SHOW GRANTS` output for `probe_wide` not captured

**Finding, and a correction to the script as first written.** The error names **`diagnosis_id`**, not
`diagnosis_text`. The server stops at the *first* ungranted column in the select list rather than the
one the query was written to test, so an `ERROR 1143` message is not an inventory of what is
missing. Script and lesson both corrected to say so. Minor but citable: it is the kind of detail
that makes a chapter read as measured rather than paraphrased.

### 02 — roles — MEASURED (this is the claim the map flagged as needing the live server)
- [x] `CURRENT_ROLE()` on fresh login returned `` `role_doctor`@`%` `` — **only** the default role.
      `role_senior_doctor` was granted in the same session and did **not** appear. Granted ≠ active,
      confirmed on this server, with `activate_all_roles_on_login` `OFF` (record 0001).
- [x] `SELECT invoice_id FROM poliklinika.invoices` before `SET ROLE`:
      `ERROR 1142. SELECT command denied to user 'doc_bar'@'localhost' for table 'invoices'` — the
      privilege existed in `tables_priv` under `role_senior_doctor`, but an inactive holder does not
      enter the check at all.
- [x] after `SET ROLE role_senior_doctor`: `invoices` returned rows 1–5.
- [x] `diagnoses` **also** returned rows 1–5 at that point, although `role_doctor` was no longer
      directly active — inheritance across two `role_edges` hops
      (`doc_bar` → `role_senior_doctor` → `role_doctor`), measured.
- [x] after `SET ROLE NONE`: `ERROR 1142 … for table 'diagnoses'`. Same account, same session, same
      statement that had just succeeded.
- [x] `CURRENT_ROLE()` immediately after `SET ROLE role_senior_doctor` returned
      `` `role_senior_doctor`@`%` `` and **nothing else**. `SET ROLE` therefore *sets* the active
      set rather than adding to it — the default role drops out. This was the claim the map flagged
      as needing the live server before it went into a chapter; it is now measured, not sourced.
- [ ] `CURRENT_ROLE()` after `SET ROLE NONE` not captured cleanly (expected literal `NONE`).

**The sharpest consequence, and it was not predicted in advance.** At the moment `CURRENT_ROLE()`
read `` `role_senior_doctor`@`%` `` alone, `SELECT` on `diagnoses` still succeeded — and that
privilege belongs to `role_doctor`, which was no longer in the active set. So `CURRENT_ROLE()`
returns the **active set**, not its transitive closure: inherited roles are in force but invisible.
Good chapter sentence — what `CURRENT_ROLE()` shows is not the list of everywhere your privileges
come from. It also means an auditor reading `CURRENT_ROLE()` alone underestimates a session's
reach, which ch. 6 can reuse.
- [ ] `SHOW GRANTS FOR CURRENT_USER() USING role_senior_doctor` not captured.

**Note for the chapter:** roles are created at host `%` (`` `role_doctor`@`%` ``), so `CURRENT_ROLE()`
prints a fully qualified authorization ID, not a bare name — further evidence that a role is the same
kind of object as an account.

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
