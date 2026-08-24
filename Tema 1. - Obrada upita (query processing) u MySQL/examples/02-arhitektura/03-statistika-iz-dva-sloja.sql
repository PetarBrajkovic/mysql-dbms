-- Lekcija 0002 / Poglavlje 2, §6 - isto pitanje ("koliko torki?"), dva sloja
-- koja na njega odgovaraju, i dva različita odgovora.
-- Proizvodi figuru: figures/02-arhitektura-02-statistika-iz-dva-sloja.png
--
-- Nastavak nalaza iz lekcije 0001: kardinalnost na country_code bila je 14, a
-- histograma nije bilo. Ovde se vidi zašto su to dve odvojene stvari - ne dolaze
-- iz istog sloja.
--
-- Provereno uživo 2026-08-24, MySQL 8.4.11. Sve izmerene vrednosti su u
-- komentarima ispod svakog koraka.

USE obrada_upita;

-- (1) Šta MOTOR misli. InnoDB kardinalnost procenjuje "random dives" - uzorkuje
--     stranice indeksa umesto da čita sve torke. Zato je to procena, a ne tačan
--     broj, i zato ume da se promeni između dva ANALYZE TABLE.
--
--     Izmereno:  n_diff_pfx01 = 14   sample_size = 16
--                n_leaf_pages = 5082
--     Dakle: zaključak "14 različitih vrednosti" nastao je iz 16 od 5082
--     stranica, tj. iz oko 0,3% indeksa.
SELECT   index_name, stat_name, stat_value, sample_size
FROM     mysql.innodb_index_stats
WHERE    database_name = 'obrada_upita'
  AND    table_name    = 'wide_events'
  AND    index_name    = 'idx_country_code';

-- (2) Šta SERVER ima. Histogrami žive u rečniku podataka serverskog sloja; motor
--     za njih ne zna. Dok se histogram izričito ne zatraži, ovaj upit ne vraća
--     nijedan red - to je stanje u kom je server bio tokom lekcije 0001.
--
--     Izmereno: prazan skup.
SELECT SCHEMA_NAME, TABLE_NAME, COLUMN_NAME
FROM   information_schema.COLUMN_STATISTICS
WHERE  SCHEMA_NAME = 'obrada_upita';

-- (3) Zatraži histogram. Ovo NE dira indeks i ne traži od motora ništa osim
--     čitanja podataka; rezultat se upisuje u rečnik podataka serverskog sloja.
ANALYZE TABLE wide_events UPDATE HISTOGRAM ON country_code WITH 16 BUCKETS;

-- (4) Sada isti upit iz (2) vraća red.
--
--     Izmereno:  tip = singleton   kantica = 15   sampling-rate ≈ 0,03
--     Server je našao 15 vrednosti; motor je procenio 14. Server je u pravu.
SELECT COLUMN_NAME,
       JSON_UNQUOTE(JSON_EXTRACT(HISTOGRAM, '$."histogram-type"')) AS tip,
       JSON_LENGTH(JSON_EXTRACT(HISTOGRAM, '$.buckets'))           AS kantica
FROM   information_schema.COLUMN_STATISTICS
WHERE  SCHEMA_NAME = 'obrada_upita';

-- (5) Raspodela, a ne samo broj. Kantice su kumulativne, pa je učestalost
--     poslednje vrednosti razlika poslednje dve.
--
--     Izmereno:  kantica[14] = ["base64:type254:VVM=", 1.0]      -> 'US'
--                kantica[13] = ["base64:type254:U0U=", ~0.299]   -> 'SE'
--     Dakle 'US' zauzima 1.0 - ~0.299 = ~0.701, oko 70% tabele.
--     Histogram se gradi iz uzorka (sampling-rate ~0,03), pa druga decimala ume
--     da se promeni između dva pokretanja - u dva merenja 0.29915 i 0.29886.
--     Ne juri cifru; ~70% je ono što se ne menja.
--     Kardinalnost 14 bi implicirala ravnomernih 1/14 = 7,1% po vrednosti -
--     promašaj od deset puta. Histogram to zna, kardinalnost ne.
SELECT JSON_EXTRACT(HISTOGRAM, '$.buckets[14]') AS kantica_14,
       JSON_EXTRACT(HISTOGRAM, '$.buckets[13]') AS kantica_13
FROM   information_schema.COLUMN_STATISTICS
WHERE  SCHEMA_NAME = 'obrada_upita'
  AND  COLUMN_NAME = 'country_code';

-- (6) OBAVEZNO: vrati server u pređašnje stanje.
--     Poglavlje 4 računa na to da histograma NEMA (vidi NOTES.md i
--     learning-records/0001), pa ovaj korak nije opcion.
ANALYZE TABLE wide_events DROP HISTOGRAM ON country_code;

-- Provera da je stanje vraćeno - mora vratiti 0.
SELECT COUNT(*) AS preostalo_histograma
FROM   information_schema.COLUMN_STATISTICS
WHERE  SCHEMA_NAME = 'obrada_upita';
