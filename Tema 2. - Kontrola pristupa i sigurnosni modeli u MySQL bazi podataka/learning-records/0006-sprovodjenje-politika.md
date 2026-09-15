# 0006 — Sprovođenje bezbednosnih politika (chapter 5)

Date: 2026-09-18 · Lesson: `lessons/0004-sprovodjenje-politika.html` ·
Reference card: `reference/04-sprovodjenje-politika.html` · Live log: `lessons-live/0004-sprovodjenje-politika.md` ·
Memo: `.scratch/kontrola-pristupa/research/05-policy-enforcement.md`

## What was taught

The chapter was taught as **one criterion**, not fourteen mechanisms. Chain:

Stage 1 selects **exactly one** `mysql.user` row (host sorting, narrowest first, no fallback, no
merging) → therefore the plugin's world is that single row → the manual's own sentence shows the
plugin receives only credential + `authentication_string` and returns one bit → **criterion: the core
is the only thing that reads state; plugin and component judge only values handed to them** →
password-strength policy has no slot (plugin runs at login, but the cleartext exists only at
set-time), so MySQL opens a third point, the **component** (`validate_password`) → the three policy
families (password / account / connection) are then just applications of the criterion, with
`validate_password` the single non-core item among them → Enterprise Firewall is the one mechanism the
criterion does *not* cover, because it judges the **statement's shape** rather than identity or object.

Final chapter sentence: **authentication is pluggable, policy enforcement is not.**

## Where his edge was, before the lesson

**Floor**: Stage 1 / Stage 2 split, clean and first-try (carried from lesson 02). **Ceiling**:
everything concrete in this chapter — he had never heard of `ACCOUNT LOCK`, did not know
`validate_password` is a component, and volunteered that **the concept "authentication plugin" itself
was not concrete to him** ("ne znam o kakvom plugin-u je reč"). That note forced an unplanned node:
plugins had to be motivated from the problem (different accounts prove identity differently → the
verification method is swapped out and named in the account's own `plugin` column) before the
criterion could be built on them. Do not assume "plugin" is self-explanatory in later chapters.

## Misconceptions found and corrected

1. **OR-composition applied to row selection.** He said two matching `mysql.user` rows merge their
   privileges. This is lesson 02's rule used in the wrong phase, and it is the most dangerous error of
   the chapter — it would make the whole host-based access-control section wrong. Fixed by naming the
   phase boundary explicitly: OR composes **levels within one already-selected account** (Stage 2);
   row selection (Stage 1) has no OR at all. Cleared on the very next question and stayed cleared
   through a delayed retrieval at the end of the session.
2. **CIDR read as more specific than a literal IP.** Residual of the above, much smaller. Fixed with
   the rule **specificity = size of the matched host set** (1 machine vs 256), plus the reason the
   ordering must run that way: the server stops at the first match, so a narrow row can only act as an
   exception if it sorts first. Confirmed with the `USAGE`-shadowing scenario.
3. **Criterion misread as being about the *moment* rather than the *state*.** Asked where
   `password_history` is enforced, he chose `validate_password` because both checks happen at
   password-set time. This is the sharpest diagnostic of the session: he had the criterion but keyed
   it on timing. Corrected by putting the two checks side by side (text of the password vs. rows in
   `mysql.password_history`) and restating the criterion in its final, stronger form — **the core is
   the only thing that reads state**. Retrieval clean afterwards.

## The correction the session produced (most important item in this record)

The lesson taught, in node 1, that a narrow `'u'@'localhost'` row holding only `USAGE` **fully**
shadows a wide `'u'@'%'` row holding privileges. **That is false, and the user's own measurement
refuted it mid-session.** Logged in as `probni`, `CURRENT_USER()` returned `probni@localhost` (narrow
row selected, as predicted) and the `SELECT` **succeeded** (not predicted).

The rule, corrected and verified against refman 8.2.7:

- Stage 1's single-row selection governs **authentication and global privileges only**: which plugin,
  which password, `REQUIRE`, lock state, and the `mysql.user` privilege columns.
- **Database-, table- and column-level privileges are looked up independently** in `mysql.db` /
  `mysql.tables_priv`, where `Host` is matched against the **client host** and may contain `%` and
  `_`: *"The `Host` and `User` columns are matched to the connecting user's host name and MySQL user
  name."*
- Therefore a grant made to `'u'@'%'` **does** apply to a session authenticated as `'u'@'localhost'`.
- Therefore `CURRENT_USER()` names the Stage-1 row but **does not bound the session's reach** — the
  same shape as `CURRENT_ROLE()` understating a session (record 0004). Third instance of this pattern
  in the workspace.

`mandatory_roles` (empty) and `activate_all_roles_on_login` (0) were checked and ruled out, and the
`mysql.db` row (`% | poliklinika | probni | Y`) was inspected directly, so the mechanism is pinned,
not inferred.

**Teaching note for later chapters:** the wrong claim was a plausible over-generalisation of a true
one, and it survived a `researcher` pass because the research question asked only about Stage 1. When
a claim spans two stages, verify it in both. The user running the demo is what caught it — concrete
evidence that step 2 of `../WORKFLOW.md` is not a formality.

## Non-obvious insights worth revisiting

- **The Stage-1 ordering is itself the argument.** core (pick row) → core (read `plugin` column) →
  plugin (one bit) → core (everything else). The plugin is sandwiched, does not select itself, and
  never sees the rest of the row. This single strip replaces any list-based defense of the chapter.
- **`validate_password`'s `check_user_name` and `changed_characters_percentage` look like
  counterexamples and are not**: the core passes those values in as input. A component never reads
  `mysql.user` or `mysql.password_history` itself. Worth keeping in the chapter, because a reader will
  raise it.
- **Enterprise Firewall is the chapter's best argument for the paper's spine**, not a footnote: SQL
  injection violates no privilege at all — subject and object are both legitimate, only the statement
  changed — so a (subject, object) model is structurally blind to it. That is a DAC limitation stated
  from the outside, which ch. 7 can reuse.
- **Account policy is stored as JSON on the account**, not as a grant-table column:
  `mysql.user.User_attributes -> $.Password_locking` holds
  `{"failed_login_attempts": 3, "password_lock_time_days": 1}`. **Measured.** That is the *fourth*
  instance of the workspace's recurring structural move (`partial_revokes` JSON, `mandatory_roles`
  variable, a view in the schema, now this): when the grant-table shape cannot express something,
  MySQL writes it outside the shape. Strong enough to be a through-line in the paper.
- The narrow-row-shadows-wide-row behaviour (`'doc'@'%'` with `SELECT` fully masked by
  `'doc'@'localhost'` with `USAGE`) is the standard way to exclude one machine, and is also the most
  likely real-world misconfiguration to name in the paper.

## Standing facts for later chapters

- **Temporary locking after failed logins returns `ERROR 3955` on 8.4.11 (measured)**, with text
  naming the counter, not the password: *"Account is blocked for 1 day(s) (1 day(s) remaining) due to
  3 consecutive failed logins."* The manual's own sample prints **3957** under the words "an error
  that looks like this" (illustration, later versions) — cite the measured number with the version,
  and note the discrepancy. Distinct from `ER_ACCOUNT_HAS_BEEN_LOCKED`, which is the **manual**
  `ACCOUNT LOCK` case and reads only "Account is locked."
- Stage 1 order per refman 8.2.4: **"The server checks credentials first, then account locking
  state."** A locked account with the correct password passes the plugin and is rejected by the core
  immediately after (`ER_ACCOUNT_HAS_BEEN_LOCKED`).
- Password expiration is **not** a connection rejection: the account connects into a restricted mode
  where every statement except the password change returns `ERROR 1820 ER_MUST_CHANGE_PASSWORD`.
  `default_password_lifetime` defaults to `0`, i.e. expiration is off.
- Dual passwords require `APPLICATION_PASSWORD_ADMIN` for one's own account, `CREATE USER` for others.
- Resource-limit counters live in memory, start at zero on server start, do not survive a restart, and
  are zeroed by `FLUSH USER_RESOURCES`; the limits themselves are columns of the account row.

## Corrections filed against memo 05

- **Finding 11 is wrong.** The memo says `REQUIRE` is "checked during TLS handshake before Stage 1".
  `REQUIRE` is a property of the **account**, so it cannot be evaluated before the account row is
  selected: the TLS handshake happens earlier, but the decision "may *this* account connect without an
  encrypted channel" is a server-core check on the matched row, **inside** Stage 1. Verified against
  refman `create-user.html` and `connection-access.html`. Do not write the memo's version.
- **Finding 5 is imprecise.** The memo files password expiration as "rejected at Stage 1"; the manual
  determines expiration *after* successful credential verification and puts the client into sandbox
  mode rather than rejecting it.
- The error number for account locking is **not stated** in the manual's password-management section;
  it is named as `ER_ACCOUNT_HAS_BEEN_LOCKED`. Cite the symbolic name, not a number, unless measured.

## Evidence

`.scratch/kontrola-pristupa/measurements/0006-sprovodjenje-politika.md`.

**`validate_password` is measured** (8.4.11, run by the user in-session): component installs as
`root`, defaults captured, and `CREATE USER ... IDENTIFIED BY 'abc'` fails with **`Error Code: 1819`**
— giving the paper both the error number the manual does not print and
**`validate_password.policy = MEDIUM`**, the master switch memo 05 finding 4 omits.

**The host-sorting demo is not measured yet** and the failure was instructive: the lesson's `.try`
block named a non-existent table (`poliklinika.pacijent`; the sandbox tables are English —
`patients`), and the statement was run from a privileged connection, returning `1146` instead of the
`1142` the test exists to show. An account holding only `USAGE` gets `1142` whether or not the table
exists, because the server does not disclose object existence without schema access. Both faults
corrected in the lesson; re-run from a separate connection logged in as `probni`.

## What comes next

1. ~~**Finish the measurements.**~~ **Done — all three ran in-session.** Scripts 01, 02 and 03 in
   `examples/05-sprovodjenje-politika/` all carry their measured output in comments. Script 03
   (failed-login locking) delivered exactly the intended capture: the fourth login used the
   **correct** password and still failed, and the same password worked after `ACCOUNT UNLOCK` — so the
   password is excluded as the cause by construction. Original wording of this item kept below for
   the record:

   **Finish the measurements.** `examples/05-sprovodjenje-politika/01-host-sortiranje.sql` and
   `02-validate-password.sql` are committed; 02 is done, 01 needs the re-run described above. Add a
   third: `FAILED_LOGIN_ATTEMPTS 3 PASSWORD_LOCK_TIME 1`, three wrong logins, then a **correct** one
   that still fails — the chapter's strongest capture, since it shows the plugin succeeding while the
   core rejects. `INSTALL COMPONENT` and `CREATE USER` both need `root`; `dbadmin` will not do
   (cf. record 0002 on `general_log`).
2. **Figure candidates, two, both now backed by measurement:**
   - the Stage-1 strip — core → core → plugin → core — with the plugin as the only swappable box and
     everything else a state read;
   - **the correction figure**: one result row showing `probni@localhost` beside the row it should not
     have been able to read, with the `mysql.db` `Host='%'` line underneath as the explanation. This
     one is the more valuable of the two, since it documents a trap rather than restating the manual.
3. **Check `rad.md` §3 before writing §5.** Chapter 3 discusses grant tables and the two-stage check;
   if it asserts anywhere that the Stage-1 row determines the session's privileges, it now needs the
   db-table qualification.
3. **Write the chapter**, ~3.5 pages, criterion first, mechanisms as its evidence.
   `references.bib` needs refman 8.2.4, 8.2.17, 8.4.3, 8.2.15, 8.2.21 and 8.4.7.
