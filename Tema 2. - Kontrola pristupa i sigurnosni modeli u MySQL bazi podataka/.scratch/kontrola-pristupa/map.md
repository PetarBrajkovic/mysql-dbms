# Map: Kontrola pristupa i sigurnosni modeli u MySQL bazi podataka

Label: `wayfinder:map`

## Destination

A finished seminar paper in Serbian on access control and security models in MySQL — IEEE-cited,
illustrated with captioned figures produced from a live server, exported to Word — built up chapter by
chapter, where each chapter is *first taught* to the user as a lesson and *then* written. Reached when
this topic's own `rad.md` contains every chapter, the bibliography is complete, and the DOCX export is
verified.

**Same process as Tema 1, new subject matter, its own folder.** Nothing in `../TEACHING.md`,
`../WRITING.md`, `../WORKFLOW.md`, `../assets/` or `../tools/` is copied or restated here; this effort
only fills in the subject-matter half (`MISSION.md`, `GLOSSARY.md`, `NOTES.md`, `rad.md`, lessons,
figures, examples).

## Notes

**Domain**: MySQL 8.4 access control — the privilege system and its grant tables, roles (RBAC),
column- and view-level fine-grained access control, row-level security as something MySQL does *not*
have natively, authentication and password/account policy, audit logging, least privilege, and
multi-tenant schema/privilege designs. The professor's bullet list is the screenshot at this topic's
root, `Screenshot 2026-09-01 173910.png`.

**Execution override**: this map is *not* planning-only. As on Tema 1, the chapter tickets (still fog
— see below) deliberately carry execution: a chapter ticket is resolved only when the lesson has been
taught, the examples run, and the Serbian prose is appended to `rad.md`.

**Skills every session must consult**:
- `academic-research-writer` — **mandatory** for all prose that lands in the paper. Non-negotiable.
- `serbian-grammar` — for every line of Serbian written, per `../WRITING.md`.
- `/teach` — drives the lesson half of each chapter ticket. The agent cannot invoke it
  (`disable-model-invocation: true`); ask the user to type the slash command. The user has adjusted
  his `teach` skill since Tema 1; that is the skill's business, not this map's.
- `pdf-reader` — for every PDF, including `../../Predavanja/06_Sigurnost 2016.pdf`.
- `grilling` + `domain-modeling` — for the decision tickets.

**Standing preferences** (carried from Tema 1 unless noted):
- Paper in Serbian, written Serbian-first per chapter. Everything else — lessons, notes, commits,
  these files — in English.
- All artifacts stay inside this `Tema 2. ...` folder. Tema 1 is finished and is not touched.
- Length: **soft target ~20–25 rendered DOCX pages, measured every chapter, never a hard cap**
  (decided at charting). Tema 1's scar is binding here: a hard ceiling drove figure widths down until
  the figures were unreadable, and was retired anyway. Figures are sized by aspect ratio for
  readability; page count is not a lever to shrink them. See `../WRITING.md`.
- **Everything demonstrated must be free.** No paid editions, no trials that turn into a bill. Where a
  feature is Enterprise-only (audit log plugin, Enterprise Firewall, data masking), it is covered
  **in theory from primary sources and explicitly stated as a commercial feature** rather than faked.
  Decided at charting; it shapes tickets 06 and 11 in particular.
- Citation sourcing: the university lecture decks in `../../Predavanja/` are for **learning only and
  are never cited** (`../WORKFLOW.md` rule 7). Deck-backed claims are cited to their published origin
  instead. For this topic that means Ramakrishnan & Gehrke for the classical models plus the primary
  access-control literature (e.g. the NIST/Sandhu RBAC papers) for RBAC, and the MySQL 8.4 reference
  manual — with the source tree and worklogs where the manual is silent — for MySQL specifics.
- Every substantive chapter needs runnable SQL plus at least one captioned figure. What a "figure"
  even is differs from Tema 1: there are no flame graphs here, so the medium is an open decision
  (ticket 12).
- Subagents run on **haiku** with narrow, specific briefs.
- Git: one repo at the **course** level, `origin` = `github.com/PetarBrajkovic/mysql-dbms.git`. Push
  as part of finishing a chapter.
- Pacing from Tema 1's actual history: one lesson *or* one chapter per session, sessions roughly every
  two days; a lesson and its chapter are written in **different** sessions. Do not plan a session that
  teaches and writes the same chapter.
- Export: `../tools/make-docx.ps1` from inside this folder. Never bare `pandoc` — it drops the title
  page.

## Decisions so far

<!-- one line per closed ticket: the gist, then the link to the ticket that holds the detail -->

- **Destination, length policy, and the free-only constraint fixed** (charting session, 2026-09-01):
  same paper shape as Tema 1 in a new folder; ~20–25 pages soft; commercial features covered as
  theory rather than demoed; chapter tickets deliberately left as fog until the skeleton is locked.

## Not yet specified

- **The chapter tickets.** The nine bullets on the professor's screenshot are not nine chapters:
  *fine-grained access control* and *row-level security* are one chapter's worth of material,
  *least privilege* reads as a thread running through all of them rather than a chapter, and
  *security policy enforcement* may be a chapter or may be the frame the whole paper hangs on.
  Expect ~7 chapters plus an intro and a conclusion. These graduate into tickets in one pass when
  [Decide the Serbian terminology glossary and lock the paper skeleton](issues/09-terminology-and-skeleton.md)
  closes, and not before.
- **The paper's spine.** Tema 1 found one late ("one query, many plans, unified by cost") and it made
  the paper. A candidate here is that MySQL's access control is *discretionary and object-based*, and
  that everything the modern bullets ask for is either composed out of that (roles, views, definers)
  or absent and named as absent — but this is a hunch, not a decision, and the research tickets are
  what will confirm or kill it.
- **Whether the paper needs a comparison system at all.** Row-level security in PostgreSQL and Oracle
  VPD/Label Security are the obvious contrasts, and Tema 1's chapter 6 proved a contrast chapter can
  carry a paper. Whether that is one section, one chapter, or a thread depends on ticket 04.
- **How much of the Tema 1 dataset survives.** `wide_events` and Sakila were built for query
  processing; a security paper wants tenants, roles and users instead. Ticket 08 decides the scenario
  and ticket 10 builds it, but whether Sakila is reused as the *data* underneath a new privilege
  design is not yet decided.
- **The defense angle.** What the professor is likely to press on for a security topic — probably
  least privilege applied to a real design, and whether the student can say precisely what MySQL
  cannot enforce. Revisit once the skeleton exists.

## Out of scope

- **Tema 1 and Tema 3.** Separate efforts, separate folders, separate maps. Tema 1 is finished and is
  not reopened for this.
- **Paid MySQL editions and trials.** Enterprise Audit, Enterprise Firewall, Enterprise Data Masking,
  Enterprise Transparent Data Encryption: covered in theory and named as commercial, never purchased
  or trialled.
- **The PowerPoint defense deck.** A separate deliverable the user handles himself.
- **The title page's faculty seals and the final Word polish.** Done by hand in Word after export, as
  on Tema 1.
- **General MySQL administration and application building.** The professor asked for isolated,
  focused examples, not a working multi-tenant application.
- **Network- and OS-level security.** Firewalls, TLS certificate infrastructure beyond what MySQL
  itself configures, disk encryption, and OS hardening are a different subject; the paper stays
  inside the DBMS.
