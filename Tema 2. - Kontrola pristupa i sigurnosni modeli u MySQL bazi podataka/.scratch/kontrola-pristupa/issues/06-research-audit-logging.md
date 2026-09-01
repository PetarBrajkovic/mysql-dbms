# Research: audit logging — what is free, what is commercial, what is demonstrable

Type: research
Status: open

## Question

The user's constraint, set at charting, is **completely free**: a feature that cannot be tried for
free is covered in theory and stated to be commercial. MySQL's own audit log plugin is Enterprise, so
this bullet needs its options laid out before any chapter can be planned.

Produce a memo at `../research/06-audit-logging.md` covering:
1. **MySQL Enterprise Audit**: what it records, its filtering model, its output formats, and the
   licensing status stated plainly and citably. This is the reference point the free options get
   compared against.
2. **The free options**, each with what it actually captures and what it misses:
   - the **general query log** — every statement, no filtering, no identity of the *authorization*,
     heavy;
   - the **error log** and connection events;
   - `performance_schema` tables, especially the connection/account tables and
     `events_statements_*`;
   - **Percona Server's** free `audit_log` plugin and **MariaDB's** `server_audit` plugin — are they
     loadable into a stock **Oracle MySQL 8.4** Community server, or do they require running the
     vendor's own server build? Answer this precisely; it is the whole question behind ticket 11.
3. **What an audit log is supposed to be**, from a citable source rather than from MySQL: tamper
   resistance, the identity recorded (`USER()` vs `CURRENT_USER()` — a real and paper-worthy
   distinction under `SQL SECURITY DEFINER`), and completeness. This is what lets the chapter judge
   the free options instead of merely listing them.
4. A **recommendation** for ticket 11: the cheapest free path that produces a real audit trail on
   this machine, and what it costs in install effort and risk.

Do not install anything in this ticket — it is research. Ticket 11 does the installing.
