-- 05-sprovodjenje-politika / 03 - zakljucavanje naloga posle N promasaja
--
-- Poenta poglavlja u jednom kadru: cetvrta prijava ide sa TACNOM lozinkom.
-- Autentifikacioni plugin je uspesno proverio kredencijal - i veza svejedno
-- pada. Odluku je doneo server, iz kolone naloga, posle plugina.
-- Prirucnik (8.2.4): "The server checks credentials first, then account
-- locking state."
--
-- Pokrece se kao root (trazi CREATE USER). Baza poliklinika se ne dira.
-- Ako je iz primera 02 ostala ucitana komponenta validate_password,
-- lozinka ispod je zadovoljava (12 znakova, velika/mala slova, cifra, znak).

-- --- korak 1: nalog sa politikom zakljucavanja ---------------------------
DROP USER IF EXISTS 'kljucar'@'localhost';

CREATE USER 'kljucar'@'localhost'
  IDENTIFIED BY 'Lozinka!2345'
  FAILED_LOGIN_ATTEMPTS 3
  PASSWORD_LOCK_TIME 1;

-- Politika je vidljiva u samom nalogu.
SHOW CREATE USER 'kljucar'@'localhost';
-- IZMERENO: ... REQUIRE NONE PASSWORD EXPIRE DEFAULT ACCOUNT UNLOCK
--           PASSWORD HISTORY DEFAULT PASSWORD REUSE INTERVAL DEFAULT
--           PASSWORD REQUIRE CURRENT DEFAULT
--           FAILED_LOGIN_ATTEMPTS 3 PASSWORD_LOCK_TIME 1

-- Politika je i kolona reda - dokaz da je rec o stanju, ne o pluginu.
SELECT user, host, plugin,
       JSON_EXTRACT(User_attributes, '$.Password_locking') AS zakljucavanje
FROM mysql.user
WHERE user = 'kljucar';
-- IZMERENO: kljucar | localhost | caching_sha2_password |
--           {"failed_login_attempts": 3, "password_lock_time_days": 1}
-- Politika je, dakle, JSON upisan na sam nalog - isti obrazac kao
-- partial_revokes: sto grant-tabele ne mogu da izraze, pise se van njihovog
-- oblika, u User_attributes.

-- --- korak 2: tri promasaja ---------------------------------------------
-- Iz komandne linije (cmd), tri puta, svaki put sa POGRESNOM lozinkom.
-- Workbench nije pogodan jer kesira i ponovo koristi konekciju.
--
--   mysql -u kljucar -h 127.0.0.1 -p
--   (unesi: pogresna1 / pogresna2 / pogresna3)
--
-- Ocekivano prva tri puta:
--   ERROR 1045 (28000): Access denied for user 'kljucar'@'localhost'
--                       (using password: YES)

-- --- korak 3: cetvrti pokusaj, TACNA lozinka ----------------------------
--   mysql -u kljucar -h 127.0.0.1 -p
--   (unesi: Lozinka!2345)
--
-- IZMERENO na 8.4.11:
--   ERROR 3955 (HY000): Access denied for user 'kljucar'@'localhost'.
--   Account is blocked for 1 day(s) (1 day(s) remaining)
--   due to 3 consecutive failed logins.
--
-- NAPOMENA ZA RAD: prirucnik u primeru prikazuje ERROR 3957 uz formulaciju
-- "an error that looks like this", dakle ilustraciju a ne specifikaciju.
-- U rad ide 3955 kao IZMERENO na 8.4.11, uz napomenu o razlici.
-- Ovo nije ista greska kao ER_ACCOUNT_HAS_BEEN_LOCKED, koja se vraca za
-- rucno zakljucan nalog i glasi samo "Account is locked."
--
-- OVO JE CELA POENTA POGLAVLJA: kredencijal je tacan, plugin je rekao "da",
-- a jezgro je svejedno odbilo, jer cita stanje koje plugin ne vidi.

-- --- korak 4: rucno otkljucavanje ---------------------------------------
-- Brojac se resetuje i tacnom prijavom (kad nalog nije zakljucan) ili rucno:
ALTER USER 'kljucar'@'localhost' ACCOUNT UNLOCK;

-- Provera da prijava sada prolazi sa istom, nepromenjenom lozinkom:
--   mysql -u kljucar -h 127.0.0.1 -p   (Lozinka!2345)
-- IZMERENO: "Welcome to the MySQL monitor." - prijava uspeva.
--
-- Da lozinka nikad nije bila problem, dokazuje to sto se nista u vezi
-- sa lozinkom nije menjalo izmedju koraka 3 i koraka 4.

-- --- korak 5: ciscenje ---------------------------------------------------
DROP USER 'kljucar'@'localhost';