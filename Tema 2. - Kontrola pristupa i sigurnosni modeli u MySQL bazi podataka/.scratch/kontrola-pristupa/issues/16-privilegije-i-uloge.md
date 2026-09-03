# Chapter 3. Sistem privilegija i uloga u MySQL-u

Type: task
Status: open
Blocked by: 03, 09, 10

## Question

Execution ticket - resolves only when all four Definition-of-Done items are done.

**Target length**: ~4 pages of `rad.md`.

**Scope**: The grant tables as a data model, the two-stage privilege check (OR-composition across
global/db/table/column), static vs. dynamic privileges and `SUPER`'s decomposition,
`partial_revokes` as the one deny-shaped thing in a grant-only model — then MySQL roles judged
against ch. 2's RBAC model **by name**: role activation (`SET ROLE`, `mandatory_roles`,
`activate_all_roles_on_login`) and role-to-role grants (`mysql.role_edges`) exist; separation of duty
does not. Use the **corrected** claim from memo 07, never the deleted wording it replaced.

**Definition of done**:
1. The user has been taught this chapter via `/teach` (they must invoke it themselves) and a lesson
   exists in `lessons/`.
2. Runnable SQL committed to `examples/` against the Poliklinika sandbox (ticket 10) — at minimum,
   the four roles' grants and a `SET ROLE` demonstration — and at least one captioned figure in
   `figures/` per the strategy set in ticket 12 (a role-graph diagram is the natural fit here).
3. Serbian prose appended to `rad.md` **using the `academic-research-writer` skill**, with IEEE
   citations added to `references.bib` as they are used.
4. A learning record written to `learning-records/`, and the work committed. **Verify live**: memo
   03/07's role-activation semantics claim, flagged in the map as needing the live server before it
   goes into a chapter.

**Grounding**: research memo 03 (privileges and roles), the corrected RBAC-gap paragraph in memo 07,
the sandbox built in ticket 10, and `../../GLOSSARY.md` §1–§2a.
