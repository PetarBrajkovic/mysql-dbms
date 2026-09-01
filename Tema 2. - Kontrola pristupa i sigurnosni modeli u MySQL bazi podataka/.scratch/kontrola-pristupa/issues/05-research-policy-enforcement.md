# Research: security policy enforcement — authentication, password and account policy

Type: research
Status: resolved

## Question

*Security policy enforcement* is the vaguest bullet on the professor's list, and it needs a concrete
referent before it can be taught or written. The honest reading for a DBMS is: **which policies can
the server itself enforce, rather than the application?** Establish the inventory from the MySQL 8.4
manual.

Produce a memo at `../research/05-policy-enforcement.md` covering:
1. **Authentication**: pluggable authentication, `caching_sha2_password` as the 8.x default and why
   it replaced `mysql_native_password`, multi-factor authentication in 8.x, and what an
   authentication plugin can and cannot decide.
2. **Password policy**: the `validate_password` component (its policy levels and variables), password
   expiration, reuse restrictions via `password_history` / `password_reuse_interval`, **dual
   passwords** for rotation without downtime, and `random password` generation.
3. **Account policy**: `ACCOUNT LOCK`/`UNLOCK`, `FAILED_LOGIN_ATTEMPTS` and `PASSWORD_LOCK_TIME`,
   `MAX_QUERIES_PER_HOUR` and the other resource limits, and account expiry.
4. **Connection policy**: `REQUIRE SSL` / `REQUIRE X509` / `REQUIRE SUBJECT` per account, the host
   part of an account name as an access rule in its own right, and `--skip-networking`. Keep this
   inside the DBMS — TLS certificate infrastructure is out of scope on the map.
5. **Where the enforcement point actually is** for each of the above: the server, a component, a
   plugin, or the client. This is the distinction that makes the chapter worth writing rather than a
   list of settings.
6. **Enterprise Firewall**: what it does, and confirmation that it is commercial — it belongs in the
   paper as a named, cited, commercial feature, not as a demo.

Flag which of these are demonstrable on a free Community 8.4 server (most should be) and which
produce a good figure — a locked account and its exact error is a better picture than a settings
table.

## Answer

Findings: [`research/05-policy-enforcement.md`](../research/05-policy-enforcement.md)

Fourteen enforcement mechanisms inventoried across authentication (pluggable auth,
`caching_sha2_password` as the 8.4 default and `mysql_native_password`'s removal, multi-factor auth
via `authentication_policy`), password policy (`validate_password`, expiration, history and reuse,
**dual passwords**, random generation), account policy (`ACCOUNT LOCK`, `FAILED_LOGIN_ATTEMPTS` +
`PASSWORD_LOCK_TIME`, resource limits) and connection policy (`REQUIRE SSL`/`X509`/`SUBJECT`, host
matching and the user-table sort order, `skip_networking`).

**The organising finding, and the chapter's spine**: for each mechanism the memo names *where the
enforcement point is* - server core (11 of 14), loadable component (`validate_password`, Enterprise
Firewall), or built-in plugin (`caching_sha2_password`) - and establishes that **an authentication
plugin only verifies credentials; every policy decision is made by the server core**. That turns a
settings list into an argument.

**13 of 14 are demonstrable free**; only Enterprise Firewall is commercial, and it is cited as such.
Five figure candidates identified, all of the good kind - a visible error rather than a settings
table (failed-login lockout, error 1820 on an expired password, host-matching behaviour, SSL
rejection, error 1226 on a resource limit).

**Caveat - the shortest memo of the five (~560 words)**. The inventory is complete but thin on
detail; expect to re-read the manual when the chapter is taught rather than writing from this alone.
