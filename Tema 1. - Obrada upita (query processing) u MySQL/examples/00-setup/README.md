# 00-setup

Builds the synthetic wide table `obrada_upita.wide_events`: a 5,000,000-row, ~19-column
table designed so the optimizer has real decisions to make (Sakila is too small - table
scans win trivially there and chapters 3, 4, 6, and 7 would have nothing to show).

## Run order

1. `01-schema.sql` - creates the `obrada_upita` schema and the table (no secondary
   indexes yet).
2. `02-generate.sql` - generates 5,000,000 rows in five batches of 1,000,000. Takes a
   few minutes; watch for the `Batch N/5 done` messages between batches. To generate a
   different amount, edit `SET @batches = 5;` near the bottom before running.
3. `03-index-and-analyze.sql` - adds the secondary indexes and runs `ANALYZE TABLE` so
   the optimizer's row-estimate statistics are fresh.
4. `04-verify.sql` - sanity checks: row count, table size on disk, the country_code
   skew, and a couple of `EXPLAIN`s that should show the optimizer making opposite
   access-path decisions on the same index depending on which value is filtered.

Run all four in order, top to bottom, the first time. Re-running 02 on its own adds
another 5,000,000 rows on top of whatever is already there - `01-schema.sql` is the one
that resets the table (it drops and recreates `wide_events`).

## How to run

**MySQL Workbench**: File > Open SQL Script..., open each file in order, then the
lightning-bolt "Execute" button (or Ctrl+Shift+Enter to run the whole script).

**Command line**, from this folder, one connection per file so `02`'s stored procedures
and session variables don't leak into unrelated scripts:
```
mysql -u root -p < 01-schema.sql
mysql -u root -p < 02-generate.sql
mysql -u root -p < 03-index-and-analyze.sql
mysql -u root -p < 04-verify.sql
```

The MySQL84 Windows service must be running first (Services app, or `net start MySQL84`
from an elevated terminal).

## What the columns are for

See the comments in `01-schema.sql` and `03-index-and-analyze.sql` - every column and
index exists for a specific chapter's worked example, not just to pad the row count.
