# Research: audit logging — what is free, what is commercial, what is demonstrable

Type: research
Status: resolved

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

## Answer

Findings: [`research/06-audit-logging.md`](../research/06-audit-logging.md)

**The answer to the ticket's central question is no**: neither Percona's `audit_log` nor MariaDB's
`server_audit` can be relied on to load into a stock Oracle MySQL 8.4 Community server on Windows -
the plugin ABI is tied to the vendor's own server build, and no precompiled Windows binary exists
for this one. So **ticket 11 should not attempt a plugin install**, which removes the only real risk
to the working server.

MySQL Enterprise Audit documented as the reference point and confirmed commercial. The free options
inventoried with what each misses: the general query log (everything, unfiltered, expensive, a plain
writable file), the error log's connection events, and `performance_schema` - whose decisive
limitation is that it is a **fixed-size in-memory ring buffer, not a durable trail**.

**The chapter's argument**, taken from NIST SP 800-92 and PCI-DSS req. 10 rather than from MySQL: an
audit log must be complete, retained, tamper-resistant and accountable. Community's free options
fail tamper-resistance by construction. They are *instruments*, not audit trails, and the chapter
should say exactly that.

**Two repairs made at charting, before acceptance.** (a) The subagent's heredoc truncated the file
mid-section 4; sections 4 and 5 were reconstructed from its returned findings and are marked as such
in the memo. (b) Its recommendation to *migrate the server to Percona* was overruled - the map
forbids risking the working install for one figure. The recommendation is now the general query log
with file-system hardening, plus an optional side-by-side Percona install on another port.

**Unverified**: the NIST SP 800-92 and PCI-DSS citations were not fetched in full and must be
checked before either enters `references.bib`.
