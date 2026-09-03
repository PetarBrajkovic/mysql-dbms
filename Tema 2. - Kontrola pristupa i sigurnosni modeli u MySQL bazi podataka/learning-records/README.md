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

## Standing constraints these records impose on every later chapter

Facts already settled, with the record that settled them. **Do not re-litigate or re-measure these.**

- Sandbox is `poliklinika`: 3 branches, 6 tables, 4 roles, 12 named `<role>_<branch>`
  accounts, `dbadmin`@`localhost` as the paper's own non-root connection. Measured on MySQL
  8.4.11 Community, Win64. (0001)
- `activate_all_roles_on_login` is `OFF` on this server; every demo account has its role set
  as its `DEFAULT ROLE` so a plain login already has it active. (0001)
- Re-running `examples/00-setup/04-roles-and-accounts.sql` requires re-running
  `05-tenant-view.sql` immediately after — `04` drops and recreates the roles, wiping the
  view grant. (0001)

## Corrections filed against the research memos

- **Memo 04** claimed (via MySQL bug #41354) that `SELECT *` bypasses column-level privileges
  and silently returns ungranted columns. **Not reproducible on 8.4.11**: `SELECT *` against
  a column-restricted account returns `ERROR 1142` (table access denied), not a partial leak.
  The paper must not cite this bypass without a version caveat. (0001)
