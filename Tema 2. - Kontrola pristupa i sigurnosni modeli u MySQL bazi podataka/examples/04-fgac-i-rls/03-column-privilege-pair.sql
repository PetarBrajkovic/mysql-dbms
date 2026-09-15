-- ---------------------------------------------------------------------------
-- 04-fgac-i-rls / 03 — Kolonska privilegija: SELECT icd_code naspram
-- SELECT diagnosis_text kao nurse_podgorica
--
-- Poglavlje 4, Slika 4.1. Isti nalog, ista tabela, dve kolone: jedna dodeljena
-- (icd_code), jedna ne (diagnosis_text). Figuru generiše
-- tools/make-pair-figure.ps1, koji obe naredbe zaista izvršava na serveru rada
-- i baca grešku ako se ijedna strana ne ponaša kako je najavljeno.
--
-- Preduslov: sandbox poliklinika (examples/00-setup/), nalog nurse_podgorica
--            sa GRANT SELECT (diagnosis_id, visit_id, tenant_id, icd_code)
--            ON poliklinika.diagnoses (04-roles-and-accounts.sql).
-- Izmereno:   MySQL 8.4.11, 2026-09-1x.
-- ---------------------------------------------------------------------------

-- Dozvoljeno — icd_code je u dodeljenom skupu kolona.
SELECT diagnosis_id, icd_code FROM diagnoses LIMIT 3;

-- Odbijeno — diagnosis_text nikada nije dodeljen nalogu nurse_podgorica.
SELECT diagnosis_id, diagnosis_text FROM diagnoses LIMIT 3;
-- Očekivano: ERROR 1143 (42000): SELECT command denied to user
-- 'nurse_podgorica'@'localhost' for column 'diagnosis_text' in table 'diagnoses'

-- Generisanje figure (iz koren foldera teme):
-- ..\tools\... (topic-local): .\tools\make-pair-figure.ps1 `
--     -Database poliklinika `
--     -SuccessSql "SELECT diagnosis_id, icd_code FROM diagnoses LIMIT 3" `
--     -FailSql    "SELECT diagnosis_id, diagnosis_text FROM diagnoses LIMIT 3" `
--     -SuccessUser nurse_podgorica -SuccessPassword 'Demo#2026' `
--     -SuccessLabel "nurse_podgorica - SELECT icd_code (dozvoljeno)" `
--     -FailLabel    "nurse_podgorica - SELECT diagnosis_text (odbijeno, ERROR 1143)" `
--     -ExpectedError '1143' `
--     -OutBase figures\04-fgac-01-kolonska-privilegija
