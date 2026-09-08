# examples/03-privilegije-i-uloge

Runnable evidence for chapter 3, "Sistem privilegija i uloga u MySQL-u". Every script runs against
the `poliklinika` sandbox built by `../00-setup/` and cleans up after itself.

| Script | Claim it demonstrates | Connections needed |
|---|---|---|
| `01-nivoi-i-ili-sastavljanje.sql` | Privilege levels compose by **OR**, never by intersection — a narrower grant never narrows a wider one | `dbadmin`, then two throwaway demo accounts |
| `02-uloge-hijerarhija-i-aktivacija.sql` | Role-to-role grants build a hierarchy (`mysql.role_edges`); a granted role is not an active role (`SET ROLE`) | `dbadmin`, then `doc_bar` |
| `03-partial-revokes.sql` | The one deny-shaped thing in a grant-only model, stored as JSON in `mysql.user.User_attributes`, restricting only the global term of the OR chain | **root only** — see below |

## Why 03 needs root

`SET PERSIST partial_revokes` requires `SYSTEM_VARIABLES_ADMIN`, and the demo needs a global
`SELECT ON *.*` that `dbadmin` cannot delegate because it does not hold it. That `dbadmin` is
blocked here is itself the chapter's point about `SUPER`'s decomposition: the account that
administers accounts does not administer the server.

## Ordering trap

`02` creates `role_senior_doctor` and grants it to `doc_bar`. Re-running
`../00-setup/04-roles-and-accounts.sql` at any later point drops and recreates the four base roles,
which destroys that edge (and the view grant from `05-tenant-view.sql`). Re-run `02` afterwards if
the hierarchy demo is needed again.

## Two irreversibilities in 03

Per [8.2.12](https://dev.mysql.com/doc/refman/8.4/en/partial-revokes.html): `partial_revokes`
cannot be switched off while any account still carries a restriction, and while it is on, `_` and
`%` in schema names are read literally. Part D of the script therefore drops the account before
setting the variable back to `OFF`.
