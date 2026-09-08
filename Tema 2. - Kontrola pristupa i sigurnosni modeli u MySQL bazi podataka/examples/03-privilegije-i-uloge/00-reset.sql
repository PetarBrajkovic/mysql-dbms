-- 00-reset.sql
-- Vraca sandbox u stanje pre 01/02/03: brise sve sto ova tri skripta naprave, i nista vise.
-- Bezbedno je pokrenuti u bilo kom trenutku, i vise puta. Ne dira nista iz 00-setup/ -
-- cetiri osnovne uloge, 12 demo naloga i poliklinika sema ostaju netaknuti.
--
-- Konekcija: dbadmin@localhost (ima CREATE USER i ROLE_ADMIN).
-- Poslednji red trazi ROOT i potreban je samo ako je 03-partial-revokes.sql bio pokrenut.

-- Iz 01-nivoi-i-ili-sastavljanje.sql
DROP USER IF EXISTS 'probe_wide'@'localhost', 'probe_narrow'@'localhost';

-- Iz 02-uloge-hijerarhija-i-aktivacija.sql
-- DROP ROLE sam po sebi uklanja i sve ivice u mysql.role_edges koje ta uloga drzi,
-- pa poseban REVOKE nije neophodan; ostavljen je zbog citljivosti i radi ako uloga vec ne postoji.
DROP ROLE IF EXISTS role_senior_doctor;

-- Provera: doc_bar treba da ima tacno jednu ulogu, role_doctor, i nista vise.
SHOW GRANTS FOR 'doc_bar'@'localhost';

-- ---------------------------------------------------------------------------------------
-- Samo ako je 03-partial-revokes.sql bio pokrenut. KONEKCIJA: root@localhost.
-- Redosled je obavezan: dok postoji nalog sa restrikcijom, iskljucivanje pada sa greskom.
--
--   DROP USER IF EXISTS 'backup_op'@'localhost';
--   SET PERSIST partial_revokes = OFF;
--   SELECT @@global.partial_revokes;   -- ocekivano: 0
