-- Lekcija 0003 / Poglavlje 3, §2 - granica između parsera i resolvera.
-- Bez figure: dokaz je poruka o grešci, ne plan.
--
-- Parser gleda samo tekst i gramatiku; resolver (faza pripreme) je prvi koji otvara
-- rečnik podataka i pita da li imena uopšte postoje. Redosled te dve faze ne mora da
-- se veruje na reč: naredba koja greši na oba načina odjednom uvek prijavi grešku
-- parsera, jer se do razrešavanja imena nikad ne stigne.
--
-- Provereno uživo 2026-08-24, MySQL 8.4.11. Svaka naredba namerno pada, pa ih
-- pokreni jednu po jednu.

USE obrada_upita;

-- (1) Greška parsera. WHERE bez uslova nije gramatičan SQL.
--     Kolona `nepostojeca` takođe ne postoji, ali to se ovde još ne vidi.
SELECT nepostojeca FROM wide_events WHERE;
-- ERROR 1064 (42000): You have an error in your SQL syntax ...

-- (2) Ista naredba, popravljena samo gramatički. Sada progovara resolver: tek kad je
--     stablo raščlanjeno, imena se traže u rečniku podataka.
SELECT nepostojeca FROM wide_events WHERE id = 1;
-- ERROR 1054 (42S22): Unknown column 'nepostojeca' in 'field list'

-- (3) Isti sloj, druga vrsta imena.
SELECT id FROM nepostojeca_tabela WHERE id = 1;
-- ERROR 1146 (42S02): Table 'obrada_upita.nepostojeca_tabela' doesn't exist

-- Poenta: kod (1) greške 1054 i 1146 nikada ne stignu na red. Redosled faza nije
-- stvar tumačenja, nego se meri time koja se greška prijavi.
