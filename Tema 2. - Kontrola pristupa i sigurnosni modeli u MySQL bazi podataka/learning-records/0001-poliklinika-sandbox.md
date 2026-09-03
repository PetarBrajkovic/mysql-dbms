# 0001 — Standing up the Poliklinika sandbox (ticket 10)

Not a taught lesson — this is the execution record for ticket 10, which builds ticket 08's
scenario on the live server. Kept in the same index because it settles facts every later
chapter (14–21) needs and must not re-measure.

## What was built

`examples/00-setup/01` through `05`: the `poliklinika` schema (3 branches, 6 tables, ~90
patients/180 visits/180 diagnoses/90 invoices), `dbadmin`@`localhost` (scoped to
`poliklinika.*` plus `CREATE USER`/`ROLE_ADMIN`, no `*.*` beyond that), 4 roles, 12 named
`<role>_<branch>` accounts with default roles set, and `v_my_branch_diagnoses` — an
`INVOKER`-security view emulating branch (row-level) isolation for doctors.

Measured on: **MySQL 8.4.11, Community Server - GPL, Win64** (same install Tema 1 is pinned
to).

## Non-obvious insights

1. **`SELECT *` does NOT bypass column-level privileges on 8.4.11 — corrects memo 04.**
   Memo 04 cited MySQL bug #41354 to claim `SELECT *` against a table where the account only
   holds column-level `SELECT` returns every column, silently leaking ungranted ones.
   Live-tested as `nurse_podgorica` (granted `SELECT (icd_code, ...)` but not
   `diagnosis_text`): `SELECT diagnosis_text FROM diagnoses` gives `ERROR 1143` as expected,
   but `SELECT * FROM diagnoses` gives **`ERROR 1142`** (table access denied), not a silent
   return of all columns. Likely explanation: bug #41354 is contemporaneous with MySQL
   5.0/5.1-era privilege checking; 8.0 rewrote statement-time access checking
   (`request-access.html`'s Stage 2 algorithm memo 03 already documents), and this bypass
   looks to have been closed somewhere in that rewrite. **Correct memo 04 in place**: the
   `SELECT *` gap is not reproducible on this server and the paper must not claim it without a
   version caveat — if anything, `SELECT *` against a column-restricted account is now the
   *safer* failure (an outright denial, not a partial leak).
2. **Role activation works out of the box only because `SET DEFAULT ROLE` was used.**
   `activate_all_roles_on_login` is `OFF` on this server (the default). A fresh connection as
   any demo account already shows `CURRENT_ROLE()` populated with its role — confirms memo
   03/07's account that `SET DEFAULT ROLE` (not just `GRANT ... TO`) is what makes a role
   usable without the client running `SET ROLE` itself.
3. **A view under `SQL SECURITY INVOKER` needs the caller's own grant on every table it
   touches, including tables the view only reads for its filter logic.** First attempt at
   `v_my_branch_diagnoses` failed with `ERROR 1356` for every doctor account, because
   `role_doctor` had no grant at all on `staff` (the view's subquery joins `staff` to resolve
   `CURRENT_USER()` to a `tenant_id`). Fixed by granting `role_doctor` `SELECT` on exactly the
   three `staff` columns the subquery needs. Worth a sentence in the FGAC chapter: `INVOKER`
   security is not free — it moves the privilege requirement onto every account that uses the
   view, not just the view's definer.
4. **`DROP ROLE ... CREATE ROLE` wipes grants made to that role afterwards, including grants
   on views created in a later script.** `04-roles-and-accounts.sql` drops and recreates all
   four roles on every run; `05-tenant-view.sql`'s `GRANT SELECT ON v_my_branch_diagnoses TO
   role_doctor` does not survive a re-run of `04` unless `05` is re-run immediately after.
   Documented as a run-order trap in both scripts and the setup `README.md`.
5. **MySQL option files (`.cnf`) treat `#` as a comment marker even mid-value.** The chosen
   password `DbAdmin#2026` silently truncated to `DbAdmin` when unquoted in
   `mysql-credentials.cnf`, producing `ERROR 1045` that looked like a wrong password rather
   than a parsing issue. Fix: quote the value (`password="DbAdmin#2026"`). Small, but exactly
   the kind of tooling trap worth a footnote if the paper ever shows a credentials file.
6. **`dbadmin` genuinely cannot read `mysql.user`** (`ERROR 1142`), despite holding the global
   `CREATE USER` privilege — a live demonstration that MySQL's administrative dynamic
   privileges (`CREATE USER`, `ROLE_ADMIN`) are checked independently of, and do not imply,
   table-level access to the grant tables themselves. Good evidence for the
   privileges-and-roles chapter's point that `SUPER`'s decomposition is about narrowing what
   an admin account can do, not just renaming one big privilege.

## Proof of enforcement (ticket 10, requirement 4)

All four demo roles produced a real error against something they should not reach:
`recept_podgorica`/`billing_podgorica` → `ERROR 1142` on `diagnoses`; `nurse_podgorica` →
`ERROR 1143` on `diagnosis_text`; raw-table `doc_podgorica` sees all 3 branches (the
deliberately broad grant), `v_my_branch_diagnoses` narrows the same account to its own branch
only, confirmed against two different doctor accounts (`doc_podgorica` → tenant 1 only,
`doc_niksic` → tenant 2 only). Full reproduction steps: `examples/00-setup/06-verify.sql`.

## What comes next

Ticket 11 (audit demonstrability) and the FGAC/RLS chapter (17) build directly on this
sandbox — `v_my_branch_diagnoses` is the artifact ticket 17 teaches around, and insight 3
above is worth a sentence there. Chapter 16 (privilegije i uloge) gets insight 2 and 6 for
free from this record.
