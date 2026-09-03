# 0002 — Audit logging: what's free, and what it can't tell you (ticket 11)

Not a taught lesson — execution record for ticket 11, which resolves memo 06's recommendation
against the map's free-only, don't-risk-the-server constraints. Chapter 19 (Audit logging) reads
this directly.

## What was built

`examples/11-audit/`: `v_definer_demo`, a `SQL SECURITY DEFINER` view over `diagnoses` that also
returns `USER()`/`CURRENT_USER()` as columns, granted to `role_receptionist` (no other grant on
`diagnoses`). Three statements run as `recept_podgorica` and `doc_podgorica` while `general_log`
was briefly on, captured to `captured-view-result.txt` and `captured-general-log.txt`.

Measured on the same server as record 0001: MySQL 8.4.11 Community, Win64.

## Non-obvious insights

1. **There was no install to attempt.** Memo 06 predicted Percona's `audit_log` and MariaDB's
   `server_audit` would not load into this server; `SHOW PLUGINS` confirms no `AUDIT`-class
   plugin is even present besides the two built-in cache cleaners, and the plugin directory has
   no third-party audit `.dll` sitting there to try. The timebox in ticket 11 step 1 resolved
   before it started — nothing was risked because nothing was attempted against the live server.
2. **The general query log names the connecting account, never the effective one.** Every
   `Connect` line in `captured-general-log.txt` reads `recept_podgorica@localhost` for all three
   of that account's statements, including the one that returned rows from `diagnoses` — a table
   `recept_podgorica` has no grant on at all. The log gives no hint that the third statement ran
   under `v_definer_demo`'s definer (`dbadmin`). You would need to already know the view is
   `SQL SECURITY DEFINER` and who defined it to reconstruct what actually authorized that read.
   This is memo 06's "connected user vs. effective user" gap, now measured rather than asserted
   from the manual.
3. **`dbadmin` cannot toggle `general_log` — this had to run as root.** `SET GLOBAL general_log`
   needs `SUPER` or `SYSTEM_VARIABLES_ADMIN`, neither granted to `dbadmin` (ticket 10's
   deliberately narrow scope). This is itself a small least-privilege data point worth a
   sentence: the account doing the demo cannot switch on the very log meant to watch it.
4. **`LOAD_FILE()` is the only path back into the log without OS-admin rights.** The MySQL data
   directory is owned by the service account; a normal Windows user (this machine's own account)
   gets `Access is denied` opening the log file directly. `secure_file_priv` scopes `LOAD_FILE()`
   to one directory (`.../Uploads/`); pointing `general_log_file` there at record time, then
   reading it back with `SELECT LOAD_FILE(...)` as root, is what produced
   `captured-general-log.txt`. Worth a footnote if the paper shows this reproduction path — it is
   not how a production DBA would retrieve a log file, just how this sandbox's file permissions
   forced it.
5. **`mysql`-CLI batch output escapes literal tabs/newlines by default.** A first capture via
   plain `-N` printed the log's tabs and newlines as literal `\t`/`\n` text instead of real
   whitespace. Fixed with `--raw`. Worth remembering for any later chapter that pulls raw text
   out through a `SELECT` in batch mode.

## Correction filed against memo 06

None of memo 06's claims were overturned. Its central prediction — no free plugin loads on this
server — held exactly, and its sharpest suggested measurement (definer vs. connected identity in
the log) is now proven rather than argued. The NIST SP 800-92 / PCI-DSS citation-verification
task the memo flagged is still open and belongs to whoever writes chapter 19's citations, not to
this ticket.

## Server state after this ticket

`general_log` is `OFF`, `general_log_file` reset to its server default
(`.../Data/DESKTOP-UR43C5V.log`). The one-off capture file
(`.../Uploads/tema2-audit-demo.log`) is left on disk outside the repo; it is not required for
anything further and is not committed (only its `LOAD_FILE()` text pull is, under
`examples/11-audit/`).

## What comes next

Chapter 19 (Audit logging) writes from this record and `examples/11-audit/`: the "instruments,
not audit trails" framing from memo 06, this ticket's connected-vs-effective-identity proof as
the chapter's centerpiece figure, and the NIST SP 800-92 / PCI-DSS citations once verified.
