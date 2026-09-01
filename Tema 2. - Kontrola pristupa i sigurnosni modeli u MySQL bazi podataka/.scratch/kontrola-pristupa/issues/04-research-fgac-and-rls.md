# Research: fine-grained and row-level access control — what MySQL has, and what it doesn't

Type: research
Status: open

## Question

The riskiest bullet on the list. **MySQL has no `CREATE POLICY`**: row-level security is not a feature
you can turn on, so the chapter either becomes "here is how it is built" plus "here is what that
cannot enforce", or it has nothing to stand on. Establish which, from primary sources.

Produce a memo at `../research/04-fgac-and-rls.md` covering:
1. **Fine-grained access control that MySQL genuinely has**: column-level privileges
   (`GRANT SELECT (col) ON ...`, `columns_priv`), routine privileges, and the exact granularity
   ceiling — where does the privilege system stop being able to express a rule?
2. **Views as the FGAC mechanism**: `SQL SECURITY DEFINER` vs `INVOKER`, what privileges the definer
   needs, `WITH CHECK OPTION` (`CASCADED` vs `LOCAL`), and updatable-view restrictions. This is the
   load-bearing part — get the semantics exactly right, including what happens when the definer
   account is dropped.
3. **The row-level security emulation pattern**: view + `CURRENT_USER()` / `SESSION_USER()` /
   `USER()`, or a session variable set by the application, or a stored procedure API with no direct
   table access. For each: what it enforces, and **precisely how it is defeated** (session variables
   are attacker-settable if the tenant controls the connection; `CURRENT_USER()` only works if every
   tenant is a real MySQL account, which collides with connection pooling).
4. **The contrast systems**: PostgreSQL `CREATE POLICY` / `ROW LEVEL SECURITY`, and Oracle VPD or
   Label Security. Enough detail, with citable sources, to state what they enforce *in the engine*
   that MySQL cannot. Do not overreach — one accurate paragraph per system beats a survey.
5. Which MySQL features in this space are **Enterprise-only** (data masking, in particular) and must
   therefore be written as theory with the commercial status stated.

Say plainly whether there is enough here for a chapter of its own, or whether row-level security is a
section inside the fine-grained-access-control chapter. That answer feeds ticket 09.
