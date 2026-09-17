-- 01-domasaj-naloga.sql
-- Chapter 7. Measures the one quantity the chapter argues is the real least-privilege
-- measure: how many tenants (branches) a single account MAY reach - not how many it
-- happens to reach in the queries the application currently sends.
--
-- Run as 'doc_bar'@'localhost' (password Demo#2026), a Bar-branch account, i.e. an account
-- whose CURRENT_USER() does carry its tenant. Nothing here is created or altered; the
-- script only reads.
--
--   mysql -h 127.0.0.1 -u doc_bar -p -D poliklinika < 01-domasaj-naloga.sql

-- 1. The two identities. USER() records the connection (what the client said, and the host
--    it came from); CURRENT_USER() names the row in mysql.user the first step selected, and
--    that row is the only thing that determines privileges.
SELECT USER() AS ko_se_konektovao, CURRENT_USER() AS cija_se_prava_proveravaju;

-- 2. Reach through the base table. role_doctor's grant names the TABLE poliklinika.diagnoses,
--    and that table holds the rows of all three branches. A Bar account therefore reads
--    Podgorica (tenant_id = 1) and Niksic (tenant_id = 2) with no error at all: the tenant
--    boundary is not among the coordinates the privilege system checks.
SELECT tenant_id, COUNT(*) AS redova FROM diagnoses GROUP BY tenant_id ORDER BY tenant_id;

-- 3. Reach through the filtered view. The same account, the same data, one branch - because
--    the view adds a WHERE that resolves the caller's branch from staff.mysql_account via
--    CURRENT_USER() (see ../00-setup/05-tenant-view.sql). The view narrows what is SEEN; it
--    does not narrow what is ALLOWED, which step 2 has already shown.
SELECT tenant_id, COUNT(*) AS redova FROM v_my_branch_diagnoses GROUP BY tenant_id ORDER BY tenant_id;

-- 4. The account's actual privileges, for the record: the grant that produced step 2's reach
--    is visible here, and there is nothing in it that mentions a branch.
SHOW GRANTS FOR CURRENT_USER();
