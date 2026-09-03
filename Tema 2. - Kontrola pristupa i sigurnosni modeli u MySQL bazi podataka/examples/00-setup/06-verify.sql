-- 06-verify.sql
-- Proof-of-enforcement checks and the three research claims ticket 08 flagged for live
-- testing. Not one connection: each section is commented with which account must run it -
-- run each section's statements with `mysql --defaults-extra-file=<account>.cnf -D poliklinika`
-- for that account, not all as dbadmin. Results as observed on 8.4.11 are recorded inline
-- and in the learning record.

-- =========================================================================================
-- 1. Role activation on a fresh login (memo 03/07): activate_all_roles_on_login is OFF on
--    this server, so this only works because 04-roles-and-accounts.sql set a DEFAULT ROLE
--    for every demo account.
-- Run as: any demo account, e.g. recept_podgorica
SELECT CURRENT_USER(), CURRENT_ROLE();
-- Observed: CURRENT_ROLE() = `role_receptionist`@`%` immediately, no SET ROLE needed.

-- =========================================================================================
-- 2. Table-level denial (ERROR 1142): role_receptionist and role_billing have no grant at
--    all on diagnoses.
-- Run as: recept_podgorica
SELECT * FROM diagnoses LIMIT 1;
-- Observed: ERROR 1142 (42000): SELECT command denied to user 'recept_podgorica'@'localhost'
-- for table 'diagnoses'.

-- =========================================================================================
-- 3. Column-level denial (ERROR 1143) and the SELECT * bypass claim (memo 04, bug #41354):
--    role_nurse has SELECT on icd_code but not diagnosis_text.
-- Run as: nurse_podgorica
SELECT diagnosis_id, icd_code FROM diagnoses LIMIT 2;         -- allowed
SELECT diagnosis_text FROM diagnoses LIMIT 1;                 -- ERROR 1143 (named column)
SELECT * FROM diagnoses LIMIT 1;                               -- claim under test
-- Observed on 8.4.11: SELECT * also fails, with ERROR 1142 (not 1143, and not a silent
-- bypass returning every column as bug #41354 described). CORRECTS memo 04: the bypass this
-- server exhibits is none - see the learning record for the full correction and the
-- likely reason (the bug report predates 8.0's privilege-checking rewrite).

-- =========================================================================================
-- 4. Branch isolation: the raw table grant is broad (any doctor account can see every
--    branch's diagnoses); v_my_branch_diagnoses is the narrower, correct alternative.
-- Run as: doc_podgorica
SELECT DISTINCT tenant_id FROM diagnoses ORDER BY tenant_id;             -- expect 1, 2, 3 (the leak)
SELECT DISTINCT tenant_id FROM v_my_branch_diagnoses ORDER BY tenant_id; -- expect only 1
-- Run as: doc_niksic
SELECT DISTINCT tenant_id FROM v_my_branch_diagnoses ORDER BY tenant_id; -- expect only 2
-- Observed: exactly as expected on both counts - confirms the view isolates by branch while
-- the raw table grant does not.

-- =========================================================================================
-- 5. dbadmin is not root: dbadmin's own scope excludes the mysql system database.
-- Run as: dbadmin
SELECT user, host FROM mysql.user LIMIT 1;
-- Observed: ERROR 1142 (42000): SELECT command denied to user 'dbadmin'@'localhost' for
-- table 'user' - dbadmin cannot read mysql.user despite being able to create accounts in it
-- via CREATE USER (a global dynamic-ish administrative privilege, not a table grant).
