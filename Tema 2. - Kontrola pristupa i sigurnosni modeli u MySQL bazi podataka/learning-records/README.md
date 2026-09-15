# Learning records — index

One record per taught lesson (or, occasionally, per execution ticket that settles facts a
lesson would otherwise re-measure — flagged as such in the record itself). **Read this index
first and open only the records it points you at** — reading all of them costs more context
than any one lesson needs.

Each record holds: what was taught (short), the non-obvious insights worth revisiting, and what
comes next. Measured numbers, produced artifacts and write-up notes are **not** here — they live
in `.scratch/kontrola-pristupa/measurements/<same-filename>` and are only needed when writing or
checking a chapter, never when planning a lesson.

| # | Chapter | Headline | Open it when you are teaching / writing about |
|---|---|---|---|
| [0001](0001-poliklinika-sandbox.md) | 10 (sandbox, pre-chapter) | Sandbox built and enforcing; `SELECT *` does not bypass column privileges on 8.4.11 | Privilegije i uloge (16), FGAC i RLS (17), any chapter that runs a demo against `poliklinika` |
| [0002](0002-audit-log-vs-definer-identity.md) | 19 (audit, pre-chapter) | No free audit plugin loads on this server (nothing to install); general query log records the connecting account, never the `SQL SECURITY DEFINER` view's effective account | Audit logging (19), any mention of `USER()` vs `CURRENT_USER()` |
| [0003](0003-klasicni-modeli-kontrole-pristupa.md) | 15 (klasični modeli) | The whole DAC → Trojan horse → MAC/BLP → RBAC → least-privilege chain, taught by derivation; MySQL's `REVOKE` does not cascade, unlike the SQL standard | Writing ch. 2; any chapter that judges MySQL against a model (3, 4, 7); anything invoking least privilege |
| [0004](0004-privilegije-i-uloge.md) | 16 (privilegije i uloge) | Everything derived from "a privilege is a row in an ordinary table": level count, OR-composition, static=column/dynamic=row, `partial_revokes`, roles as locked accounts, the RBAC verdict | Writing ch. 3; any chapter using roles, `SET ROLE`, grant tables or the RBAC verdict (4, 5, 7) |
| [0005](0005-fgac-i-rls.md) | 17 (FGAC i RLS) | Column is the granularity ceiling because a row has no name; a view is a name for a predicate; filtering is not authorization; the three RLS emulation patterns and how each breaks | Writing ch. 4; any chapter using views, `DEFINER`/`INVOKER`, `USER()` vs `CURRENT_USER()`, or tenant isolation (5, 6, 7) |

## Standing constraints these records impose on every later chapter

Facts already settled, with the record that settled them. **Do not re-litigate or re-measure these.**

- Sandbox is `poliklinika`: 3 branches, 6 tables, 4 roles, 12 named `<role>_<branch>`
  accounts, `dbadmin`@`localhost` as the paper's own non-root connection. Measured on MySQL
  8.4.11 Community, Win64. (0001)
- `activate_all_roles_on_login` is `OFF` on this server; every demo account has its role set
  as its `DEFAULT ROLE` so a plain login already has it active. (0001)
- Re-running `examples/00-setup/04-roles-and-accounts.sql` requires re-running
  `05-tenant-view.sql` immediately after - `04` drops and recreates the roles, wiping the
  view grant. (0001)
- **MySQL's `REVOKE` does not cascade.** In standard SQL, revoking a privilege also revokes
  everything granted on the strength of it; MySQL removes privileges only explicitly, via
  `REVOKE` or `DROP USER`, and the manual states the difference itself (8.4 refman 15.7.1.6,
  "MySQL and Standard SQL Versions of GRANT"). A privilege delegated with `WITH GRANT OPTION`
  outlives the grant it grew from. Do not write "kaskadno oduzimanje" as MySQL behaviour — it is
  model/standard behaviour only. **Measured on 8.4.11**, not just sourced. (0003)
- **`REVOKE <priv>` does not remove `GRANT OPTION`.** Measured: revoking `SELECT` left
  `GRANT USAGE ON … WITH GRANT OPTION` on the account. `USAGE` means "no privileges"; the
  delegation capability needs its own `REVOKE GRANT OPTION ON …`, and per the manual it covers
  privileges the account "may be given in the future". (0003)
- **`mysql.tables_priv` has a `Grantor` column that the server does not use** — the manual says it
  is set to `CURRENT_USER` "but otherwise unused" (8.4 refman 8.2.3). Use this whenever the paper
  argues that non-cascading revoke is a design decision rather than a data limitation. (0003)
- Saltzer & Schroeder 1975 supplies **two** citable principles for this paper, not one: least
  privilege (f) and fail-safe defaults (b, *"Base access decisions on permission rather than
  exclusion"*), the latter describing MySQL's grant-only model exactly. Memo 07 cites only (f). (0003)
- **Privilege levels compose by `OR`, never by intersection**: `(global − restrictions) OR db OR
  table OR column OR routine`, quoted verbatim from 8.4 refman 8.2.7. A narrower grant therefore
  **never** narrows a wider one — least privilege is achieved by not granting the wider one at all.
  Never write that a column privilege "restricts" an account that also holds a db- or global-level
  privilege. (0004)
- **Static privilege = a column in `mysql.user`; dynamic privilege = a row in
  `mysql.global_grants`.** Consequences to reuse rather than re-derive: the static list is frozen
  per server version, dynamic privileges exist **only** at global scope, and dynamic global
  privileges take effect on already-open sessions while static global ones apply only to new
  connections (8.2.13). (0004)
- **`partial_revokes` is the only deny-shaped thing, and it is narrow**: schema level only, stored
  as JSON in `mysql.user.User_attributes`, and it subtracts **only from the global term** of the OR
  chain — a table-level grant inside the restricted schema still works. Its schema-only limit is a
  design decision, not a consequence of the model. (0004)
- **`SET ROLE` sets the active set, it does not add to it**, and **`CURRENT_ROLE()` returns that
  active set, not its transitive closure**. Measured on 8.4.11: after `SET ROLE role_senior_doctor`
  the default `role_doctor` dropped out of `CURRENT_ROLE()`, yet a privilege belonging to
  `role_doctor` still worked through the role graph. Inherited roles are in force but invisible —
  reusable in ch. 6, since `CURRENT_ROLE()` alone understates a session's reach. (0004)
- **`ERROR 1143` names the first ungranted column in the select list**, not the column the query was
  written to test. Measured. Do not present an `ERROR 1143` message as an inventory of what an
  account is missing. (0004)
- **A role is a locked row in `mysql.user`** — the same object as an account, differing only in the
  lock. `GRANT role TO x` writes an edge in `mysql.role_edges` and copies **no** privilege; the
  server resolves by walking the graph at check time. (0004)
- **The chapter-3 RBAC verdict, final wording**: RBAC₀ yes (`SET ROLE` is a real session), RBAC₁
  only partially (edges exist, but `role_edges` is a plain digraph, not the partial order NIST
  requires — cycles are nowhere prohibited), RBAC₂ no (no SoD mechanism, structurally: nothing to
  attach a constraint to). **Never write that MySQL lacks `SET ROLE` or role inheritance** — that
  common claim is two-thirds false, and memo 07's deleted paragraph is where it comes from. (0004)
- **Filtering is not authorization.** A view's `WHERE` is run by the query executor, not the privilege
  subsystem: a failed privilege check gives `ERROR 1142`, a failed predicate gives an empty result. A
  view therefore isolates **only** if the account has no access to the base table — grants compose by
  `OR`, so a direct query bypasses it. Never write that a view adds a row-level privilege check. (0005)
- **`SQL SECURITY` selects *whose* privileges are checked, not *when* or *at what level*.** Checking
  stays in Stage 2, per request. Only `DEFINER` can form a security boundary; `INVOKER` requires the
  caller to hold the base-table grants anyway. In definer context only the definer's **default** roles
  are active unless `activate_all_roles_on_login` is on — it is `OFF` here (0001). (0005)
- **`USER()` is frozen at login and can never be the definer**; `CURRENT_USER()` is the matched
  `mysql.user` row and becomes the definer inside definer context. **Measured on 8.4.11** in one
  result row: `doc_podgorica@localhost` (connected) next to `dbadmin@localhost` (checked). The two
  also differ without any view, through wildcard host matching — but that part is *not* what the
  capture shows, so do not cite it as such. (0005)
- **A view's `WHERE` does not constrain writes** unless `WITH CHECK OPTION` is present (defaults to
  `CASCADED` when the clause is given, to no checking when absent — refman 27.5.4). **Measured**: the
  unguarded `INSERT` of another tenant's row reported `1 row(s) affected`, the guarded one failed with
  `Error Code: 1369. CHECK OPTION failed 'poliklinika.v_sa_proverom'`, and the row was then visible in
  the base table (`1 row`) but not through the view that accepted it (`0 rows`). This is a default,
  not a limitation: the candidate row's values are available before the write. (0005)
- **MySQL Enterprise Data Masking is not an RLS substitute** — it hides values, it does not prevent
  row access, and it is commercial. (0005)
- No third-party audit plugin (Percona `audit_log`, MariaDB `server_audit`) is installed or
  installable on this server: `SHOW PLUGINS` shows no `AUDIT`-class plugin beyond the two
  built-in cache cleaners, and the plugin directory has no such `.dll` to attempt loading.
  `dbadmin` cannot toggle `general_log` (needs `SUPER`/`SYSTEM_VARIABLES_ADMIN`); any future
  general-log capture must be run by root, by hand, same as ticket 11. (0002)

## Corrections filed against the research memos

- **Memo 04** claimed (via MySQL bug #41354) that `SELECT *` bypasses column-level privileges
  and silently returns ungranted columns. **Not reproducible on 8.4.11**: `SELECT *` against
  a column-restricted account returns `ERROR 1142` (table access denied), not a partial leak.
  The paper must not cite this bypass without a version caveat. (0001)
