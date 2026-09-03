# Chapter 7. Multi-tenant bezbednosni modeli

Type: task
Status: open
Blocked by: 07, 08, 09, 10, 16, 17, 18

## Question

Execution ticket - resolves only when all four Definition-of-Done items are done.

**Target length**: ~3.5 pages of `rad.md`.

**Scope**: The closing synthesis, not a fourth access-control model (memo 07's verdict). The three
tenancy patterns (database-per-tenant, schema-per-tenant, shared-schema-with-discriminator), each
justified by reference back to ch. 2's models and ch. 3's roles, each failure mode traced to a
principle violated. The connection-pooling collision stated precisely: a shared pool account blinds
the database to tenant identity, turning row-level isolation (ch. 4) into an application concern.
Closes the least-privilege thread running since ch. 2, landing it explicitly here.

**Definition of done**:
1. The user has been taught this chapter via `/teach` (they must invoke it themselves) and a lesson
   exists in `lessons/`.
2. Runnable SQL committed to `examples/` against the Poliklinika sandbox's three branches
   (ticket 08/10) — the per-branch, per-role accounts as the correct design — with the shared-pool
   account kept as a prose strawman, not built on the server. At least one captioned figure in
   `figures/` per the strategy set in ticket 12 (a schema/pattern comparison diagram fits).
3. Serbian prose appended to `rad.md` **using the `academic-research-writer` skill**, with IEEE
   citations added to `references.bib` as they are used.
4. A learning record written to `learning-records/`, and the work committed.

**Grounding**: research memo 07 (multi-tenant patterns, connection-pooling collision), the running
example's tenant design (ticket 08), the sandbox (ticket 10), and everything ch. 3/4/5 established
about MySQL's actual DAC mechanics.
