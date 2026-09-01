# Research: MySQL's privilege system and roles (RBAC)

Type: research
Status: open

## Question

Two of the professor's bullets — *privilege management* and *RBAC* — rest on the same machinery, and
this is the material most likely to become the paper's centre. Establish what is actually there in
**MySQL 8.4**, from primary sources only: the MySQL 8.4 reference manual first, then worklogs and the
`mysql-8.4.x` source tree where the manual is silent (Tema 1 cites both; see its `references.bib`).

Produce a memo at `../research/03-privileges-and-roles.md` covering:
1. **The grant tables as a data model** — `mysql.user`, `db`, `tables_priv`, `columns_priv`,
   `procs_priv`, `proxies_priv`, `global_grants`, `role_edges`, `default_roles`, `password_history`.
   Which privilege level each one holds, and how they compose.
2. **How a privilege is actually checked** at statement time: the order of levels, when the in-memory
   copy is loaded, what `FLUSH PRIVILEGES` really does, and what happens on `GRANT` in a live
   connection.
3. **Static vs dynamic privileges**, and the deprecation of `SUPER` into named dynamic privileges —
   a genuinely citable design change with a rationale, and good paper material.
4. **Roles**: `CREATE ROLE`, `GRANT role TO user`, `SET ROLE`, `SET DEFAULT ROLE`, `mandatory_roles`,
   `activate_all_roles_on_login`, role graphs and cycles, `SHOW GRANTS ... USING`, and what
   `WITH ADMIN OPTION` means. Critically: **how close is this to the NIST RBAC model** — are there
   sessions, is there role hierarchy, is there separation of duty? Name the gaps precisely; the
   contrast is worth more to the paper than the feature list.
5. **`partial_revokes`** and schema-level restrictions — the closest MySQL comes to a deny rule, and
   an odd one, since the privilege model is otherwise grant-only.
6. **What cannot be shown on a free Community server**, if anything, flagged for the map.

Flag any claim that ought to be checked against the live server rather than trusted; Tema 1's live
server corrected its research memos more than once.
