-- Figura: figures/04-explain-09-explain-for-connection.png
-- Lekcija 06, odeljak 5. Plan upita koji upravo radi u drugoj sesiji.
-- Preduslov: baza obrada_upita, tabela wide_events, i DVA otvorena taba u Workbench-u.
--
-- Ovo je jedini primer u Poglavlju 4 koji se ne može odraditi iz jednog taba. Broj veze
-- mora da se otkuca doslovno: EXPLAIN FOR CONNECTION ne prolazi kroz pripremljenu naredbu.

-- ===========================================================================
-- SESIJA A  (prvi tab)
-- ===========================================================================
USE obrada_upita;

-- Zapamti svoj broj veze i pokaži ga sesiji B.
SELECT CONNECTION_ID();

-- Pusti spor upit. Traje nekoliko sekundi; za to vreme pređi u drugi tab.
SELECT SQL_NO_CACHE COUNT(*)
FROM   wide_events
WHERE  notes LIKE '%zzqzq%'
  AND  LOWER(notes) LIKE '%qzq%';

-- ===========================================================================
-- SESIJA B  (drugi tab, dok gornji upit još radi)
-- ===========================================================================
USE obrada_upita;

-- Ako ti broj veze iz sesije A nije pri ruci, nađi ga ovde.
SELECT ID, USER, COMMAND, STATE, TIME, LEFT(INFO, 60) AS upit
FROM   information_schema.PROCESSLIST
WHERE  COMMAND <> 'Sleep' AND ID <> CONNECTION_ID();

-- Zameni 42 brojem iz prethodnog reda. Upit se pri tome ne prekida i ne usporava.
EXPLAIN FOR CONNECTION 42;
EXPLAIN FORMAT=TREE FOR CONNECTION 42;
EXPLAIN FORMAT=JSON FOR CONNECTION 42;

-- Brojač poziva, globalni (sesijski bi u novom tabu uvek bio nula).
SHOW GLOBAL STATUS LIKE 'Com_explain_other';

-- ===========================================================================
-- Četiri odbijanja koja vredi videti jednom, da se posle prepoznaju
-- ===========================================================================

-- (a) ERROR 1235: merenje traži da upit pokreneš ti, u svojoj sesiji.
EXPLAIN ANALYZE FOR CONNECTION 42;

-- (b) ERROR 3012: ta veza jeste zauzeta, ali naredbom koja nema plan.
--     Otvori treći tab, pokreni u njemu DO SLEEP(20); i uzmi njegov broj veze.
EXPLAIN FOR CONNECTION 43;

-- (b2) A veza koja MIRUJE (COMMAND: Sleep) nije greška: vraća se prazan rezultat.
--      Uzmi broj bilo koje veze iz PROCESSLIST-a kojoj je COMMAND jednako Sleep.
EXPLAIN FOR CONNECTION 44;

-- (c) ERROR 1094: veza ne postoji, ili je upit u međuvremenu završio.
EXPLAIN FOR CONNECTION 999999;

-- (d) ERROR 1295: broj veze mora da se otkuca, ne može kroz pripremljenu naredbu.
PREPARE s FROM 'EXPLAIN FOR CONNECTION 42';
EXECUTE s;

-- ===========================================================================
-- Zašto su ovo dva prozora, a ne jedan
-- ===========================================================================
-- Trag ide duboko, ali samo u sopstvenoj sesiji. Pokreni ovo iz sesije B dok sesija A
-- ima uključen trag: rezultat je 0, uvek.
SELECT COUNT(*) AS tudji_tragovi_koje_vidim
FROM   INFORMATION_SCHEMA.OPTIMIZER_TRACE;
