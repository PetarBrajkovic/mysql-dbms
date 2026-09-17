-- Bug #41354, retested in its OWN setup (final pass, ticket 13).
--
-- Why this file exists: chapter 4 originally tested the bug's claim against a BASE TABLE, but
-- bug #41354 ("Access control is bypassed when all columns of a view are selected by * wildcard")
-- is specifically about column privileges on a SQL SECURITY DEFINER *view*. Testing the adjacent
-- case is not testing the claim, so the claim is retested here on the exact object the bug names.
--
-- Run as dbadmin:
--   mysql --defaults-extra-file=../../mysql-credentials.cnf -D poliklinika < 04-bug41354-na-pogledu.sql
-- then run the three probes at the bottom as the created account.
--
-- Measured on MySQL 8.4.11 Community, Win64, 2026-09-17.

DROP VIEW IF EXISTS v_bug41354;
DROP USER IF EXISTS 'probni41354'@'localhost';

-- A definer view over a table the probe account has no privilege on at all,
-- exactly as in the bug report (the view exists precisely so the caller need
-- not hold rights on the base table).
CREATE SQL SECURITY DEFINER VIEW v_bug41354 AS
  SELECT diagnosis_id, tenant_id, icd_code, diagnosis_text FROM diagnoses;

CREATE USER 'probni41354'@'localhost' IDENTIFIED BY 'Probni#41354x';

-- One column of the view only. The bug claims `SELECT *` escapes this limit.
GRANT SELECT (icd_code) ON poliklinika.v_bug41354 TO 'probni41354'@'localhost';

/* ---------------------------------------------------------------------------
   Probes, run as 'probni41354'@'localhost':

   A) SELECT * FROM v_bug41354 LIMIT 2;
      MEASURED 8.4.11:
      ERROR 1143 (42000): SELECT command denied to user 'probni41354'@'localhost'
                          for column 'diagnosis_id' in table 'v_bug41354'
      -> The bug does NOT reproduce. `*` is expanded and checked column by column,
         and the check stops at the first ungranted column, not at the requested one.

   B) SELECT icd_code FROM v_bug41354 LIMIT 2;   -- granted column
      MEASURED: returns rows (J06.9, M54.5). The grant itself works.

   C) SELECT diagnosis_text FROM v_bug41354 LIMIT 2;   -- ungranted column
      MEASURED: ERROR 1143, naming 'diagnosis_text'.

   Note the error NUMBER differs from the base-table probe in 03-column-privilege-pair.sql:
   there, `SELECT *` on `diagnoses` fails with 1142 (no table-level privilege at all),
   here with 1143, because the account does hold a column privilege on the view and so
   reaches the column-level check. Same verdict, different level.
   --------------------------------------------------------------------------- */

-- Cleanup (the paper's sandbox is left exactly as ticket 10 built it):
-- DROP VIEW IF EXISTS v_bug41354;
-- DROP USER IF EXISTS 'probni41354'@'localhost';
