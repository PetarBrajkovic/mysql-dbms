-- 01-nivoi-i-ili-sastavljanje.sql
-- Poglavlje 3. Pokazuje da se nivoi privilegija sastavljaju logickim ILI, nikada presekom:
--   (global - restrictions) OR db OR table OR column OR routine
-- Priprema, tj. deo A, izvrsava se kao dbadmin. Deo B i deo C su dve odvojene konekcije,
-- svaka kao svoj demo nalog. Deo D cisti za sobom.
--
-- Cilj: dva naloga koja imaju POTPUNO ISTU kolonsku privilegiju, a razlicit ishod, zato sto
-- jedan od njih pored nje ima i siru privilegiju na nivou baze. Sira privilegija sama resava
-- upit; uza je ne suzava.

-- ===== DEO A: priprema (konekcija: dbadmin@localhost) =====================================

DROP USER IF EXISTS 'probe_wide'@'localhost', 'probe_narrow'@'localhost';
CREATE USER 'probe_wide'@'localhost'   IDENTIFIED BY 'Demo#2026';
CREATE USER 'probe_narrow'@'localhost' IDENTIFIED BY 'Demo#2026';

-- probe_wide: siroka privilegija na nivou baze PLUS uska kolonska nad diagnoses.
GRANT SELECT ON poliklinika.*                          TO 'probe_wide'@'localhost';
GRANT SELECT (icd_code) ON poliklinika.diagnoses       TO 'probe_wide'@'localhost';

-- probe_narrow: ista kolonska privilegija, i nista vise. Kontrolna grupa.
GRANT SELECT (icd_code) ON poliklinika.diagnoses       TO 'probe_narrow'@'localhost';

-- ===== DEO B: konekcija kao probe_wide@localhost =========================================

SHOW GRANTS;
-- Ocekivano: tri reda - USAGE ON *.*, SELECT ON `poliklinika`.*, i SELECT (`icd_code`) ON
-- `poliklinika`.`diagnoses`. Dva razlicita nivoa, dva zasebna zapisa; nijedan ne pominje
-- onaj drugi.

SELECT diagnosis_id, diagnosis_text FROM poliklinika.diagnoses LIMIT 5;
-- Ocekivano: PROLAZI i vraca diagnosis_text, iako kolonska privilegija pokriva samo icd_code.
-- Clan "db" u ILI-lancu je sam dovoljan. Ovo je merenje koje obara intuiciju
-- "uza privilegija suzava siru".

-- ===== DEO C: konekcija kao probe_narrow@localhost =======================================

SHOW GRANTS;
-- Ocekivano: dva reda - USAGE ON *.* i SELECT (`icd_code`) ON `poliklinika`.`diagnoses`.

SELECT icd_code FROM poliklinika.diagnoses LIMIT 5;
-- Ocekivano: PROLAZI. Kolonska privilegija radi ono za sta je dodeljena.

SELECT diagnosis_id, diagnosis_text FROM poliklinika.diagnoses LIMIT 5;
-- Ocekivano: ERROR 1143 (42000): SELECT command denied to user 'probe_narrow'@'localhost'
-- for column 'diagnosis_text' in table 'diagnoses'.
--
-- Poredjenje B i C je cela poenta: kolonska privilegija je identicna u oba naloga. Razlika
-- je iskljucivo u tome sto probe_wide ima jos jedan, siri clan ILI-lanca. Najmanje privilegije
-- se, dakle, ne postizu dodavanjem uze privilegije, nego time sto se sira nikad ne dodeli.

-- ===== DEO D: ciscenje (konekcija: dbadmin@localhost) ====================================

DROP USER IF EXISTS 'probe_wide'@'localhost', 'probe_narrow'@'localhost';
