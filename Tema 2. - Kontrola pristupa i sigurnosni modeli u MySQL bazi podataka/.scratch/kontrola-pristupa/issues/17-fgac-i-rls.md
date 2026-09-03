# Chapter 4. Fino-granularna kontrola pristupa i red-level security

Type: task
Status: open
Blocked by: 04, 09, 10

## Question

Execution ticket - resolves only when all four Definition-of-Done items are done.

**Target length**: ~4 pages of `rad.md`.

**Scope**: Column-level privileges as the ceiling of native FGAC (`mysql.columns_priv`, errors 1142
vs. 1143), views as the real mechanism (`DEFINER`/`INVOKER`, `WITH CHECK OPTION` LOCAL vs. CASCADED,
the orphan-object problem), then the three RLS emulation patterns as **one section**, not a chapter
(memo 04's verdict) — each with its failure mode — closing with the PostgreSQL `CREATE POLICY` and
Oracle VPD contrast: what MySQL cannot do at the engine level.

**Definition of done**:
1. The user has been taught this chapter via `/teach` (they must invoke it themselves) and a lesson
   exists in `lessons/`.
2. Runnable SQL committed to `examples/` against the Poliklinika sandbox (ticket 10): the nurse role's
   column-level grant on `diagnoses.icd_code` excluding `diagnosis_text`, and at least one RLS
   emulation pattern against the tenant (branch) boundary. At least one captioned figure in `figures/`
   per the strategy set in ticket 12 (a result-and-error pair fits column privileges well).
3. Serbian prose appended to `rad.md` **using the `academic-research-writer` skill**, with IEEE
   citations added to `references.bib` as they are used.
4. A learning record written to `learning-records/`, and the work committed. **Verify live**: whether
   `SELECT *` really bypasses column privileges (memo 04, MySQL Bug #41354), flagged in the map as
   needing the live server before it goes into a chapter.

**Grounding**: research memo 04 (FGAC and RLS), the sandbox and its `diagnoses.diagnosis_text`
sensitive column (ticket 08/10), and `../../GLOSSARY.md` §1–§2a.
