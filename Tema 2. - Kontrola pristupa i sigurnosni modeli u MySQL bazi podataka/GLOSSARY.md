# Glossary and skeleton - binding on every chapter

Terminology and chapter skeleton for **Tema 2. - Kontrola pristupa i sigurnosni modeli u MySQL bazi podataka**. Written in the first session, before any chapter,
so a term is decided once and never re-translated later. Do not deviate from a term below without
updating this file first and noting why.

**How to read it cheaply:** the term tables are always relevant; each chapter-specific subsection is
read only when working on that chapter. The reasoning behind a locked non-choice belongs in
`.scratch/kontrola-pristupa/terminology-rationale.md`; the one-line rule here is the binding part.

Voice and citation density are **not** here - they are the same for every paper in this course and
live in `../WRITING.md` (confirmed unchanged for this topic at ticket 09: impersonal *se*-construction,
per-paragraph citation).

## 0. The paper's spine

> MySQL sprovodi isključivo diskrecionu, na objektima zasnovanu kontrolu pristupa (DAC); svaki
> savremeni zahtev sa profesorove liste — RBAC u punom smislu, red-level security, multi-tenant
> izolacija — je ili sastavljen iz te osnove, ili odsutan i mora se graditi izvan same baze podataka.

Every chapter's job is to show, for its own slice, which side of that sentence it lands on:
composed-from-DAC, or absent-and-built-elsewhere. Decided at ticket 09, from the map's charting hunch,
surviving all six research memos.

## 1. Terminology

Source column marks where a term's rendering comes from: **deck** (professor's own vocabulary, memo
02, never deviated from without reason), or **09** (decided fresh at this ticket, for concepts the
deck never named).

| Concept | Serbian term (first use) | After first use | Source |
|---|---|---|---|
| Database security | sigurnost kod baza podataka | — | deck |
| Confidentiality / integrity / availability | tajnost / integritet / dostupnost | — | deck |
| Access control | kontrola pristupa | — | deck |
| Access policy | politika pristupa | politika | deck |
| Security mechanism | mehanizam sigurnosti | mehanizam | deck |
| Discretionary access control | diskreciona kontrola pristupa (DAC) | DAC | deck |
| Mandatory access control | obavezna kontrola pristupa (MAC) | MAC | deck |
| Privilege / access right | privilegija / pravo pristupa | privilegija | deck |
| Granting and revoking | dodela i oduzimanje prava | — | deck |
| Object (table, view) | objekat (tabela, pogled) | objekat | deck |
| Subject (user, application) | subjekat (korisnik, korisnička aplikacija) | subjekat | deck |
| Owner / creator | vlasnik / kreator | vlasnik | deck |
| View | pogled | — | deck |
| Role | uloga | — | deck |
| Role-based access control | kontrola pristupa zasnovana na ulogama (RBAC) | RBAC | 09 (deck said "Role-Based autorizacija"; RBAC needed a full, precise first-use gloss since ch. 3 judges MySQL against the NIST model by name) |
| Authorization ID | ID autorizacije (authorization ID) | — | deck |
| Field-level / fine-grained access control | sigurnost na nivou polja | — | deck |
| Granularity of control | granularnost kontrole | — | deck |
| Security class / clearance | klasa sigurnosti / dozvola | — | deck |
| Multilevel relations | višenivovske relacije | — | deck |
| Statistical database | statistička baza podataka | — | deck |
| Database administrator | administrator baze podataka (DBA) | DBA | deck |
| `GRANT` / `REVOKE` / `WITH GRANT OPTION` | kept in English | — | deck (never translates these) |
| `Simple Security Property` / `*-Property` / Bell–LaPadula | kept in English | — | deck |
| Authentication | autentifikacija (provera identiteta) | autentifikacija | 09 |
| Authorization | autorizacija (provera prava pristupa) | autorizacija | 09 — defined against authentication on first joint use, because Serbian blurs the two more readily than English does; every later use keeps them distinct |
| Least privilege (Saltzer–Schroeder) | princip najmanjih privilegija (least privilege) | princip najmanjih privilegija | 09 |
| Audit log / audit trail | kept in English, glossed once as *"audit log/trail (evidencioni zapis pristupa bazi)"* | audit log / audit trail | 09, extending the deck's own move (slide 20 glosses "audit trail" the same way, unglossed after) |
| Tenant / multi-tenancy | kept in English, glossed once; the running example's concrete tenant is *podružnica* (branch) | tenant / multi-tenancy | 09 |
| Definer / invoker | kept in English (MySQL keywords), glossed on first use | definer / invoker | 09 |
| Enforcement | sprovođenje | — | 09, paired with *politika* from the deck |
| Row-level security | red-level security, glossed once as *"bezbednost na nivou reda/vrste"* | RLS | 09 — kept close to English since it is not a MySQL feature name but a comparison concept (PostgreSQL/Oracle) |

## 2. Chapter skeleton - top-level

Soft target ~20-25 rendered pages; 22.5 budgeted below is a starting point, not a cap (`../WRITING.md`
length policy: page count is not a lever that shrinks figures).

| # | Chapter | Page budget | Backing |
|---|---|---|---|
| 1 | Uvod | 1 | — |
| 2 | Klasični modeli kontrole pristupa | 3.5 | deck (memo 02) + memo 07 |
| 3 | Sistem privilegija i uloga u MySQL-u | 4 | memo 03 |
| 4 | Fino-granularna kontrola pristupa i red-level security | 4 | memo 04 |
| 5 | Sprovođenje bezbednosnih politika | 3.5 | memo 05 |
| 6 | Audit logging | 2 | memo 06 |
| 7 | Multi-tenant bezbednosni modeli | 3.5 | memo 07 |
| 8 | Zaključak | 1 | — |

**Total: 22.5 pages.**

### 2a. What each chapter owns, decided at ticket 09

- **Ch. 2 (Klasični modeli)**: follows the deck's own order — policy vs. mechanism, DAC, the
  Trojan-horse argument (deck slide 15, motivates MAC, never on the professor's bullet list but his
  own material) as the DAC→MAC hinge, then MAC/Bell–LaPadula, then extends past the deck with
  RBAC-as-a-model and the least-privilege principle's exact wording (memo 07). The statistical-
  database/inference problem (deck slide 19) gets **one paragraph**, not a section — genuinely
  interesting, off the bullet list, and MySQL offers nothing for it.
- **Ch. 3 (Privilegije i uloge)**: grant tables, the two-stage check, static vs. dynamic privileges,
  `SUPER`'s decomposition, `partial_revokes`, then MySQL roles judged against ch. 2's RBAC model by
  name — role activation and role-to-role grants exist, separation of duty does not (the corrected
  claim from memo 07, not the deleted one).
- **Ch. 4 (FGAC i RLS)**: column privileges and their ceiling, views (`DEFINER`/`INVOKER`, `WITH
  CHECK OPTION`), then the three RLS emulation patterns as a **section**, not their own chapter (memo
  04's verdict), closing with the PostgreSQL/Oracle contrast.
- **Ch. 5 (Sprovođenje politika)**: authentication as pluggable, everything else (password, account,
  connection policy) as a server-core decision a plugin cannot make (memo 05's spine: *where* is the
  enforcement point).
- **Ch. 6 (Audit logging)**: kept as its own short chapter rather than folded into ch. 5 — it earns
  its space with the "instruments, not an audit trail" argument against NIST SP 800-92, and a real
  measurement (same statement, two accounts, direct vs. through a `SQL SECURITY DEFINER` view).
- **Ch. 7 (Multi-tenant)**: the closing synthesis (memo 07), not a fourth access-control model. Reuses
  ch. 2's models, ch. 3's roles and ch. 4's RLS emulation to justify the three tenancy patterns, and
  is where the least-privilege thread (running since ch. 2) lands explicitly via the
  connection-pooling collision.
- **Least privilege** is confirmed as a **thread**, not a chapter: it is defined once in ch. 2 and
  named again wherever a design trade-off makes it concrete (ch. 3's role scoping, ch. 7's tenancy
  patterns).
