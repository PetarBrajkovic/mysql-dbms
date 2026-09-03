# Chapter 2. Klasični modeli kontrole pristupa

Type: task
Status: resolved
Blocked by: 02, 07, 09

## Question

Execution ticket - resolves only when all four Definition-of-Done items are done.

**Target length**: ~3.5 pages of `rad.md`.

**Scope**: The theory chapter every later chapter judges MySQL against. Follows the deck's own order
(`GLOSSARY.md` §2a): policy vs. mechanism, DAC (ownership, delegable privileges, cascading revoke),
the Trojan-horse argument as the DAC→MAC hinge (deck slide 15 — Dick and Justin, cited to R&G not the
deck), MAC and Bell–LaPadula with both properties stated formally, then extends past the deck with
RBAC-as-a-model (Sandhu 1996, Ferraiolo & Kuhn 1992, ANSI/INCITS 359-2004) and the least-privilege
principle's exact 1975 wording (Saltzer & Schroeder). One paragraph, no more, on the statistical
database / inference problem (deck slide 19). Closes by stating the paper's spine as a claim to be
tested in every chapter after this one.

**Definition of done**:
1. The user has been taught this chapter via `/teach` (they must invoke it themselves) and a lesson
   exists in `lessons/`.
2. Runnable SQL committed to `examples/` where the chapter has anything to run (this chapter is
   theory-heavy; a minimal DAC-vs-MAC illustration may be enough), and at least one captioned figure
   in `figures/` per the strategy set in ticket 12.
3. Serbian prose appended to `rad.md` **using the `academic-research-writer` skill**, with IEEE
   citations added to `references.bib` as they are used. Every deck-backed claim cites its published
   origin (R&G ch. 21), never the deck itself (`../../WORKFLOW.md` rule 7).
4. A learning record written to `learning-records/`, and the work committed.

**Grounding**: research memo 02 (the deck) and memo 07 (RBAC/ABAC theory, least privilege, the
Sandhu/NIST bibliography), plus the terminology and chapter notes in `../../GLOSSARY.md` §1–§2a.

## Answer

All four Definition-of-Done items closed.

1. **Lesson taught** (2026-09-04): `lessons/0001-klasicni-modeli-kontrole-pristupa.html`, learning
   record `learning-records/0003-klasicni-modeli-kontrole-pristupa.md`. Taught by derivation (DAC →
   Trojan horse → MAC/Bell-LaPadula → RBAC → least privilege), not by definition; three
   misconceptions found and corrected (owner-decides read as owner-only; BLP assumed symmetric;
   overcorrection to "any class crossing is forbidden", fixed with the Bell-LaPadula figure).
2. **Artifacts**: `examples/02-klasicni-modeli/01-dac-kaskadno-oduzimanje.sql` (run live by the user
   on 8.4.11: no cascade on `REVOKE`, `GRANT OPTION` survives the revoke of the privilege it applied
   to, `mysql.tables_priv.Grantor` set but unused), figure
   `figures/02-klasicni-modeli-01-bell-lapadula.png` (Mermaid via `visualize`, verified by looking at
   it).
3. **Prose**: ~3.5 pages appended to `rad.md` §2 with `academic-research-writer`, impersonal
   *se*-construction, per-paragraph citation. Follows the deck's own order (policy vs. mechanism →
   DAC → Trojan horse → MAC/BLP, both properties stated formally → statistical-database paragraph)
   then extends past it with RBAC-as-a-model (Sandhu 1996, Ferraiolo & Kuhn 1992, ANSI/INCITS
   359-2004) and least privilege in Saltzer & Schroeder's exact 1975 wording, plus their
   fail-safe-defaults principle (found while teaching, not in memo 07) linked to MySQL's grant-only
   design. Every deck-backed claim cites R&G, never the deck. Six new `references.bib` entries:
   `bell1973`, `ferraiolokuhn1992`, `incits2004`, `saltzerschroeder1975` (plus the two chapter-1
   entries already present). Closes by restating the paper's spine as the claim every later chapter
   tests.
4. **Learning record**: already covers this chapter in full (0003, written at the lesson); no
   separate writing-session record needed. Export re-verified clean with `make-docx.ps1`.
