# Terminology rationale

The one-line rule for each term lives in `../../GLOSSARY.md` §1; this file is the reasoning behind the
choices that are not a straight copy of the deck (memo 02), written at ticket 09.

- **Authentication / authorization split.** The deck never distinguishes them explicitly — slide 3's
  "identifikacija korisnika" and slide 4's "ovlašćenja i prava pristupa" gesture at the split without
  naming it. Serbian usage in practice blurs the two more readily than English does ("autentifikacija"
  is sometimes used loosely to cover both). Decided: define both terms against each other on first
  joint use (autentifikacija = provera identiteta, autorizacija = provera prava pristupa), because
  ch. 5's whole spine — a plugin only verifies credentials, the server core decides everything else —
  depends on the reader holding the distinction precisely.

- **RBAC spelled out in full.** The deck says "Role-Based autorizacija", a half-translated fragment.
  Ch. 3 needs to name the NIST model precisely to judge MySQL's roles against it, so the full Serbian
  gloss ("kontrola pristupa zasnovana na ulogama") plus the acronym is used from first mention, then
  RBAC throughout.

- **Least privilege.** No deck precedent at all — the principle is implicit in the deck's view
  examples but never named. Rendered as "princip najmanjih privilegija" with "least privilege" in
  parentheses on first use, matching the deck's convention for DAC/MAC (Serbian term first, English
  in parens). Saltzer & Schroeder's exact wording (memo 07) is quoted once, in ch. 2, in English with
  a Serbian gloss alongside it rather than a translated paraphrase, since the paper cites the
  original 1975 wording directly.

- **Audit log / audit trail.** Kept in English throughout, following the deck's own move: slide 20
  writes "izvršava audit trail, ili istoriju pristupa korisnika bazi podataka" and never translates
  the term after that. Ch. 6 reuses exactly that gloss on first use and does not re-translate it.

- **Tenant / multi-tenancy.** No natural one-word Serbian equivalent — "zakupac" (lease-tenant) reads
  wrong for a software tenant, and "višekorisnički" collapses into "multi-user," a different concept
  memo 07 and ch. 7 need to keep separate. Kept in English, glossed once in ch. 7. The running
  example's concrete tenant (ticket 08) is already named in Serbian as *podružnica* (branch), which
  gives ch. 7 a natural bridge from the abstract English term to the concrete Serbian scenario.

- **Definer / invoker.** These are MySQL keywords (`SQL SECURITY DEFINER`/`INVOKER`), not general
  vocabulary; translating them would separate the prose from the SQL it discusses. Kept in English,
  glossed once in ch. 4 where they are first used (memo 04's DEFINER/INVOKER section).

- **Policy / enforcement.** "Politika" is already the deck's word (politika pristupa). "Enforcement"
  has no deck precedent since the deck never gets past defining the concept (slide 4); "sprovođenje"
  is the natural pairing and is also the word memo 05's own title uses in English translation,
  confirmed at ticket 09.

- **Row-level security.** Not a MySQL feature — it is the comparison concept ch. 4 uses to name what
  PostgreSQL and Oracle have and MySQL emulates. Glossed once as "bezbednost na nivou reda/vrste,"
  then referred to as RLS, matching the deck's own pattern of Serbian-gloss-then-acronym for DAC/MAC.

## Citation density and voice

Confirmed unchanged at ticket 09: impersonal *se*-construction and per-paragraph citation, as settled
on Tema 1 (`../../WRITING.md`). No finding in the six research memos argued for a different voice.
