# Measurements 0008 - chapter 7, multi-tenant

Server: MySQL 8.4.11 Community, Win64. Date: 2026-09-17. Connection: `doc_bar`@`localhost`
(a Bar-branch account, `role_doctor` active as its default role). Scripts:
`examples/07-multi-tenant/01-domasaj-naloga.sql`, `examples/07-multi-tenant/02-krpa-korisnicka-promenljiva.sql`.
Read-only; no server state was created or changed, and no shared-pool account exists.

## 01-domasaj-naloga.sql

```
+-------------------+---------------------------+
| ko_se_konektovao  | cija_se_prava_proveravaju |
+-------------------+---------------------------+
| doc_bar@localhost | doc_bar@localhost         |
+-------------------+---------------------------+

diagnoses (base table)          v_my_branch_diagnoses
+-----------+--------+          +-----------+--------+
| tenant_id | redova |          | tenant_id | redova |
+-----------+--------+          +-----------+--------+
|         1 |     60 |          |         3 |     60 |
|         2 |     60 |          +-----------+--------+
|         3 |     60 |
+-----------+--------+

Grants for doc_bar@localhost
GRANT USAGE ON *.* TO `doc_bar`@`localhost`
GRANT SELECT, INSERT, UPDATE ON `poliklinika`.`diagnoses` TO `doc_bar`@`localhost`
GRANT SELECT, INSERT, UPDATE ON `poliklinika`.`patients` TO `doc_bar`@`localhost`
GRANT SELECT (`mysql_account`, `staff_id`, `tenant_id`) ON `poliklinika`.`staff` TO `doc_bar`@`localhost`
GRANT SELECT ON `poliklinika`.`v_ko_pita` TO `doc_bar`@`localhost`
GRANT SELECT ON `poliklinika`.`v_my_branch_diagnoses` TO `doc_bar`@`localhost`
GRANT SELECT, INSERT, UPDATE ON `poliklinika`.`visits` TO `doc_bar`@`localhost`
GRANT `role_doctor`@`%`,`role_senior_doctor`@`%` TO `doc_bar`@`localhost`
```

**Finding.** Reach through the base table is all three tenants; reach through the filtered view is
one. Not a single line of `SHOW GRANTS` mentions a branch, which is the chapter's whole point: the
grant names a table, and the table holds every tenant's rows. Note `USER()` and `CURRENT_USER()`
agree here only because the account is host-locked to `localhost` and connects from the server
machine; this capture is *not* evidence about wildcard host matching (same caveat as measurement
0005).

## 02-krpa-korisnicka-promenljiva.sql

```
SET @tenant_id = 3;   ->  prijavljeni_tenant 3, redova 60
SET @tenant_id = 1;   ->  prijavljeni_tenant 1, redova 60
CURRENT_USER() = doc_bar@localhost   (unchanged throughout)
```

**Finding.** One assignment moves the same account, in the same session, out of its own branch and
into another one: no grant, no role activation, no error. The authenticated identity never changes
while the "tenant" value is rewritten at will. This is chapter 4's Pattern B failing in the setting
that motivates it.

## Numbers used in prose

Only the *set* of `tenant_id` values (three vs. one) is quoted in `rad.md`, never the row counts,
per `../../../WRITING.md`'s rule on absolute numbers. The counts are uniform (60 per branch) only
because the seed data is uniform.
