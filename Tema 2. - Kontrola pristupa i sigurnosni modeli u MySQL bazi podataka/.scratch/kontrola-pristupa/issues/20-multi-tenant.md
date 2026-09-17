# Chapter 7. Multi-tenant bezbednosni modeli

Type: task
Status: closed
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

## Resolution

All four DoD items done. Lesson had been taught in the prior session
(`lessons/0006-multi-tenant.html`, learning record
[0008](../../../learning-records/0008-multi-tenant.md)); this session wrote the chapter.

`rad.md` §7, ~1440 words, with `academic-research-writer`: the chapter opens on the database's
own vocabulary (subject = the selected `mysql.user` row named by `CURRENT_USER()`, object = what
`GRANT` names, operation = the privilege) and the observation that *tenant* appears in none of the
three coordinates. From there the pattern taxonomy is **derived, not listed**: operation is fixed,
so only object and subject may differ per tenant, and the two questions exhaust the space. Silo
(database-per-tenant) is enforced by the core in the second step; the pool boundary falls on the
row, which has no name, so ch. 4's granularity ceiling applies. The pool verdict is stated in the
lesson's exact wording: the database is not weaker, it is **excluded from the decision**. Then the
connection-pooling collision (one pool account = one row in `mysql.user` = one `CURRENT_USER()`
for every tenant, with the manual's anonymous-account example fixing the `USER()`/`CURRENT_USER()`
split), the `SET @tenant_id` patch shown failing by measurement, and the closing argument that
isolation (forwards) and attribution (backwards) are one defect, tied back to ch. 6's criteria.
The least-privilege thread lands as a measurable quantity: how many tenants an account *may*
reach, unrepairable afterwards because levels compose by `OR`.

**Memo 07 correction carried into the paper as written**: *schema-per-tenant* is not a third MySQL
mechanism (`CREATE SCHEMA` is a synonym for `CREATE DATABASE`); the borrowed name is called out
explicitly, and the vendors' own naming (AWS silo/bridge/pool, Azure standalone/database-per-tenant/
sharded multitenant) is cited instead. Both vendor pages were fetched and read before citing;
`awssaaslens` and `azuretenancy` added to `references.bib` (15 entries, all resolving).

New SQL in `examples/07-multi-tenant/` (read-only, run as `doc_bar`): `01-domasaj-naloga.sql`
measures reach (all three branches through the base table, one through `v_my_branch_diagnoses`,
and a `SHOW GRANTS` with no mention of a branch) and `02-krpa-korisnicka-promenljiva.sql` shows
one `SET @tenant_id` assignment moving the same account into another branch. Captures in
`.scratch/kontrola-pristupa/measurements/0008-multi-tenant.md`. **The shared-pool account was
never created** — it stays a prose strawman, as the ticket required. No silo script either: it
would need new server state to prove what ch. 3's two-stage check already proves.

Figure 7.1 was built in the lesson session; this session only removed an em dash from one leaf
node (`../../../../WRITING.md` rule 8 applies to figure text too) and re-rendered from
`figures/raw/07-multi-tenant-01-obrasci-stablo-odluke.mmd`.

Export re-verified: `rad.docx` builds clean, 0 unresolved citation keys, **22 rendered pages** with
only ch. 8 (1 page budgeted) left, i.e. inside the 20-25 soft target with no trimming needed.
