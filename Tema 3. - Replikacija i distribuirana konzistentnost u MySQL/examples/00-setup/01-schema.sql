-- 01-schema.sql
-- Creates the `poliklinika` schema: a small multi-branch outpatient clinic group.
-- Run once, as root (or another account with CREATE DATABASE). Safe to re-run: drops the
-- schema first.
--
-- Every clinical/financial table carries tenant_id - the branch boundary later chapters
-- filter on. There is no native row-level security in MySQL 8.4 (see research memo 04);
-- that filtering is emulated with a view in 05-tenant-view.sql, not enforced here.

DROP DATABASE IF EXISTS poliklinika;

CREATE DATABASE poliklinika
  CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;

USE poliklinika;

-- One row per branch (podruznica): Podgorica, Niksic, Bar.
CREATE TABLE tenants (
  tenant_id   TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
  name        VARCHAR(60)      NOT NULL,
  city        VARCHAR(60)      NOT NULL,
  PRIMARY KEY (tenant_id)
) ENGINE = InnoDB;

-- Maps a person to the MySQL account they log in as. Multiple staff rows can share one
-- account (accounts are named <role>_<branch>, not one account per person) - see
-- 04-roles-and-accounts.sql. mysql_account is what 05-tenant-view.sql joins on to derive
-- "which branch is this connection allowed to see".
CREATE TABLE staff (
  staff_id      INT UNSIGNED NOT NULL AUTO_INCREMENT,
  tenant_id     TINYINT UNSIGNED NOT NULL,
  full_name     VARCHAR(100)     NOT NULL,
  role_name     VARCHAR(30)      NOT NULL,   -- receptionist | nurse | doctor | billing
  mysql_account VARCHAR(64)      NOT NULL,   -- e.g. 'doc_niksic' (no @host - the account name only)
  PRIMARY KEY (staff_id),
  KEY idx_staff_tenant (tenant_id),
  KEY idx_staff_account (mysql_account),
  CONSTRAINT fk_staff_tenant FOREIGN KEY (tenant_id) REFERENCES tenants (tenant_id)
) ENGINE = InnoDB;

CREATE TABLE patients (
  patient_id  INT UNSIGNED NOT NULL AUTO_INCREMENT,
  tenant_id   TINYINT UNSIGNED NOT NULL,
  full_name   VARCHAR(100)     NOT NULL,
  dob         DATE             NOT NULL,
  PRIMARY KEY (patient_id),
  KEY idx_patients_tenant (tenant_id),
  CONSTRAINT fk_patients_tenant FOREIGN KEY (tenant_id) REFERENCES tenants (tenant_id)
) ENGINE = InnoDB;

CREATE TABLE visits (
  visit_id        INT UNSIGNED NOT NULL AUTO_INCREMENT,
  patient_id      INT UNSIGNED NOT NULL,
  tenant_id       TINYINT UNSIGNED NOT NULL,
  staff_id        INT UNSIGNED NOT NULL,   -- attending staff member
  visit_date      DATE             NOT NULL,
  chief_complaint VARCHAR(200)     NOT NULL,
  PRIMARY KEY (visit_id),
  KEY idx_visits_tenant (tenant_id),
  KEY idx_visits_patient (patient_id),
  CONSTRAINT fk_visits_patient FOREIGN KEY (patient_id) REFERENCES patients (patient_id),
  CONSTRAINT fk_visits_tenant  FOREIGN KEY (tenant_id)  REFERENCES tenants (tenant_id),
  CONSTRAINT fk_visits_staff   FOREIGN KEY (staff_id)   REFERENCES staff (staff_id)
) ENGINE = InnoDB;

-- The sensitive table. diagnosis_text is the FGAC target (memo 04's column-privilege demo
-- and the "SELECT * bypass" claim under test in 06-verify.sql); icd_code is what triage
-- (role_nurse) is allowed to see instead.
CREATE TABLE diagnoses (
  diagnosis_id    INT UNSIGNED NOT NULL AUTO_INCREMENT,
  visit_id        INT UNSIGNED NOT NULL,
  tenant_id       TINYINT UNSIGNED NOT NULL,
  icd_code        VARCHAR(10)      NOT NULL,
  diagnosis_text  VARCHAR(500)     NOT NULL,
  staff_id        INT UNSIGNED NOT NULL,   -- who recorded it
  PRIMARY KEY (diagnosis_id),
  KEY idx_diagnoses_tenant (tenant_id),
  KEY idx_diagnoses_visit (visit_id),
  CONSTRAINT fk_diagnoses_visit  FOREIGN KEY (visit_id)  REFERENCES visits (visit_id),
  CONSTRAINT fk_diagnoses_tenant FOREIGN KEY (tenant_id) REFERENCES tenants (tenant_id),
  CONSTRAINT fk_diagnoses_staff  FOREIGN KEY (staff_id)  REFERENCES staff (staff_id)
) ENGINE = InnoDB;

CREATE TABLE invoices (
  invoice_id  INT UNSIGNED NOT NULL AUTO_INCREMENT,
  patient_id  INT UNSIGNED NOT NULL,
  tenant_id   TINYINT UNSIGNED NOT NULL,
  amount      DECIMAL(8,2)     NOT NULL,
  paid_status ENUM('unpaid','paid','overdue') NOT NULL DEFAULT 'unpaid',
  PRIMARY KEY (invoice_id),
  KEY idx_invoices_tenant (tenant_id),
  KEY idx_invoices_patient (patient_id),
  CONSTRAINT fk_invoices_patient FOREIGN KEY (patient_id) REFERENCES patients (patient_id),
  CONSTRAINT fk_invoices_tenant  FOREIGN KEY (tenant_id)  REFERENCES tenants (tenant_id)
) ENGINE = InnoDB;
