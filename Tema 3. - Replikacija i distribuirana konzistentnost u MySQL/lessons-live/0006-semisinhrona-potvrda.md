> [!quote] YOU
> > [!note] SKILL loaded: teach
>
> Chapter 4 – Semisinhrona replikacija i značenje potvrde (ticket 16,
>  .scratch/replikacija/issues/16-chapter-4-semisync.md). Lesson half only; do not write the paper prose this session.
>
>    Teach me what a semisync acknowledgement actually means:
>    - AFTER_SYNC vs AFTER_COMMIT: what each waits for, and the window where a client can read a transaction that a
>  failover then erases.
>    - The timeout that silently degrades semisync back to async, and how an operator could notice.
>    - Why acknowledgement cost is a network-distance story (the 2×2 durability matrix from tickets 10 and 15).
>
>    You may re-teach any distributed-systems background I've forgotten (acks, durability, failover). Lessons get the
>  long theory budget. Everything in Serbian must follow serbian-grammar, with no Croatianisms and the terms from
>  GLOSSARY.md.
>
>    Run the visibility-window and failed-source-rejoin measurements (memo 04 claims 2, 3 and 6) as part of the lesson,
>  so I see them live, not just read about them. Use the 3307/3308/3309 sandbox in the async state. Start the instances
>  with examples/00-setup/topology.ps1, and leave port 3306 alone. Use mysqlsh JS with held sessions for the sub-second
>  window.

> [!question] Question — Obsidian
> Da li želiš da se ova lekcija uživo prenosi u Obsidian belešku (md-log)?
>
> 1. Da, nova beleška
> 2. Da, postojeća beleška
> 3. Ne

> [!example] Answer
> Da, nova beleška

> [!abstract] PI
> Napravio sam praznu belešku. Nalepi ovu komandu:
>
> ```
> /md-log lessons-live/0006-semisinhrona-potvrda.md
> ```
>
> Javi mi kad je povezana. Topologija je već pokrenuta (3307/3308/3309, asinhrona, oba kanala ON; 3306 netaknut).


> [!quote] YOU
> Nastavi


> [!abstract] PI
> Počinjemo proverom znanja: nekoliko kratkih pitanja da vidim šta je ostalo iz lekcija 0004 i 0005 i gde se znanje završava. Ništa se ne ocenjuje osim za moju orijentaciju.


> [!question] Quiz
> Izvor (3307) radi sa sync_binlog = 1 i innodb_flush_log_at_trx_commit = 1. Transakcija T je prošla pripremu u redo logu, a zatim je upisana u binarni log i nad njim je urađen fsync. Pre nego što InnoDB obeleži T kao komitovanu, proces mysqld pada. Šta oporavak radi sa T pri ponovnom pokretanju?
>
> 1. Komituje T, jer se T nalazi u binarnom logu
> 2. Ostavlja T pripremljenu dok je replika ne potvrdi
> 3. Poništava T i briše je iz binarnog loga
> 4. Poništava T, jer T nije komitovana u InnoDB-u


> [!success] Quiz — correct ✓
> Your answer: 1. Komituje T, jer se T nalazi u binarnom logu
> Correct answer: 1
>
> Binarni log je jedina tačka odluke dvofaznog komitovanja. Pripremljena transakcija koja postoji u binarnom logu se komituje (tačka pada B), a ona koje nema u binarnom logu se poništava (tačka A). Razlog: čim je T u binarnom logu, replike su je možda već preuzele, pa bi njeno poništavanje razdvojilo izvor i replike.


> [!question] Quiz
> Izvor radi sa sync_binlog = 0 i innodb_flush_log_at_trx_commit = 1. Klijent je dobio OK za COMMIT. Koji događaj može da izgubi tu transakciju iz binarnog loga?
>
> 1. Samo pad procesa mysqld, ne i pad sistema
> 2. I pad procesa mysqld i pad operativnog sistema
> 3. Nijedan, jer je redo log već sinhronizovan
> 4. Samo pad operativnog sistema ili nestanak struje


> [!success] Quiz — correct ✓
> Your answer: 4. Samo pad operativnog sistema ili nestanak struje
> Correct answer: 4
>
> Sa sync_binlog = 0 binarni log se upisuje pozivom write(), pa podaci stoje u kešu operativnog sistema. Pad procesa mysqld ne briše keš OS-a, pa OS ipak upiše te podatke na disk. Pad operativnog sistema ili nestanak struje briše keš, pa se gubi deo binarnog loga koji nije prošao fsync.


> [!abstract] PI
> Oba pitanja iz lekcije 0005 su tačna, pa prelazim na semisinhronu replikaciju, da vidim šta već znaš o njoj.


> [!question] Quiz
> Uključena je semisinhrona replikacija sa jednom replikom. Izvor je dobio potvrdu (acknowledgement) za transakciju T od replike 3308. Šta je ta potvrda tačno utvrdila o T na 3308?
>
> 1. Nit primene je primenila T na tabele
> 2. Replika je proverila T i nije našla sukob
> 3. Nit prijema je upisala T u relay log
> 4. Replika je komitovala T u svom binarnom logu


> [!question] Quiz — I don't know
> Your answer: I don't know
> Correct answer: 3
>
> Potvrdu šalje nit prijema kada upiše događaje transakcije u relay log (i nad njim uradi flush). Nit primene to tek kasnije primenjuje, pa potvrđena transakcija ne mora biti vidljiva na replici. Provera sukoba je pojam iz Group Replication-a, ne iz semisinhrone replikacije.


> [!question] Quiz
> Na replici 3309 je nit prijema zaustavljena (STOP REPLICA IO_THREAD), a nit primene radi. Izvor 3307 komituje novu transakciju T. Šta se dešava sa T na 3309?
>
> 1. Nit primene sama čita T iz binarnog loga izvora
> 2. Izvor šalje T direktno niti primene
> 3. T stiže u relay log, ali se ne primenjuje
> 4. T ne stiže na 3309 dok se nit prijema ne pokrene


> [!question] Quiz — I don't know
> Your answer: I don't know
> Correct answer: 4
>
> Note: Pretpostavljam 4. ili 3.
>
> Samo nit prijema razgovara sa izvorom: preuzima događaje od niti koja šalje log i upisuje ih u relay log. Nit primene čita isključivo lokalni relay log. Bez niti prijema ništa novo ne ulazi u relay log, pa T ne stiže na 3309 sve dok se nit prijema ne pokrene.


> [!question] Quiz
> Na izvoru su otvorene dve sesije, A i B, sa podrazumevanim nivoom izolovanosti. Sesija A izvršava INSERT i zatim COMMIT. U kom trenutku sesija B prvi put može da pročita taj red?
>
> 1. Tek kad klijent A dobije OK za COMMIT
> 2. Čim je red upisan u binarni log
> 3. Čim A izvrši INSERT, pre COMMIT-a
> 4. Čim InnoDB komituje transakciju


> [!failure] Quiz — incorrect ✗
> Your answer: 2. Čim je red upisan u binarni log
> Correct answer: 4
>
> Vidljivost za druge sesije određuje InnoDB: red postaje vidljiv kada InnoDB komituje transakciju. Upis u binarni log to ne čini (to je još priprema pa odluka u dvofaznom komitovanju), a trenutak kada klijent A primi OK je zaseban događaj koji može doći i kasnije. Upravo taj razmak između komitovanja u InnoDB-u i odgovora klijentu je tema današnje lekcije.


> [!question] Quiz
> Transakcija T na izvoru je upisana u binarni log i nad njim je urađen fsync, ali InnoDB još nije uradio drugu fazu (komitovanje). U tom trenutku sesija B čita tabelu. Šta B vidi?
>
> 1. Stanje sa T, jer je odluka već u binarnom logu
> 2. B čeka dok se T ne komituje u InnoDB-u
> 3. Stanje sa T, jer je T već u redo logu
> 4. Stanje bez T, jer InnoDB još nije komitovao T


> [!question] Quiz — I don't know
> Your answer: I don't know
> Correct answer: 4
>
> Obično čitanje (SELECT bez zaključavanja) u InnoDB-u čita snimak podataka i vidi samo transakcije koje je InnoDB već komitovao. Pripremljena transakcija nije komitovana, pa je B ne vidi i ne čeka na nju. Binarni log odlučuje šta će oporavak uraditi posle pada, a o vidljivosti za druge sesije odlučuje InnoDB.


> [!question] Quiz
> Asinhrona replikacija: 3307 je izvor, 3308 replika. Klijent dobija OK za transakciju T, a 3307 pada pre nego što je nit prijema na 3308 preuzela T. Operator radi failover i proglašava 3308 za novi izvor. Šta važi za T?
>
> 1. Failover se odbija dok 3307 ne pošalje T
> 2. 3308 preuzima T iz binarnog loga srušenog izvora
> 3. T je izgubljena, iako je klijent dobio OK
> 4. T se vraća na 3308 kad se 3307 ponovo pokrene


> [!success] Quiz — correct ✓
> Your answer: 3. T je izgubljena, iako je klijent dobio OK
> Correct answer: 3
>
> Asinhroni izvor šalje OK pre nego što je ijedna replika videla transakciju. Mrtav izvor ne šalje ništa, a novi izvor ne može da čita njegov disk, pa je T izgubljena na novom izvoru. Šta se dešava kada se stari izvor vrati i ima T u svom binarnom logu, deo je današnje lekcije.


> [!question] Quiz
> Semisinhrona replikacija je uključena sa rpl_semi_sync_source_timeout = 1000 (ms), a obe replike su nedostupne. Klijent šalje COMMIT. Šta klijent dobija?
>
> 1. OK posle oko 1 s, uz upozorenje u odgovoru
> 2. Grešku posle oko 1 s, transakcija je poništena
> 3. OK posle oko 1 s, bez ikakvog upozorenja
> 4. Ništa, COMMIT čeka dok se replika ne vrati


> [!failure] Quiz — incorrect ✗
> Your answer: 2. Grešku posle oko 1 s, transakcija je poništena
> Correct answer: 3
>
> Posle isteka vremena izvor prestaje da čeka, komituje i vraća običan OK; klijent ne saznaje da potvrde nije bilo. Izvor se istovremeno prebacuje u asinhroni režim i u njemu ostaje dok se replika ne vrati. To je izmereno na našoj topologiji (zapis 0001): prvi COMMIT je trajao 1 004 293 µs, drugi 782 µs.


> [!abstract] PI
> ## Plan lekcije
>
> **Pristup.** Prvo vraćamo dva temelja koja su ti se pokazala klimava: (1) replika saznaje za transakciju **samo** preko niti prijema, koja je upisuje u relay log; (2) **vidljivost** i **odluka** su dva različita trenutka na izvoru. Binarni log odlučuje šta će oporavak uraditi, a InnoDB odlučuje šta drugi mogu da pročitaju. Iz ta dva temelja izvodimo šta potvrda uopšte može da znači i **gde u nizu komitovanja** izvor može da je čeka. Ima tačno dva razumna mesta, a to su `AFTER_SYNC` i `AFTER_COMMIT`. Tvoj zadatak biće da sam zaključiš koje od njih otvara prozor.
>
> Zatim ide merenje uživo:
>
> - **M1:** prozor vidljivosti pod oba režima. Potvrdu namerno zadržavamo tako što zaustavimo niti prijema.
> - **M2:** stvarni pad izvora (proces se ubija), pa failover na 3308. Proveravamo da li red koji je sesija B pročitala i dalje postoji.
> - **M3:** stari izvor se ponovo pokreće. Pravilo oporavka iz lekcije 0005 sada radi **protiv nas**, jer komituje transakciju koju niko nije potvrdio. Zatim pokušavamo da ga vratimo kao repliku.
>
> Na kraju dolaze istek vremena (M1 ga usput pokazuje uživo), signali po kojima operator primećuje da je semisinhrona replikacija isključena, i cena potvrde kao priča o mrežnoj udaljenosti, uz matricu 2×2 iz lekcije 0005 i zapisa 0001. Matricu ne merimo ponovo.
>
> Sva merenja idu u novi folder `examples/03-semisync/`. Prozor meri mysqlsh JS sa otvorenim sesijama. Pisac je zaseban proces, jer njegov COMMIT blokira. Na kraju skripta za vraćanje dovodi topologiju u asinhrono stanje mirovanja, sa identičnim `gtid_executed` na sva tri čvora.
>
> ```mermaid
> graph TD
>   T1["T1: replika saznaje samo preko niti prijema → relay log"]
>   T2["T2: vidljivost = komitovanje u InnoDB-u"]
>   T3["T3 (0005): niz komitovanja; binarni log odlučuje pri oporavku"]
>   P["Potvrda = T je u relay logu na drugom disku"]
>   W["Dva mesta čekanja: AFTER_SYNC / AFTER_COMMIT"]
>   M1["M1 uživo: prozor vidljivosti"]
>   F["M2: failover briše ono što je B pročitao"]
>   R["M3: stari izvor posle oporavka ima višak → ne vraća se"]
>   TO["Istek vremena: tihi OK → asinhrono; signali"]
>   C["Cena = povratno putovanje mreže (matrica 2×2)"]
>   G["Cilj: šta potvrda zaista znači → okosnica rada"]
>   T1 --> P
>   T3 --> W
>   P --> W
>   T2 --> W
>   W --> M1 --> F --> G
>   T3 --> R --> G
>   F --> R
>   M1 --> TO --> G
>   P --> C --> G
> ```


> [!question] Question — Plan
> Da li je plan u redu i kako da podelimo gradivo?
>
> 1. Plan OK, jedna lekcija (Recommended)
> 2. Plan OK, dve lekcije
> 3. Izmeni plan


> [!example] Answer
> Plan OK, jedna lekcija (Recommended)


> [!abstract] PI
> ## Čvor 1: kako replika uopšte saznaje za transakciju
>
> **Zašto nam ovo treba sada:** potvrda je poruka koju replika šalje izvoru. Da bismo znali šta ta poruka tvrdi, moramo da znamo šta se na replici dešava sa transakcijom i ko tamo radi koji posao.
>
> **Bezuslovna istina:** na replici rade dve odvojene niti, i **samo jedna od njih razgovara sa izvorom**.
>
> ```
> IZVOR 3307                          REPLIKA 3308
> binarni log ──► nit koja šalje log ──mreža──► nit prijema ──► relay log (disk) ──► nit primene ──► tabele
>                                               (jedina veza                          (čita samo lokalni
>                                                sa izvorom)                           relay log)
> ```
>
> - **Nit prijema** (receiver, u starijim verzijama „IO thread“) održava vezu sa izvorom. Preuzima događaje iz njegovog binarnog loga i **samo ih upisuje** u lokalnu datoteku, **relay log**. Ništa ne primenjuje.
> - **Nit primene** (applier, „SQL thread“) uopšte ne zna za izvor. Čita relay log na lokalnom disku i izvršava izmene nad tabelama replike.
>
> **Zašto podela na dve niti, a ne jedna?** Ovo je **namerna odluka u dizajnu**, a ne nešto što bi moralo tako da bude. Razlog je praktičan: preuzimanje sa mreže je brzo, a primena je spora. Kad su odvojene, replika može da ima „sve preuzeto, a ništa primenjeno“. U zapisu 0001 to se videlo: relay log je narastao na 2,9 MB za 3 s i tu stao, a primena je kasnila još 10 s.
>
> **Posledice koje ti trebaju danas:**
>
> 1. Ako zaustaviš nit prijema (`STOP REPLICA IO_THREAD`), **ništa novo ne stiže** na repliku. Nit primene i dalje radi, ali samo nad onim što je već u relay logu. Tu ćemo kočnicu koristiti u svim merenjima danas: tako ćemo **namerno zadržati potvrdu**.
> 2. Za transakciju na replici postoje **tri različita stanja**: (a) još nije stigla, (b) **u relay logu je**, ali nije primenjena, (c) primenjena je i vidljiva na replici. Između stanja (b) i (c) može proći dosta vremena.
>
> **Veza sa onim što znaš:** iz lekcije 0004 znaš da replikacija u MySQL-u znači slanje loga i njegovo ponovno izvršavanje. Nit prijema je deo koji „šalje“, a nit primene deo koji „izvršava“. Relay log je prostor između njih, na disku replike.
>
> Napiši „dalje“.


> [!quote] YOU
> Dalje


> [!question] Quiz
> Na replici 3308 nit prijema radi, a nit primene je zaustavljena (STOP REPLICA SQL_THREAD). Izvor 3307 komituje transakciju T. Gde je T na 3308 posle nekoliko sekundi?
>
> 1. U tabelama, jer je nit prijema primenjuje sama
> 2. U binarnom logu izvora, čeka da se nit primene pokrene
> 3. Nigde, jer bez niti primene ništa ne stiže
> 4. U relay logu, ali nije primenjena na tabele


> [!success] Quiz — correct ✓
> Your answer: 4. U relay logu, ali nije primenjena na tabele
> Correct answer: 4
>
> Nit prijema radi nezavisno od niti primene: preuzima T od izvora i upisuje je u relay log. Pošto je nit primene zaustavljena, T ostaje u stanju (b): u relay logu je, ali nije primenjena, pa nije vidljiva na replici.


> [!abstract] PI
> ## Čvor 2: odluka i vidljivost su dva različita trenutka
>
> **Zašto nam ovo treba:** na proveri znanja si rekao da drugi vide red čim je upisan u binarni log. To je razumna pretpostavka, jer je u lekciji 0005 binarni log bio „tačka odluke“. Ali na izvoru postoje **dva različita pitanja**, i na njih ne odgovara isti deo sistema.
>
> **Niz komitovanja na izvoru** (iz lekcije 0005, sa `sync_binlog = 1`):
>
> ```
> 1. priprema u redo logu (InnoDB)         T je "pripremljena"
> 2. upis + fsync binarnog loga            ◄── ODLUKA: posle pada oporavak komituje T
> 3. komitovanje u InnoDB-u                ◄── VIDLJIVOST: od sada druge sesije čitaju T
> 4. OK klijentu                           klijent saznaje da je T komitovana
> ```
>
> **Pitanje 1: „Šta će biti sa T ako server sada padne?“** Odgovor daje **binarni log**. To je pravilo oporavka koje znaš: ako je T u binarnom logu, oporavak je komituje. Ovo pitanje postoji samo **posle** pada.
>
> **Pitanje 2: „Šta sesija B vidi ako sada čita?“** Odgovor daje **InnoDB**, i binarni log ga uopšte ne zanima. Obično čitanje (`SELECT` bez zaključavanja) u InnoDB-u čita **snimak** podataka. U snimku su samo transakcije koje je InnoDB već komitovao (korak 3). Pripremljena transakcija posle koraka 2 još nije komitovana u InnoDB-u, pa je B **ne vidi**. B pritom ne čeka, nego jednostavno čita stanje bez T.
>
> **Zašto je ovo bezuslovno:** binarni log je datoteka u koju se piše. Sesija B nikad ne čita binarni log, nego čita tabele kroz InnoDB. Zato upis u binarni log ne može da učini red vidljivim. Vidljivim ga čini samo InnoDB, u trenutku kada komituje.
>
> **Šta je važno za danas:** koraci 3 i 4 su **odvojeni događaji**. Ako se između njih nešto ubaci (na primer čekanje na repliku), nastaje period u kome **drugi već vide T, a klijent koji ju je upisao još nije dobio OK**. Isto tako, ako se nešto ubaci između koraka 2 i 3, T je odlučena za oporavak, ali je još niko ne vidi. Ova dva mesta su cela današnja lekcija.
>
> Napiši „dalje“.


> [!quote] YOU
> dalje


> [!question] Quiz
> Na izvoru je transakcija T prošla korake 1 (priprema) i 2 (upis i fsync binarnog loga), a korak 3 (komitovanje u InnoDB-u) još nije urađen. Koji par odgovora je tačan za ovaj trenutak?
>
> 1. Sesija B ne vidi T; posle pada oporavak komituje T
> 2. Sesija B čeka na T; posle pada oporavak komituje T
> 3. Sesija B ne vidi T; posle pada oporavak poništava T
> 4. Sesija B vidi T; posle pada oporavak komituje T


> [!success] Quiz — correct ✓
> Your answer: 1. Sesija B ne vidi T; posle pada oporavak komituje T
> Correct answer: 1
>
> Ova dva odgovora daju dva različita dela sistema. Vidljivost određuje InnoDB: T još nije komitovana u InnoDB-u, pa je B ne vidi (i ne čeka na nju, jer čita snimak). Oporavak određuje binarni log: T je u binarnom logu, pa je oporavak komituje.


> [!abstract] PI
> ## Čvor 3: šta potvrda treba da znači (izvodimo je sami)
>
> **Problem od koga polazimo** (znaš ga iz lekcije 0004): kod asinhrone replikacije izvor šalje OK pre nego što je ijedna replika videla T. Ako izvor tada padne, failover proglašava repliku koja nema T, i T je izgubljena **iako je klijent dobio OK**.
>
> **Prirodna ideja za popravku:** izvor **ne šalje OK** klijentu dok ne zna da T postoji i **van njegove mašine**. Ako tada izvor padne, T i dalje postoji negde drugde. Za to replika mora da pošalje poruku „imam T“. Ta poruka je **potvrda** (acknowledgement).
>
> **Ostaje pitanje:** u kom trenutku replika sme da kaže „imam T“? Iz čvora 1 znaš da transakcija na replici prolazi kroz stanja:
>
> ```
> (a) stigla u memoriju niti prijema
> (b) upisana u relay log + fsync (na disku replike)
> (c) primenjena na tabele replike (vidljiva na replici)
> ```
>
> Imamo dva zahteva koji vuku na suprotne strane:
>
> - **Potvrda mora da preživi pad.** Ako izvor padne, a odmah zatim padne i replika, T ne sme da nestane ni sa replike.
> - **Potvrda mora biti jeftina**, jer klijent sve to vreme čeka na OK. Iz zapisa 0001 znaš da je primena spora: nit primene može da kasni i desetine sekundi.
>
> Probaj sam da odabereš trenutak koji zadovoljava oba zahteva. Pitanje sledi.
>
> Napiši „dalje“.


> [!quote] YOU
> Dalje


> [!question] Quiz
> Izvor čeka potvrdu pre nego što pošalje OK klijentu. Koji je najraniji trenutak na replici u kome ona sme da pošalje potvrdu, a da T i dalje preživi ako odmah zatim padnu i izvor i proces replike?
>
> 1. Kad nit prijema upiše T u relay log i uradi fsync
> 2. Čim nit prijema primi T u memoriju
> 3. Kad nit prijema upiše T u relay log, bez fsync-a
> 4. Kad nit primene primeni T na tabele


> [!success] Quiz — correct ✓
> Your answer: 1. Kad nit prijema upiše T u relay log i uradi fsync
> Correct answer: 1
>
> Stanje (a) je samo u memoriji, pa nestaje sa padom procesa. Primena (c) bi bila sigurna, ali je nepotrebno spora: za oporavak je dovoljno da T bude na disku replike, jer nit primene posle ponovnog pokretanja nastavlja iz relay loga. Najraniji siguran trenutak je (b). Upravo to piše u priručniku za 8.4: „The replica acknowledges receipt of a transaction's events only after the events have been written to its relay log and flushed to disk.“ Napomena: odgovor bez fsync-a bi preživeo pad procesa replike, ali ne i pad njenog operativnog sistema (lekcija 0005), pa se MySQL odlučio za fsync.


> [!abstract] PI
> Jedna ispravka, jer pitanje nije bilo ispravno sastavljeno. U pitanju sam napisao „padnu izvor i **proces** replike“. Pod tim uslovom bi i opcija „bez fsync-a“ preživela, jer pad procesa ne briše keš operativnog sistema (to je tvoje znanje iz lekcije 0005). Taj distraktor je zato bio odbranjiv. Tačna formulacija glasi: fsync je potreban da potvrda preživi i **pad operativnog sistema replike**, a MySQL čeka upravo njega. Tvoj odgovor je ispravan, a greška je bila u mom pitanju.
>
> ## Čvor 4: gde u nizu komitovanja izvor čeka
>
> **Motivacija:** sada znamo **šta** izvor čeka: potvrdu da je T u relay logu replike, na disku. Ostaje pitanje **kada** u svom nizu komitovanja počinje da čeka. Ponovo niz sa izvora:
>
> ```
> 1. priprema u redo logu
> 2. upis + fsync binarnog loga      ← T postoji u binarnom logu i može se poslati replici
> 3. komitovanje u InnoDB-u          ← vidljivost za druge sesije
> 4. OK klijentu
> ```
>
> **Čekanje ne može doći pre koraka 2.** Nit koja šalje log šalje replici ono što je u binarnom logu, pa pre koraka 2 nema šta da se pošalje. Ne može doći ni posle koraka 4, jer bi to bila asinhrona replikacija. Ostaju **tačno dva mesta**:
>
> - **između 2 i 3:** to je `AFTER_SYNC` („posle sinhronizacije binarnog loga“);
> - **između 3 i 4:** to je `AFTER_COMMIT` („posle komitovanja u InnoDB-u“).
>
> Oba se biraju istom promenljivom, `rpl_semi_sync_source_wait_point`, koja se menja dinamički. Podrazumevana vrednost je `AFTER_SYNC`. Istorijska napomena, čisto kao činjenica: `AFTER_COMMIT` je bio jedini način rada pre MySQL-a 5.7.2, a `AFTER_SYNC` je dodat kasnije upravo zbog problema koji ćeš sada sam izvesti.
>
> **U oba slučaja klijent koji upisuje dobija OK tek posle potvrde.** Dakle, sa stanovišta tog klijenta, režimi izgledaju **isto**. Razlika je u tome šta za to vreme vide **ostale** sesije. Primeni čvor 2 na oba mesta.
>
> Napiši „dalje“.


> [!quote] YOU
> Dalje


> [!question] Quiz
> Semisinhrona replikacija je uključena, a potvrda sa replike još nije stigla. Klijent A je poslao COMMIT za T i čeka. Sesija B na izvoru čita tabelu u koju T upisuje. U kom režimu B već vidi T?
>
> 1. Samo u AFTER_COMMIT
> 2. Samo u AFTER_SYNC
> 3. U oba režima
> 4. Ni u jednom režimu


> [!success] Quiz — correct ✓
> Your answer: 1. Samo u AFTER_COMMIT
> Correct answer: 1
>
> U AFTER_COMMIT izvor čeka između koraka 3 i 4: InnoDB je već komitovao T, pa je B vidi, dok A još čeka OK. U AFTER_SYNC izvor čeka između koraka 2 i 3: T je u binarnom logu, ali je InnoDB još nije komitovao, pa je B ne vidi. Priručnik za AFTER_COMMIT: „other clients can see the committed transaction before the committing client.“


> [!abstract] PI
> Tačno. Sada ovo merimo na živoj topologiji. Pišem skripte za merenje M1 u `examples/03-semisync/`.


> [!abstract] PI
> Pomoćna funkcija je pogrešno prosleđivala argumente. Popravljam je, a izlaz pomoći sam ignorisao.


> [!abstract] PI
> ## Rezultat M1 (živo merenje, staged: potvrda je zadržana zaustavljanjem niti prijema)
>
> | | `AFTER_SYNC` | `AFTER_COMMIT` |
> |---|---|---|
> | COMMIT pisca A trajao je | 3012 ms | 3010 ms |
> | B prvi put vidi red posle | **3012 ms** (u istom trenutku kada A dobija OK) | **5 ms** |
> | prozor (B vidi red, a A još nema OK) | **0 ms** | **3005 ms** |
> | red na 3308 i 3309 dok traje prozor | 0 / 0 | 0 / 0 |
>
> ```
> AFTER_COMMIT, vreme od COMMIT-a pisca A →
> 0 ms     5 ms                                   3010 ms
> |--------|=======================================|
> A: COMMIT ... "Waiting for semi-sync ACK" ...... OK (bez upozorenja)
> B:       vidi red ───────────────────────────────►
> 3308/3309: reda NEMA ════════════════════════════►
> ```
>
> **Kako da pročitaš rezultat:**
>
> 1. **Ključni red u tabeli je poslednji.** Pod `AFTER_COMMIT` B je 3 sekunde čitao red koji **postoji samo na 3307**. Nijedna replika ga nije imala. Ako 3307 padne bilo kada u tom periodu, B je pročitao podatak koji ne postoji ni na jednom preživelom serveru.
> 2. Proces pisca je bio u stanju **„Waiting for semi-sync ACK from replica“**. Pod `AFTER_COMMIT` B je pre toga video i stanje „waiting for handler commit“, što znači da je InnoDB već radio komitovanje. Ovo je čvor 2 uživo: vidljivost dolazi iz InnoDB-a, a čekanje je došlo **posle** nje.
> 3. **Uzgred se videlo i nešto drugo:** A je posle 3 s dobio **OK**, ne grešku, iako potvrda nikad nije stigla. `Rpl_semi_sync_source_status` je prešao u OFF, a `no_tx` je porastao. Tome se vraćamo kod isteka vremena. Primeti i da je `Rpl_semi_sync_source_clients` sve vreme pokazivao **2**, iako su obe niti prijema bile zaustavljene. Taj brojač, dakle, nije pouzdan signal.
>
> **Šta sledi (M2):** ponovićemo `AFTER_COMMIT`, ali ovaj put **ubijamo proces** na 3307 dok pisac čeka, pa radimo failover na 3308. Pre toga probaj da predvidiš ishod.
>
> Napiši „dalje“.


> [!quote] YOU
> Dalje


> [!question] Quiz
> AFTER_COMMIT, niti prijema na 3308 i 3309 su zaustavljene. Pisac A upisuje red id = 2001 i čeka potvrdu; sesija B na 3307 je već pročitala taj red. Tada ubijamo proces mysqld na 3307, a 3308 proglašavamo za novi izvor. Šta tada važi?
>
> 1. A dobija grešku veze; red 2001 ne postoji na 3308
> 2. A dobija grešku veze; red 2001 postoji na 3308
> 3. A dobija OK; red 2001 postoji na 3308
> 4. A dobija OK; red 2001 ne postoji na 3308


> [!success] Quiz — correct ✓
> Your answer: 1. A dobija grešku veze; red 2001 ne postoji na 3308
> Correct answer: 1
>
> A nikad nije dobio OK: njegova veza je pukla dok je čekao potvrdu, pa A dobija grešku veze i ne zna da li je upis uspeo. Red 2001 nikad nije stigao na 3308, jer je nit prijema bila zaustavljena, pa ga novi izvor nema. Anomalija je u sesiji B: B je pročitala red i možda je na osnovu njega već nešto uradila, a sada taj red ne postoji. Pisac nije izgubio ništa što mu je potvrđeno, ali je čitalac video podatak koji je failover izbrisao.


> [!abstract] PI
> Pokrećem M2: `AFTER_COMMIT`, pisac upisuje id = 2001, zatim **ubijam proces** na 3307 i radim failover na 3308.


> [!abstract] PI
> ## Rezultat M2 (živo merenje: pravi pad procesa, potvrda zadržana kao u M1)
>
> ```
> t = 0 ms      A: INSERT id=2001 (COMMIT) → "Waiting for semi-sync ACK from replica"
> t = 1500 ms   B na 3307: COUNT(*) WHERE id=2001  →  1     ← B je VIDELA red
> t = 1500 ms   ⚡ mysqld na 3307 ubijen (Stop-Process -Force)
> t = 1497 ms   A: "Lost connection to MySQL server during query"   ← A nije dobio OK
> failover      3308 je novi izvor, 3309 je preusmeren na 3308
>               aplikacija na 3308: id=2001  →  0           ← red NE POSTOJI
> ```
>
> **Kako da pročitaš rezultat:**
>
> - **Pisac A je dobio grešku, ne OK.** Iz njegovog ugla ništa nije prekršeno, jer mu niko nije rekao da je upis uspeo.
> - **Sesija B je pročitala red koji sada ne postoji ni na jednom serveru koji radi.** GTID skup na 3308 posle failover-a je isti kao pre upisa (`…92f36f51…:1-17678`), pa nijedna transakcija nije stigla. To je **anomalija konzistentnosti**: sistem je jednom klijentu pokazao stanje, a zatim ga je, posle failover-a, poništio. Zato ovo nije sporedna napomena o performansama. Pitanje nije koliko brže radi `AFTER_COMMIT`, nego **šta je B smela da pročita**.
> - Priručnik kaže isto, a mi smo to sada izmerili: „it is possible for such clients to see a loss of data relative to what they saw on the source.“
>
> **Usput, definicije koje poglavlje mora da uvede zajedno:** ono što smo uradili je **failover** (preuzimanje uloge izvora nakon otkaza): izvor je **otkazao** i nije mogao ništa da preda. Njegov par je **switchover** (planirana promena uloga): izvor je ispravan, operator ga zaustavi, sačeka da replika primi sve, pa zameni uloge. Kod switchover-a ovaj problem ne postoji, jer potvrda nikad ne ostaje „u letu“. Zato se ova dva pojma definišu jedan naspram drugog.
>
> **Sledeći korak (M3):** stari izvor 3307 sada ponovo pokrećemo. Pre toga razmisli: šta će oporavak uraditi sa id = 2001, i šta će se desiti kada 3307 povežemo kao repliku novog izvora 3308?
>
> Napiši „dalje“.


> [!quote] YOU
> Dalje


> [!question] Quiz
> Stari izvor 3307 se ponovo pokreće posle pada. Red id = 2001 je pre pada bio komitovan u InnoDB-u (AFTER_COMMIT), a novi izvor 3308 ga nema. Zatim 3307 povezujemo kao repliku od 3308, sa SOURCE_AUTO_POSITION = 1. Šta očekuješ?
>
> 1. 3307 ima red; 3308 ga preuzima od 3307
> 2. 3307 nema red; oporavak ga poništava
> 3. 3307 ima red; povezivanje uspeva bez greške
> 4. 3307 ima red; povezivanje odbijeno GTID greškom


> [!question] Quiz — I don't know
> Your answer: I don't know
> Correct answer: 3
>
> Note: Nisam siguran, idealno bi bilo da ga preuzume od 3307
>
> Red je bio komitovan u InnoDB-u (i u binarnom logu), pa ga oporavak zadržava. Povezivanje po GTID-u proverava samo da li replika ima GTID-ove sa UUID-om novog izvora koje sam izvor nema (greška 1885). Višak na 3307 nosi UUID samog 3307, pa ga ta provera ne vidi. Zato očekujem da povezivanje prođe bez greške, a da se podaci tiho razlikuju. Replikacija teče samo od izvora ka replici, pa 3308 ništa ne preuzima od 3307. Ovo je predviđanje. Sada ga merimo.


> [!abstract] PI
> Tvoja beleška („idealno bi bilo da ga 3308 preuzme od 3307“) je dobra ideja, i vratiću se na nju posle merenja, jer upravo ona objašnjava zašto priručnik kaže „discard“. Pokrećem M3:


> [!abstract] PI
> Upit za status je imao grešku u nazivu kolone (`replication_applier_status` nema kolonu za grešku). Ispravljam ga i čitam stanje kanala na 3307:


> [!abstract] PI
> Popravljam taj upit u skripti, da sledeći put radi:


> [!abstract] PI
> ## Rezultat M3 (živo merenje)
>
> ```
> 3307 posle oporavka:  id=2001 → 1     GTID_SUBTRACT(3307, 3308) = 92f36f51…:17679  ← višak
> povezivanje 3307 → 3308:  Replica_IO_Running: Yes   Replica_SQL_Running: Yes
>                           Last_IO_Errno: 0   Last_SQL_Errno: 0   Seconds_Behind_Source: 0
> red id=2001:   3307 = 1   3308 = 0   3309 = 0
> CHECKSUM TABLE: 3307 = 1524585538   3308 = 3309 = 2038849628   ← podaci se razlikuju
> ```
>
> **Predviđanje je potvrđeno, i to je najopasniji ishod.** Stari izvor ima transakciju `…:17679` koju niko drugi nema. Povezali smo ga kao repliku i **svi indikatori su zeleni**: obe niti rade, nema grešaka, kašnjenje je 0. Ipak, tabela na 3307 se razlikuje od tabele na 3308 i 3309. MySQL nas ni u jednom trenutku nije zaustavio. Greška 1885 bi se javila samo da 3307 ima GTID-ove sa UUID-om **novog izvora 3308**, a višak nosi UUID samog 3307. Zato priručnik kaže da stari izvor „should be discarded“, a ne da će ga MySQL odbiti. **Odbacivanje je posao operatora, ne sistema.** To je okosnica rada, ovaj put izmerena.
>
> **Tvoja ideja „neka 3308 preuzme red od 3307“.** Intuitivno ima smisla, ali pogledaj šta se dešava u stvarnom radu:
>
> 1. Pisac A je dobio **grešku**. Ispravna aplikacija tada ponovi upis, i to na novom izvoru 3308. Ako bi 3308 posle toga „preuzeo“ i staru verziju sa 3307, ista namera bi bila upisana dva puta, ili bi došlo do sukoba po primarnom ključu.
> 2. Za vreme dok je 3307 bio mrtav, 3308 je primao nove upise. Spajanje dva loga koja su se razdvojila zahteva rešavanje sukoba, a to je problem sistema sa više leadera (lekcija 0001, poglavlje 2). Replikacija sa jednim izvorom ga namerno izbegava tako što podaci teku **samo u jednom smeru**.
> 3. MySQL to ne radi automatski. Postoji ručni postupak (alati u MySQL Shell-u za „extra transactions“ u ClusterSet-u), ali on traži odluku operatora o svakom višku. To je tema poglavlja 6.
>
> **Veza sa lekcijom 0005, i otvoreno pitanje:** pod `AFTER_COMMIT` red je pre pada već bio komitovan u InnoDB-u, pa oporavak tu nije imao šta da odluči. Šta je sa `AFTER_SYNC`? Tamo je transakcija u trenutku pada samo **pripremljena** i upisana u binarni log, a niko je nije video. To ćemo izmeriti u M4, posle vraćanja topologije u početno stanje.
>
> Napiši „dalje“.


> [!quote] YOU
> Dalje


> [!question] Quiz
> Isti eksperiment, ali sa AFTER_SYNC: pisac upisuje id = 3001, 3307 je ubijen dok čeka potvrdu, failover ide na 3308. Sesija B na 3307 tokom čekanja NIJE videla red. Šta važi kada se 3307 ponovo pokrene?
>
> 1. Oporavak čeka potvrdu replike pre odluke
> 2. id = 3001 nije ni u binarnom logu; 3307 je čist
> 3. Oporavak poništava id = 3001; 3307 je čist
> 4. Oporavak komituje id = 3001; 3307 opet ima višak


> [!success] Quiz — correct ✓
> Your answer: 4. Oporavak komituje id = 3001; 3307 opet ima višak
> Correct answer: 4
>
> AFTER_SYNC čeka posle koraka 2: transakcija je već upisana u binarni log i nad njim je urađen fsync, a u InnoDB-u je samo pripremljena. Pravilo oporavka iz lekcije 0005 kaže da se pripremljena transakcija koja postoji u binarnom logu komituje. Oporavak ne zna ništa o semisinhronoj replikaciji ni o potvrdi, pa komituje transakciju koju niko nije potvrdio i niko nije video. Klijenti su zaštićeni (failover je bez gubitka), ali stari izvor ponovo ima višak. Zato priručnik i za AFTER_SYNC kaže da se stari izvor mora odbaciti.


> [!abstract] PI
> Tačno. Sada vraćam topologiju u početno stanje i merim M4 (`AFTER_SYNC`, pad procesa, failover, ponovno pokretanje, ponovno povezivanje).


> [!abstract] PI
> Topologija je vraćena (sva tri `gtid_executed` su identična, a replike su ponovo na 3307), i semisinhrona replikacija je ponovo uključena. Pokrećem M4:


> [!abstract] PI
> ## Rezultat M4 (živo merenje: `AFTER_SYNC`, pravi pad procesa)
>
> | | M2: `AFTER_COMMIT` | M4: `AFTER_SYNC` |
> |---|---|---|
> | B čita red na 3307 tokom čekanja | **1** (videla ga je) | **0** (nije ga videla) |
> | pisac A | greška veze | greška veze |
> | red na novom izvoru 3308 posle failover-a | 0 | 0 |
> | **da li je neki klijent video izbrisan podatak?** | **da, B** | **ne** |
> | stari izvor posle oporavka | ima red, višak `…:17679` | ima red, višak `…:17682` |
> | ponovno povezivanje na 3308 | Yes/Yes, nijedna greška | Yes/Yes, nijedna greška |
>
> **Kako da pročitaš rezultat:** `AFTER_SYNC` je uradio ono što obećava, a to je failover bez gubitka **sa stanovišta klijenata**. Niko nije video ništa što je kasnije nestalo. Ali red koji B nikad nije video (`COUNT = 0` pre pada) **postoji** na 3307 posle ponovnog pokretanja. To je pravilo oporavka iz lekcije 0005 na delu: transakcija je bila pripremljena i u binarnom logu, pa ju je oporavak komitovao. **Oporavak ne zna za potvrdu.** Dakle, `AFTER_SYNC` štiti **klijente**, ali ne čini **stari izvor** ponovo upotrebljivim. Priručnik zato za oba režima kaže da se stari izvor odbacuje.
>
> ## Čvor 5: istek vremena, tiho vraćanje na asinhronu replikaciju
>
> **Motivacija:** u M1 je pisac posle 3 s dobio **OK**, iako potvrda nikad nije stigla. Na proveri znanja si očekivao grešku. Zašto MySQL to ne radi?
>
> **Zamisli da nema isteka vremena.** Replika padne, a izvor čeka potvrdu koja nikad neće stići. Tada **nijedan upis više ne prolazi**, i zbog jedne mrtve replike je sistem praktično nedostupan za upis. Imaš dve mogućnosti:
>
> - **čekati zauvek** (ili vratiti grešku): ne lažeš klijenta, ali ne primaš upise;
> - **posle nekog vremena odustati, komitovati i reći OK**: primaš upise, ali OK sada znači manje nego što klijent misli.
>
> Ovo je pitanje iz lekcije 0001 (PACELC, prvo pitanje): kada se replika ne može dostići, da li biraš konzistentnost ili dostupnost? **MySQL po podrazumevanoj vrednosti bira dostupnost**: `rpl_semi_sync_source_timeout = 10000` ms. To je **odluka u dizajnu**, a ne nešto što iz nečega sledi. Operator može da postavi ogroman istek vremena i time praktično izabere čekanje.
>
> **Šta se tačno dešava** (izmereno u M1 i u zapisu 0001):
>
> 1. Prvi COMMIT traje koliko i istek vremena (3012 ms), pa vraća **običan OK, bez upozorenja**.
> 2. Izvor prelazi u **asinhroni režim** i u njemu ostaje. Sledeći COMMIT uopšte ne čeka (u zapisu 0001: 782 µs).
> 3. Kada se replika vrati i sustigne izvor, izvor se **sam** vraća u semisinhroni režim (M1: status ON posle `START REPLICA IO_THREAD`).
>
> Klijent ne vidi ništa od toga. **Ko onda može da primeti?** Samo operator, i to ako gleda. Evo signala koje smo danas videli na živom 3307:
>
> | signal | šta pokazuje | izmereno danas |
> |---|---|---|
> | `Rpl_semi_sync_source_status` | ON ili OFF, stanje **sada** | ON → OFF → ON |
> | `Rpl_semi_sync_source_no_tx` | broj komitova bez potvrde, **ostaje kao trag** | 0 → 1 → 2 |
> | `Rpl_semi_sync_source_no_times` | koliko puta se izvor prebacio u asinhroni režim | 0 → 1 → 2 |
> | `Rpl_semi_sync_source_yes_tx` | broj potvrđenih komitova, prestaje da raste | ostao na 1 |
> | `Rpl_semi_sync_source_wait_sessions` | sesije koje upravo čekaju potvrdu | > 0 samo tokom čekanja |
> | log grešaka: `MY-011153` | „Timeout waiting for reply of binlog …“ | dva upisa u `node1.err` |
> | vreme komitovanja | nagli skok na vrednost isteka vremena | 3010–3012 ms |
>
> **Nije signal:** `Rpl_semi_sync_source_clients` je sve vreme pokazivao 2, iako su obe niti prijema bile zaustavljene. Takođe, `Rpl_semi_sync_source_timeouted` koji navodi memo 04 **ne postoji** u 8.4.
>
> Status ON/OFF pokazuje samo trenutno stanje. Ako je istek vremena trajao 5 minuta noću, a ti pogledaš ujutru, status je opet ON. **Jedino `no_tx` i `no_times` ostaju kao trag** da je bilo perioda bez garancije.
>
> Napiši „dalje“.


> [!quote] YOU
> Dalje


> [!question] Quiz
> Operator ujutru proverava izvor. Rpl_semi_sync_source_status je ON, Rpl_semi_sync_source_no_tx je 4 120 (juče u isto vreme bio je 0), a nijedan klijent nije prijavio grešku. Šta operator može da zaključi?
>
> 1. 4 120 transakcija je izgubljeno na replikama
> 2. Preko noći je 4 120 komitova dobilo OK bez potvrde
> 3. Ništa, jer je status ON pa je sve potvrđeno
> 4. Preko noći je 4 120 komitova odbijeno sa greškom


> [!success] Quiz — correct ✓
> Your answer: 2. Preko noći je 4 120 komitova dobilo OK bez potvrde
> Correct answer: 2
>
> no_tx broji komitove koji su završeni bez potvrde replike, tj. u periodu kada se izvor vratio na asinhroni režim. Klijenti su za njih dobili običan OK, pa niko nije prijavio grešku. Status ON pokazuje samo da je semisinhrona replikacija ponovo uključena sada; brojač ostaje kao jedini trag. Te transakcije nisu nužno izgubljene: replike su ih kasnije preuzele kad su se vratile. Ali da je izvor pao u tom periodu, mogle su biti izgubljene, kao kod asinhrone replikacije.


> [!abstract] PI
> ## Čvor 6: cena potvrde je pitanje udaljenosti
>
> **Motivacija:** memo 04 je tvrdio da semisinhrona replikacija pravi commit 10 do 1000 puta sporijim. U zapisu 0001 je na našoj topologiji izmereno nešto sasvim drugo. Ko je u pravu? Oboje, i razlog je jednostavan.
>
> **Bezuslovna istina (priručnik):** usporenje je „at least the TCP/IP roundtrip time to send the commit to the replica and wait for the acknowledgment of receipt by the replica“. Potvrda je **jedno povratno putovanje** preko mreže (plus fsync relay loga na replici).
>
> **Komitovanje je zbir delova:**
>
> $$
> t_{\text{commit}} \approx t_{\text{fsync binarnog loga}} + t_{\text{fsync redo loga}} + t_{\text{povratno putovanje do replike}}
> $$
>
> Matrica iz lekcije 0005 određuje prva dva sabirka. Mreža određuje treći. Merenje iz zapisa 0001 (300 komitova po polju, loopback, na našoj topologiji):
>
> | `sync_binlog` | `innodb_flush_log_at_trx_commit` | asinhrona | semisinhrona | razlika |
> |---|---|---|---|---|
> | 1 | 1 (puna postojanost) | 764 µs | 978 µs | u granicama šuma merenja |
> | 1 | 2 | 355 µs | 406 µs | +14 % |
> | 0 | 1 | 634 µs | 533 µs | nije vidljiva |
> | 0 | 2 (bez fsync-a) | **61 µs** | **124 µs** | **+103 %** |
>
> **Kako da pročitaš tabelu:** na loopback-u je povratno putovanje desetine mikrosekundi. Uz dva fsync-a (~900 µs) potvrda se **izgubi u šumu**. Kada isključiš fsync-ove, ostaje skoro samo protokol, i tada potvrda **udvostruči** vreme komitovanja (61 → 124 µs). Cena je, dakle, uvek postojala, samo je disk bio skuplji od nje.
>
> **Šta to znači van jedne mašine:** povratno putovanje raste sa **fizičkom udaljenošću**. Svetlost u optičkom vlaknu prelazi oko 200 000 km/s. Za repliku udaljenu 1000 km povratno putovanje je zato **najmanje ~10 ms**, a to je desetak puta više od oba fsync-a zajedno. Tada potvrda postaje dominantan trošak, i memo 04 je opisivao upravo taj slučaj.
>
> Zato važe dva pravila za rad (i za odbranu): (1) **nijedan broj o ceni semisinhrone replikacije ne navodi se bez podešavanja postojanosti** pod kojim je izmeren; (2) cena potvrde je **cena udaljenosti replike**, a ne cena „uključivanja dodatka“. Operator zapravo bira **koliko daleko je replika koja mora da potvrdi**. Ovo vodi direktno u poglavlje 6 (geo-distribucija).
>
> Napiši „dalje“.


> [!quote] YOU
> Dalje


> [!question] Quiz
> Izvor i replika su na istoj mašini (loopback), uz sync_binlog = 1 i innodb_flush_log_at_trx_commit = 1. Uključivanje semisinhrone replikacije ne pravi merljivu razliku u vremenu komitovanja. Šta se desi ako repliku premestimo u data centar udaljen 1000 km, sa istim podešavanjima?
>
> 1. Commit se ubrzava, jer replika više ne deli disk
> 2. Ništa, jer smo izmerili da potvrda ne košta
> 3. Usporenje ostaje isto, jer zavisi samo od fsync-a
> 4. Commit postaje znatno sporiji, potvrda nadjača fsync


> [!success] Quiz — correct ✓
> Your answer: 4. Commit postaje znatno sporiji, potvrda nadjača fsync
> Correct answer: 4
>
> Potvrda košta najmanje jedno povratno putovanje do replike. Na loopback-u je to desetine mikrosekundi i nestaje pored dva fsync-a (~900 µs). Na 1000 km povratno putovanje je najmanje ~10 ms (svetlost u vlaknu ~200 000 km/s), pa postaje dominantan trošak komitovanja. Merenje na loopback-u ne kaže da je potvrda besplatna, nego da je na toj udaljenosti jeftinija od diska.


> [!abstract] PI
> ## Cilj: šta semisinhrona potvrda zaista znači
>
> Sve što smo danas izgradili staje u jednu rečenicu, i to je rečenica koju braniš:
>
> > **Semisinhrona potvrda znači: „bar jedna replika ima ovu transakciju u relay logu, na disku“, i ništa više. Ne znači da je replika primenila transakciju, ne znači da ju je neko video, i važi samo dok ne istekne vreme.**
>
> Svaki deo te rečenice smo izveli ili izmerili:
>
> | deo rečenice | odakle dolazi |
> |---|---|
> | „u relay logu, na disku“ | čvor 3: najraniji trenutak koji preživi pad (priručnik: „written to its relay log and flushed to disk“) |
> | ne znači da ju je replika primenila | čvor 1: nit primene radi odvojeno; stanje (b) nije stanje (c) |
> | šta drugi smeju da vide **zavisi od mesta čekanja** | čvor 2 + M1: `AFTER_COMMIT` prozor 3005 ms, `AFTER_SYNC` 0 ms |
> | failover može da izbriše ono što je čitalac video | M2: B je videla id = 2001, a 3308 ga nema |
> | stari izvor se ne vraća | M3/M4: oporavak komituje višak, ponovno povezivanje prolazi **bez greške**, a podaci se razlikuju |
> | „važi samo dok ne istekne vreme“ | čvor 5 + M1: OK posle 3 s bez upozorenja, `no_tx` kao jedini trag |
> | cena je udaljenost | čvor 6: povratno putovanje, matrica iz zapisa 0001 |
>
> **Veza sa okosnicom rada.** MySQL ovde nudi **četiri podesive tačke**: `rpl_semi_sync_source_wait_point`, `rpl_semi_sync_source_timeout`, `rpl_semi_sync_source_wait_for_replica_count` i udaljenost replike. Svaka od njih kupuje deo konzistentnosti po nekoj ceni. Na dva mesta je sistem **ćutao** dok je garancija nestajala: posle isteka vremena (OK bez upozorenja) i pri povratku starog izvora (zeleni indikatori, različiti podaci). Primećivanje u oba slučaja je **posao operatora**. Zato poglavlje 4 ne opisuje opciju za podešavanje performansi, nego pokazuje da je konzistentnost odluka operatora, a ne svojstvo sistema.
>
> Još jedno završno pitanje koje meša čvorove, pa prelazim na pisanje lekcije.
>
> Napiši „dalje“.


> [!quote] YOU
> Dalje


> [!question] Quiz
> Sistem radi sa AFTER_SYNC i timeout = 10000 ms. Replika 3308 je bila nedostupna 20 s; za to vreme je izvor komitovao 50 transakcija, a zatim je izvor pao i urađen je failover na 3308 (koja se u međuvremenu nije vratila). Šta važi?
>
> 1. Svih 50 komitova je vratilo grešku klijentima
> 2. Ništa nije izgubljeno, jer AFTER_SYNC je bez gubitka
> 3. Ništa nije izgubljeno, ali B je videla te redove
> 4. Deo od 50 transakcija sa OK-om može biti izgubljen


> [!success] Quiz — correct ✓
> Your answer: 4. Deo od 50 transakcija sa OK-om može biti izgubljen
> Correct answer: 4
>
> Posle prvog isteka vremena izvor je prešao u asinhroni režim, pa su klijenti dobijali OK bez ikakve potvrde. Garancija bez gubitka koju daje AFTER_SYNC važi samo dok je semisinhrona replikacija zaista uključena. Za transakcije komitovane u asinhronom periodu važi pravilo asinhrone replikacije: ako replika nije stigla da ih preuzme, failover ih briše iako je klijent dobio OK.


> [!abstract] PI
> Šaljem izradu pet slika paralelno, preko alata za crtanje.


> [!abstract] PI
> Pregledam svih pet slika pre nego što ih ugradim.


> [!abstract] PI
> Svih pet slika je ispravno. Na slici o tihoj degradaciji jedna oznaka malo seče isprekidanu liniju, ali se i dalje čita, pa je ostavljam. Proveravam ugovor za kviz, pa pišem lekciju.


> [!abstract] PI
> Pišem lekciju.


> [!abstract] PI
> HTML nema matematički prikaz, pa formulu prebacujem u običan tekst:


> [!abstract] PI
> Pišem zapise: merenja, zapis o učenju, indeks, README za primere, dopunu rečnika i komentar na ticket.


> [!abstract] PI
> Ažuriram indeks zapisa, rečnik i ticket:


> [!abstract] PI
> Lekcija je gotova i otvorena u pregledaču. Sva četiri merenja (M1–M4) urađena su uživo. Prozu za rad nisam pisao, to ide u sledećoj sesiji.
>
> **Šta su merenja pokazala** (claims 2, 3 i 6 iz memoa 04):
> - **Prozor vidljivosti:** pod `AFTER_SYNC` je 0 ms, a pod `AFTER_COMMIT` 3005 ms. Potvrdu sam namerno zadržao tako što sam zaustavio niti prijema, a istek vremena je bio 3000 ms.
> - **Anomalija pod `AFTER_COMMIT` se ponavlja:** sesija B je pročitala red id = 2001. Posle pada procesa i failover-a na 3308 taj red ne postoji ni na jednom serveru koji radi. Pisac je dobio grešku veze, a ne OK, pa je anomalija kod čitaoca.
> - **Stari izvor (claim 6):** posle pada pod oba režima ima transakciju koju novi izvor nema. Pod `AFTER_SYNC` ju je oporavak komitovao iako je niko nije potvrdio ni video.
> - **Ponovno povezivanje prolazi bez ijedne greške:** Yes/Yes, `Seconds_Behind_Source` 0, a `CHECKSUM TABLE` se razlikuje. Claim 6 je tačan po suštini, ali ne po mehanizmu: memo očekuje greške replikacije, a razlika u podacima je tiha.
>
> **Ispravke memoa 04:**
> - `Rpl_semi_sync_source_timeouted` ne postoji u 8.4.
> - `Rpl_semi_sync_source_clients` nije pouzdan signal: ostao je 2 i sa zaustavljenim nitima prijema.
> - Memo navodi pet signala, ne sedam kako piše u ticketu. Novu listu od sedam signala, napravljenu iz onoga što server zaista prikazuje, upisao sam u zapis merenja.
>
> **Dve tvrdnje koje sam izrekao iz sećanja** treba proveriti pre nego što uđu u rad. Označene su u zapisu merenja:
> - da je `AFTER_COMMIT` bio jedini način rada pre MySQL-a 5.7.2;
> - da 8.4 nema mehanizam koji pri oporavku odbacuje transakcije bez potvrde. Ovo je tvrdnja o odsustvu, proverena samo u priručniku, a izvori drugog nivoa još nisu.
>
> Topologija je vraćena u asinhrono stanje mirovanja i `gtid_executed` je identičan na sva tri čvora. Prazna tabela `poliklinika.semisync_demo` je ostala, a briše se sa `09-restore.ps1 -DropTable`. Port 3306 nije diran.
>
> Ako ti nešto iz lekcije nije jasno, pitaj ovde.
>
> Fajlovi su u `C:\Faks\Sistemi Baza\Tema 3. - Replikacija i distribuirana konzistentnost u MySQL\`:
> - `lessons\0004-semisinhrona-potvrda.html` (lekcija, 5 slika iz `viz\viz-l04-*`)
> - `reference\semisinhrona-potvrda.html`
> - `examples\03-semisync\` (`01`–`04`, `09-restore.ps1`, `README.md`)
> - `learning-records\0006-semisync-acknowledgement.md` (indeks i stalna ograničenja ažurirani)
> - `.scratch\replikacija\measurements\0006-semisync-acknowledgement.md`
> - `GLOSSARY.md` (§1b, nova potsekcija sa terminima za poglavlje 4)
> - `.scratch\replikacija\issues\16-chapter-4-semisync.md` (dodat komentar o rezultatima)


> [!quote] YOU
> cd examples\03-semisync
> .\01-semisync-on.ps1                              # semisync ON, 2 clients, AFTER_SYNC
> .\02-window.ps1 -WaitPoint AFTER_SYNC   -Id 1001  # writer = separate mysqlsh process,
> .\02-window.ps1 -WaitPoint AFTER_COMMIT -Id 1002  # reader = held mys ovo mi je malo iseceno jer je u sekcijij za pokreni ovo a nema scroll bar horizontalni


> [!abstract] PI
> Popravljeno, i lekcija je ponovo otvorena. Osveži stranicu ako je bila otvorena od ranije.
>
> - **Ovaj blok i blok za pad i failover u `lessons/0004-semisinhrona-potvrda.html`:** sada imaju klasu `sql run`. Dobili su tamnu pozadinu, dugme „Kopiraj“ i horizontalni scroll. Komentare sam prebacio u zasebne redove iznad komandi, pa su redovi kratki i scroll uglavnom ne treba.
> - **`../assets/lesson.css`:** dodato je `.try pre { overflow-x: auto; }`. Ubuduće se nijedan blok koda u sekciji „Pokreni ovo“ ne odseca, ni u starim ni u novim lekcijama.
>
> Kartica `reference/semisinhrona-potvrda.html` ima dva bloka bez klase, ali nije pogođena. Ti blokovi nisu u `.try` okviru, a redovi su im kratki.


> [!quote] YOU
> Da li postoji specijalna odluka zasto je ovoliko sirok deo na HTML, da li bi mogao malo da se sve poveca u sirinu zbot citljivosti ili je to po nekoj specijalnoj dimenziji


> [!question] Question — Širina
> Kako da proširim prikaz?
>
> 1. Širi samo slike i kod (Recommended)
> 2. Šira cela kolona
> 3. Šira kolona i veći font


> [!example] Answer
> Širi samo slike i kod (Recommended)


> [!abstract] PI
> Proveravam izgled u pregledaču bez prozora (headless), da ne bih nagađao:


> [!abstract] PI
> U zajednički `../assets/lesson.css` sam dodao široki prikaz i proverio ga u pregledaču bez prozora (headless Edge, širina 1600 px). Raspored je kakav smo hteli: tekst je ostao uzak, a slike i kod su široki.
>
> Na šta se promena odnosi:
> - **Tekst:** ostaje u koloni od 42rem (oko 820 px), da red i dalje ima udobnih 70 do 80 znakova.
> - **Slike, blokovi koda, „Pokreni u PowerShell-u“ okviri i uporedne tabele:** šire se na **62rem (oko 1200 px)** i centrirani su na tekst. Na manjem ekranu nikad nisu širi od prozora.
> - **Pasusi unutar okvira „Pokreni…“ i natpisi ispod slika:** zadržavaju širinu teksta, pa se i oni čitaju lako.
> - **Štampa:** ostaje kako je bila, bez širenja.
>
> Pošto je stylesheet zajednički, promena odmah važi za sve lekcije i kartice za podsećanje, i iz Tema 1 i 2. Uzane definicione tabele (`table.exp`) namerno nisam širio, jer bi sa samo dve kolone kratkog teksta delovale prazno.
>
> Osveži lekciju u pregledaču (Ctrl+F5) da vidiš promenu.


> [!quote] YOU
> Ne svidja mi se, vrati kako je bilo


> [!abstract] PI
> Vratio sam prikaz kako je bio. Iz `../assets/lesson.css` sam uklonio široki prikaz, pa su tekst, slike i kod ponovo u istoj koloni od 42rem. Osveži stranicu sa Ctrl+F5 da vidiš promenu.
>
> Zadržao sam samo popravku zbog koje si se javio: `.try pre { overflow-x: auto; }`, da se kod u okvirima „Pokreni ovo“ ne odseca.
>
> U `../TEACHING.md` sam zapisao da širina ostaje 42rem i da je široki prikaz isproban i odbijen, da ti ga sledeće sesije ne nude ponovo.
