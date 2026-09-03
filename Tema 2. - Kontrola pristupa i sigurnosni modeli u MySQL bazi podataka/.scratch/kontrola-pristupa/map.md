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

- [Scaffold the Tema 2 workspace and write MISSION.md](issues/01-scaffold-workspace.md): full
  directory skeleton scaffolded (worked around the scaffolder's refusal to write into an existing
  folder by scaffolding into a temp sibling and merging), `MISSION.md` written and approved by the
  user, title set in `naslovna.md` and `rad.md`, `mysql-credentials.cnf` copied from Tema 1 (root,
  revisit at ticket 10), `GLOSSARY.md` left as the stub for ticket 09. All UTF-8, no BOM.

- [Research: mine the lecture deck for required content and Serbian terminology](issues/02-research-mine-lecture-deck.md):
  the deck is **Ramakrishnan & Gehrke ch. 21 in Serbian** — its own metadata names R&G and the
  examples are `Sailors`/`Boats` — so every deck-backed claim cites a book Tema 1 already owns.
  ~36 Serbian terms harvested, including *sigurnost na nivou polja* for fine-grained access control.
  Its frame is **DAC vs MAC, with a third of the deck on Bell–LaPadula**, which MySQL has none of,
  making the professor's own material the paper's sharpest contrast. **Zero MySQL coverage**: the
  split is Tema 1's reversed — the theory chapters are deck-backed, every MySQL chapter is not.

- [Research: MySQL's privilege system and roles (RBAC)](issues/03-research-privileges-and-roles.md):
  ten grant tables, the two-stage check, static vs dynamic privileges and the `SUPER` decomposition,
  `partial_revokes` as the one deny-shaped thing in a grant-only model. **All of it is Community.**
  The leverage is that MySQL's roles miss the NIST model **structurally**: a role and a user are the
  same object, and there is no separation of duty.

- [Research: fine-grained and row-level access control](issues/04-research-fgac-and-rls.md):
  three RLS emulation patterns, each with how it is defeated, plus definer/invoker semantics and the
  `USER()`/`CURRENT_USER()` distinction that recurs in the audit chapter. **Verdict: RLS is a
  section, not a chapter** — MySQL's absence of native RLS is the point, and a chapter of absence
  does not sustain itself. One startling claim (`SELECT *` bypassing column privileges, sourced to a
  2009 bug) is flagged for live testing before it goes anywhere near the paper.

- [Research: security policy enforcement](issues/05-research-policy-enforcement.md): fourteen
  mechanisms across authentication, password, account and connection policy, **13 of them free**.
  The chapter's spine is not the list but the question *where is the enforcement point* — server
  core, component, or plugin — and the finding that **an auth plugin only verifies credentials while
  the server core makes every policy decision**. Five figure candidates, all of them a visible error
  rather than a settings table.

- [Research: audit logging](issues/06-research-audit-logging.md): **no** — neither Percona's nor
  MariaDB's free audit plugin can be relied on to load into stock Oracle MySQL 8.4 Community on
  Windows, so ticket 11 does not attempt an install and the working server is never at risk. The
  free instruments (general query log, error log, `performance_schema` as a **ring buffer, not a
  durable trail**) are judged against NIST SP 800-92 rather than against the manual: they are
  *instruments, not audit trails*. Two repairs made before acceptance — a truncated tail
  reconstructed, and a "migrate to Percona" recommendation overruled as against the map's rules.

- [Research: access-control theory and multi-tenant security models](issues/07-research-models-and-multitenancy.md):
  **15 references with full bibliographic detail**, ready for `references.bib` — Sandhu 1996,
  Ferraiolo & Kuhn 1992, ANSI/INCITS 359-2004, NIST SP 800-162, Bell–LaPadula, the Orange Book, and
  Saltzer & Schroeder 1975 with the least-privilege principle's exact wording. Recommends least
  privilege as a **thread**, multi-tenancy as the **closing synthesis chapter**, and hands the paper
  its best single idea: the **connection-pooling collision**. **One false claim corrected in place**
  (it denied `SET ROLE` and role-to-role grants, both of which exist) — the memo carries the
  correction and ticket 09 is warned off the deleted wording.

- [Decide the Serbian terminology glossary and lock the paper skeleton](issues/09-terminology-and-skeleton.md):
  all four frontier questions accepted as recommended in one grilling round. Terminology and chapter
  skeleton written into `GLOSSARY.md` (deck's ~36 terms as default, 7 fresh decisions for concepts the
  deck never named, reasoning in `terminology-rationale.md`). Skeleton locked at 6 body chapters +
  intro + conclusion, 22.5 pages budgeted: Uvod, Klasični modeli, Privilegije i uloge, FGAC i RLS
  (RLS a section, not a chapter), Sprovođenje politika, Audit logging (survives as its own short
  chapter), Multi-tenant (the closing synthesis, least privilege lands here as a thread). Paper's
  spine adopted as charted: MySQL is DAC-only, everything modern is composed from that or absent.
  Citation voice confirmed unchanged from Tema 1. **Fog graduated**: chapter tickets 14–21 created
  and wired into ticket 13's blocking.

- [Decide the running example the whole paper is built on](issues/08-running-example.md): **the
  "Poliklinika" scenario** — a small multi-branch outpatient clinic, built fresh (not Sakila), 6
  tables (`tenants`, `staff`, `patients`, `visits`, `diagnoses`, `invoices`), 4 roles
  (`role_receptionist`, `role_nurse`, `role_doctor`, `role_billing`) with genuinely different rights
  over `diagnoses.diagnosis_text`, 3 branches as tenants, ~10–12 named `<role>_<branch>` accounts, and
  a named `dbadmin` account instead of `root`. Approved by the user as-sketched. Hands ticket 10 four
  discharge sentences to build the demos against, and a to-do list of the three live-verification
  claims (memos 03/04/06/07) to test on this exact schema.

- [Stand up the security sandbox on the live server](issues/10-build-the-sandbox.md): built and
  verified on MySQL 8.4.11 Community, Win64 — `poliklinika` schema, `dbadmin`@`localhost` as the
  paper's own non-root connection (`mysql-credentials.cnf` repointed), 4 roles, 12 named
  `<role>_<branch>` accounts, and `v_my_branch_diagnoses` emulating branch isolation. Real
  `ERROR 1142`/`1143` proven for every restricted role and both isolation directions. **One
  memo 04 claim overturned**: `SELECT *` does not bypass column privileges on this server —
  reproducible `ERROR 1142` instead of bug #41354's silent leak; the paper must caveat this by
  version. Findings in `learning-records/0001-poliklinika-sandbox.md`, scripts in
  `examples/00-setup/`.

## Not yet specified

- **Whether the paper needs a comparison system at all.** *Partly settled*: ticket 04 fixes
  PostgreSQL `CREATE POLICY` and Oracle VPD as the cited contrasts for row-level security, and
  ticket 07 supplies the theory to compare against. What is still open is **how much weight they
  carry** — a paragraph each inside the RLS section, or a Tema-1-style contrast chapter.
- **The defense angle.** What the professor is likely to press on for a security topic — probably
  least privilege applied to a real design, and whether the student can say precisely what MySQL
  cannot enforce. The deck sharpens the guess: he taught **Bell–LaPadula formally** and the
  **Trojan-horse argument** for why DAC is insufficient, so "why does MySQL not implement MAC, and
  what does that cost you" is a question worth being ready for. Revisit once the skeleton exists.
- **Which research claims need the live server to settle them.** Two of the three named at
  charting are now settled by ticket 10 (learning record 0001): `SELECT *` does **not** bypass
  column privileges on 8.4.11 (memo 04 corrected), and role-activation via `SET DEFAULT ROLE`
  works exactly as memo 03/07 described. Still open: whether the NIST/PCI-DSS citations say what
  memo 06 says they say — that one waits for ticket 11. More will accumulate as chapters are
  taught.

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
