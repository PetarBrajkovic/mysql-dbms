# Audit Logging in MySQL 8.4 Community Edition: Free vs Commercial Options on Windows

**No, third-party audit plugins (Percona's audit_log, MariaDB's server_audit) cannot be reliably installed on Oracle MySQL 8.4 Community on Windows; they are built for their own server distributions and the plugin ABI is incompatible.** Free audit logging on stock Oracle MySQL 8.4 Community Windows is limited to the general query log, error log connection events, and performance_schema in-memory tables—none of which offer durable, append-only, tamper-resistant audit trails as standards require.

## 1. MySQL Enterprise Audit: Reference Point (Commercial Only)

MySQL Enterprise Audit is a paid-only feature included in MySQL Enterprise Edition. This is stated in the official documentation: "MySQL Enterprise Audit is an extension included in MySQL Enterprise Edition, a commercial product." [MySQL 8.0 Reference Manual 8.4.5](https://dev.mysql.com/doc/refman/8.0/en/audit-log.html).

### What It Records

- Connection events: user, host, IP, success/failure status, connection ID
- General queries: every SQL statement with user and database context
- Table access events: read, insert, update, delete operations with table names
- Administrative actions: schema changes, privilege changes, view/function creation
- Asynchronous execution support: time and size metrics per query (MySQL 8.0.30+)

### Filtering Model

Filtering is JSON-based, stored in mysql system database tables, and supports:

- Inclusive/exclusive filtering: log only specified classes or log everything except specified items
- Per-user filters via audit_log_include_accounts and audit_log_exclude_accounts
- Per-event-class filtering (connection, general, table_access, message)
- Per-event-subclass filtering (connect, disconnect, insert, delete, update, read, status)
- Field-level conditions: filter on connection type, query status, user, host, IP, database, table names
- Event blocking (abort): can block execution of INSERT, UPDATE, DELETE based on conditions

All filters are JSON values documented in [MySQL 8.4 Reference Manual 8.4.5.8](https://dev.mysql.com/doc/refman/8.4/en/audit-log-filter-definitions.html).

### Output Formats

- NEW (default MySQL 8.0.12+): compact binary format, space-efficient
- JSON: structured, machine-parseable
- XML: legacy, human-readable

### Licensing Proof

Oracle's official product matrix states MySQL Enterprise Edition requires paid licensing while Community Edition is free. Community Edition is excluded from receiving the audit plugin [MySQL Products: Compare Editions](https://www.mysql.com/products/enterprise/compare/).

---

## 2. Free Options in Stock MySQL Community 8.4 on Windows

### a) General Query Log: Every Statement, No Filtering

**What it captures:**
- Every SQL statement received by the server
- Connect and disconnect events with user, host, timestamp
- Username is recorded in each log entry
- Connection ID
- Database in use

**What it misses:**
- No filtering—logs everything or nothing (only on/off at runtime)
- No access control: doesn't distinguish read vs. write at statement level
- Not tamper-resistant: any user with file system access or FILE privilege can truncate or delete
- No append-only guarantee: file can be rotated, renamed, or cleared

**Configuration:**
```sql
SET GLOBAL general_log = ON;
SET GLOBAL general_log_file = 'C:\ProgramData\MySQL\MySQL Server 8.4\Data\general.log';
SET GLOBAL log_output = 'FILE';
```

**Cost to performance:** Significant. Every query is serialized to disk. High-throughput systems can see 20–50% throughput reduction.

**Reference:** [MySQL 8.4 Reference Manual 7.4.3](https://dev.mysql.com/doc/refman/8.4/en/query-log.html)

---

### b) Error Log with Connection Events: Limited

**What it captures (with log_error_verbosity >= 3):**
- Server startup and shutdown
- Connection initiation attempts (successful and failed)
- Disconnection events
- Authentication failures

**What it misses:**
- No SQL statement text
- No table access or data modification audit
- Verbosity is global—cannot filter per user
- Not structured for audit compliance

**Configuration:**
```sql
SET GLOBAL log_error_verbosity = 3;
```

**Cost:** Negligible. Connection events logged only during authentication.

**Reference:** [MySQL 8.4 Reference Manual 7.4.2](https://dev.mysql.com/doc/refman/8.4/en/error-log.html)

---

### c) Performance Schema: In-Memory, Ring-Buffered, Volatile

**What it captures:**
- accounts, users, hosts tables: connection statistics per account/user/host
- events_statements_history: most recent N ended statements per thread (default N=10)
- events_statements_history_long: most recent ~10000 ended statements globally
- Query text, timing, error code, rows affected, user, host, database

**What it misses:**
- No persistence to disk: lost on server restart
- Not append-only: fixed-size ring buffer overwrites old events
- Not tamper-resistant: any SELECT-privileged user can read
- No filtering: fixed instrumentation
- Buffer exhaustion: on 50 concurrent connections, 100 queries/sec, global buffer overflows in ~1.7 minutes

**CRITICAL:** Performance_schema is NOT designed as a durable audit trail. It is for profiling, not compliance logging.

**Reference:** [MySQL 8.4 Reference Manual 29.12.8](https://dev.mysql.com/doc/refman/8.4/en/performance-schema-connection-tables.html), [29.12.6](https://dev.mysql.com/doc/refman/8.4/en/performance-schema-statement-tables.html)

---

### SQL SECURITY DEFINER Views: Connected User vs Effective User

A critical distinction: **connected user** (who ran the query) vs **effective user** (whose privileges are checked). With SQL SECURITY DEFINER, execution uses creator's privileges, not caller's.

- General query log logs connected user, not effective user.
- Performance_schema logs connected user, not effective user.

For compliance auditing of DEFINER views, you must audit both the calling user and the creator separately. Free options do not provide this.

**Reference:** [MySQL 8.4 Reference Manual 27.8](https://dev.mysql.com/doc/refman/8.4/en/stored-objects-security.html)

---

## 3. Third-Party Free Plugins: Cannot Load on Stock Oracle MySQL 8.4 Community Windows

### Percona Audit_log Plugin

**Reality:**
- Built for Percona Server for MySQL only, not Oracle's Community Edition.
- Plugin ABI tied to server version and build flags. MySQL Extending documentation states: "Compiled plugins are not compatible across server versions." [MySQL Extending Manual](https://downloads.mysql.com/docs/extending-mysql-8.4-en.a4.pdf)
- No precompiled Windows binary documented for Oracle MySQL 8.4 Community.
- User attempting to install Percona Audit Log Filter component on Oracle MySQL 8.4.4 Community received error; Percona response: "Are you using the Percona Server for MySQL or the Upstream (Oracle) 8.4?" [Percona Community Forum](https://forums.percona.com/t/audit-log-filter-component-and-mysql-8-4/36704).

---

### MariaDB Server_audit Plugin

**Reality:**
- Compatible with MySQL 5.6 when plugin API was similar.
- In MySQL 5.7 and 8.0, plugin APIs diverged significantly.
- MariaDB's server_audit does NOT support MySQL 8.0 or later.
- Loading MariaDB server_audit.dll on MySQL 8.0+ Community returns: "ERROR 1126 (HY000): Can't open shared library 'server_audit.dll' (errno: 0 API version for AUDIT plugin is too different)" [MariaDB Jira MDEV-26998](https://jira.mariadb.org/browse/MDEV-26998).
- No compatibility effort since 2017.

---

### AWS Audit Plugin for MySQL

AWS created MariaDB audit plugin fork for RDS MySQL 8.0, but:
- No Windows support: "Amazon Linux OS only."
- No precompiled binary for download: requires source compilation.
- Not integrated into Oracle MySQL Community: RDS-specific only.

---

## 4. What an Audit Log Should Be: Standards

### NIST SP 800-92: Guide to Computer Security Log Management

[NIST SP 800-92 (2006)](https://csrc.nist.gov/pubs/sp/800/92/final) defines audit log properties:

1. **Completeness**
2. **Retention** — logs kept long enough to investigate an incident found late.
3. **Tamper resistance** — write-once or append-only storage, segregation from the production
   account, cryptographic signing, and least-privilege access to the log itself.
4. **Accountability** — the record must identify *who*, not just *what*.

[PCI-DSS Requirement 10](https://www.pcisecuritystandards.org/document_library/) is the other
standard worth citing: it requires per-user logging of all access to cardholder data, with the
individual user identified, and log integrity protection.

**None of MySQL Community's free options meets the tamper-resistance criterion**, and that is the
paper's argument: the general query log is a plain file writable by the server account, and
`performance_schema` is a ring buffer that overwrites itself. They are *instruments*, not audit
trails, and the chapter should say so in exactly those terms.

---

## 5. Recommendation for ticket 11

**Cheapest free path that produces a real trail on this machine: the general query log, hardened
at the file-system level.** Setup is minutes (`SET GLOBAL general_log = ON` plus `general_log_file`),
it runs on the existing stock server, and it risks nothing. Its cost is real \u2014 every statement
written synchronously, a large and fast-growing file \u2014 so it is turned on for the demonstration and
off afterwards, which is itself worth stating in the paper.

**Do not migrate the working server.** Percona Server for MySQL is free and ships the audit plugin,
but swapping the server build for one chapter's figure risks the install every other chapter depends
on. If a genuine plugin-based trail is wanted, install Percona Server **side by side on a different
port** rather than replacing 8.4 \u2014 and treat even that as optional.

**What to capture either way** (this is the chapter's real payload): run the same statement as two
different accounts, once directly and once through a `SQL SECURITY DEFINER` view, and show which
identity the log records. That single measurement is worth more than a feature comparison table.

---

## 6. Status of this memo

**Reconstructed tail, 2026-09-01.** Sections 4 (from "2. Retention") and 5 were lost when the
research subagent's heredoc truncated its own file; they are rewritten here from that subagent's
returned findings. Section 5's recommendation is deliberately more conservative than the subagent's
(which proposed migrating to Percona Server), because the map's standing preferences forbid risking
the working server. **The NIST SP 800-92 and PCI-DSS citations above must be verified against the
actual documents before either is written into `references.bib`** \u2014 they were not fetched in full.
