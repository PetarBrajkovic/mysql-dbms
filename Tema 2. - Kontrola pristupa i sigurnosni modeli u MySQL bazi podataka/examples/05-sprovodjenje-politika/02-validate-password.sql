-- 05-sprovodjenje-politika / 02 - validate_password kao KOMPONENTA
--
-- Poenta: politika o jacini lozinke ne moze se sprovesti pri prijavi (tada
-- server ima samo otisak), nego u trenutku postavljanja lozinke. Autentifikacioni
-- plugin tada ne radi, pa MySQL otvara trece mesto sprovodjenja - komponentu,
-- koju jezgro poziva nad prosledjenim tekstom lozinke.
--
-- Pokrece se kao root (trazi INSTALL COMPONENT).
-- Izmereno na MySQL 8.4.11 Community, Win64.

INSTALL COMPONENT 'file://component_validate_password';

SHOW VARIABLES LIKE 'validate_password%';
-- Izmereno:
--   validate_password.policy                        MEDIUM
--   validate_password.length                        8
--   validate_password.mixed_case_count              1
--   validate_password.number_count                  1
--   validate_password.special_char_count            1
--   validate_password.check_user_name               ON
--   validate_password.dictionary_file               (prazno)
--   validate_password.changed_characters_percentage 0
--
-- policy je prekidac koliko se ostalih primenjuje:
--   LOW = samo duzina, MEDIUM = + sastav znakova, STRONG = + recnik.

-- Slaba lozinka: nalog ne nastaje.
CREATE USER 'slaba'@'localhost' IDENTIFIED BY 'abc';
-- Izmereno: Error Code: 1819. Your password does not satisfy the current
--           policy requirements
-- Simbolicko ime greske: ER_NOT_VALID_PASSWORD.

-- Vracanje servera u prvobitno stanje.
UNINSTALL COMPONENT 'file://component_validate_password';
