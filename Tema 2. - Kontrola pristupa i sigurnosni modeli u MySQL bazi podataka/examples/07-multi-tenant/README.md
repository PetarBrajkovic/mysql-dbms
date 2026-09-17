# examples/07-multi-tenant

Runnable evidence for chapter 7, "Multi-tenant bezbednosni modeli". Both scripts were run on
MySQL 8.4.11 on 2026-09-17 and their captured output is recorded in
`.scratch/kontrola-pristupa/measurements/0008-multi-tenant.md`. Neither creates, alters or deletes
anything: they only read, and the shared-pool account the chapter argues about is deliberately
**not** built on the server (it stays a prose strawman, per ticket 08 section 4 and ticket 20).

| Script | Claim it demonstrates | Connection |
|---|---|---|
| `01-domasaj-naloga.sql` | The least-privilege measure is *reach*: a branch account reads all three branches through the base table (the grant names the table, and the table holds every tenant's rows) while the filtered view shows only its own. `SHOW GRANTS` contains no mention of a branch at all. | `doc_bar` |
| `02-krpa-korisnicka-promenljiva.sql` | `SET @tenant_id = ...` is not access control: one assignment moves the same account, in the same session, from its own branch to another one, with no grant and no error. | `doc_bar` |

Both run as `doc_bar`@`localhost` (password `Demo#2026`, as for every demo account, see
`../00-setup/README.md`):

```
mysql -h 127.0.0.1 -u doc_bar -p -D poliklinika --table < 01-domasaj-naloga.sql
```

## The measured result worth quoting

Same account, same data, two access paths:

```
base table diagnoses          view v_my_branch_diagnoses
tenant_id  redova             tenant_id  redova
1          60                 3          60
2          60
3          60
```

The view narrows what is **seen**; it does not narrow what is **allowed**. The row counts are equal
per branch only because the seed data is uniform; the argument is the set of `tenant_id` values that
comes back, not the counts, so do not quote the counts in prose as if they meant anything else.

## Why no silo script

The silo (database-per-tenant) pattern would need a second database and a second account created
just to show a `GRANT ... ON pod_bar.*`, i.e. new server state for a claim the two-stage check of
chapter 3 already proves. It is argued in prose instead. The sandbox itself is the silo pattern's
subject-side half: 12 `<role>_<branch>` accounts, each its own row in `mysql.user`, which is exactly
what makes `CURRENT_USER()` carry the branch.

## Related

`../00-setup/05-tenant-view.sql` builds `v_my_branch_diagnoses` (`SQL SECURITY INVOKER`), and
`../04-fgac-i-rls/01-ko-pita.sql` measures the `USER()`/`CURRENT_USER()` split the pooling argument
in this chapter rests on.
