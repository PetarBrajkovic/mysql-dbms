# Measurements — 0006 Sprovođenje bezbednosnih politika (chapter 5)

Server: MySQL 8.4.11 Community, Win64. Client: MySQL Workbench. Run by the user, 2026-09-18.

## 1. `validate_password` — MEASURED, clean

Script: `examples/05-sprovodjenje-politika/02-validate-password.sql`.

`INSTALL COMPONENT 'file://component_validate_password'` succeeded as `root`.
`SHOW VARIABLES LIKE 'validate_password%'` returned the defaults:

```
validate_password.changed_characters_percentage  0
validate_password.check_user_name                ON
validate_password.dictionary_file
validate_password.length                         8
validate_password.mixed_case_count               1
validate_password.number_count                   1
validate_password.policy                         MEDIUM
validate_password.special_char_count             1
```

`CREATE USER 'slaba'@'localhost' IDENTIFIED BY 'abc';` →

```
Error Code: 1819. Your password does not satisfy the current policy requirements
```

**Usable in the paper as a measured figure.** Two things memo 05 did not have:

- the **error number 1819** for `ER_NOT_VALID_PASSWORD` (the manual names the symbol, not the number);
- **`validate_password.policy = MEDIUM`** as the master switch governing which of the other variables
  apply at all (`LOW` = length only, `MEDIUM` = + character composition, `STRONG` = + dictionary file).
  Memo 05 finding 4 lists the individual variables without mentioning `policy`, which makes its list
  read as if all of them always apply.

## 2. Host sorting — MEASURED, and it REFUTED the lesson's original claim

Script: `examples/05-sprovodjenje-politika/01-host-sortiranje.sql`.

From a separate Workbench connection logged in as `probni`:

```
SELECT CURRENT_USER(), p.* FROM poliklinika.patients p LIMIT 1;

probni@localhost | 1 | 1 | Pacijent 001 | 1967-12-23
```

The lesson predicted `ERROR 1142`. It got a row. **The lesson was wrong, the server was right.**

Cause, confirmed against the manual and by direct inspection: Stage 1's single-row selection governs
authentication and **global** privileges only. Database-level privileges are looked up independently
in `mysql.db`, where `Host` is matched **against the client host** and may contain `%` and `_`
(refman 8.2.7, quoted in the lesson). The grant to `'probni'@'%'` therefore applies to a session whose
`CURRENT_USER()` is `probni@localhost`.

Alternative explanations ruled out in the same session:

```
SELECT @@mandatory_roles, @@activate_all_roles_on_login;   -->  (empty), 0
SELECT Host, Db, User, Select_priv FROM mysql.db WHERE User = 'probni';
                                                    -->  % | poliklinika | probni | Y
```

**This is the better figure candidate for the chapter**, better than the one originally planned: one
result row that shows the authenticated account and the leaked-in privilege side by side, plus the
two-line `mysql.db` proof underneath.

## 2b. Original failed attempt — kept because it explains a trap

First attempt returned:

```
SELECT * FROM poliklinika.pacijent LIMIT 1
Error Code: 1146. Table 'poliklinika.pacijent' doesn't exist
```

Two faults, both in the lesson's `.try` block, not on the server:

1. **Wrong table name.** The sandbox tables are English (`tenants`, `staff`, `patients`, `visits`,
   `diagnoses`, `invoices` — `examples/00-setup/01-schema.sql`). The block invented
   `poliklinika.pacijent`. Corrected in the lesson.
2. **Wrong connection.** `1146` proves the statement ran from a privileged session: an account holding
   only `USAGE` would have received `1142` regardless of whether the table exists, since the server
   does not disclose object existence to an account without schema access. The measurement therefore
   did not test what it was written to test.

Re-run done — see section 2 above. Keep this trap in the chapter's example script: `1146` from a
privileged session is not evidence of anything about `probni`.

## 3. `FAILED_LOGIN_ATTEMPTS` — MEASURED, clean, and the chapter's best capture

Script: `examples/05-sprovodjenje-politika/03-zakljucavanje-naloga.sql`. Account created with
`FAILED_LOGIN_ATTEMPTS 3 PASSWORD_LOCK_TIME 1`.

`SHOW CREATE USER` echoed the policy back verbatim:

```
CREATE USER `kljucar`@`localhost` IDENTIFIED WITH 'caching_sha2_password' AS '...'
REQUIRE NONE PASSWORD EXPIRE DEFAULT ACCOUNT UNLOCK PASSWORD HISTORY DEFAULT
PASSWORD REUSE INTERVAL DEFAULT PASSWORD REQUIRE CURRENT DEFAULT
FAILED_LOGIN_ATTEMPTS 3 PASSWORD_LOCK_TIME 1
```

The policy is stored as JSON on the account itself:

```
kljucar | localhost | caching_sha2_password |
{"failed_login_attempts": 3, "password_lock_time_days": 1}
```

After three wrong passwords, the **fourth attempt with the correct password** still failed:

```
ERROR 3955 (HY000): Access denied for user 'kljucar'@'localhost'.
Account is blocked for 1 day(s) (1 day(s) remaining)
due to 3 consecutive failed logins.
```

After `ALTER USER ... ACCOUNT UNLOCK`, the same unchanged password logged in successfully
(`Welcome to the MySQL monitor.`).

**Why this is the chapter's strongest figure:** the credential was correct, so the plugin returned
success; the rejection came from the core reading state the plugin cannot see. And because nothing
about the password changed between the failure and the success, the password is excluded as the cause
by construction, not by assertion.

### Caveat to carry into the write-up — error number

**Measured: `3955` on 8.4.11.** The reference manual's own example for this message prints
**`ERROR 3957`**, introduced with the words *"an error that looks like this"* — an illustration, not a
specification, and the pages carrying it are for later server versions. Cite the measured `3955` with
the version stated, and note the manual's differing sample; never the other way round.

This is **not** `ER_ACCOUNT_HAS_BEEN_LOCKED`, which is returned for a **manually** locked account and
reads only `Account is locked.` (refman 8.2.20). Two distinct messages for two distinct routes to the
same outcome — worth one sentence in the chapter.
