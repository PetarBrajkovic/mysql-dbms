# Research: fine-grained and row-level access control — what MySQL has, and what it doesn't

Type: research
Status: resolved

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

## Answer

Findings: [`research/04-fgac-and-rls.md`](../research/04-fgac-and-rls.md)

The fullest of the five memos (~1900 words, 25+ primary URLs). Column-level privileges and the
1142/1143 error distinction documented - **1143 names the column, so the error itself leaks that the
column exists**. Definer/invoker semantics, `WITH CHECK OPTION` `CASCADED` vs `LOCAL`, and what
happens to a view whose `DEFINER` account is dropped, all covered.

**Three row-level-security emulation patterns**, each with how it is defeated: `CURRENT_USER()`
views (needs one real MySQL account per tenant, so it collides with pooling), session variables
(settable by anyone who controls the connection), and a stored-procedure API with no direct table
grants. The `USER()` / `SESSION_USER()` / `CURRENT_USER()` distinction under `SQL SECURITY DEFINER`
is the technical heart of it, and it recurs in the audit ticket.

**Flagged for live verification**: the memo claims `SELECT *` bypasses column privileges, citing a
2009 bug report. That would be a startling security claim to put in a paper on the strength of an
old bug entry - **ticket 10 must test it directly**, and the chapter states whatever the server
actually does.

**Verdict**: row-level security is a *section* inside a fine-grained-access-control chapter, not a
chapter of its own - MySQL's *absence* of native RLS is the point, and a whole chapter of absence
does not sustain itself. PostgreSQL `CREATE POLICY` and Oracle VPD/Label Security are the cited
contrasts. Enterprise Data Masking confirmed commercial.
