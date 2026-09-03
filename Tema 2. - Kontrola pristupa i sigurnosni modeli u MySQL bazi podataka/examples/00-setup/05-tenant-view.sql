-- 05-tenant-view.sql
-- Emulates branch (tenant) isolation for role_doctor with a filtered view - MySQL has no
-- native row-level security (memo 04), so this is Pattern A (CURRENT_USER()-driven) crossed
-- with Pattern B's intent (filter on context, not on a hardcoded value), avoiding Pattern B's
-- worst failure mode: nothing here is a session variable a client could SET to a different
-- branch. Instead the view looks up the caller's own branch from staff.mysql_account, which
-- only dbadmin can repoint (staff is not writable by any demo account).
--
-- This view is the "correct, narrower" alternative from ticket 08's least-privilege contrast;
-- it is built and available here so a later chapter (17, FGAC i RLS) can teach the contrast
-- against 04-roles-and-accounts.sql's deliberately broad role_doctor table grant. The broad
-- grant is NOT revoked in this ticket - see 04's note.
--
-- Run once, as dbadmin.

USE poliklinika;

DROP VIEW IF EXISTS v_my_branch_diagnoses;

CREATE
  DEFINER = 'dbadmin'@'localhost'
  SQL SECURITY INVOKER
  VIEW v_my_branch_diagnoses AS
SELECT d.diagnosis_id, d.visit_id, d.tenant_id, d.icd_code, d.diagnosis_text, d.staff_id
FROM diagnoses d
WHERE d.tenant_id = (
  SELECT s.tenant_id
  FROM staff s
  WHERE s.mysql_account = SUBSTRING_INDEX(CURRENT_USER(), '@', 1)
  LIMIT 1
);

-- SQL SECURITY INVOKER: the view runs with the calling account's own privileges, not
-- dbadmin's - so a doctor still needs (and already has, via role_doctor) SELECT on
-- diagnoses itself. The view adds a WHERE, it does not substitute for a grant.

GRANT SELECT ON poliklinika.v_my_branch_diagnoses TO role_doctor;
