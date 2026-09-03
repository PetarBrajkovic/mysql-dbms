# Measurements — chapter 2, DAC delegation and non-cascading REVOKE

Server: MySQL 8.4.11 Community, Win64. Run by the user in Workbench, two connections
(`dbadmin`@`localhost` and `demo_boris`@`localhost`), 2026-09-04.
Script: `examples/02-klasicni-modeli/01-dac-kaskadno-oduzimanje.sql`.
Record: `learning-records/0003-klasicni-modeli-kontrole-pristupa.md`.

## What was run

1. As `dbadmin`: created `demo_boris`@`localhost` and `demo_ceca`@`localhost`;
   `GRANT SELECT ON poliklinika.patients TO 'demo_boris'@'localhost' WITH GRANT OPTION`.
2. As `demo_boris`: `GRANT SELECT ON poliklinika.patients TO 'demo_ceca'@'localhost'`.
3. As `dbadmin`: `REVOKE SELECT ON poliklinika.patients FROM 'demo_boris'@'localhost'`.

## Observed output

`SHOW GRANTS FOR 'demo_boris'@'localhost';` after the revoke:

```
GRANT USAGE ON *.* TO `demo_boris`@`localhost`
GRANT USAGE ON `poliklinika`.`patients` TO `demo_boris`@`localhost` WITH GRANT OPTION
```

`SHOW GRANTS FOR 'demo_ceca'@'localhost';` after the same revoke:

```
GRANT USAGE ON *.* TO `demo_ceca`@`localhost`
GRANT SELECT ON `poliklinika`.`patients` TO `demo_ceca`@`localhost`
```

## Two separate findings, both usable in the chapter

**1. No cascade.** Ceca keeps `SELECT` on `poliklinika.patients` after the account that authorised
her lost it. Standard SQL would have removed it. Matches the manual's own statement of the
difference (8.4 refman 15.7.1.6, "MySQL and Standard SQL Versions of GRANT"). Her grant row is
free-standing; only an explicit `REVOKE` against her, or `DROP USER`, removes it.

**2. `GRANT OPTION` survives the revoke of the privilege it applied to.** `REVOKE SELECT` left a
`USAGE ... WITH GRANT OPTION` row on the table. `USAGE` displays "no privileges at all", so Boris
holds nothing on that table yet keeps the delegation capability, which needs its own statement:

```sql
REVOKE GRANT OPTION ON poliklinika.patients FROM 'demo_boris'@'localhost';
```

Consequence, in the manual's own words (same section): *"any privileges the user possesses (or may
be given in the future) at that level can also be granted by that user to other users."* So a
future `GRANT INSERT` to Boris is immediately re-delegable, with nobody having granted delegation
again. Revoking in MySQL does not restore the pre-`GRANT` state; it leaves residue.

## The sharpest supporting fact (manual, not measured)

`mysql.tables_priv` **has** a `Grantor` column, and the manual says of it:

> "The `Timestamp` and `Grantor` columns are set to the current timestamp and the `CURRENT_USER`
> value, respectively, but are otherwise unused."
> — MySQL 8.4 Reference Manual, 8.2.3 Grant Tables

The provenance needed for a cascade is therefore recorded and then ignored. Non-cascading revoke
is a design decision, not a data limitation. **Not yet verified against the live table** — reading
`mysql.tables_priv` requires root, `dbadmin` is denied (see record 0001). Run before citing the
row contents; the manual quote itself needs no verification beyond the page.

## For rad.md

Chapter 2 closes its DAC section with this pair: the model says the branch falls with the root,
MySQL leaves it hanging, and it does so while holding the very column that would let it do
otherwise. Cite the manual for both statements and this measurement for the demonstration.
