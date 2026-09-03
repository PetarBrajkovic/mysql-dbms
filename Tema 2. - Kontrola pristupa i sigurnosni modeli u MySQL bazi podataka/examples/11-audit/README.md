# 11-audit — ticket 11 evidence

What this folder proves: **the general query log records the connecting account, not the
account whose privileges actually served the query.** When a `SQL SECURITY DEFINER` view is
involved, that gap means the log alone cannot show that elevated (definer) privileges were used
— you have to already know which views are `DEFINER` and who defined them.

## Files

| # | File | Run as | What it does |
|---|---|---|---|
| 1 | `01-definer-view.sql` | dbadmin | Creates `v_definer_demo`, a `SQL SECURITY DEFINER` view over `diagnoses` that also selects `USER()` and `CURRENT_USER()` as columns, and grants it to `role_receptionist` (which has no other grant on `diagnoses` at all — `00-setup/04`). |
| 2 | `02-run-demo.sql` | recept_podgorica, then doc_podgorica | The captured statements: direct `diagnoses` access denied, the same data reachable through the view, and a doctor's direct grant for contrast. |
| — | `captured-view-result.txt` | — | The view's actual result set: `connected_user` stays `recept_podgorica@localhost`, `effective_user` becomes `dbadmin@localhost`. |
| — | `captured-general-log.txt` | — | The general query log covering the same three connections — every `Connect` line names the login account only; nothing in the log says the third query ran with `dbadmin`'s privileges. |

## Why there's no plugin here

Ticket 06 already established (research memo, `.scratch/kontrola-pristupa/research/06-audit-logging.md`)
that neither Percona's `audit_log` nor MariaDB's `server_audit` loads into stock Oracle MySQL 8.4
Community — different plugin ABI, no Windows binary for this combination. Confirmed again here:
`SHOW PLUGINS` on this server lists no `AUDIT`-type plugin besides the two built-in cache
cleaners, and the plugin directory has no third-party audit `.dll` to attempt loading. There was
nothing to install, so nothing was risked — the map's "do not risk the working server" rule was
never tested.

## How the general log was produced (not scripted — needs root)

`dbadmin` cannot toggle `general_log` (`ERROR 1227`: needs `SUPER` or
`SYSTEM_VARIABLES_ADMIN`, deliberately not granted — least privilege, ticket 10). Root ran, by
hand, once:

```sql
SET GLOBAL log_output = 'FILE';
SET GLOBAL general_log_file = 'C:/ProgramData/MySQL/MySQL Server 8.4/Uploads/tema2-audit-demo.log';
SET GLOBAL general_log = ON;
-- (02-run-demo.sql executed here, as the three accounts)
SET GLOBAL general_log = OFF;
SET GLOBAL general_log_file = DEFAULT;
```

The log file was written under `.../Uploads/`, MySQL's `secure_file_priv` directory — the only
path `LOAD_FILE()` is allowed to read from a SQL session, which is how `captured-general-log.txt`
was pulled out (the OS-level file itself is owned by the MySQL service account; a normal user
account cannot open it directly on this machine).

**Cost of leaving this on**, confirmed by the memo and worth repeating in the chapter: every
statement is written to disk synchronously. It was on for the width of one demo and switched
back off immediately.

## Read this together with

- `examples/00-setup/05-tenant-view.sql` — the `SQL SECURITY INVOKER` counterpart, built for a
  different reason (narrowing a doctor's own privileges, not substituting the definer's).
- `learning-records/0002-audit-log-vs-definer-identity.md` — the write-up of what this proves and
  the one correction it makes to memo 06.
