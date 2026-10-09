-- Poglavlje 3 - ista transakcija, isto ime (GTID), razlicita adresa (datoteka + bajt).
-- Korak A na IZVORU (3307), korak B na REPLICI (3309), oba kao root
-- (SHOW BINLOG EVENTS trazi privilegiju REPLICATION SLAVE, koju dbadmin nema).
-- Upisuje jedan red u poliklinika.heartbeat; to je instrumentalna tabela, red sme da ostane.
-- Provereno na MySQL 8.4.11 (lekcija 0002).

-- ===== Korak A: na 3307 =====
USE poliklinika;
INSERT INTO heartbeat (ts, node) VALUES (NOW(6), 'primer-gtid');

-- U 8.4 je ovo zamena za uklonjeni SHOW MASTER STATUS.
SHOW BINARY LOG STATUS;              -- zapamti File (npr. node1-bin.000008)

-- Zameni ime datoteke onim iz prethodnog rezultata:
SHOW BINLOG EVENTS IN 'node1-bin.000008';
-- Poslednjih pet dogadjaja: Gtid -> Query (BEGIN) -> Table_map -> Write_rows -> Xid (COMMIT).
-- Zapamti GTID iz reda Gtid i njegov Pos.

-- ===== Korak B: na 3309 =====
SHOW BINARY LOG STATUS;              -- druga datoteka (npr. node3-bin.000010)
SHOW BINLOG EVENTS IN 'node3-bin.000010';
-- Isti GTID, ali u drugoj datoteci i sa drugim End_log_pos.

-- Skup svih izvrsenih transakcija: isti na sva tri servera kad replike stignu izvor.
SELECT @@GLOBAL.gtid_executed;
