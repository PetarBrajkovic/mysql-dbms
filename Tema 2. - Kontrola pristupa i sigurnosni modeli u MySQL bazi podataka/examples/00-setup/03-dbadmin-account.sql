-- 03-dbadmin-account.sql
-- Creates the dedicated administrative account this paper's own tooling (mysql-credentials.cnf,
-- the figure pipeline, every later `mysql --defaults-extra-file=...` call) connects as, instead
-- of root. A security paper that does everything as root undercuts its own least-privilege
-- chapter - see ticket 10.
--
-- Run once, as root. Safe to re-run: DROP USER IF EXISTS first.
--
-- Scope, deliberately narrow:
--   - Full rights over the poliklinika schema only (not *.*), so dbadmin can create/alter/seed
--     that schema and read anything in it for figures.
--   - CREATE USER, ROLE_ADMIN so it can create the four roles and ~12 demo accounts in
--     04-roles-and-accounts.sql (root is not used again after this script).
--   - Nothing else: no SUPER, no SHUTDOWN, no privileges on other schemas or on the mysql
--     system database itself.

DROP USER IF EXISTS 'dbadmin'@'localhost';
CREATE USER 'dbadmin'@'localhost' IDENTIFIED BY 'DbAdmin#2026';

GRANT ALL PRIVILEGES ON poliklinika.* TO 'dbadmin'@'localhost' WITH GRANT OPTION;
GRANT CREATE USER, ROLE_ADMIN ON *.* TO 'dbadmin'@'localhost';

-- No FLUSH PRIVILEGES: CREATE USER/GRANT are account-management statements and trigger an
-- implicit reload themselves (memo 03).
