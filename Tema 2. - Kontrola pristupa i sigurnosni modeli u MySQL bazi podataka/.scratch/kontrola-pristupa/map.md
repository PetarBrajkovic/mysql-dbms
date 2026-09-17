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

- [Get an audit trail demonstrable, for free](issues/11-make-audit-demonstrable.md): no plugin
  install was even attempted — `SHOW PLUGINS` confirms no `AUDIT`-class plugin or third-party
  `.dll` is present to try, matching memo 06's prediction exactly, so the working server was
  never at risk. Fallback executed instead: `v_definer_demo`, a `SQL SECURITY DEFINER` view
  granted to an account (`recept_podgorica`) with **no** grant on `diagnoses` at all, captured
  reading `diagnoses` through the view while the general query log ran. Payload proven: the
  log's `Connect` line names only the connecting account; nothing in it shows the query actually
  ran under the view definer's (`dbadmin`'s) privileges — `USER()`/`CURRENT_USER()` inside the
  view's own result set is what makes that split visible at all. `dbadmin` cannot toggle
  `general_log` itself (needed root, by hand, once). Evidence in `examples/11-audit/`, findings
  in `learning-records/0002-audit-log-vs-definer-identity.md`.

- [Decide the figure and example strategy for a security paper](issues/12-figure-and-example-strategy.md):
  five figure types catalogued — result-and-error pair (this paper's workhorse, built by a new shared
  `tools/make-pair-figure.ps1`), table figure (`make-table-figure.ps1`, used sparingly), drawn diagram
  (role graph, privilege-check flow, RLS/tenancy comparisons — Mermaid via the `visualize` skill is
  the default, replacing Tema 1's hand-built SVG), and a log extract for ch. 6 (shape TBD between a
  new `make-log-figure.ps1` and a `-Raw` mode on the existing table script). **No screenshots
  anywhere**, carried forward from Tema 1's own trap note. Naming/caption/aspect-ratio-width rules
  adopted unchanged. Budget locked lean after a round of user pushback on page count: **~8 figures
  total** (1-2 per substantive chapter, 0 for Uvod/Zaključak), down from an initial ~14-figure draft.
  Written into `figures/README.md`, binding from here on.

- [Chapter 1. Uvod](issues/14-uvod.md): no lesson taught (intro needs none, per `../WORKFLOW.md`);
  no SQL, no figure (ch. 12's budget gives Uvod none). Serbian prose written straight into `rad.md`
  §1 with `academic-research-writer`: policy-vs-mechanism and DAC/MAC framing cited to Ramakrishnan
  & Gehrke, the paper's spine stated from `GLOSSARY.md` §0, then a one-sentence roadmap per chapter
  2–8 with RBAC named against Sandhu et al. 1996 ahead of ch. 3's full use. `references.bib` seeded
  with `ramakrishnan2003`, `mysql84refman`, `sandhu1996`. Export pipeline re-verified clean. Ch. 8
  should reconcile against this intro once written, per Tema 1's own note.

- [Chapter 2. Klasični modeli kontrole pristupa](issues/15-klasicni-modeli.md): lesson taught by
  derivation (learning record 0003), then ~3.5 pages written into `rad.md` §2 with
  `academic-research-writer` — the (subject, object, operation) triple, policy vs. mechanism, DAC
  with the ownership/delegation argument, the live-measured MySQL `REVOKE` non-cascade
  (`examples/02-klasicni-modeli/`), the Trojan-horse hinge, MAC/Bell–LaPadula with both properties
  stated formally and illustrated by a new figure, one paragraph on the statistical-database
  problem, then RBAC-as-a-model (Sandhu 1996, Ferraiolo & Kuhn 1992, ANSI/INCITS 359-2004) and
  least privilege in Saltzer & Schroeder's exact 1975 wording plus their fail-safe-defaults
  principle. Four new `references.bib` entries. Every deck-backed claim cites R&G, never the deck.

- [Chapter 3. Sistem privilegija i uloga u MySQL-u](issues/16-privilegije-i-uloge.md): lesson
  already taught (learning record 0004), so this session wrote ~1400 words into `rad.md` §3 with
  `academic-research-writer`: the grant tables as a data model (level count derived from column
  naming arity), the two-stage check, the OR-composition chain illustrated by the live
  `probe_wide`/`probe_narrow` measurement, static vs. dynamic privileges and `SUPER`'s decomposition,
  `partial_revokes` and `mandatory_roles` framed together as written outside the model, roles as
  locked `mysql.user` rows resolved via the `mysql.role_edges` graph, then the live-measured
  `SET ROLE`/`CURRENT_ROLE()` activation semantics, closing with the RBAC verdict (RBAC0 full,
  RBAC1 partial because the graph is not a partial order, RBAC2 absent and structural). Two new
  Mermaid figures (`figures/03-privilegije-01-provera-ili.png`, `figures/03-privilegije-02-role-graf.png`),
  both verified by rendering before saving. No new `references.bib` entries needed, every claim
  cites `mysql84refman`, `sandhu1996`, `incits2004` or `saltzerschroeder1975`, all already seeded.
  Export re-verified clean.

- [Chapter 4. FGAC i RLS](issues/17-fgac-i-rls.md): lesson already taught (learning record 0005), so
  this session wrote ~1600 words into `rad.md` §4 with `academic-research-writer`: column privileges
  as the granularity ceiling, the 1142/1143 message-content distinction corrected against the manual
  directly (memo 04's claim that 1142 hides the table's existence was checked and found false, so it
  was dropped rather than carried into the paper), the live-verified `SELECT *` non-bypass with a
  version caveat on bug #41354, views as the FGAC mechanism (`DEFINER`/`INVOKER`, the measured
  `USER()`/`CURRENT_USER()` split, orphan-`DEFINER` `DROP USER` behaviour, `WITH CHECK OPTION`
  `CASCADED` default and `ERROR 1369`), then the three RLS emulation patterns as one section closing
  on "filtering is not authorization" and the PostgreSQL `CREATE POLICY` / Oracle VPD contrast. Wrote
  and first-used `tools/make-pair-figure.ps1` (the result/error-pair script promised at ticket 12,
  self-asserting against the live server) for Figure 4.1, plus a new Mermaid diagram for Figure 4.2.
  Three new `references.bib` entries (`postgresrls2024`, `oraclevpd2024`, `mysqlbug41354`). Export
  re-verified clean, all citation keys resolve. Committed and pushed.

- [Chapter 5. Sprovođenje bezbednosnih politika](issues/18-sprovodjenje-politika.md): lesson already
  taught (learning record 0006, uncommitted from a prior session — its own correction: a narrow
  `USAGE`-only row does **not** fully shadow a wide row's db/table grants), so this session wrote
  ~1400 words into `rad.md` §5 with `academic-research-writer`: the criterion (jezgro is the only
  thing that reads state; plugin and component judge only values handed to them) built from Stage-1
  row selection, `validate_password` motivated as a third enforcement point (cleartext exists only at
  password-set time), failed-login locking as the chapter's strongest capture (measured `ERROR 3955`
  vs. the manual's illustrative `3957`, new Figure 5.1 via `make-pair-figure.ps1`), password
  expiration as a restricted session rather than a rejection, the `REQUIRE` correction against memo
  05 finding 11, and the host-matching correction (`CURRENT_USER()` names the Stage-1 row but does
  not bound the session — same shape as ch. 3's `CURRENT_ROLE()` finding). Closes on Enterprise
  Firewall as the DAC-blindness argument ch. 7 will reuse. No new `references.bib` entries — every
  claim cites `mysql84refman`, already seeded. Terminology aligned to ch. 3's "prvi korak"/"drugi
  korak", not the scratch notes' informal "Faza 1/2". Export re-verified clean. Committed.

- [Chapter 6. Audit logging](issues/19-audit-logging.md): lesson already taught (learning record
  0007), so this session wrote ~1000 words into `rad.md` §6 with `academic-research-writer`: the
  four audit-trail criteria derived by negating one definition of what an audit trail is, named
  against NIST SP 800-92, SP 800-53 Rev. 5 (AU-3/AU-9/AU-11) and PCI DSS v4.0 10.5.1 (all three
  verified against source documents before citing, per the ticket's own flag), MySQL Enterprise
  Audit named as the commercial reference point and tied to ch. 5's plugin-vs-core split, the
  three free instruments judged one by one. **Verdict sharpened during teaching**: attribution,
  not tamper resistance, is the fatal criterion, because the effective identity is never emitted
  and so cannot be recovered downstream, while the other three are purchasable. Closes on the
  `v_definer_demo` measurement from ticket 11 — general query log records only the connecting
  account, `USER()`/`CURRENT_USER()` inside the view's own result set shows the split the log
  cannot. Three new `references.bib` entries. New `-Raw`/`-RawFile` mode added to
  `tools/make-table-figure.ps1` for Figure 6.1's log extract, deciding the shape ticket 12 left
  open. Export re-verified clean. Committed and pushed.

- [Chapter 7. Multi-tenant bezbednosni modeli](issues/20-multi-tenant.md): lesson already taught
  (learning record 0008), so this session wrote ~1440 words into `rad.md` §7 with
  `academic-research-writer`: the taxonomy **derived** from the database's own vocabulary (tenant is
  neither subject nor object, operation is fixed, so only two coordinates may differ) rather than
  listed, silo enforced by the core against pool's boundary falling on the nameless row, the verdict
  worded as *the database is excluded from the decision* rather than weaker, the connection-pooling
  collision (one pool account = one `mysql.user` row = one `CURRENT_USER()` for every tenant), the
  `SET @tenant_id` patch shown failing by measurement, and isolation/attribution closed as one defect
  with two faces against ch. 6's criteria. Least privilege lands as a measurable quantity: how many
  tenants an account *may* reach, unrepairable later because levels compose by `OR`. Memo 07's
  `schema-per-tenant` correction is stated openly in the paper, with AWS (silo/bridge/pool) and Azure
  (standalone/database-per-tenant/sharded multitenant) fetched and cited as the vendors' own naming;
  two new `references.bib` entries. New read-only SQL in `examples/07-multi-tenant/` measures reach
  (three branches through the table, one through the view, no branch anywhere in `SHOW GRANTS`);
  **the shared-pool account was never created**. Figure 7.1 re-rendered only to strip an em dash.
  Export clean, **22 rendered pages** with only ch. 8 left.

- [Chapter 8. Zaključak](issues/21-zakljucak.md): no lesson (a conclusion needs none), no SQL, no
  figure. ~660 words written into `rad.md` §8 with `academic-research-writer`, separating the two
  sides of the thesis: composed-from-DAC (grant tables and the two-stage check, RBAC0 full / RBAC1
  partial, column privileges plus definer views, silo tenancy) against absent-and-built-elsewhere
  (MAC/Bell–LaPadula, RBAC2, RLS as an enforcement point inside query processing, attribution,
  pool-pattern isolation). **The chapter's own contribution**: those six absences are one finding,
  since each is exactly one rule unwritable in MySQL's three-coordinate vocabulary (subject =
  `mysql.user` row, object = what `GRANT` names, operation = the privilege), with the corollary that
  where the model cannot express a rule MySQL writes it outside the grant schema and the enforcement
  point moves from the core onto the author of a view, procedure or application. Ch. 1 reconciled
  and needed **no edit**. No new `references.bib` entries; all 15 resolve. Learning record 0009.
  Export clean. **The paper's prose is complete**; only the final pass (ticket 13) is left.

## Not yet specified

- **Whether the paper needs a comparison system at all.** *Settled by ch. 4 and ch. 8, not by a
  chapter*: PostgreSQL `CREATE POLICY` and Oracle VPD carry a paragraph each inside the RLS section
  and one clause in the conclusion. No contrast chapter was written and none is now possible without
  reopening the skeleton.
- **The defense angle.** What the professor is likely to press on for a security topic — probably
  least privilege applied to a real design, and whether the student can say precisely what MySQL
  cannot enforce. The deck sharpens the guess: he taught **Bell–LaPadula formally** and the
  **Trojan-horse argument** for why DAC is insufficient, so "why does MySQL not implement MAC, and
  what does that cost you" is a question worth being ready for. *Partly answered by ch. 8*: learning
  record 0009 holds the one-line reply (MySQL is precisely bounded, not weak) and the table of six
  absences it rests on. Still fog because preparing the defense itself is the user's own deliverable,
  outside this map (the deck is already out of scope).
- **Which research claims need the live server to settle them.** Two of the three named at
  charting are now settled by ticket 10 (learning record 0001): `SELECT *` does **not** bypass
  column privileges on 8.4.11 (memo 04 corrected), and role-activation via `SET DEFAULT ROLE`
  works exactly as memo 03/07 described. The NIST/PCI-DSS question is now settled: ch. 6 verified all
  three source documents before citing them. Nothing measurable is left open for ch. 8, which is
  prose synthesis only.

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
