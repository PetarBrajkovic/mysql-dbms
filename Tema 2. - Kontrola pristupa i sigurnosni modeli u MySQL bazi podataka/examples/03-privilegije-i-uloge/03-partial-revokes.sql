-- 03-partial-revokes.sql
-- Poglavlje 3. Jedina stvar oblika zabrane u modelu koji poznaje samo dodelu prava.
--
-- ZAHTEVA ROOT. Razlozi, oba namerna:
--   - SET PERSIST partial_revokes trazi SYSTEM_VARIABLES_ADMIN, koji dbadmin nema;
--   - demo trazi globalnu privilegiju (SELECT ON *.*), koju dbadmin ne moze dodeliti jer je
--     ni sam nema (ima GRANT OPTION samo nad poliklinika.*).
-- To sto ovaj skript ne moze da izvrsi administrativni nalog rada je samo po sebi ilustracija
-- razlozenog SUPER-a: dbadmin administrira naloge, ali ne dira server.
--
-- OPREZ, dve nepovratnosti iz prirucnika 8.2.12:
--   - dok postoji ijedan nalog sa restrikcijom, partial_revokes se ne moze iskljuciti;
--   - dok je ukljucena, _ i % u nazivima sema tumace se doslovno, kao da su escape-ovani.
-- Zato deo D brise nalog PRE nego sto se promenljiva vraca na OFF.

-- ===== DEO A: ukljucivanje i priprema (konekcija: root@localhost) =========================

SELECT @@global.partial_revokes;   -- ocekivano: 0 (podrazumevano iskljuceno)
SET PERSIST partial_revokes = ON;
SELECT @@global.partial_revokes;   -- ocekivano: 1

DROP USER IF EXISTS 'backup_op'@'localhost';
CREATE USER 'backup_op'@'localhost' IDENTIFIED BY 'Demo#2026';

-- Zahtev koji se u ILI-modelu ne moze izraziti: citaj sve, osim jedne seme.
GRANT SELECT ON *.* TO 'backup_op'@'localhost';
REVOKE SELECT ON poliklinika.* FROM 'backup_op'@'localhost';
-- Bez partial_revokes=ON ova naredba bi pala sa ERROR 1141; sa ON, prolazi i upisuje
-- restrikciju - ali ne kao privilegiju, nego kao JSON dokument zakacen nalogu.

-- ===== DEO B: gde je zabrana zapisana (konekcija: root@localhost) =========================

SHOW GRANTS FOR 'backup_op'@'localhost';
-- Ocekivano: GRANT SELECT ON *.* ..., pa zatim red oblika
--   REVOKE SELECT ON `poliklinika`.* FROM ...
-- SHOW GRANTS prikazuje restrikciju kao REVOKE naredbu, iako nikakav "negativan grant" ne postoji.

SELECT User, Host, User_attributes
FROM   mysql.user
WHERE  User = 'backup_op';
-- Ocekivano, u User_attributes:
--   {"Restrictions": [{"Database": "poliklinika", "Privileges": ["SELECT"]}]}
-- Nije red u grant tabeli, nego slobodan JSON u koloni naloga. Zabrana nije stala u oblik
-- grant tabele, pa je zapisana van tog oblika.

-- ===== DEO C: restrikcija pogadja samo globalni clan ILI-lanca ===========================
-- Konekcija: backup_op@localhost.

SELECT COUNT(*) FROM mysql.user;
-- Ocekivano: PROLAZI. Globalni SELECT vazi svuda osim nad poliklinika.

SELECT COUNT(*) FROM poliklinika.patients;
-- Ocekivano: ERROR 1142. Restrikcija je izuzela ovu semu iz globalne privilegije.

-- Konekcija: root@localhost.
GRANT SELECT ON poliklinika.diagnoses TO 'backup_op'@'localhost';

-- Konekcija: backup_op@localhost (sledeci zahtev, bez ponovne prijave).
SELECT COUNT(*) FROM poliklinika.diagnoses;
-- Ocekivano: PROLAZI. Restrikcija umanjuje samo clan "global"; tabelski grant je zaseban clan
-- ILI-lanca i prolazi netaknut:
--     (global - restrictions) OR db OR table OR column OR routine
-- Zato restrikcija nije zabrana pristupa semi, nego izuzimanje seme iz jedne globalne
-- privilegije. Prirucnik ovaj obrazac i navodi kao nacin da se dobiju najmanje privilegije:
-- oduzmi siroko nad semom, pa vrati tacno ono sto treba.

SELECT COUNT(*) FROM poliklinika.patients;
-- Ocekivano: i dalje ERROR 1142. Vraceno je tacno jedno, imenovano.

-- ===== DEO D: ciscenje (konekcija: root@localhost) =======================================

DROP USER IF EXISTS 'backup_op'@'localhost';
SET PERSIST partial_revokes = OFF;
-- Redosled je obavezan: dok postoji nalog sa restrikcijom, iskljucivanje pada sa greskom.
SELECT @@global.partial_revokes;   -- ocekivano: 0
