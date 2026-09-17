# Chapter 8. Zaključak

Type: task
Status: closed
Blocked by: 14, 15, 16, 17, 18, 19, 20

## Question

Execution ticket - resolves only when all four Definition-of-Done items are done.

**Target length**: ~1 page of `rad.md`.

**Scope**: Close the argument opened in ch. 1: revisit the paper's spine (`GLOSSARY.md` §0) against
what chapters 2–7 actually showed — where MySQL composes a modern requirement from its DAC base, and
where it names an absence instead. Reconcile with ch. 1's roadmap, exactly as Tema 1's own note
recommended (intro and conclusion written in different sessions, reconciled once both exist).

**Definition of done**:
1. Teaching is optional here per `../../WORKFLOW.md` (a conclusion needs no lesson); use judgment.
2. No new SQL or figures expected — this chapter is prose synthesis. If ticket 12's strategy calls
   for a closing summary figure, that is a candidate here, not a requirement.
3. Serbian prose appended to `rad.md` **using the `academic-research-writer` skill**, with any closing
   citations added to `references.bib`.
4. A learning record written to `learning-records/` if anything non-obvious surfaced while closing
   the argument, and the work committed.

**Grounding**: `../../GLOSSARY.md` §0 (the spine) and every chapter it is judged against — reread
ch. 1's roadmap (ticket 14) before writing this one.

## Resolution

All DoD items done.

1. **No lesson taught**, by the ticket's own judgment clause and `../../WORKFLOW.md` (a conclusion
   needs none; ch. 1 was handled identically).
2. **No new SQL, no new figure.** Ticket 12's budget gives Zaključak none, and a closing summary
   figure was considered and rejected: the conclusion's synthesis is a table of six absences that
   reads better as prose than as a diagram, and the paper already sits at the top of its page budget.
3. **`rad.md` §8 written with `academic-research-writer`**, ~660 words / ~1 page, in five paragraphs:
   the thesis restated, then the two sides of it separated. Composed-from-DAC side: the grant tables
   and the two-stage check, RBAC0 full / RBAC1 partial (`mysql.role_edges` is not a partial order),
   column privileges plus definer views, and the silo tenancy pattern enforced by the core. Absent
   side: MAC/Bell–LaPadula entirely, RBAC2 structurally, RLS as an enforcement point inside query
   processing (against PostgreSQL `CREATE POLICY` and Oracle VPD), attribution in the audit
   instruments, and pool-pattern tenant isolation.

   **The chapter's own contribution** (not stated by any single earlier chapter): those six absences
   are *one* finding. MySQL's vocabulary has three coordinates (subject = the `mysql.user` row,
   object = what `GRANT` names, operation = the privilege), and each absence is exactly one rule that
   cannot be written in it: a security class (ch. 2), a constraint over a pair of roles (ch. 3), a
   predicate over a row (ch. 4), the shape of a statement (ch. 5), the effective identity in a log
   record (ch. 6), and tenant itself (ch. 7). The corollary follows: where the model cannot express a
   rule, MySQL does not extend the grant schema, it writes the rule outside it, moving the
   enforcement point from the server core onto the discipline of whoever wrote the view, procedure or
   application. Closes on least privilege as a design-time decision, unrepairable later because
   levels compose by `OR`, and names the commercial-only mechanisms as covered in theory only and as
   the natural direction of further work.

   **No new `references.bib` entries** — every claim recites a key already seeded
   (`mysql84refman`, `ramakrishnan2003`, `sandhu1996`, `incits2004`, `postgresrls2024`,
   `oraclevpd2024`, `nistsp80092`, `saltzerschroeder1975`). All 15 entries now resolve, and the
   export runs with zero unresolved keys. No em dash; impersonal *se* throughout; terminology taken
   from `GLOSSARY.md` §1 (*pripisivost*, *evidencioni trag*, *klasa sigurnosti*, *domašaj*).
4. **Reconciliation with ch. 1 came back clean**: the intro's roadmap sentence for ch. 8 ("sumira
   nalaze i zaokružuje odgovor na tezu") matches what was written, and the two-sided split uses the
   intro's and `GLOSSARY.md` §0's own wording. **No edit to ch. 1 was needed.**
5. Learning record [0009](../../../learning-records/0009-zakljucak.md) written (the six-absences
   table and the "precisely bounded, not weak" defense line), index row added. Export re-verified
   clean via `..\tools\make-docx.ps1`. **Rendered page count still has to be read in Word** —
   ch. 7 measured 22 pages with 1 page budgeted here, so ~23 expected, inside the 20-25 soft target;
   ticket 13 measures it for real.

**The paper's prose is now complete**; only ticket 13 (final export, bibliography, consistency pass,
hand-off) remains.
