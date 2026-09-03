-- 01-dac-kaskadno-oduzimanje.sql
--
-- Chapter 2 (Klasicni modeli kontrole pristupa) - the one runnable thing in a theory chapter.
--
-- What it shows: DAC's delegation primitive (WITH GRANT OPTION) and the point where MySQL
-- deliberately DIVERGES from the SQL standard. In standard SQL, revoking a privilege also revokes
-- everything granted on the strength of it. MySQL does not cascade - the manual states the
-- difference itself, in "MySQL and Standard SQL Versions of GRANT":
--   "In standard SQL, when you revoke a privilege, all privileges that were granted based on that
--    privilege are also revoked. In MySQL, privileges can be dropped with DROP USER or REVOKE
--    statements."
--   https://dev.mysql.com/doc/refman/8.4/en/grant.html
--
-- Needs TWO connections, because step 2 must run as demo_boris himself:
--   connection A: dbadmin@localhost  (has ALL ON poliklinika.* WITH GRANT OPTION, plus CREATE USER)
--   connection B: demo_boris@localhost
--
-- Cleanup at the bottom is not optional - these accounts are not part of the sandbox.

-- ---------------------------------------------------------------------------
-- Step 1 - connection A (dbadmin): create the two demo accounts, delegate to Boris
-- ---------------------------------------------------------------------------
CREATE USER IF NOT EXISTS 'demo_boris'@'localhost' IDENTIFIED BY 'Demo#2026';
CREATE USER IF NOT EXISTS 'demo_ceca'@'localhost'  IDENTIFIED BY 'Demo#2026';

GRANT SELECT ON poliklinika.patients TO 'demo_boris'@'localhost' WITH GRANT OPTION;

SHOW GRANTS FOR 'demo_boris'@'localhost';
-- Expect the GRANT OPTION to appear on the poliklinika.patients line.

-- ---------------------------------------------------------------------------
-- Step 2 - connection B (demo_boris): pass the privilege on
-- ---------------------------------------------------------------------------
GRANT SELECT ON poliklinika.patients TO 'demo_ceca'@'localhost';
-- Boris may grant only what he himself holds: SELECT, and nothing more. Proof, expect an error:
-- GRANT INSERT ON poliklinika.patients TO 'demo_ceca'@'localhost';
--   -> ERROR 1142 (42000): INSERT command denied ...

-- ---------------------------------------------------------------------------
-- Step 3 - connection A (dbadmin): pull the root of the delegation chain
-- ---------------------------------------------------------------------------
REVOKE SELECT ON poliklinika.patients FROM 'demo_boris'@'localhost';

SHOW GRANTS FOR 'demo_boris'@'localhost';   -- SELECT gone, as expected
SHOW GRANTS FOR 'demo_ceca'@'localhost';    -- THE POINT: SELECT is still there

-- Standard SQL would have removed Ceca's privilege along with Boris's. MySQL leaves it dangling:
-- the branch outlives the root it grew from. Ceca can still read poliklinika.patients even though
-- the account that authorised her no longer can.

-- ---------------------------------------------------------------------------
-- Cleanup - connection A (dbadmin)
-- ---------------------------------------------------------------------------
DROP USER IF EXISTS 'demo_boris'@'localhost';
DROP USER IF EXISTS 'demo_ceca'@'localhost';
