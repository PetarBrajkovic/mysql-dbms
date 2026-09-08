-- 02-uloge-hijerarhija-i-aktivacija.sql
-- Poglavlje 3. Dve tvrdnje na jednom mestu:
--   (1) grant uloge ulozi postoji i gradi hijerarhiju - mysql.role_edges cuva taj graf;
--   (2) dodeljena uloga nije aktivna uloga - RBAC-0 sesija postoji, preko SET ROLE.
-- Deo A kao dbadmin (ima ROLE_ADMIN i GRANT OPTION nad poliklinika.*). Delovi B i C kao
-- doc_bar. Deo D cisti za sobom.
--
-- OPREZ (zapis 0001): ako se ikada ponovo pokrene 00-setup/04-roles-and-accounts.sql, on brise
-- i ponovo pravi sve cetiri uloge, cime nestaje i role_senior_doctor veza napravljena ovde,
-- kao i grant iz 05-tenant-view.sql. Ovaj skript je bezbedno ponoviti sam za sebe.

-- ===== DEO A: hijerarhija uloga (konekcija: dbadmin@localhost) ============================

DROP ROLE IF EXISTS role_senior_doctor;
CREATE ROLE role_senior_doctor;

-- Uloga ulozi. Prirucnik 8.2.10: dozvoljeno je dodeliti korisnika korisniku, ulogu korisniku,
-- korisnika ulozi, i ulogu ulozi - jer su sve to ID-jevi autorizacije, ista vrsta objekta.
GRANT role_doctor TO role_senior_doctor;

-- Sopstvena privilegija starije uloge, koju mladja nema.
GRANT SELECT ON poliklinika.invoices TO role_senior_doctor;

-- Nalog dobija samo stariju ulogu. Nijedna privilegija se time ne kopira na nalog.
GRANT role_senior_doctor TO 'doc_bar'@'localhost';

-- ===== DEO B: dodeljeno nije aktivno (konekcija: doc_bar@localhost, sveza prijava) ========

SELECT CURRENT_USER(), CURRENT_ROLE();
-- Ocekivano: role_doctor je aktivna (upisana je kao DEFAULT ROLE u 04-roles-and-accounts.sql),
-- a role_senior_doctor NIJE - dodeljena je, ali nije aktivirana.
-- activate_all_roles_on_login je OFF na ovom serveru (izmereno, zapis 0001).

SELECT invoice_id, paid_status FROM poliklinika.invoices LIMIT 5;
-- Ocekivano: ERROR 1142 (42000): SELECT command denied ... za tabelu 'invoices'.
-- Privilegija postoji - stoji u tables_priv sa nosiocem role_senior_doctor - ali nosilac
-- nije aktivan u ovoj sesiji, pa u proveru uopste ne ulazi.

SET ROLE role_senior_doctor;
SELECT CURRENT_ROLE();
-- Ocekivano: sada je aktivna role_senior_doctor, a role_doctor VISE NIJE.
-- SET ROLE postavlja skup aktivnih uloga, ne dodaje u njega.

SELECT invoice_id, paid_status FROM poliklinika.invoices LIMIT 5;
-- Ocekivano: PROLAZI. Ista sesija, isti nalog, isti upit - promenio se samo aktivan skup uloga.

SELECT diagnosis_id, icd_code FROM poliklinika.diagnoses LIMIT 5;
-- Ocekivano: PROLAZI, iako role_doctor vise nije direktno aktivna. Do te privilegije se stize
-- obilaskom grafa: doc_bar -> role_senior_doctor -> role_doctor -> red u tables_priv.
-- Ovo je nasledjivanje kroz dve ivice, tj. hijerarhija uloga na delu.

SET ROLE NONE;
SELECT CURRENT_ROLE();
SELECT diagnosis_id FROM poliklinika.diagnoses LIMIT 5;
-- Ocekivano: CURRENT_ROLE() vraca NONE, a upit pada sa ERROR 1142. Nalog i dalje ima sve
-- dodeljene uloge; nijedna nije na snazi. Ovo je RBAC-0 sesija u punom smislu.

SET ROLE DEFAULT;
-- Vraca sesiju na podrazumevano stanje, tj. na role_doctor.

-- ===== DEO C: gde privilegija zaista stoji (konekcija: doc_bar@localhost) =================

SHOW GRANTS FOR CURRENT_USER();
-- Ocekivano: nabraja dodeljene ULOGE, ne privilegije nad tabelama - jer nijedan red u
-- tables_priv nema User='doc_bar'. Nalog nema nijednu sopstvenu tabelsku privilegiju.

SHOW GRANTS FOR CURRENT_USER() USING role_senior_doctor;
-- Ocekivano: razresen spisak, ukljucujuci i privilegije nasledjene od role_doctor.
-- Klauzula USING trazi od servera da graf obidje unapred i pokaze rezultat.

-- ===== DEO D: ciscenje (konekcija: dbadmin@localhost) ====================================

REVOKE role_senior_doctor FROM 'doc_bar'@'localhost';
DROP ROLE IF EXISTS role_senior_doctor;
