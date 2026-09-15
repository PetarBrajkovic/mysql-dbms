-- 05-sprovodjenje-politika / 01 - dokle dopire izbor reda u Fazi 1
--
-- Faza 1 bira TACNO JEDAN red mysql.user, po hostu, od najuzeg ka najsirem, i
-- nikada se ne vraca na siri red. ALI taj izbor odredjuje samo autentifikaciju
-- i GLOBALNE privilegije. Privilegije nad bazom traze se nezavisno, u mysql.db,
-- gde se Host poredi sa hostom klijenta i sme da sadrzi dzokere.
--
-- Zato grant dat nalogu 'probni'@'%' vazi i za sesiju ciji je CURRENT_USER()
-- jednak 'probni'@'localhost'. Izmereno na MySQL 8.4.11 Community, Win64.
--
-- Pokrece se kao root (trazi CREATE USER). Baza poliklinika se ne menja.

-- --- korak 1: dva reda za isto ime, razlicit host ------------------------
CREATE USER 'probni'@'%'         IDENTIFIED BY 'Lozinka!2345';
CREATE USER 'probni'@'localhost' IDENTIFIED BY 'Lozinka!2345';

-- Privilegija ide SAMO na siri red.
GRANT SELECT ON poliklinika.* TO 'probni'@'%';

SELECT user, host FROM mysql.user WHERE user = 'probni';
SHOW GRANTS FOR 'probni'@'%';
SHOW GRANTS FOR 'probni'@'localhost';

-- --- korak 2: otvoriti NOVU konekciju kao 'probni' -----------------------
-- Workbench: nova konekcija, korisnik probni, lozinka Lozinka!2345,
-- host 127.0.0.1 ili localhost. Iz TE konekcije pokrenuti:
--
--   SELECT CURRENT_USER(), p.* FROM poliklinika.patients p LIMIT 1;
--
-- IZMERENO: probni@localhost | 1 | 1 | Pacijent 001 | 1967-12-23
--
-- Dakle Faza 1 je izabrala uzi red (CURRENT_USER to potvrdjuje), a SELECT
-- ipak prolazi - privilegija stize iz reda mysql.db sa Host='%'.
--
-- PAZNJA: ovaj upit se NE sme pokrenuti iz privilegovane konekcije.
-- Tada vraca 1146 (Table doesn't exist) i meri nesto sasvim drugo.

-- --- korak 3: cime je objasnjenje potvrdjeno -----------------------------
-- Iskljucuje mandatory_roles kao alternativno objasnjenje.
SELECT @@mandatory_roles, @@activate_all_roles_on_login;
-- IZMERENO: prazno, 0

SELECT Host, Db, User, Select_priv FROM mysql.db WHERE User = 'probni';
-- IZMERENO: % | poliklinika | probni | Y

-- --- korak 4: ciscenje ---------------------------------------------------
DROP USER 'probni'@'%', 'probni'@'localhost';
