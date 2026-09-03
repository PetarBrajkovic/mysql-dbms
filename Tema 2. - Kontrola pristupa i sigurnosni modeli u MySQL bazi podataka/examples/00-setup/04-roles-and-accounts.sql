-- 04-roles-and-accounts.sql
-- Creates the four roles from ticket 08's design and the 12 named demo accounts
-- (<role>_<branch>), then wires each account to its role as its DEFAULT ROLE so a plain
-- login already has the role's privileges active (activate_all_roles_on_login is OFF on
-- this server - see the learning record - so without a default role a fresh connection
-- would have none of the granted privileges until it ran SET ROLE itself).
--
-- Run once, as dbadmin (created in 03-dbadmin-account.sql), never as root: this is the
-- account whose own privilege scope (poliklinika.* plus CREATE USER/ROLE_ADMIN) is the
-- proof that admin work does not need root either.
--
-- Ordering trap: this script DROPs and recreates all four roles every time it runs, which
-- wipes any grant made directly TO a role after this script last ran - including
-- 05-tenant-view.sql's `GRANT SELECT ON v_my_branch_diagnoses TO role_doctor`. Re-run
-- 05-tenant-view.sql immediately after any re-run of this script (confirmed live - see the
-- learning record).
--
-- Deliberately the "obvious" grant, not yet the corrected one: role_doctor gets table-level
-- rights on diagnoses/visits/patients, which is broader than "own branch only" - a doctor
-- account can currently read another branch's diagnoses through the raw table. That gap, and
-- the branch-filtered view that narrows it, is 05-tenant-view.sql; ticket 08's least-privilege
-- contrast (lazy grant vs. correct one) is deliberately left visible here for that chapter to
-- use, not pre-fixed.

USE poliklinika;

-- 1. Roles -------------------------------------------------------------------------------
DROP ROLE IF EXISTS role_receptionist, role_nurse, role_doctor, role_billing;
CREATE ROLE role_receptionist, role_nurse, role_doctor, role_billing;

-- role_receptionist: schedules visits, manages invoices. No grant at all on diagnoses -
-- the ERROR 1142 (table access denied) demo.
GRANT SELECT, INSERT, UPDATE ON poliklinika.visits   TO role_receptionist;
GRANT SELECT, INSERT, UPDATE ON poliklinika.invoices TO role_receptionist;
GRANT SELECT ON poliklinika.patients                 TO role_receptionist;

-- role_nurse: triage needs icd_code, never diagnosis_text - the column-privilege demo
-- (mysql.columns_priv) and the ERROR 1143 (column access denied) case, plus the SELECT *
-- bypass claim under test in 06-verify.sql.
GRANT SELECT (diagnosis_id, visit_id, tenant_id, icd_code) ON poliklinika.diagnoses TO role_nurse;
GRANT SELECT ON poliklinika.visits                                                  TO role_nurse;
GRANT SELECT ON poliklinika.patients                                                TO role_nurse;

-- role_doctor: full read/write on the clinical tables. Branch scoping is NOT enforced here -
-- see the note above and 05-tenant-view.sql.
GRANT SELECT, INSERT, UPDATE ON poliklinika.diagnoses TO role_doctor;
GRANT SELECT, INSERT, UPDATE ON poliklinika.visits    TO role_doctor;
GRANT SELECT, INSERT, UPDATE ON poliklinika.patients  TO role_doctor;
-- staff (mysql_account, tenant_id only) so v_my_branch_diagnoses's subquery works under
-- SQL SECURITY INVOKER (05-tenant-view.sql) - the view does not borrow dbadmin's rights,
-- the caller needs its own.
GRANT SELECT (staff_id, tenant_id, mysql_account) ON poliklinika.staff TO role_doctor;

-- role_billing: updates payment status, sees patient contact fields, never touches
-- diagnoses (no grant at all - another ERROR 1142 case, and a second account to prove it
-- with, distinct from the receptionist).
GRANT SELECT ON poliklinika.invoices                              TO role_billing;
GRANT UPDATE (paid_status) ON poliklinika.invoices                TO role_billing;
GRANT SELECT (patient_id, tenant_id, full_name) ON poliklinika.patients TO role_billing;

-- 2. Accounts: <role>_<branch>, one per (role, branch) pair, 12 total. Every clinical
-- worker at a branch shares that branch's role account (staff.mysql_account already
-- encodes this - see 02-seed.sql) rather than one account per person; the paper's
-- connection-pooling discussion (memo 07) is about the shared-pool account this
-- deliberately is NOT (that strawman stays hypothetical, per ticket 08 section 4).
-- All demo accounts share one password here (a local teaching sandbox, not a production
-- system - see README.md); each account is host-locked to localhost.

DROP USER IF EXISTS
  'recept_podgorica'@'localhost', 'nurse_podgorica'@'localhost', 'doc_podgorica'@'localhost', 'billing_podgorica'@'localhost',
  'recept_niksic'@'localhost',    'nurse_niksic'@'localhost',    'doc_niksic'@'localhost',    'billing_niksic'@'localhost',
  'recept_bar'@'localhost',       'nurse_bar'@'localhost',       'doc_bar'@'localhost',       'billing_bar'@'localhost';

CREATE USER
  'recept_podgorica'@'localhost'  IDENTIFIED BY 'Demo#2026',
  'nurse_podgorica'@'localhost'   IDENTIFIED BY 'Demo#2026',
  'doc_podgorica'@'localhost'     IDENTIFIED BY 'Demo#2026',
  'billing_podgorica'@'localhost' IDENTIFIED BY 'Demo#2026',
  'recept_niksic'@'localhost'     IDENTIFIED BY 'Demo#2026',
  'nurse_niksic'@'localhost'      IDENTIFIED BY 'Demo#2026',
  'doc_niksic'@'localhost'        IDENTIFIED BY 'Demo#2026',
  'billing_niksic'@'localhost'    IDENTIFIED BY 'Demo#2026',
  'recept_bar'@'localhost'        IDENTIFIED BY 'Demo#2026',
  'nurse_bar'@'localhost'         IDENTIFIED BY 'Demo#2026',
  'doc_bar'@'localhost'           IDENTIFIED BY 'Demo#2026',
  'billing_bar'@'localhost'       IDENTIFIED BY 'Demo#2026';

-- 3. Grant each account its role and activate it by default.
GRANT role_receptionist TO 'recept_podgorica'@'localhost', 'recept_niksic'@'localhost', 'recept_bar'@'localhost';
GRANT role_nurse        TO 'nurse_podgorica'@'localhost',  'nurse_niksic'@'localhost',  'nurse_bar'@'localhost';
GRANT role_doctor       TO 'doc_podgorica'@'localhost',    'doc_niksic'@'localhost',    'doc_bar'@'localhost';
GRANT role_billing      TO 'billing_podgorica'@'localhost','billing_niksic'@'localhost','billing_bar'@'localhost';

SET DEFAULT ROLE role_receptionist TO 'recept_podgorica'@'localhost', 'recept_niksic'@'localhost', 'recept_bar'@'localhost';
SET DEFAULT ROLE role_nurse        TO 'nurse_podgorica'@'localhost',  'nurse_niksic'@'localhost',  'nurse_bar'@'localhost';
SET DEFAULT ROLE role_doctor       TO 'doc_podgorica'@'localhost',    'doc_niksic'@'localhost',    'doc_bar'@'localhost';
SET DEFAULT ROLE role_billing      TO 'billing_podgorica'@'localhost','billing_niksic'@'localhost','billing_bar'@'localhost';

-- No FLUSH PRIVILEGES: dbadmin does not have RELOAD (deliberately - see 03-dbadmin-account.sql),
-- and none is needed. GRANT/CREATE USER/SET DEFAULT ROLE are account-management statements that
-- trigger an implicit reload themselves (memo 03).
