# Measurements — 0005 FGAC i RLS (chapter 4)

Run by the user, 2026-09-10, MySQL 8.4.11 Community Server GPL Win64, MySQL Workbench, two
connections (`dbadmin`@`localhost` for DDL, `doc_podgorica` for the read). Both demos ran clean and
matched the lesson's stated expectations exactly, including the error code.

Scripts promoted to `examples/04-fgac-i-rls/`.

## 1 — `USER()` vs `CURRENT_USER()` inside a `SQL SECURITY DEFINER` view

View `poliklinika.v_ko_pita`, `DEFINER = 'dbadmin'@'localhost'`, `SQL SECURITY DEFINER`, granted to
`role_doctor`. Selected from a `doc_podgorica` connection:

```
ko_se_konektovao          cija_se_prava_proveravaju
doc_podgorica@localhost   dbadmin@localhost
```

**This is the chapter's own strongest capture.** One result row carries both identities at once:
`USER()` is the account that connected and is frozen at login; `CURRENT_USER()` has become the
definer, because it names the account whose grant rows are being consulted. Previously sourced from
refman 27.6 only — now measured.

Both accounts show host `localhost` here simply because the client runs on the server machine; the
wildcard-matching distinction (`doc@192.168.1.5` vs `doc@%`) is not exercised by this capture and
should not be presented as if it were.

Cross-reference: record 0002 measured the same split from the other side — the general query log
records the connecting account, never the definer.

## 2 — `WITH CHECK OPTION` on writes

Table `poliklinika.t_proba (id INT, tenant_id INT)`, two views over `WHERE tenant_id = 2`: one plain,
one `WITH CASCADED CHECK OPTION`. Both `INSERT`s carry `tenant_id = 3`, i.e. another branch.

| Statement | Result |
|---|---|
| `INSERT INTO v_bez_provere VALUES (1, 3)` | `1 row(s) affected` |
| `INSERT INTO v_sa_proverom VALUES (2, 3)` | `Error Code: 1369. CHECK OPTION failed 'poliklinika.v_sa_proverom'` |
| `SELECT * FROM t_proba` | `1 row(s) returned` |
| `SELECT * FROM v_bez_provere` | `0 row(s) returned` |

The pair of counts is the whole argument in two numbers: **the row exists in the base table and is
invisible through the view that accepted it.** Without the clause the view's `WHERE` takes no part in
the write path; with it, the same statement fails.

Exact error text for quoting: `Error Code: 1369. CHECK OPTION failed 'poliklinika.v_sa_proverom'`.

Both views and `t_proba` were dropped afterwards; the `poliklinika` sandbox is unchanged.

## Write-up notes

- Chapter 4 can present both captures as this paper's own output, not as manual quotes.
- The `1 row / 0 rows` contrast is the better figure candidate of the two — it needs no explanation
  of privileges at all to make the point that filtering is not enforcement.
