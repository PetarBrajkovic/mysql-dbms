# examples/04-fgac-i-rls

Runnable evidence for chapter 4, "Fino-granularna kontrola pristupa i red-level security". Both
scripts were run on MySQL 8.4.11 on 2026-09-10 and their captured output is recorded in
`.scratch/kontrola-pristupa/measurements/0005-fgac-i-rls.md`. Neither touches the sandbox data.

| Script | Claim it demonstrates | Connections needed |
|---|---|---|
| `01-ko-pita.sql` | `USER()` is frozen at login and can never be the definer; `CURRENT_USER()` becomes the definer inside a `SQL SECURITY DEFINER` view — so a filter on `CURRENT_USER()` there filters by the wrong person | `dbadmin`, then `doc_podgorica` in a second connection |
| `02-with-check-option.sql` | A view's `WHERE` constrains what is seen, not what may be written: without `WITH CHECK OPTION` a row lands in the base table and is invisible through the view that accepted it (`ERROR 1369` with the clause) | `dbadmin` only |

## The measured result worth quoting

```
ko_se_konektovao          cija_se_prava_proveravaju
doc_podgorica@localhost   dbadmin@localhost
```

One result row, two identities. Both hosts read `localhost` only because the client runs on the
server machine — this capture does not exercise wildcard host matching, so do not present it as
evidence of that.

## Note on 02

The second `INSERT` is **meant** to fail. `Error Code: 1369. CHECK OPTION failed
'poliklinika.v_sa_proverom'` is the expected result, not a setup problem. The pair of row counts
that follows (`1 row` in the table, `0 rows` through the view) is the actual finding.

## Related

The sandbox's own RLS emulation, `v_my_branch_diagnoses`, is built in `../00-setup/05-tenant-view.sql`
and is `SQL SECURITY INVOKER` — it demonstrates the opposite case, where the caller needs grants on
every table the view touches, including tables used only by the filter subquery.
