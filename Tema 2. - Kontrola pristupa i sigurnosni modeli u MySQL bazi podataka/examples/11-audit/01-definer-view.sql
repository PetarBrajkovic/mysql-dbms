-- 01-definer-view.sql
-- Ticket 11: builds the one artifact this chapter needs - a SQL SECURITY DEFINER view that
-- lets an account with NO grant on `diagnoses` read through it anyway, using the view
-- definer's (dbadmin's) privileges instead of its own. The view also surfaces USER() and
-- CURRENT_USER() as columns so their split under DEFINER security is visible in the result
-- set itself, not just inferred.
--
-- Contrast with examples/00-setup/05-tenant-view.sql, which is SQL SECURITY INVOKER on
-- purpose (memo 04 / record 0001 insight 3): that view narrows a doctor's own privileges,
-- this one substitutes the definer's.
--
-- Run once, as dbadmin.

USE poliklinika;

DROP VIEW IF EXISTS v_definer_demo;

CREATE
  DEFINER = 'dbadmin'@'localhost'
  SQL SECURITY DEFINER
  VIEW v_definer_demo AS
SELECT
  USER()          AS connected_user,   -- who actually logged in (never changes with DEFINER)
  CURRENT_USER()  AS effective_user,   -- whose privileges are being checked (the definer, here)
  diagnosis_id, tenant_id, icd_code
FROM diagnoses
LIMIT 3;

-- role_receptionist has no grant at all on `diagnoses` (00-setup/04, the ERROR 1142 case) -
-- this GRANT is the only door recept_* accounts get to diagnoses data, and it opens because
-- the view runs as dbadmin, not as them.
GRANT SELECT ON poliklinika.v_definer_demo TO role_receptionist;
