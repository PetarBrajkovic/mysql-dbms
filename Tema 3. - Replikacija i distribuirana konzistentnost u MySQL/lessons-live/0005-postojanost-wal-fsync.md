> [!quote] YOU
> > [!note] SKILL loaded: teach
>
> Poglavlje 3, lekcija B — Postojanost: WAL, fsync, dvofazna potvrda redo log ↔ binarni log
>    i matrica sync_binlog × innodb_flush_log_at_trx_commit (ticket 15, druga polovina lekcije).
>
>    Lekcija A je održana (learning-records/0004-binlog-gtid-async.md) — pročitaj taj zapis prvi,
>    u njemu je i odakle B kreće: WAL i fsync ne poznajem, kreni od nule (RAM naspram diska,
>    write naspram fsync), pa redo log, pa zašto dva loga traže dvofaznu potvrdu, pa matrica,
>    uz tabelu latencija iz zapisa 0001.
>
>    Na početku ponovi najklimavija mesta iz lekcije A: K3 (replika ne čita tuđe datoteke, nego
>    razgovara sa živim procesom) i prozor u kome asinhrona replikacija gubi potvrđenu transakciju.
>
>    Ritam kao u Temi 2: objašnjenje u poruci, pa kviz na kraju. Bez prevedenih metafora.

> [!question] Question
> Da li da ovu lekciju preslikavam u Obsidian (md-log)?
>
> 1. Da, nova datoteka (Recommended)
> 2. Da, postojeća datoteka
> 3. Ne

> [!example] Answer
> (no answer)

> [!abstract] PI
> Pročitao sam zapis 0004 i indeks. Lekcija B kreće od nule: RAM naspram diska, `write` naspram `fsync`, zatim WAL, redo log, dvofazna potvrda i matrica. Pre toga jedno tehničko pitanje:

> [!question] Question
> Da li da ovu lekciju preslikavam u Obsidian (md-log)?
>
> 1. Da, nova datoteka (Recommended)
> 2. Da, postojeća datoteka
> 3. Ne

> [!example] Answer
> 1. Da, nova datoteka (Recommended)

> [!abstract] PI
> Napravio sam praznu datoteku. Nalepi ovu komandu u terminal pa mi javi kad je povezano:
>
> ```
> /md-log lessons-live/0005-postojanost-wal-fsync.md
> ```


> [!quote] YOU
> Continue


> [!abstract] PI
> Povezano. Krećemo od ponavljanja dva najklimavija mesta iz lekcije A, pa tek onda prelazimo na novo gradivo.
>
> **Ponavljanje 1 — K3.** Podsetnik na koren iz lekcije A: replika zna samo ono što joj stigne kao poruka. Sledeće pitanje proverava da li to i dalje važi kada su sva tri čvora na istom računaru.


> [!question] Quiz
> Naša topologija: 3307 je izvor, 3308 i 3309 su asinhrone replike, sva tri procesa rade na istom računaru i u istom C:\mysql-repl\ direktorijumu. 3307 komituje transakciju T, upiše je u svoj binarni log na disku i vrati klijentu „OK“. Zatim se proces 3307 ubije, pre nego što je ijedna replika primila T. Šta se dešava sa T na 3308 dok 3307 ne radi?
>
> 1. T ne stiže na 3308, jer nit prijema nema živ proces od koga bi ga primila
> 2. T stiže na 3308, jer ga nit prijema preuzima iz relay loga čvora 3309
> 3. T stiže na 3308, jer ga je 3307 upisao u relay log replike pre potvrde
> 4. T stiže na 3308, jer nit prijema čita binarni log sa diska procesa 3307


> [!success] Quiz — correct ✓
> Your answer: 1. T ne stiže na 3308, jer nit prijema nema živ proces od koga bi ga primila
> Correct answer: 1
>
> K3: replika zna samo ono što joj stigne kao poruka. Nit prijema ne otvara datoteke izvora, nego razgovara sa nit koja šalje log (binlog dump thread) u živom procesu 3307. Kad tog procesa nema, nema ni sagovornika, i nije važno to što je datoteka fizički na istom disku. Relay log replike puni isključivo njena nit prijema, i to iz te konekcije. Izvor nikada ne piše u njega. Replike međusobno ne razmenjuju log, osim ako jedna nije izričito podešena kao izvor drugoj.


> [!abstract] PI
> **Ponavljanje 2 — prozor gubitka.** Kod asinhrone replikacije izvor vraća „OK“ i ne čeka repliku. Pitanje je koji događaj, u kom trenutku, pretvara potvrđenu transakciju u izgubljenu.


> [!question] Quiz
> Asinhrona replikacija, 3307 je izvor. Klijent dobije „OK“ za transakciju T. Koji scenario dovodi do toga da je T trajno izgubljen iako je klijentu potvrđen?
>
> 1. 3308 zaostaje deset sekundi za 3307 u trenutku kada klijent dobije „OK“ za T
> 2. 3307 trajno nestane pre nego što je ijedna replika primenila T, a 3308 postane novi izvor
> 3. 3307 trajno nestane pre nego što je ijedna replika primila T, a 3308 postane novi izvor
> 4. 3307 se sruši i ponovo pokrene pre nego što je ijedna replika primila T, i ostane izvor


> [!success] Quiz — correct ✓
> Your answer: 3. 3307 trajno nestane pre nego što je ijedna replika primila T, a 3308 postane novi izvor
> Correct answer: 3
>
> Prozor gubitka je period između izvorovog „OK“ i trenutka kada T stigne u relay log neke replike. Ako izvor trajno nestane u tom prozoru, T nije nigde osim na mrtvom disku, a novi izvor nikada nije video T. Za (b) je dovoljno da je T stigao u relay log: nit primene će ga primeniti i nakon pada izvora, jer je poruka već primljena. (c) je ponovno pokretanje, a ne trajni gubitak, pa T i dalje postoji u binarnom logu 3307. Da li je to garantovano posle pada, upravo je tema današnje lekcije. (d) je kašnjenje replikacije, a ne gubitak: T stiže kasnije.


> [!abstract] PI
> Sada provera znanja za novi deo. Hoću da nađem tačnu granicu: šta već znaš o memoriji i disku i gde to prestaje. Počinjem od najnižeg nivoa.


> [!question] Quiz
> Računaru iznenada nestane struje. Šta od sledećeg preživljava kad se ponovo uključi?
>
> 1. Podaci koji su bili u RAM-u; sve što je bilo samo na disku je oštećeno
> 2. Podaci koji su bili na disku; sve što je bilo samo u RAM-u je izgubljeno
> 3. Podaci i iz RAM-a i sa diska, jer operativni sistem pri gašenju prepiše RAM na disk
> 4. Podaci koji su bili na disku i u RAM-u procesa koji je poslednji pisao


> [!success] Quiz — correct ✓
> Your answer: 2. Podaci koji su bili na disku; sve što je bilo samo u RAM-u je izgubljeno
> Correct answer: 2
>
> RAM je nepostojana (volatile) memorija: sadržaj mu se drži samo dok ima struje. Disk (SSD ili HDD) je postojana memorija i čuva sadržaj bez napajanja. Kod naglog nestanka struje nema „gašenja“ u kome bi se išta prepisalo, pa (c) opisuje uredno gašenje ili hibernaciju, a ne pad. Rečnik predmeta za ono što preživljava pad koristi izraz „stabilna memorija“.


> [!abstract] PI
> To je donja granica. Sada skačem dosta više: šta se zaista desi kada program „upiše u datoteku“.


> [!question] Quiz
> Program pozove write() da upiše 100 bajtova u datoteku na SSD-u, i poziv se uspešno vrati. Gde su tih 100 bajtova u tom trenutku, u uobičajenom slučaju?
>
> 1. U kešu kontrolera na SSD-u, koji ih čuva i bez struje
> 2. U baferu samog programa; operativni sistem ih još nije video
> 3. Na SSD-u; write() se ne vraća dok podaci nisu na disku
> 4. U kešu operativnog sistema u RAM-u; na disk će otići kasnije


> [!question] Quiz — I don't know
> Your answer: I don't know
> Correct answer: 4
>
> write() samo predaje podatke operativnom sistemu, koji ih stavi u svoj keš u RAM-u (page cache) i odmah vrati uspeh. Na disk ih prepisuje kasnije, kad sam odluči. Ako struja nestane pre toga, tih 100 bajtova nema, iako je program dobio „uspelo“. Odgovor (c) opisuje baferisanje u biblioteci (npr. fwrite u C-u), što je nivo iznad write(). (d) je deo istine na nekim diskovima, ali obični keš kontrolera je takođe nepostojan.


> [!abstract] PI
> Ostala mi je još jedna nit od koje zavisi motivacija za WAL: koliko košta upis na disk u zavisnosti od toga gde se piše.


> [!question] Quiz
> Treba da se trajno upiše 1000 malih zapisa od po 100 bajtova. Varijanta X: svih 1000 se dopiše na kraj jedne datoteke, jedan za drugim. Varijanta Y: svaki zapis ide na drugo, nasumično mesto u velikoj datoteci. Šta je tačno?
>
> 1. X i Y su jednako brze, jer disk piše isti broj bajtova u oba slučaja
> 2. Y je znatno brža, jer disk piše u blokovima i rasporedi zapise po slobodnim blokovima
> 3. X i Y su jednako brze na SSD-u, jer SSD nema glavu koja se pomera po disku
> 4. X je znatno brža, jer disk piše u blokovima i jedan blok primi mnogo susednih zapisa


> [!failure] Quiz — incorrect ✗
> Your answer: 2. Y je znatno brža, jer disk piše u blokovima i rasporedi zapise po slobodnim blokovima
> Correct answer: 4
>
> Disk ne piše bajt po bajt nego u blokovima, odnosno stranicama: na SSD-u su to tipično 4 KB, a InnoDB stranica ima 16 KB. Kod X, četrdesetak susednih zapisa od 100 B staje u isti blok, pa 1000 zapisa znači dvadesetak upisa blokova. Kod Y, svaki zapis „prlja“ drugi blok, pa se upisuje 1000 celih blokova da bi se promenilo 100 KB. SSD zaista nema glavu, pa je razlika manja nego kod HDD-a, ali ostaje, jer je jedinica upisa i dalje blok.


> [!abstract] PI
> Šaljem ponovo. Ovo je ista provera: hoću da vidim da li misliš da disk sam bira gde završava izmenjeni red.


> [!question] Quiz
> InnoDB tabela pacijent ima red sa id = 500, koji je smešten u stranicu P na disku. Izvrši se UPDATE pacijent SET telefon = '...' WHERE id = 500. Gde na disku mora da završi izmenjeni red, kad se jednom tamo upiše?
>
> 1. U stranici P, na mestu gde je red već bio
> 2. U prvoj slobodnoj stranici koju disk nađe
> 3. U stranici koju operativni sistem izabere
> 4. Na kraju datoteke tabele, iza svih stranica


> [!success] Quiz — correct ✓
> Your answer: 1. U stranici P, na mestu gde je red već bio
> Correct answer: 1
>
> U InnoDB-u red ima svoje mesto: tabela je B+ stablo po primarnom ključu, a red sa id = 500 živi u listu stabla, tj. u stranici P. Izmena prepisuje tu stranicu na njenom mestu. Ni disk ni operativni sistem ne biraju lokaciju, jer oni ne znaju šta je red ni ključ. Upravo zato su izmene raštrkane: 1000 UPDATE-ova po različitim ključevima pogađa do 1000 različitih stranica, koje su razbacane po datoteci.


> [!abstract] PI
> Provera izvora je završena. Sve semantike koje ću učiti potvrđene su iz referentnog priručnika za 8.4. Dva mesta priručnik ne kaže izričito, pa ću ih izvesti iz mehanizma i tako ih i označiti. Prvo: šta tačno preživljava pad samog procesa `mysqld`, a šta pad operativnog sistema. Drugo: tačan unutrašnji redosled kod grupnog komitovanja.
>
> ## Plan lekcije B
>
> **Pristup.** Tvoja granica je tačno ispod WAL-a. Znaš da je RAM nepostojan a disk postojan, ali ne znaš da „upisano“ ne znači „na disku“. Zato prvo postavljam dve nove neuslovne istine: `write` naspram `fsync`, i disk piše u blokovima. Iz njih ćeš sam izvesti zašto baza ne upisuje stranice pri svakom komitovanju, nego dopisuje u log. To je WAL, a u InnoDB-u se zove redo log.
>
> Zatim dolazi jedina stvar koju ne možeš izvesti, nego ćeš je primiti kao **istorijsku odluku**: MySQL ima **dva** loga, redo i binarni. Iz K2 (isti početak, iste promene, isti redosled) ćeš izvesti šta pođe naopako kad pad uhvati jedan log upisan a drugi ne. Iz toga sledi dvofazna potvrda.
>
> Na kraju matrica nije nova činjenica. Ona je samo pitanje „da li ovaj log dobija `fsync` pri komitovanju“, postavljeno dvaput, uz tvoja merenja iz zapisa 0001. To zatvara i pitanje iz ponavljanja: šta 3307 zaista zna o T posle pada i ponovnog pokretanja.
>
> WAL i dvofaznu potvrdu radimo sokratski, jer su izvodljivi. Dva loga i podrazumevane vrednosti izlažem, jer su to odluke, a ne posledice.
>
> ```mermaid
> graph TD
>   R1["R1 RAM nepostojan, disk postojan ✓"]
>   R2["R2 write = keš OS-a; fsync čeka disk"]
>   R3["R3 disk piše u blokovima"]
>   R4["R4 OK klijentu = obećanje postojanosti"]
>   D1["fsync stranica pri svakom commit-u je preskup"]
>   D2["WAL / redo log: dopiši, fsync log, stranice kasnije"]
>   H["Dva loga: redo i binarni (istorijska odluka)"]
>   K2["K2 iz lekcije A ✓"]
>   D4["Pad između dva upisa → izvor i replike se razilaze"]
>   D5["Dvofazna potvrda: prepare → binlog → commit"]
>   M["Matrica sync_binlog × innodb_flush_log_at_trx_commit"]
>   R1-->R2; R2-->D1; R3-->D1; R4-->D1; D1-->D2
>   D2-->H; H-->D4; K2-->D4; D4-->D5; D5-->M; R2-->M
> ```
>
> Može ovako, ili hoćeš nešto da promeniš pre nego što krenemo?


> [!quote] YOU
> Moze


> [!abstract] PI
> ## Čvor 1 — `write` nije `fsync`
>
> **Zašto nam ovo treba.** Kada 3307 kaže klijentu „OK“, to je obećanje postojanosti (D u ACID-u, „postojanost“ u rečniku predmeta). Ono znači: ova transakcija će preživeti i pad. Iz prvog pitanja znaš da pad preživljava samo ono što je na disku. Dakle, pre „OK“ baza mora da zna da su podaci **zaista na disku**. Videćemo da program to ne zna automatski.
>
> **Neuslovna istina R2.** Program ne piše na disk. Program traži od operativnog sistema da piše, i za to ima dva različita poziva:
>
> ```
> write(f, podaci)   →  OS kopira podatke u svoj keš u RAM-u i ODMAH vraća "uspelo"
>                        (na disk ih prepisuje kasnije, kad sam odluči)
> fsync(f)           →  OS gura sve iz keša te datoteke na disk i NE VRAĆA SE
>                        dok disk ne javi "upisano"
> ```
>
> Na Windowsu se drugi poziv zove `FlushFileBuffers`, a ideja je ista. Linux dokumentacija za `fsync` kaže: „the call blocks until the device reports that the transfer has completed“ ([fsync(2)](https://man7.org/linux/man-pages/man2/fsync.2.html)).
>
> Zašto je ovako napravljeno? Operativni sistem ne zna koji tvoji podaci su dragoceni. Kad bi svaki `write` čekao disk, svi programi bi bili spori. Zato je podrazumevano brzo i nesigurno, a program koji traži sigurnost mora izričito da je zatraži sa `fsync`.
>
> **Ključna posledica: dve vrste pada.** Keš operativnog sistema pripada operativnom sistemu, a ne procesu `mysqld`:
>
> ```
>                           pad procesa mysqld     pad OS-a / nestanak struje
> posle write, pre fsync    preživi (OS ga ima)    IZGUBLJENO
> posle fsync               preživi                preživi
> ```
>
> Ova tabela je u matrici na kraju lekcije presudna. Zato je dobro odmah zapamtiti da „pad“ nije jedna stvar.
>
> **Veza.** R2 visi direktno na R1. Keš OS-a je u RAM-u, pa deli sudbinu RAM-a kad nestane struje. Ne deli je kada umre samo jedan proces, jer RAM tada i dalje ima struju.


> [!question] Quiz
> Proces mysqld pozove write() za zapis o transakciji T u svoj log, ne pozove fsync(), i vrati klijentu „OK“. Pola sekunde kasnije Windows se sruši i računar se restartuje. Šta je sa zapisom o T?
>
> 1. Sigurno je sačuvan, jer se write() ne vraća dok zapis nije na disku
> 2. Sigurno je sačuvan, jer pad OS-a ne briše keš koji pripada OS-u
> 3. Možda je izgubljen, jer je posle write() bio samo u kešu OS-a u RAM-u
> 4. Možda je izgubljen, jer je posle write() bio samo u memoriji procesa mysqld


> [!success] Quiz — correct ✓
> Your answer: 3. Možda je izgubljen, jer je posle write() bio samo u kešu OS-a u RAM-u
> Correct answer: 3
>
> Posle write() zapis je u kešu operativnog sistema, u RAM-u. OS ga prepisuje na disk kad sam odluči, pa je možda već stigao, a možda nije. Otud „možda“. Restart OS-a briše RAM, pa i taj keš. (c) bi važilo za pad samo procesa mysqld, jer tada OS i njegov keš žive dalje. (d) brka write() sa baferom u samom programu: posle write() podaci su već predati OS-u.


> [!abstract] PI
> (Sistem je blokirao pitanje, pa ga šaljem ponovo. Usput sam ispravio slovnu grešku u jednoj opciji.) Provera čvora 2:


> [!question] Quiz
> Transakcija T menja po jedan red u tri tabele, i svaki red je u drugoj stranici od 16 KB. Ukupno se menja oko 300 bajtova. Ako bi baza pri komitovanju direktno upisala izmenjene stranice na disk i pozvala fsync, šta bi bio glavni trošak?
>
> 1. Tri cele stranice na tri različita mesta, sinhrono, dok klijent čeka
> 2. Tri dela od po 100 bajtova na tri mesta, sinhrono, dok klijent čeka
> 3. Jedna cela stranica na kraju datoteke, sinhrono, dok klijent čeka
> 4. Tri cele stranice na tri različita mesta, kasnije, kad OS odluči


> [!warning] Quiz — cancelled
> (user skipped)


> [!quote] YOU
> Ne vidim opet objasnjenje


> [!abstract] PI
> Sistem je ponovo blokirao pitanje. Zato objašnjenje šaljem kao zasebnu poruku, bez pitanja, da sigurno stigne do tebe.
>
> ## Čvor 2 — disk piše u blokovima, pa je raštrkano pisanje skupo
>
> **Zašto nam ovo treba.** Iz čvora 1 sledi očigledan plan: pri komitovanju baza pozove `fsync` za sve što je T promenio, i tek onda kaže „OK“. Pre nego što prihvatimo taj plan, treba da znamo koliko on košta.
>
> **Neuslovna istina R3.** Disk ne upisuje pojedinačne bajtove nego cele blokove, a InnoDB radi sa celim stranicama od 16 KB. Da bi promenio 100 bajtova, upisuje se ceo blok u kome se tih 100 bajtova nalazi. Cena upisa zato zavisi od toga **koliko različitih blokova** diraš, a ne od toga koliko bajtova menjaš:
>
> ```
> X: dopisivanje na kraj     [zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz]   100 KB → ~25 blokova
> Y: raštrkano po datoteci   [z...][..z.][z...][...z] ... ×1000    100 KB → 1000 blokova
> ```
>
> U X se susedni zapisi pakuju u isti blok. U Y svaki zapis „prlja“ svoj blok. Kod HDD-a se na to dodaje i pomeranje glave. SSD glavu nema, ali ni on ne može da upiše manje od bloka, pa je X i na SSD-u znatno brži. To je bila rupa u pitanju X/Y.
>
> **Veza sa onim što si tačno odgovorio.** Red sa `id = 500` mora nazad u svoju stranicu P, na svoje mesto u B+ stablu. Tipična transakcija menja nekoliko redova po različitim ključevima, plus stranice indeksa. To su stranice razbacane po datotekama, dakle varijanta Y. Plan „`fsync` svih izmenjenih stranica pri svakom komitovanju“ zato znači **raštrkano pisanje celih stranica, i to sinhrono, dok klijent čeka**. Jedan `fsync` na tvom disku traje stotine mikrosekundi (tačne brojeve vidimo u matrici), a ovde ih ima više po transakciji.
>
> Napiši **„dalje“** kad pročitaš, pa ti šaljem pitanje za proveru ovog čvora.


> [!quote] YOU
> dalje


> [!abstract] PI
> Evo pitanja za čvor 2. Primeni R3 na jednu konkretnu transakciju.


> [!question] Quiz
> Transakcija T menja po jedan red u tri tabele, i svaki red je u drugoj stranici od 16 KB. Ukupno se menja oko 300 bajtova. Ako bi baza pri komitovanju direktno upisala izmenjene stranice na disk i pozvala fsync, šta bi bio glavni trošak?
>
> 1. Tri cele stranice na tri različita mesta, sinhrono, dok klijent čeka
> 2. Tri cele stranice na tri različita mesta, kasnije, kad OS odluči
> 3. Tri dela od po 100 bajtova na tri mesta, sinhrono, dok klijent čeka
> 4. Jedna cela stranica na kraju datoteke, sinhrono, dok klijent čeka


> [!success] Quiz — correct ✓
> Your answer: 1. Tri cele stranice na tri različita mesta, sinhrono, dok klijent čeka
> Correct answer: 1
>
> Jedinica upisa je blok, odnosno stranica, pa 300 promenjenih bajtova u tri stranice znači tri cela upisa od 16 KB (zato je (b) pogrešno). Stranice imaju svoja mesta u B+ stablima, pa su upisi raštrkani, a ne na kraju datoteke kao u (d). A pošto je obećanje „OK“ vezano za fsync, sve to mora da se završi pre odgovora klijentu. Varijanta (c) bi bila brza, ali tada „OK“ ništa ne garantuje.


> [!abstract] PI
> Tačno. Usput sam u `TEACHING.md` zapisao novi način rada: objašnjenje ide kao posebna poruka, a pitanje tek kad napišeš „dalje“. Tako se objašnjenje više ne gubi.
>
> ## Čvor 3 — kako bi ti rešio ovaj problem? (WAL)
>
> **Problem, sastavljen od svega do sada.** Imamo dva zahteva koja se naizgled sudaraju:
>
> 1. **R4:** pre nego što kaže „OK“, baza mora da ima T na disku, i to posle `fsync`, jer `write` ne garantuje ništa (R2).
> 2. **R3:** upisivanje izmenjenih stranica na njihova mesta je raštrkano, pa je sinhroni `fsync` stranica preskup.
>
> Pogledaj šta tačno sudara ova dva zahteva. Zahtev 1 traži da na disku bude **informacija** o tome šta je T promenio. Ne traži da ta informacija bude **baš u stranici P**. Zahtev 2 kaže da je skupo pisati **na mnogo mesta**. Ne kaže da je skupo pisati uopšte, a iz pitanja X/Y znaš koja vrsta pisanja je jeftina.
>
> Dakle, imaš dva oblika iste informacije: „stranica P sada izgleda ovako“ i kratak opis „u stranici P, na poziciji x, upiši ove bajtove“. Imaš i dve vrste pisanja: raštrkano po stranicama i dopisivanje na kraj jedne datoteke.
>
> Pre nego što pročitaš pitanje, probaj sam da složiš dizajn: šta pišeš pre „OK“ i kako, šta odlažeš za kasnije, i kako posle pada vraćaš ono što nije stiglo u stranice. Iz lekcije A imaš i K1: log je niz zapisa u kome se samo dopisuje na kraj, u redosledu.
>
> Napiši **„dalje“** kad razmisliš, pa ti šaljem pitanje.


> [!quote] YOU
> dalje


> [!abstract] PI
> Evo pitanja. Izaberi dizajn koji ispunjava oba zahteva.


> [!question] Quiz
> Koji dizajn ispunjava oba zahteva: „OK“ znači da T preživljava pad, a komitovanje ne čeka na raštrkani upis stranica?
>
> 1. Pre „OK“: izmenjene stranice upiši na mesta bez fsync-a; log ne vodi, a posle pada OS dovrši upis iz keša
> 2. Pre „OK“: izmenjene stranice dopiši u log i fsync log; stranice ne upisuj nikada, a pri čitanju traži ih u logu
> 3. Pre „OK“: opis izmena dopiši u log bez fsync-a; stranice upiši kasnije, a posle pada ponovi opise iz loga
> 4. Pre „OK“: opis izmena dopiši u log i fsync log; stranice upiši kasnije, a posle pada ponovi opise iz loga


> [!success] Quiz — correct ✓
> Your answer: 4. Pre „OK“: opis izmena dopiši u log i fsync log; stranice upiši kasnije, a posle pada ponovi opise iz loga
> Correct answer: 4
>
> To je write-ahead logging (WAL): opis izmene se upisuje u log i sa fsync-om se potvrđuje na disku pre nego što se ijedna stranica zameni i pre „OK“. Dopisivanje kratkih opisa na kraj je jeftino (varijanta X), stranice se pišu kasnije i grupno, a posle pada se opisi iz loga ponove nad stranicama. (b) ne vodi računa da je u logu red bez svog mesta u B+ stablu, pa bi svako čitanje pretraživalo log. (c) gubi zbog R2: bez fsync-a log je u kešu OS-a i pad OS-a ga briše. (d) se oslanja na keš OS-a, koji pad OS-a ne preživljava.


> [!abstract] PI
> Izveo si WAL sam. Sad mu dajemo ime, pa prelazimo na deo koji se **ne može** izvesti.
>
> ## Čvor 3, imenovanje — redo log
>
> Dizajn koji si izabrao zove se **write-ahead logging (WAL)**: log se piše **pre** stranica. U InnoDB-u se taj log zove **redo log**. Priručnik za 8.4 ga opisuje rečima: „a disk-based data structure used during crash recovery to correct data written by incomplete transactions“. Izmene koje nisu stigle u stranice „are replayed automatically during initialization and before connections are accepted“ ([refman 17.6.5](https://dev.mysql.com/doc/refman/8.4/en/innodb-redo-log.html)).
>
> Jedan detalj ćemo uskoro koristiti. Kad stranica jednom stigne na disk, opis njene izmene u redo logu više nije potreban, pa InnoDB taj deo loga **odbacuje** („the oldest data is truncated as the checkpoint progresses“, isti izvor). Redo log je zato **privremena beleška za oporavak jednog servera**: opisuje izmene **bajtova u stranicama**, a stari deo mu se briše. Na našoj topologiji nalazi se u `#innodb_redo` direktorijumu u datadiru svakog čvora.
>
> ## Čvor 4 — dva loga (istorijska odluka, ne posledica)
>
> Iz lekcije A znaš i za drugi log: **binarni log**. On beleži izmene na nivou servera, kao iskaze ili redove (`STATEMENT`/`ROW`), čuva se dok ga ne obrišeš i šalje se replikama.
>
> Možda pomisliš da je jedan log izveden iz drugog. Nije. **Ovo je dizajnerska odluka iz istorije MySQL-a, i ne izvodi se iz ničega.** MySQL je od početka imao više mašina za skladištenje (storage engine), a ne samo InnoDB. Binarni log je pripadao **serveru**, iznad svih mašina, i služio je za replikaciju. Redo log pripada **InnoDB-u**, ispod servera, i služi za oporavak od pada. Svaki je nastao za svoju svrhu, u svom sloju. Zato ih danas ima dva, iako bi neki drugi sistem mogao da ima jedan. Postoje i dodatni praktični razlozi zašto se redo log ne bi lako mogao slati replikama: stari deo mu se briše, a opisuje bajtove u stranicama jednog servera.
>
> ```
>                  sloj        šta beleži                  čemu služi             vek trajanja
> binarni log      server      iskaze / redove (ROW)       replikacija (K1, K2)   dok se ne obriše
> redo log         InnoDB      bajtove u stranicama        oporavak od pada       do checkpointa
> ```
>
> Posledica koju ćemo koristiti u sledećem čvoru: **svako komitovanje mora da upiše T u oba loga**. To su dve odvojene datoteke, dakle dva odvojena upisa i dva `fsync`-a.
>
> Napiši **„dalje“**, pa ti šaljem pitanje.


> [!quote] YOU
> dalje


> [!abstract] PI
> Evo pitanja za čvorove 3 i 4: šta je u kom logu i čemu služi.


> [!question] Quiz
> 3307 se sruši i ponovo pokrene. Pri pokretanju neki log se čita da bi se stranice tabela dovele u stanje u kome su bile sve komitovane izmene. A dok radi normalno, 3307 iz nekog loga šalje izmene nitima prijema na 3308 i 3309. Koji log služi kojoj svrsi?
>
> 1. Oporavak čita binarni log; replikama se šalje redo log
> 2. Oporavak čita binarni log; replikama se šalje binarni log
> 3. Oporavak čita redo log; replikama se šalje redo log
> 4. Oporavak čita redo log; replikama se šalje binarni log


> [!success] Quiz — correct ✓
> Your answer: 4. Oporavak čita redo log; replikama se šalje binarni log
> Correct answer: 4
>
> Redo log je InnoDB-ov WAL: opisuje izmene bajtova u stranicama i služi da se posle pada ponove izmene koje nisu stigle u stranice. Binarni log je log servera, sa iskazima ili redovima, i njega nit koja šalje log (binlog dump thread) šalje replikama. (c) ne može da radi zato što se stari deo redo loga briše, a opisuje stranice jednog servera. (d) je blizu nečega što će se uskoro pokazati: binarni log učestvuje u oporavku, ali samo kao arbitar koji odlučuje o nedovršenim transakcijama. Stranice se ne obnavljaju iz njega.


> [!abstract] PI
> Tačno. Sledi čvor koji izvodiš sam, iz K2.
>
> ## Čvor 5 — šta pođe naopako kad su dva upisa odvojena
>
> **Postavka.** Svako komitovanje upisuje T u dva loga, a to su dva odvojena upisa. Između dva odvojena upisa uvek postoji trenutak u kome je jedan gotov, a drugi nije. Pad može da pogodi upravo taj trenutak, i ništa ga u tome ne sprečava.
>
> Zamisli najprostiji, naivan redosled, bez ikakve koordinacije:
>
> ```
> 1. redo log ← T, fsync        (InnoDB smatra T komitovanim)
>         ⚡ pad 3307 ovde
> 2. binarni log ← T, fsync
> 3. "OK" klijentu
> ```
>
> Pratimo šta se dešava posle ponovnog pokretanja 3307:
> - **Oporavak** čita redo log, tamo zatekne T i obnovi ga. Tabele na 3307 **sadrže** T.
> - **Binarni log** na 3307 nema T, jer korak 2 nije stigao da se izvrši.
> - Šta onda dobijaju 3308 i 3309, kad se seti K3: replika zna samo ono što joj stigne kao poruka, a šalje joj se binarni log?
>
> Sada iskoristi K2 iz lekcije A: isti početak + iste determinističke promene + isti redosled = isto stanje. Zapitaj se koji je od ta tri uslova ovde prekršen i šta to znači za podatke na 3307 u odnosu na 3308.
>
> Za vežbu razmisli i o obrnutom naivnom redosledu: prvo binarni log, pa pad, pa redo log nikad nije upisan. Šta tada imaju tabele 3307, a šta replike?
>
> Napiši **„dalje“**, pa ti šaljem pitanje.


> [!quote] YOU
> dajle


> [!abstract] PI
> Evo pitanja za čvor 5. Prvo prvi naivni redosled, onaj iz skice.


> [!question] Quiz
> Naivni redosled: T je upisan u redo log sa fsync-om, zatim se 3307 sruši pre nego što je T upisan u binarni log. 3307 se ponovo pokrene i radi dalje kao izvor. Kakvo je stanje posle toga?
>
> 1. 3307 ima T u tabelama, a 3308 i 3309 ga dobiju iz redo loga; svi se slažu
> 2. 3307 nema T u tabelama, a 3308 i 3309 ga dobiju; izvor i replike se trajno razlikuju
> 3. 3307 nema T u tabelama, a ni 3308 i 3309 ga ne dobiju; svi se slažu
> 4. 3307 ima T u tabelama, a 3308 i 3309 ga nikad ne dobiju; izvor i replike se trajno razlikuju


> [!success] Quiz — correct ✓
> Your answer: 4. 3307 ima T u tabelama, a 3308 i 3309 ga nikad ne dobiju; izvor i replike se trajno razlikuju
> Correct answer: 4
>
> Oporavak obnavlja T iz redo loga, pa ga tabele na 3307 imaju. Replike dobijaju samo binarni log (K3), a T u njemu ne postoji, pa ga nikad ne dobiju. K2 je prekršen u uslovu „iste promene“: izvor je primenio jednu promenu više nego replike, i od tog trenutka se njihova stanja razlikuju zauvek. Niko ne dobija grešku, jer ništa ne poredi ta dva stanja. (b) je obrnuti redosled: T je u binarnom logu, ali ne i u redo logu. Tada replike imaju T, a izvor nema, što je isto razilaženje u drugom smeru. (d) bi bilo bezopasno, i upravo to stanje će dvofazna potvrda omogućiti.


> [!abstract] PI
> Tačno. Oba naivna redosleda daju trajno razilaženje, samo u suprotnim smerovima. To je problem koji sledeći čvor rešava.
>
> ## Čvor 6 — dvofazna potvrda (izvodiš je sam)
>
> **Gde je koren problema.** U naivnom redosledu prvi upis je **konačan**: čim je T u redo logu, oporavak ga obnavlja bez pitanja. Ako pad dođe pre drugog upisa, nema načina da se ta odluka povuče. Svaki redosled dva konačna upisa ima opasan trenutak između njih.
>
> **Ideja.** Šta ako prvi upis **ne bi bio konačan**? Neka InnoDB u redo log upiše T kao **„pripremljen“**. Time poručuje: sve izmene su tu i postojane, ali da li je T komitovan, to se **još ne zna**. Posle pada oporavak takav T ne obnavlja slepo. Za njega postoje dve mogućnosti, commit ili rollback, a obe su moguće jer su sve izmene sačuvane.
>
> Sad je potreban **jedan** upis koji se smatra trenutkom odluke. Ako je taj upis stigao na disk, T je komitovan. Ako nije, T nije komitovan. Kada postoji samo jedna tačka odluke, nema više opasnog trenutka između dve odluke.
>
> ```
> 1. redo log    ← T kao PRIPREMLJEN, fsync      (izmene su postojane, odluka nije donesena)
> 2. ????? log   ← T, fsync                      ← TAČKA ODLUKE
> 3. redo log    ← T kao KOMITOVAN               (samo se beleži ono što je već odlučeno)
> 4. "OK" klijentu
> ```
>
> Na tebi su dva pitanja. Prvo: koji log treba da bude **tačka odluke** u koraku 2? Seti se šta replike vide (K3) i čega se plašimo (izvor i replike se razilaze). Drugo: kakvo onda mora biti **pravilo oporavka** za T koji je posle pada zatečen kao pripremljen?
>
> Napiši **„dalje“**, pa ti šaljem pitanje.


> [!quote] YOU
> dalje


> [!abstract] PI
> Evo pitanja za čvor 6. Pitanje sadrži oba dela: koji log je tačka odluke i pravilo oporavka.


> [!question] Quiz
> Posle pada 3307 oporavak zatekne T kao „pripremljen“ u redo logu. Koje pravilo oporavka sprečava da se izvor i replike raziđu?
>
> 1. Ako je T u binarnom logu, komituj ga; ako nije, poništi ga
> 2. Ako je T u redo logu kao pripremljen, uvek ga poništi
> 3. Ako je T u binarnom logu, poništi ga; ako nije, komituj ga
> 4. Ako je T u redo logu kao pripremljen, uvek ga komituj


> [!failure] Quiz — incorrect ✗
> Your answer: 2. Ako je T u redo logu kao pripremljen, uvek ga poništi
> Correct answer: 1
>
> Binarni log je tačka odluke zato što je on ono što replike dobijaju (K3). Ako je T u njemu, replike će ga dobiti, pa ga i izvor mora komitovati. Ako nije, replike ga nikad neće dobiti, pa ga izvor mora poništiti, i klijent u tom slučaju nikad nije ni dobio „OK“. Tako se izvor uvek slaže sa svojim binarnim logom, a time i sa replikama. Priručnik za 8.4 kaže isto: server pri oporavku pročita xid vrednosti iz binarnog loga i „tells InnoDB to complete any prepared transactions that were successfully written to the binary log“. Ostale pripremljene transakcije se poništavaju. (c) i (d) ignorišu tačku odluke, pa vraćaju upravo dva naivna razilaženja.


> [!abstract] PI
> Ovo je koristan promašaj, i mislim da znam odakle dolazi. Razmišljanje je verovatno bilo: „pripremljen znači da još nije komitovan, pa je najbezbednije poništiti ga“. Za **jedan** server to bi bilo potpuno tačno. Problem je u tome što pad može da pogodi **dva** različita mesta, a oporavak u oba slučaja zatiče T kao pripremljen:
>
> ```
> 1. redo  ← T PRIPREMLJEN, fsync
>         ⚡ pad A:  binarni log NEMA T  → replike T nikad neće dobiti
> 2. binlog ← T, fsync                    ← tačka odluke
>         ⚡ pad B:  binarni log IMA T   → nit koja šalje log ga šalje replikama posle restarta
> 3. redo  ← T KOMITOVAN
> 4. "OK"
> ```
>
> Pri padu B, redo log i dalje kaže samo „pripremljen“, jer korak 3 nije stigao da se izvrši. Ali binarni log **već ima T**. Kad se 3307 ponovo pokrene, nit koja šalje log čita taj binarni log i šalje T replikama, a one ga primene (K3).
>
> Pogledaj šta tada radi pravilo „uvek poništi“:
> - **pad A:** poništi T, a replike ga nemaju. U redu je.
> - **pad B:** poništi T na izvoru, a replike ga imaju. To je **razilaženje**: isto ono iz čvora 5, samo u obrnutom smeru.
>
> Iz samog redo loga oporavak ne može da razlikuje pad A od pada B. Jedino mesto gde se ta razlika vidi je binarni log. Zato pravilo mora da ga pita: **T je u binarnom logu → komituj, T nije u binarnom logu → poništi**. Binarni log je tačka odluke zato što je on jedino što replike ikada vide. Izvor zato mora da se povinuje svom binarnom logu, a ne obrnuto.
>
> Ovo je unutrašnja dvofazna potvrda (internal XA) između InnoDB-a i binarnog loga. Prva faza je priprema (prepare) u redo logu, druga je odluka u binarnom logu. Priručnik za 8.4 kaže da server pri oporavku pročita xid vrednosti iz binarnog loga i „tells InnoDB to complete any prepared transactions that were successfully written to the binary log“ ([refman, Binary Log](https://dev.mysql.com/doc/refman/8.4/en/binary-log.html)).
>
> Napiši **„dalje“**, pa ti šaljem jedno pitanje da proverim da li je ovo sad leglo.


> [!quote] YOU
> dalje


> [!abstract] PI
> Evo pitanja. Isti mehanizam kao u objašnjenju, ali proveravam drugo mesto pada.


> [!question] Quiz
> Dvofazna potvrda na 3307. T je upisan u redo log kao pripremljen, sa fsync-om, i upisan je u binarni log, sa fsync-om. Zatim, pre koraka „redo ← komitovan“, proces mysqld padne. Klijent nije dobio „OK“. Šta oporavak radi sa T?
>
> 1. Poništava T, jer klijent nije dobio „OK“ i ne zna za T
> 2. Komituje T, jer je T u redo logu i sve izmene su sačuvane
> 3. Poništava T, jer redo log ne sadrži zapis da je T komitovan
> 4. Komituje T, jer je T u binarnom logu i replike će ga dobiti


> [!success] Quiz — correct ✓
> Your answer: 4. Komituje T, jer je T u binarnom logu i replike će ga dobiti
> Correct answer: 4
>
> Tačka odluke je upis u binarni log, a taj upis je stigao na disk. T je time komitovan, bez obzira na to što redo log još kaže „pripremljen“ i što klijent još nije dobio „OK“. Odgovor (b) je zanimljiv: klijent koji nije dobio „OK“ ne sme da pretpostavi ni da T jeste ni da nije komitovan, jer obe ishode može da dobije posle pada. (c) je pravilo „uvek poništi“, koje bi ovde razišlo izvor i replike. (d) daje tačan ishod iz pogrešnog razloga: da je pad došao pre upisa u binarni log, izmene bi takođe bile sačuvane, a T bi ipak bio poništen.


> [!abstract] PI
> Tačno. (Ispravka u objašnjenju: „oba ishoda“, ne „obe ishode“.) Dvofazna potvrda je sada sklopljena. Ostaje matrica, koja je samo pitanje „da li ovaj log dobija `fsync` pri komitovanju“, postavljeno za svaki log posebno.
>
> ## Čvor 7 — matrica `sync_binlog` × `innodb_flush_log_at_trx_commit`
>
> **Šta znači svaka promenljiva.** Svaka od dve promenljive odlučuje o jednom logu (priručnik za 8.4: [innodb-parameters](https://dev.mysql.com/doc/refman/8.4/en/innodb-parameters.html), [replication-options-binary-log](https://dev.mysql.com/doc/refman/8.4/en/replication-options-binary-log.html)):
>
> ```
> innodb_flush_log_at_trx_commit  (redo log)
>   1  write + fsync pri svakom komitovanju                      ← podrazumevano
>   2  write pri komitovanju, fsync otprilike jednom u sekundi
>   0  write + fsync otprilike jednom u sekundi
>
> sync_binlog  (binarni log)
>   1  fsync pri svakom komitovanju                              ← podrazumevano od 5.7.7
>   0  MySQL nikad ne zove fsync, OS upisuje kad sam odluči
>   N  fsync posle svakih N grupa komitovanja
> ```
>
> Da je podrazumevano 1/1, to je **odluka** iz verzije 5.7.7. Ranije je `sync_binlog` podrazumevano bio 0. Priručnik i sam kaže da je provera „jednom u sekundi“ „not 100% guaranteed“.
>
> **Posledice izvodiš iz onoga što već imaš.** Čvor 1 kaže da `write` bez `fsync` preživljava pad procesa `mysqld`, ali ne i pad OS-a. Čvor 6 kaže da dvofazna potvrda radi samo ako su i priprema i tačka odluke zaista na disku. Kad jedan od dva loga izgubi `fsync`, posle pada OS-a nestane baš onaj upis od koga dvofazna potvrda zavisi:
>
> ```
> redo  binlog  pad mysqld       pad OS-a / nestanak struje
>  1     1      ništa            ništa; "OK" znači da je T na disku u oba loga
>  1     0      ništa            binlog može da izgubi T koji je InnoDB komitovao → izvor ima T, replike nikad
>  2     1      ništa            redo može da izgubi pripremljen T, a binlog ga ima → replike imaju T, izvor ne
>  0     *      do ~1 s izgubljeno   do ~1 s izgubljeno, plus gornje razilaženje
> ```
>
> Red `1/0` priručnik navodi doslovno: „the server has committed transactions that have not been synchronized to the binary log“. Red `2/1` i kolonu „pad mysqld“ priručnik ne razlaže red po red, nego ih ja **izvodim** iz R2 i čvora 6. Tako ćemo ih i označiti u radu. Za vrednost 0 priručnik kaže: „any unexpected mysqld process exit can erase up to N seconds of transactions“. Preporuka priručnika za replikaciju je izričita: „sync_binlog=1, innodb_flush_log_at_trx_commit=1“.
>
> **Cena, sa tvoje topologije** (zapis 0001, 300 komitovanja po ćeliji, asinhrona replikacija):
>
> ```
> redo  binlog   latencija komitovanja
>  1     1         764 µs     ← dva fsync-a pri svakom komitovanju
>  2     1         355 µs
>  1     0         634 µs
>  2     0          61 µs     ← nijedan fsync pri komitovanju
> ```
>
> Svaki `fsync` koji izbaciš ubrzava komitovanje, ali svaki izbačeni `fsync` istovremeno otvara jedan od razilaženja iz tabele iznad. Ista cifra iz zapisa 0001 objašnjava i zašto se semisinhrona potvrda kod 1/1 nije videla u merenjima: dva `fsync`-a od oko 900 µs progutaju potvrdu sa iste mašine.
>
> **Veza sa ponavljanjem sa početka.** U drugom pitanju ponavljanja ostavio sam otvoreno da li T preživljava pad i ponovno pokretanje 3307. Odgovor je: **samo pri 1/1 sigurno**. Asinhrona replikacija gubi T samo kad izvor trajno nestane. Slabija matrica može da izgubi potvrđeni T i kad se izvor samo restartuje.
>
> Napiši **„dalje“**, pa ti šaljem pitanje.


> [!quote] YOU
> dalje


> [!abstract] PI
> Evo pitanja za matricu. Stanje je u postavci.


> [!question] Quiz
> Na 3307 je podešeno sync_binlog = 1 i innodb_flush_log_at_trx_commit = 2. Klijent dobije „OK“ za T, a 0,3 s kasnije računaru nestane struje. Posle ponovnog pokretanja, šta je moguće?
>
> 1. T je u binarnom logu i InnoDB je zadržao pripremu, jer je nestanak struje isto što i pad mysqld
> 2. T nije u binarnom logu, a InnoDB je zadržao pripremu, pa izvor ima T, a replike ga nikad ne dobiju
> 3. T je u binarnom logu, a InnoDB je izgubio pripremu, pa replike dobiju T, a izvor ga nema
> 4. T nije u binarnom logu i InnoDB je izgubio pripremu, pa T nema niko, ali se izvor i replike slažu


> [!success] Quiz — correct ✓
> Your answer: 3. T je u binarnom logu, a InnoDB je izgubio pripremu, pa replike dobiju T, a izvor ga nema
> Correct answer: 3
>
> sync_binlog = 1 znači da je binarni log dobio fsync pre „OK“, pa je T na disku u njemu i replike će ga dobiti. innodb_flush_log_at_trx_commit = 2 znači da je priprema u redo logu samo prošla kroz write, dakle bila je u kešu OS-a, a nestanak struje briše taj keš (R2). Pri oporavku InnoDB nema pripremljen T, a binarni log ne može da obnovi stranice, pa tabele izvora T nemaju. (b) je red 1/0 iz matrice, odnosno obrnuta postavka. (c) brka pad mysqld sa padom OS-a: vrednost 2 štiti samo od pada procesa. (d) bi bio bezopasan ishod, ali T sa binlogom koji je dobio fsync ne može da nestane iz binarnog loga. Ovaj red matrice nisam našao doslovno u priručniku, nego je izveden iz mehanizma.


> [!abstract] PI
> Poslednje pitanje se i dalje blokira, pa ga ostavljam za sledeću poruku. Napiši **„dalje“** i odmah ti ga šaljem. Proverava samo čvor 1 na ćeliji 0/2 iz matrice: šta se dešava sa T kad padne samo proces `mysqld`, a Windows radi dalje.


> [!quote] YOU
> dalje


> [!abstract] PI
> Evo poslednjeg pitanja: čvor 1 primenjen na najbržu ćeliju matrice.


> [!question] Quiz
> Na 3307 je podešeno sync_binlog = 0 i innodb_flush_log_at_trx_commit = 2 (61 µs po komitovanju). Klijent dobije „OK“ za T, a zatim se ubije samo proces mysqld; Windows radi dalje. Posle ponovnog pokretanja mysqld, šta je sa T?
>
> 1. T je izgubljen ako je pao u poslednjoj sekundi, jer se fsync radi jednom u sekundi
> 2. T je sačuvan samo u redo logu, jer InnoDB ima svoj keš, a binarni log nema
> 3. T je sačuvan u oba loga, jer su oba upisa bila u kešu OS-a, koji je preživeo
> 4. T je izgubljen iz oba loga, jer nijedan upis nije dobio fsync pre „OK“


> [!success] Quiz — correct ✓
> Your answer: 3. T je sačuvan u oba loga, jer su oba upisa bila u kešu OS-a, koji je preživeo
> Correct answer: 3
>
> Pri vrednosti 2 i pri sync_binlog = 0, oba loga su pri komitovanju predata OS-u kroz write. Keš OS-a pripada OS-u, a ne procesu mysqld, pa preživljava pad procesa (R2) i OS ga kasnije upiše na disk. (b) i (d) primenjuju pravilo za pad OS-a na pad procesa. Nedostatak fsync-a je opasan samo kad i keš OS-a nestane. (d) bi bilo tačno za innodb_flush_log_at_trx_commit = 0, gde ni write ne ide pri komitovanju, pa izmene ostaju u memoriji samog mysqld. Zato ova ćelija nije „nesigurna“ uopšteno: ona je sigurna od pada procesa, a nesigurna od pada OS-a i nestanka struje.


> [!abstract] PI
> Topologija trenutno ne radi. Pokrećem je da bih primer za lekciju proverio na živim serverima, umesto da ga pišem napamet.


> [!question] Question
> Kako da zovemo two-phase commit u lekciji, rečniku i radu?
>
> 1. dvofazno komitovanje (Recommended)
> 2. dvofazna potvrda
> 3. two-phase commit, na engleskom


> [!abstract] PI
> Proba je očišćena: `lab_postojanost` je obrisana na sva tri čvora, a promenljive su vraćene na 1/1.
>
> Pre nego što zapišem lekciju, jedno pitanje o terminu, koje utiče i na rad. U `GLOSSARY.md` je reč **potvrda** već zaključana za *acknowledgement*, dakle za izvorovo „OK“ i za semisinhronu potvrdu iz poglavlja 4. Ako *two-phase commit* nazovemo „dvofazna potvrda“, ista reč će značiti dve različite stvari. Rečnik predmeta za *commit* koristi „komitovanje“, pa se nameće „dvofazno komitovanje“. Pitanje stiže u sledećoj poruci; napiši **„dalje“**.


> [!quote] YOU
> dalje


> [!abstract] PI
> Evo pitanja o terminu za two-phase commit.


> [!question] Question
> Kako da zovemo two-phase commit u lekciji, rečniku i radu?
>
> 1. dvofazno komitovanje (Recommended)
> 2. dvofazna potvrda
> 3. two-phase commit, na engleskom


> [!example] Answer
> 1. dvofazno komitovanje (Recommended)


> [!abstract] PI
> Zaključano je „dvofazno komitovanje“. Sada pišem primer, lekciju, referentni list, rečnik i zapis.


> [!abstract] PI
> Skripta radi od početka do kraja, a replike su posle čišćenja ispravne. Sada lekcija.


> [!abstract] PI
> Sada referentni list.


> [!abstract] PI
> Zapisi su sređeni. Otvaram lekciju.


> [!abstract] PI
> Lekcija B je završena i otvorio sam je u pregledaču.
>
> **Kako je prošlo:**
> - **Ponavljanje iz lekcije A, 2/2 bez podsećanja.** K3 se smatra naučenim: replika ne čita datoteku mrtvog izvora, nego razgovara sa živim procesom. Isto važi za prozor gubitka kod asinhrone replikacije.
> - **WAL si izveo sam, na prvi pokušaj.**
> - **Jedna zabluda je ispravljena:** „pripremljena transakcija se uvek poništava“. Na jednom serveru to radi, ali sa replikama ne. Pad A (pre upisa u binarni log) i pad B (posle njega) ostavljaju isti redo log, a razlikuje ih samo binarni log. Pitanje za pad B posle toga si rešio tačno.
> - **Oba pitanja o matrici tačno:** ćelija 2/1 pri nestanku struje i ćelija 0/2 kad padne samo `mysqld`.
>
> **Merenje na topologiji pre pisanja lekcije:**
> - Kad binarni log učestvuje, redo log dobije oko **2 `fsync`-a po komitovanju**. Bez njega oko 1.
> - Vreme po komitovanju je oko 930 µs sa binarnim logom, a oko 360 µs bez njega.
> - Merenje se slaže sa slikom dvofaznog komitovanja, ali tačan raspored `fsync`-ova nijedan izvor nije potvrdio. Zato u radu ide kao merenje, ne kao opis mehanizma.
>
> **Napravljeno:**
> - `lessons/0003-postojanost-wal-dvofazno-komitovanje.html`: lekcija sa primerom koji se pokreće i kvizom od 8 pitanja.
> - `reference/postojanost-matrica.html`: referentni list sa matricom.
> - `examples/02-binlog-async/04-postojanost.sql`: skripta je proverena na topologiji, sama čisti probnu bazu i vraća promenljive na 1/1.
> - `learning-records/0005-durability-wal-2pc.md` i indeks zapisa. Merenja i doslovni citati su u `.scratch/.../measurements/0005-…`.
> - `GLOSSARY.md` §1b‴: zaključano je **„dvofazno komitovanje“**. U četu sam do odluke govorio „dvofazna potvrda“, a u lekciji i zapisima je ispravljeno.
> - `../TEACHING.md`: novi način rada (objašnjenje kao posebna poruka, pa „dalje“, pa pitanje), jer je sistem za proveru i dalje gutao objašnjenja.
>
> **Dve stvari koje rad mora da označi:**
> - Red 2/1 u matrici i kolona „pad samo `mysqld`“ su **izvedeni iz mehanizma**, ne citirani iz priručnika.
> - Za tvrdnju da su dva loga istorijska odluka treba naći citat pre nego što uđe u poglavlje 3.
>
> Topologija (3307/3308/3309) je i dalje pokrenuta. Sledeći korak je pisanje poglavlja 3, u novoj sesiji, jer su sada obe lekcije gotove.


> [!quote] YOU
> Hocu detaljnije slike i grafike kad se generise HTML, dodaj to i u skill


> [!abstract] PI
> Prvo pravilo upisujem u `teach` skill, pa ga odmah primenjujem na lekciju 03: dobija prave slike umesto samo tabela i `pre` blokova.


> [!abstract] PI
> Sada šest slika za lekciju 03, paralelno, preko `svg-maker`-a. On svaku sliku renderuje i proveri pre nego što je vrati.


> [!abstract] PI
> Pre ugradnje u lekciju i sam pregledam svaku sliku.


> [!abstract] PI
> Lekcija 03 sada ima šest detaljnih slika, a pravilo je upisano u `teach` skill, pa važi za svaku sledeću lekciju. Svaku sliku sam pregledao pre ugradnje. Tri su imale greške (preklopljeni tekst i jedna boja koja je značila suprotno), pa sam ih ponovo napravio. Lekcija je otvorena u pregledaču.
>
> **U skillu** (`~/.pi/agent/skills/teach/SKILL.md`, novi odeljak §Figures):
> - **Obavezne slike:** svaki deo lekcije koji ima oblik dobija svoju sliku. To su slojevi, vremenska linija, poređenje „pre/posle“, mehanizam, matrica ili izmereni rezultat. Tipično ih je 3–6 po lekciji.
> - **Šta znači „detaljno“:** sve je obeleženo, strelice kažu šta teče, mesto pada je ucrtano, a na kraju svake putanje piše ishod. Boje znače isto u celoj lekciji (crveno = izgubljeno, zeleno = preživi).
> - **Merenja postaju grafikoni:** brojevi se prepisuju tačno iz zapisa o merenju i uz svaki stoji podešavanje pod kojim je izmeren.
> - **Izrada:** slike se prave preko `svg-maker`/`mermaid-maker`, paralelno. Svaka ide u `<figure>`, sa `alt` tekstom u punim rečenicama i potpisom koji kaže zaključak i izvor podataka.
> - **Uslov za završetak:** svaki takav deo ima sliku, i ja sam pogledao svaku renderovanu sliku pre nego što lekciju proglasim gotovom.
>
> **U kursu** (`../TEACHING.md`): dodao sam uputstvo na skill. Ono kaže i da slike lekcija idu u `viz/`, a `figures/` ostaje samo za slike u `rad.md`.
>
> **Slike u lekciji 03:**
> 1. `write` / `fsync` i šta briše koji pad
> 2. blokovi: dopisivanje na kraj naspram raštrkanog pisanja
> 3. WAL: komitovanje i oporavak posle pada
> 4. dvofazno komitovanje: padovi A i B i pravilo oporavka
> 5. matrica kao grafikon latencija, obojen po riziku
> 6. današnje merenje: `fsync`-ovi redo loga i vreme po komitovanju


> [!quote] YOU
> Primetio sam da su subagenti radili crtanje svg-a, hocu da tu gde je koriscen Sonnet 5 sad bude Sonnet 5.5


> [!abstract] PI
> U spisku modela postoji `claude-sonnet-5-5`. Sonnet 5 se koristi na dva mesta: `svg-maker` i `mermaid-maker`. Menjam oba.


> [!abstract] PI
> Gotovo. `svg-maker` i `mermaid-maker` sada rade na Sonnet 5.5.
>
> - `~/.pi/agent/agents/svg-maker.md`: `model: anthropic/claude-sonnet-5-5`
> - `~/.pi/agent/agents/mermaid-maker.md`: `model: anthropic/claude-sonnet-5-5`
>
> Sonnet 5 nije korišćen nigde drugde: ni u skillovima ni u `settings.json`. `researcher` radi na Haiku 5.5 i njega nisam dirao. Promena važi od sledećeg pokretanja subagenta. Slike koje su već napravljene za lekciju 03 nisam ponovo generisao.
