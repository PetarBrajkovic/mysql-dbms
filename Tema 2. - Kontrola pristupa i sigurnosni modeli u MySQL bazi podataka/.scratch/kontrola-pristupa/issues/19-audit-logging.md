# Chapter 6. Audit logging

Type: task
Status: closed
Blocked by: 06, 09, 10, 11

## Question

Execution ticket - resolves only when all four Definition-of-Done items are done.

**Target length**: ~2 pages of `rad.md`.

**Scope**: The shortest chapter, earning its space with an argument rather than a feature list:
MySQL Community's free instruments (general query log, error log, `performance_schema` as a ring
buffer) judged against NIST SP 800-92's criteria (completeness, retention, tamper resistance,
accountability) and found to fail tamper resistance — they are *instruments, not an audit trail*,
stated in exactly those terms. MySQL Enterprise Audit is named as the commercial reference point, not
demoed. Closes with the chapter's real payload: the same statement run as two accounts, once directly
and once through a `SQL SECURITY DEFINER` view, showing which identity the log records.

**Definition of done**:
1. The user has been taught this chapter via `/teach` (they must invoke it themselves) and a lesson
   exists in `lessons/`.
2. Runnable SQL committed to `examples/` capturing whatever ticket 11 got working (general query log
   plus the definer-view identity comparison), and at least one captioned figure in `figures/` — a
   log extract, per the strategy set in ticket 12.
3. Serbian prose appended to `rad.md` **using the `academic-research-writer` skill**, with IEEE
   citations added to `references.bib` as they are used. **Verify the NIST SP 800-92 and PCI-DSS
   citations against the actual documents before writing them in** — memo 06 flagged them as not
   fully fetched.
4. A learning record written to `learning-records/`, and the work committed.

**Grounding**: research memo 06 (audit logging: free vs. commercial), ticket 11's execution of its
recommendation, and `../../GLOSSARY.md` §1 for the audit log/trail gloss.

## Resolution

All four DoD items done. Lesson taught (`lessons/0005-audit-logging.html`), learning record
[0007](../../../learning-records/0007-audit-logging.md) written. `rad.md` §6 written
(~1000 words) with `academic-research-writer`: the four audit-trail criteria derived by negating
one definition of an audit trail, then named against NIST SP 800-92, SP 800-53 Rev. 5
(AU-3/AU-9/AU-11) and PCI DSS v4.0 10.5.1 — all three verified against their source documents
before citing (`nistsp80092`, `nistsp80053r5`, `pcidss2022` added to `references.bib`). MySQL
Enterprise Audit named as the commercial reference point, not demoed, tied back to ch. 5's
plugin-vs-core split. The three free instruments (general query log, error log,
`performance_schema`) judged one by one, with the general query log's failures derived from one
fact (written on receipt, before execution). **Refinement over the ticket's original framing**:
teaching (learning record 0007) sharpened the verdict from "fails tamper resistance" to
"attribution is the one criterion that cannot be bought downstream" — completeness, retention and
tamper resistance are all purchasable (ship logs off-box, lock the filesystem, retain 12 months);
attribution cannot be, because the effective identity is never emitted. The chapter closes on
that measurement: `examples/11-audit/`'s `v_definer_demo` read through a `SQL SECURITY DEFINER`
view by an account with no grant on `diagnoses`, general query log capturing only the connecting
account, the view's own `USER()`/`CURRENT_USER()` columns showing the split the log cannot.
Figure 6.1 (`figures/06-audit-01-log-izvod.png`) renders a trimmed log extract via a new
`-Raw`/`-RawFile` mode added to `tools/make-table-figure.ps1` (plain-text `<pre>` block, no SQL
run) — the log-figure shape ticket 12 left TBD is now decided and written into
`figures/README.md`. Export re-verified clean, 0 unresolved citations. Committed and pushed.
