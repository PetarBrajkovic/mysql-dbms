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

SHOW GRANTS FOR 'demo_boris'@'localhost';   -- SELECT gone, but see below
SHOW GRANTS FOR 'demo_ceca'@'localhost';    -- THE POINT: SELECT is still there

-- Measured on 8.4.11 (Workbench, two connections), verbatim:
--
--   demo_boris:  GRANT USAGE ON *.* TO `demo_boris`@`localhost`
--                GRANT USAGE ON `poliklinika`.`patients` TO `demo_boris`@`localhost` WITH GRANT OPTION
--   demo_ceca:   GRANT USAGE ON *.* TO `demo_ceca`@`localhost`
--                GRANT SELECT ON `poliklinika`.`patients` TO `demo_ceca`@`localhost`
--
-- Two findings, not one:
--
-- (1) NO CASCADE. Standard SQL would have removed Ceca's privilege along with Boris's. MySQL
--     leaves it dangling - the branch outlives the root it grew from. Ceca still reads
--     poliklinika.patients although the account that authorised her no longer can. Only an
--     explicit REVOKE against her, or DROP USER, removes it.
--
-- (2) GRANT OPTION SURVIVES the revoke of the privilege it applied to. USAGE means "no privileges
--     at all", so Boris now holds nothing on the table - yet keeps the delegation capability, which
--     needs its own statement. Per the manual, that capability extends to privileges he "may be
--     given in the future": a later GRANT INSERT would be re-delegable with nobody having granted
--     delegation again.

REVOKE GRANT OPTION ON poliklinika.patients FROM 'demo_boris'@'localhost';
SHOW GRANTS FOR 'demo_boris'@'localhost';   -- now only the bare USAGE ON *.* row remains

-- ---------------------------------------------------------------------------
-- Step 4 - as ROOT (dbadmin is denied on the mysql schema, see record 0001)
-- MySQL records the provenance a cascade would need, and then ignores it: the manual says of
-- tables_priv.Grantor that it is "set to ... the CURRENT_USER value, ... but otherwise unused"
-- (8.4 refman, 8.2.3 Grant Tables). Non-cascading revoke is a decision, not a data limitation.
-- ---------------------------------------------------------------------------
SELECT Host, Db, User, Table_name, Grantor, Table_priv
FROM mysql.tables_priv
WHERE User LIKE 'demo_%';

-- ---------------------------------------------------------------------------
-- Cleanup - connection A (dbadmin)
-- ---------------------------------------------------------------------------
DROP USER IF EXISTS 'demo_boris'@'localhost';
DROP USER IF EXISTS 'demo_ceca'@'localhost';
