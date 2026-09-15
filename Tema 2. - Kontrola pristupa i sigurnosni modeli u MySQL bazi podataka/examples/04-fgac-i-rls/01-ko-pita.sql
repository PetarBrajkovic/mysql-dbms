-- ---------------------------------------------------------------------------
-- 04-fgac-i-rls / 01 — USER() naspram CURRENT_USER() u DEFINER pogledu
--
-- Poglavlje 4. Pokazuje da jedan isti red rezultata nosi dva razlicita
-- identiteta: nalog koji se konektovao i nalog cija se prava proveravaju.
--
-- Preduslov: sandbox poliklinika (examples/00-setup/), nalog dbadmin@localhost
--            i bar jedan nalog sa ulogom role_doctor (npr. doc_podgorica).
-- Pokretanje: sekcije A i C kao dbadmin, sekciju B u zasebnoj konekciji
--             kao doc_podgorica.
-- Izmereno:   MySQL 8.4.11, 2026-09-10.
-- ---------------------------------------------------------------------------

-- === A. Kao dbadmin@localhost ==============================================
USE poliklinika;

CREATE DEFINER = 'dbadmin'@'localhost'
  SQL SECURITY DEFINER
  VIEW v_ko_pita AS
  SELECT USER()         AS ko_se_konektovao,
         CURRENT_USER() AS cija_se_prava_proveravaju;

GRANT SELECT ON poliklinika.v_ko_pita TO role_doctor;

-- === B. Kao doc_podgorica, u DRUGOJ konekciji ==============================
-- SELECT * FROM poliklinika.v_ko_pita;
--
-- Izmereni rezultat:
--   ko_se_konektovao          cija_se_prava_proveravaju
--   doc_podgorica@localhost   dbadmin@localhost
--
-- Kako se cita: USER() je zamrznut pri loginu i ne moze biti definer.
-- CURRENT_USER() imenuje nalog cijim se grant redovima proverava pristup, pa
-- u DEFINER kontekstu postaje definer. Zato filter oblika
-- WHERE tenant_id = f(CURRENT_USER()) unutar DEFINER pogleda filtrira po
-- definer-u, svima isto, i izolacija tiho nestaje.

-- === C. Ciscenje, kao dbadmin ==============================================
-- DROP VIEW poliklinika.v_ko_pita;
