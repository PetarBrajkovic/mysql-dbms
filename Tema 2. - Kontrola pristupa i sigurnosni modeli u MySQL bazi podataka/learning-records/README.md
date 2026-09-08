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
- **A role is a locked row in `mysql.user`** — the same object as an account, differing only in the
  lock. `GRANT role TO x` writes an edge in `mysql.role_edges` and copies **no** privilege; the
  server resolves by walking the graph at check time. (0004)
- **The chapter-3 RBAC verdict, final wording**: RBAC₀ yes (`SET ROLE` is a real session), RBAC₁
  only partially (edges exist, but `role_edges` is a plain digraph, not the partial order NIST
  requires — cycles are nowhere prohibited), RBAC₂ no (no SoD mechanism, structurally: nothing to
  attach a constraint to). **Never write that MySQL lacks `SET ROLE` or role inheritance** — that
  common claim is two-thirds false, and memo 07's deleted paragraph is where it comes from. (0004)
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
