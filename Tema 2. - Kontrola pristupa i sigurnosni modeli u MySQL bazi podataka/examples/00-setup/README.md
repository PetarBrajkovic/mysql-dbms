# 00-setup

Builds the "Poliklinika" sandbox from ticket 08's design: a small multi-branch outpatient
clinic (3 branches, 6 tables, 4 roles, 12 named accounts) that every later chapter runs its
demos against. Design rationale lives in `.scratch/kontrola-pristupa/issues/08-running-example.md`;
this folder is the execution (ticket 10).

## Run order and who runs each script

| # | Script | Run as | What it does |
|---|---|---|---|
| 1 | `01-schema.sql` | **root** | Creates the `poliklinika` schema and its 6 tables. |
| 2 | `02-seed.sql` | **root** | Seeds ~90 patients, ~180 visits, ~180 diagnoses, ~90 invoices. |
| 3 | `03-dbadmin-account.sql` | **root** | Creates `dbadmin`@`localhost` - scoped to `poliklinika.*` plus `CREATE USER`/`ROLE_ADMIN`, nothing global beyond that. Every script after this one runs as dbadmin, not root. |
| 4 | `04-roles-and-accounts.sql` | **dbadmin** | Creates the 4 roles and the 12 `<role>_<branch>` demo accounts, grants each account its role as its default role. |
| 5 | `05-tenant-view.sql` | **dbadmin** | Creates `v_my_branch_diagnoses`, the branch-filtered view that emulates row-level security (MySQL has none natively - memo 04). |

Root is used **only** for steps 1-3. `mysql-credentials.cnf` (gitignored) points at `dbadmin`,
not root - this paper's own connection, and the figure pipeline, never run as root. A
root-capable path stays available for anyone re-running the setup from scratch.

```
mysql -u root -p poliklinika < 01-schema.sql        # or without `poliklinika` - the script USEs it
mysql -u root -p              < 02-seed.sql
mysql -u root -p              < 03-dbadmin-account.sql
mysql --defaults-extra-file=../../mysql-credentials.cnf < 04-roles-and-accounts.sql
mysql --defaults-extra-file=../../mysql-credentials.cnf < 05-tenant-view.sql
```

Re-running from `01` is always safe: `01` drops and recreates the schema, `02` truncates
before reseeding, `03` and `04` drop-if-exists their users/roles before recreating them.
**One ordering trap**: `04` drops and recreates all four roles, which wipes any grant made
directly to a role afterwards - including `05`'s `GRANT SELECT ON v_my_branch_diagnoses TO
role_doctor`. Always re-run `05` immediately after any re-run of `04`.

## Accounts

All 12 demo accounts share one password (`Demo#2026`) and are host-locked to `localhost` -
this is a local teaching sandbox with no `validate_password` component installed, not a
production system; do not reuse this password anywhere real. `dbadmin`'s password is
`DbAdmin#2026`. Both are recorded here (not secret) because this whole schema is throwaway
and rebuilt from these scripts, per `../../.gitignore`'s policy on `mysql-credentials.cnf`
itself.

| Branch | Receptionist | Nurse | Doctor | Billing |
|---|---|---|---|---|
| Podgorica | `recept_podgorica` | `nurse_podgorica` | `doc_podgorica` | `billing_podgorica` |
| Niksic | `recept_niksic` | `nurse_niksic` | `doc_niksic` | `billing_niksic` |
| Bar | `recept_bar` | `nurse_bar` | `doc_bar` | `billing_bar` |

## What `06-verify.sql` and the learning record cover

`06-verify.sql` is the proof-of-enforcement script (real `ERROR 1142`/`1143` from restricted
accounts) plus the three research claims ticket 08 flagged for live testing:

1. Does `SELECT *` bypass `role_nurse`'s column-level grant on `diagnoses` (memo 04, bug
   #41354)?
2. Does a demo account's default role activate on a plain login, given
   `activate_all_roles_on_login` is `OFF` on this server (memo 03/07)?
3. Does `v_my_branch_diagnoses` actually block a doctor from another branch's rows?

Findings, including anything that corrected a research memo, are in the learning record, not
here or in `NOTES.md`.
