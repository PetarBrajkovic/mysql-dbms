# Research: security policy enforcement — authentication, password and account policy

Type: research
Status: open

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
