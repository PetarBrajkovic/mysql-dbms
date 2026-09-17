# 0008 — Multi-tenant: tenant is neither subject nor object (chapter 7)

Taught lesson. Artifacts: `lessons/0006-multi-tenant.html`, `reference/06-multi-tenant.html`, live
log `lessons-live/0006-multi-tenant.md`. Chapter 7 is the closing synthesis (~3.5 pages). `rad.md`
was **not** written this session; no server state was touched (the pool account stays a prose
strawman, as the ticket requires).

## What was taught

The chapter's argument, derived rather than asserted:

1. **The database's vocabulary is the (subject, object, operation) triple**, and each coordinate has
   a concrete MySQL filling: subject = the selected `mysql.user` row (`CURRENT_USER()`), object =
   what a `GRANT` *names*, operation = the privilege. **The word "tenant" appears nowhere in it.**
2. **Therefore the tenant boundary can only be written as a difference in subject or in object** —
   operation is fixed. That single move generates the whole pattern taxonomy mechanically.
3. **Both differ → silo** (database-per-tenant, core enforces). **Neither differs → pool** (boundary
   falls on the row; the row has no name; ch. 4's granularity ceiling applies).
4. **The middle pattern does not exist in MySQL** — `CREATE SCHEMA` is a synonym for
   `CREATE DATABASE`, so "schema-per-tenant" *is* database-per-tenant.
5. **The connection-pooling collision**, built on the repaired `CURRENT_USER()` node.
6. **Least privilege landed as a measurable quantity**: how many tenants one account *may* reach.

## Probe result (Phase 1)

- **Floor, solid:** ch. 5's core-vs-plugin criterion — answered cleanly and fast on a *new* case (an
  LDAP authentication plugin). Record 0007 flagged it as inference-capable but not automatic; **it is
  now automatic.** That retrieval item is closed.
- **Floor, solid:** `OR`-composition (a narrower grant never narrows a wider one) and the column
  privilege's meaning — both clean.
- **Ceiling, and the session's main find:** `USER()` / `CURRENT_USER()` were **inverted**. He holds
  the `SQL SECURITY DEFINER` instance perfectly (answered it correctly, twice over two lessons) but
  as a *memorised pair*, not as the general rule. Asked about wildcard host matching with no view in
  sight, he said `CURRENT_USER()` varies per connection and `USER()` is the stable one — exactly
  backwards. Two consecutive misses pinned it.
- **Second ceiling, a reflex rather than a gap:** when a question carries the word *tenant*, he
  reaches for a database mechanism instead of answering "the database has nothing here". He picked
  `GRANT SELECT (tenant_id)` as row isolation, then — one question later, same fact without the
  tenant framing — described column privileges correctly. Not a regression in ch. 4; a framing
  effect.
- Seven of seven correct after the probe, including the repaired node and the closing synthesis.

## Non-obvious insights worth revisiting

1. **The taxonomy is a derivation, not a list.** Because the triple has exactly two coordinates that
   may vary by tenant, "how many of them do we actually differentiate?" enumerates the patterns
   exhaustively — the same rhetorical shape as ch. 6's four criteria. The chapter never has to defend
   "why these three".
2. **`schema-per-tenant` is a terminology import, and it is false on MySQL.** Memo 07 describes it as
   table prefixes; the 8.4 manual says `CREATE SCHEMA` is a synonym for `CREATE DATABASE`. Primary
   sources back this up by *not* using the name: AWS says **silo / bridge / pool**, Azure says
   standalone / database-per-tenant / sharded multi-tenant. The real MySQL middle case (a table set
   per tenant in one database) introduces **no new grant scope**, so it is a *worse variant of silo*,
   not a compromise between silo and pool. **Correction filed against memo 07 — see below.**
3. **The precise wording for the pool verdict is "the database is excluded from the decision", not
   "the database is weaker".** MySQL's DAC check runs at full strength under a pool; it just runs
   over coordinates that do not include the tenant. He got the closing synthesis question right on
   exactly this distinction, rejecting "MySQL ne sprovodi ništa".
4. **Isolation and attribution are one defect with two faces.** Isolation fails *forwards* (nothing
   to refuse on), attribution fails *backwards* (nothing to record). Same sentence causes both: the
   tenant identity never entered the server. This is the chapter's closing argument and it is what
   makes ch. 7 a synthesis rather than a fourth model — it needs ch. 6's criteria to even state.
5. **Least privilege becomes a number here: how many tenants one account *may* reach, not how many it
   does.** He produced this himself ("sve — grant imenuje tabelu"). Combined with `OR`-composition it
   yields the chapter's landing sentence: *the choice of tenancy pattern is the least-privilege
   decision, made once at design time and not repairable by grants afterwards.*
6. **The repaired `CURRENT_USER()` node has a consequence worth reusing**: the number of identities
   the database can distinguish is the number of rows in `mysql.user`, not the number of humans. That
   one sentence is the whole pooling collision, and it is the cleanest way to state it in the paper.
7. **The manual's own anonymous-account example is the best teaching instrument for the split**
   (`USER()` = `'davida@localhost'` while `CURRENT_USER()` = `'@localhost'`) — the user names differ,
   not just the hosts, which kills the inversion in one line. Worth reusing in ch. 7's prose or in a
   figure caption, since `dbadmin` cannot `SELECT` from `mysql.user` to demonstrate it live.

## Corrections filed

- **Memo 07** describes *schema-per-tenant* as a distinct MySQL pattern realised by table prefixes
  (`t1_users`, `t2_users`). **False on MySQL**: `CREATE SCHEMA` is a synonym for `CREATE DATABASE`
  (8.4 refman 15.1.12), so the pattern collapses into database-per-tenant. The paper must present
  **two** enforceable patterns plus a degenerate middle, and should say explicitly that the
  three-pattern framing is borrowed from systems where schema ≠ database. Verified against the
  manual, not measured (no server state needed).
- Nothing else in memo 07 was contradicted this session; the connection-pooling section held up.

## What comes next

Chapter 7's prose, in a separate session, from this record: the triple-as-vocabulary opening, the
two-coordinate derivation of the patterns, the `schema = database` correction stated openly, the
pooling collision with isolation and attribution as one defect, and the least-privilege thread landed
as the closing sentence. Ticket 20's remaining DoD items are the SQL in `examples/` (the per-branch
accounts as the correct design — mostly already in `examples/00-setup/`), at least one captioned
figure (a pattern-comparison diagram, Mermaid per ticket 12), the Serbian prose with
`academic-research-writer`, and new `references.bib` entries for the AWS and Azure sources.

**Figure 7.1 is already built** (this session, outside the lesson proper):
`figures/07-multi-tenant-01-obrasci-stablo-odluke.png`, Mermaid source kept at
`figures/raw/07-multi-tenant-01-obrasci-stablo-odluke.mmd`. It draws the two-coordinate derivation
as a decision tree with the four patterns as leaves, each leaf carrying reach / who enforces / cost,
plus the `schema = database` note. Caption to use from `rad.md`:

> `![Slika 7.1: Izbor multi-tenant obrasca kao stablo odluke. Dva pitanja — razlikuju li se objekti, razlikuju li se nalozi — iscrpljuju sve mogućnosti, pa četiri obrasca nisu spisak nego posledica.](figures/07-multi-tenant-01-obrasci-stablo-odluke.png)`

Layout trap recorded in the `.mmd` header: the dotted note edge must hang off the SILO node, not
off the second decision diamond — attaching it to the diamond makes Mermaid flip the root's branches
and the pool (bad) side lands on the left, reversing the reading order. After
that only chapter 8 (Zaključak) remains, and it must reconcile against ch. 1's roadmap.
