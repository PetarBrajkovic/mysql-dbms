-- 02-seed.sql
-- Seeds `poliklinika` with 3 branches, 12 staff, ~90 patients, ~180 visits, ~180 diagnoses,
-- and ~90 invoices - a few hundred rows total, enough for role/branch demos to return
-- believable result sets without needing Tema 1's million-row generator.
--
-- Run once, after 01-schema.sql, as the same account (root). Safe to re-run: truncates the
-- data tables first (tenants stay small and fixed, so they are re-seeded too via TRUNCATE).

USE poliklinika;

SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE invoices;
TRUNCATE TABLE diagnoses;
TRUNCATE TABLE visits;
TRUNCATE TABLE patients;
TRUNCATE TABLE staff;
TRUNCATE TABLE tenants;
SET FOREIGN_KEY_CHECKS = 1;

-- 1. Branches --------------------------------------------------------------
INSERT INTO tenants (tenant_id, name, city) VALUES
  (1, 'Poliklinika Podgorica', 'Podgorica'),
  (2, 'Poliklinika Niksic',    'Niksic'),
  (3, 'Poliklinika Bar',       'Bar');

-- 2. Staff: 4 roles x 3 branches = 12 rows, one MySQL account name per (role, branch) pair.
-- The account itself is created in 04-roles-and-accounts.sql; this table is what
-- 05-tenant-view.sql joins against to turn "which account is connected" into "which branch".
INSERT INTO staff (tenant_id, full_name, role_name, mysql_account) VALUES
  (1, 'Ana Kovacevic',   'receptionist', 'recept_podgorica'),
  (1, 'Marija Jovanovic', 'nurse',       'nurse_podgorica'),
  (1, 'Petar Radovic',   'doctor',       'doc_podgorica'),
  (1, 'Ivana Peric',     'billing',      'billing_podgorica'),
  (2, 'Milos Vukovic',   'receptionist', 'recept_niksic'),
  (2, 'Jelena Backovic', 'nurse',        'nurse_niksic'),
  (2, 'Nikola Djuric',   'doctor',       'doc_niksic'),
  (2, 'Tijana Lakic',    'billing',      'billing_niksic'),
  (3, 'Vuk Popovic',     'receptionist', 'recept_bar'),
  (3, 'Sanja Miljanic',  'nurse',        'nurse_bar'),
  (3, 'Dusan Racic',     'doctor',       'doc_bar'),
  (3, 'Milena Vujovic',  'billing',      'billing_bar');

-- 3. Patients: 30 per branch, 90 total, via a recursive row generator.
INSERT INTO patients (tenant_id, full_name, dob)
WITH RECURSIVE seq AS (
  SELECT 1 AS n
  UNION ALL
  SELECT n + 1 FROM seq WHERE n < 90
)
SELECT
  ((n - 1) DIV 30) + 1                                   AS tenant_id,       -- 1..30 -> 1, 31..60 -> 2, 61..90 -> 3
  CONCAT('Pacijent ', LPAD(n, 3, '0'))                   AS full_name,
  DATE_SUB('2026-01-01', INTERVAL (18*365 + FLOOR(RAND() * 60*365)) DAY) AS dob
FROM seq;

-- 4. Visits: 2 per patient (180 total), attended by the doctor of the patient's own branch.
INSERT INTO visits (patient_id, tenant_id, staff_id, visit_date, chief_complaint)
WITH RECURSIVE seq AS (
  SELECT 1 AS n
  UNION ALL
  SELECT n + 1 FROM seq WHERE n < 180
)
SELECT
  p.patient_id,
  p.tenant_id,
  (SELECT s.staff_id FROM staff s WHERE s.tenant_id = p.tenant_id AND s.role_name = 'doctor'),
  DATE_SUB('2026-01-15', INTERVAL FLOOR(RAND() * 300) DAY),
  ELT(1 + FLOOR(RAND() * 6),
      'Glavobolja', 'Povisena temperatura', 'Bol u ledjima', 'Kontrolni pregled',
      'Alergijska reakcija', 'Bol u grudima')
FROM seq
JOIN patients p ON p.patient_id = ((seq.n - 1) DIV 2) + 1;

-- 5. Diagnoses: one per visit (180 total), recorded by that visit's attending doctor.
INSERT INTO diagnoses (visit_id, tenant_id, icd_code, diagnosis_text, staff_id)
SELECT
  v.visit_id,
  v.tenant_id,
  ELT(1 + FLOOR(RAND() * 5), 'R51', 'J06.9', 'M54.5', 'Z00.0', 'T78.4'),
  CONCAT('Nalaz za posetu #', v.visit_id, ': ',
         ELT(1 + FLOOR(RAND() * 4),
             'blaga infekcija gornjih disajnih puteva, preporucen odmor',
             'sumnja na migrenu, propisana terapija',
             'mehanicki bol u ledima, uput na fizikalnu terapiju',
             'kontrola bez patoloskog nalaza')),
  v.staff_id
FROM visits v;

-- 6. Invoices: one per patient (90 total), amounts and status vary.
INSERT INTO invoices (patient_id, tenant_id, amount, paid_status)
SELECT
  p.patient_id,
  p.tenant_id,
  ROUND(20 + RAND() * 180, 2),
  ELT(1 + FLOOR(RAND() * 3), 'paid', 'unpaid', 'overdue')
FROM patients p;
