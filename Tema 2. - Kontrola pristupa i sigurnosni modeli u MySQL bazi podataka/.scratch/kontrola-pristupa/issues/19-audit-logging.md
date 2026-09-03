# Chapter 6. Audit logging

Type: task
Status: open
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
