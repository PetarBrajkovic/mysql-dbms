# Chapter 5. Sprovođenje bezbednosnih politika

Type: task
Status: closed
Blocked by: 05, 09, 10

## Question

Execution ticket - resolves only when all four Definition-of-Done items are done.

**Target length**: ~3.5 pages of `rad.md`.

**Scope**: Not a list of fourteen mechanisms but the question memo 05 found underneath them: *where
is the enforcement point*. Pluggable authentication verifies credentials only
(`caching_sha2_password`); the server core decides everything else — account lock status, password
expiration, failed-login locking, SSL/TLS requirements, resource limits. Covers password policy
(`validate_password`, expiration, reuse, dual passwords), account policy (`FAILED_LOGIN_ATTEMPTS`,
resource limits), and connection policy (`REQUIRE SSL`, host-based access control). All 13 of the 14
mechanisms found are free; the one that is not (Enterprise Firewall) is named as commercial, not
demoed.

**Definition of done**:
1. The user has been taught this chapter via `/teach` (they must invoke it themselves) and a lesson
   exists in `lessons/`.
2. Runnable SQL committed to `examples/` against the Poliklinika sandbox (ticket 10) reproducing at
   least one of memo 05's five visible-error figure candidates (failed-login lock, password
   expiration, SSL rejection, resource-limit error). At least one captioned figure in `figures/` per
   the strategy set in ticket 12.
3. Serbian prose appended to `rad.md` **using the `academic-research-writer` skill**, with IEEE
   citations added to `references.bib` as they are used.
4. A learning record written to `learning-records/`, and the work committed.

**Grounding**: research memo 05 (security policy enforcement), the sandbox (ticket 10), and
`../../GLOSSARY.md` §1 for the authentication/authorization distinction this chapter depends on.

## Answer

All four Definition-of-Done items closed, across two sessions (lesson taught earlier and
uncommitted; chapter written this session).

1. Lesson taught earlier (`lessons/0004-sprovodjenje-politika.html`, reference card
   `reference/04-sprovodjenje-politika.html`, live log `lessons-live/0004-sprovodjenje-politika.md`,
   learning record `learning-records/0006-sprovodjenje-politika.md`). The lesson's own claim that a
   narrow `USAGE`-only row fully shadows a wide row's grants was refuted mid-session by the user's own
   measurement and corrected before being written into the chapter.
2. `examples/05-sprovodjenje-politika/`: `01-host-sortiranje.sql` (the host-matching correction),
   `02-validate-password.sql` (`validate_password` as a component, `ERROR 1819`),
   `03-zakljucavanje-naloga.sql` (`FAILED_LOGIN_ATTEMPTS`/`PASSWORD_LOCK_TIME`, `ERROR 3955`) — all
   pre-existing from the lesson session. One new figure this session, **Figure 5.1**
   (`figures/05-sprovodjenje-01-zakljucavanje.png`), built with `tools/make-pair-figure.ps1`: a
   working account beside `kljucar`, whose *correct* fourth-attempt password is still rejected with
   `ERROR 3955` because the account is locked — the chapter's core argument (plugin says yes, core
   reads state the plugin never saw) in one capture.
3. `rad.md` §5 written with `academic-research-writer` (~1400 words): the criterion (core is the only
   thing that reads state; plugin and component judge only values handed to them) stated from Stage-1
   row selection, `validate_password` motivated as a *third* enforcement point tied to the
   cleartext-only-at-set-time argument, failed-login locking as the chapter's strongest capture with
   the measured-`3955`-vs-manual's-illustrative-`3957` caveat, password expiration as a restricted
   session rather than a rejection, the `REQUIRE` correction against memo 05 finding 11, and the
   host-matching correction (`CURRENT_USER()` names the Stage-1 row but does not bound the session —
   same shape as ch. 3's `CURRENT_ROLE()` finding). Closes on Enterprise Firewall as the DAC-blindness
   argument for ch. 7. **No new `references.bib` entries** — every claim cites `mysql84refman`,
   already seeded. Terminology aligned to ch. 3's established "prvi korak"/"drugi korak", not the
   scratch notes' informal "Faza 1/2".
4. This ticket's Answer section is the learning record for the write-up half; the teaching half's
   record is `learning-records/0006-sprovodjenje-politika.md`. Export re-verified clean, all citation
   keys resolve. Committed.
