# Research: access-control theory and multi-tenant security models

Type: research
Status: resolved

## Question

Two bullets — *kontrola pristupa i sigurnosni modeli* and *multi-tenant security modeli* — need
material that is **not** in the MySQL manual, and the paper's first chapters cannot be written from
vendor documentation alone. This ticket finds the citable backbone.

Produce a memo at `../research/07-models-and-multitenancy.md` covering:
1. **The classical models**, each with its primary citable source and a one-paragraph definition
   sharp enough to classify a real system: DAC, MAC (and where Bell–LaPadula belongs), RBAC, ABAC.
   The Sandhu et al. RBAC paper and the NIST RBAC standard are the obvious anchors; find the exact
   references, with years and venues, in a form that goes straight into `references.bib`.
2. **Where MySQL sits.** Classify MySQL's privilege system against those definitions and defend the
   classification: it is discretionary, object-based, grant-only, with an ownership notion that is
   weaker than Oracle's. State what it is *not* — there is no MAC, no labels, no ABAC. Support each
   claim with something citable rather than with an assertion.
3. **The least privilege principle**: its origin (Saltzer & Schroeder, 1975 — get the exact citation)
   and what it means operationally for a DBMS. Note whether this reads as a chapter or as a thread
   running through every chapter; the map currently suspects the latter.
4. **Multi-tenancy patterns**, with sources rather than blog folklore: database-per-tenant,
   schema-per-tenant, shared-schema-with-discriminator. For each: which MySQL mechanism enforces the
   isolation (separate accounts and `GRANT` scope, `partial_revokes`, view-based row filtering),
   what it costs at scale (accounts, connections, pooling, migrations), and where it fails.
5. **The connection-pooling collision**, stated precisely: pooled applications connect as one MySQL
   account, so the database cannot see the tenant, so every per-user mechanism above stops applying.
   This is the sharpest thing the multi-tenancy chapter can say — find whether it can be cited.

Say whether this is enough for its own chapter, or whether multi-tenancy is the paper's closing
synthesis chapter that reuses everything before it. That answer feeds ticket 09.

## Answer

Findings: [`research/07-models-and-multitenancy.md`](../research/07-models-and-multitenancy.md)

The paper's theoretical backbone, with **full bibliographic detail for 15 references** ready for
`references.bib`: Sandhu et al. 1996 (IEEE Computer 29(2), 38-47, DOI 10.1109/2.485845),
Ferraiolo & Kuhn 1992, ANSI/INCITS 359-2004, NIST SP 800-162 for ABAC, Bell & LaPadula (MITRE
TR-2547), the TCSEC/Orange Book, and - the one the least-privilege thread needs - **Saltzer &
Schroeder 1975, Proc. IEEE 63(9), 1278-1308, DOI 10.1109/proc.1975.9939**, with the principle's
exact wording.

Least privilege is judged to be **a thread through every chapter, not a chapter**. Multi-tenancy is
judged to be **the closing synthesis chapter** that reuses everything before it. Both feed ticket 09
as recommendations, not decisions.

**The best thing in the memo** is the connection-pooling collision stated precisely: a pooled
application connects as one MySQL account, so the database cannot see the tenant, so every per-user
mechanism collapses into application-level enforcement. It is what ties the multi-tenancy chapter
back to the RLS chapter, and it is citable through AWS SaaS and Azure architecture guidance.

**One error corrected in place at charting, before acceptance.** The memo claimed MySQL roles lack
"role sessions - no `SET ROLE` command" and "role hierarchy - no inheritance". **Both are false**:
`SET ROLE`, `SET DEFAULT ROLE` and `activate_all_roles_on_login` exist, and `GRANT role TO role`
builds a graph stored in `mysql.role_edges`. Memo 03 has it right. A correction block now sits in
the memo at that paragraph, with the defensible narrower claim written out - a role and a user are
the same object, there is no separation of duty, and there is no constrained RBAC session beyond the
active-role set. **Ticket 09 must not adopt the deleted wording**, and ticket 10 verifies it live.
This is why sister memos get cross-read before they are trusted.
