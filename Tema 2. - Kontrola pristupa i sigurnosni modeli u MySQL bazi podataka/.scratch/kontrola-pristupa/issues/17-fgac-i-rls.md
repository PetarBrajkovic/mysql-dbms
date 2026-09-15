# Chapter 4. Fino-granularna kontrola pristupa i red-level security

Type: task
Status: closed
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

## Answer

All four Definition-of-Done items closed.

1. Lesson taught earlier (`lessons/0003-fgac-i-rls.html`, learning record `0005-fgac-i-rls.md`,
   live-log `lessons-live/0003-fgac-i-rls.md`).
2. This session: `examples/04-fgac-i-rls/03-column-privilege-pair.sql` (the `nurse_podgorica`
   `icd_code`/`diagnosis_text` column-privilege pair, `01-ko-pita.sql` for the `DEFINER`
   `CURRENT_USER()` RLS pattern against `v_my_branch_diagnoses`'s tenant/branch boundary), plus the
   pre-existing `02-with-check-option.sql`. Two figures: **Figure 4.1**
   (`figures/04-fgac-01-kolonska-privilegija.png`), the paper's first real use of the promised
   `tools/make-pair-figure.ps1`, newly written this session, self-asserting against the live server;
   **Figure 4.2** (`figures/04-fgac-02-rls-obrasci.png`), a Mermaid diagram of the three RLS emulation
   patterns and their failure modes.
3. `rad.md` §4 written with `academic-research-writer` (~1600 words): column privileges as the
   granularity ceiling, the corrected 1142/1143 message-content distinction, views as the FGAC
   mechanism (`DEFINER`/`INVOKER`, the measured `USER()`/`CURRENT_USER()` split, orphan-`DEFINER`
   behaviour, `WITH CHECK OPTION`), the three RLS emulation patterns closing on "filtering is not
   authorization", then the PostgreSQL `CREATE POLICY` / Oracle VPD contrast. Three new
   `references.bib` entries (`postgresrls2024`, `oraclevpd2024`, `mysqlbug41354`).
4. Learning record `0005-fgac-i-rls.md` closed out. **`SELECT *` verified live** (carried from ticket
   10/record 0001, re-confirmed here): it does **not** bypass column privileges on 8.4.11, contrary
   to memo 04's bug #41354 citation, which the chapter now states with an explicit version caveat
   rather than as a live bypass. Export re-verified clean, all citation keys resolve. Committed and
   pushed (`86b2aab`).
