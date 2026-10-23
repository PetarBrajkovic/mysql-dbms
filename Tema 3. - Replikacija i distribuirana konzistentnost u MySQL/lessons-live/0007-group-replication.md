> [!quote] YOU
> > [!note] SKILL loaded: teach
>
> Chapter 5 lesson (ticket 17): Group Replication — kvorum, certification i multi-primary. Lesson 0005, record 0007.
>
>    Read by pointer per ../TEACHING.md's reading protocol; ticket at .scratch/replikacija/issues/17-chapter-5-group-replication.md, measurements from ticket 11 in
>  .scratch/replikacija/measurements/0002-group-replication.md (and learning-records/0002).
>
>    Cover, in order:
>    1. Certification: write-sets, first-commit-wins, row-level not table-level. Re-teach why multi-leader creates conflicts as long as I need it.
>    2. Majority quorum: the minority blocks rather than diverges; what split brain is and why GR doesn't produce it (ticket 11's quorum-loss run: reads 39 ms, writes blocked, suspended write committed after
>  forced repair).
>    3. Single- vs multi-primary, and when multi-primary is actually justified.
>    4. Climax: group_replication_consistency levels mapped onto ch. 2's named models (EVENTUAL / BEFORE / AFTER / BEFORE_AND_AFTER), with ticket 11's stale-read and latency numbers.
>
>    Live demos against the sandbox (switch it to the group state first, declare and check state per figures/README.md; mysqlsh JS with held sessions for sub-second windows):
>    - conflict pair on poliklinika.invoices: same invoice (one rolls back — expect ERROR 1180 'Lock deadlock', not 3101) and two different invoices (both commit);
>    - throwaway no_pk_demo rejected for lacking a primary key, then dropped;
>    - read-your-writes second half: stale read closed by group_replication_consistency='BEFORE'.
>    Write outputs to measurements/ and examples/, return the sandbox to async resting at the end.
>
>    Binding: GLOSSARY.md terms (certification glossed once as "provera saglasnosti transakcija", never "sertifikacija"), serbian-grammar for every Serbian line, ../../NOTES.md research rules — verify every
>  absence claim and record the rung (watch "automatic vs manual failover": Asynchronous Connection Failover exists). Lesson only — no rad.md prose this session.

> [!question] Question — Obsidian
> Da li želiš da se ova lekcija prati uživo u Obsidianu?
>
> 1. Da, nova datoteka
> 2. Da, postojeća datoteka
> 3. Ne

> [!example] Answer
> Da, nova datoteka

> [!abstract] PI
> Stanje topologije je proverено: sva tri čvora rade, a stanje je **async**. To je stanje mirovanja: 3308 i 3309 imaju kanal `ON`, grupa ne postoji. Na grupu prelazim tek kad nam zatreba za demonstracije.
>
> Čekam da potvrdiš da je `/md-log` povezan.

> [!quote] YOU
> Daj mi instrukcije koji fajl si napravio da povezem sa md-log, iz nekog razloga nisi napisao objasnjenje

> [!abstract] PI
> Napravio sam praznu datoteku:
>
> ```
> C:\Faks\Sistemi Baza\Tema 3. - Replikacija i distribuirana konzistentnost u MySQL\lessons-live\0007-group-replication.md
> ```
>
> Pošto je radni direktorijum tema 3, dovoljno je da u terminal nalepiš ovu komandu:
>
> ```
> /md-log lessons-live/0007-group-replication.md
> ```
>
> Ako relativna putanja ne radi, probaj sa punom putanjom pod navodnicima, zbog razmaka u imenu foldera:
>
> ```
> /md-log "C:\Faks\Sistemi Baza\Tema 3. - Replikacija i distribuirana konzistentnost u MySQL\lessons-live\0007-group-replication.md"
> ```
>
> Moja prethodna poruka imala je i grešku u kucanju: u reči „provereno“ su se umešala ćirilična slova. Evo je ponovo: stanje topologije je provereno. Sva tri čvora rade u stanju **async**, 3308 i 3309 imaju kanal `ON`, a grupa ne postoji.
>
> Kad datoteka bude povezana, napiši „povezano“ i počinjemo proveru znanja.


> [!quote] YOU
> Nastavi


> [!abstract] PI
> Počinjemo proverom znanja. Ništa se ne ocenjuje: tražim granicu do koje znaš gradivo, da bih lekciju počeo tačno odatle. Ako ne znaš, izaberi „Ne znam“. To mi pomaže više od pogađanja.


> [!question] Quiz
> Dva čvora primaju upise nezavisno (multi-leader). Klijent X na čvoru A postavi iznos računa 7 na 100, a klijent Y na čvoru B u istom trenutku postavi isti iznos na 200. Oba čvora odmah potvrde komitovanje svom klijentu i tek onda šalju promenu onom drugom. Šta je osnovni problem?
>
> 1. Čvorovi ne mogu da razmene promene dok neki zaključavanje ne oslobodi red 7
> 2. Oba upisa su potvrđena, a ne mogu oba da opstanu, pa jedan potvrđeni upis mora da nestane
> 3. Replike primenjuju promene istim redom, pa svi čvorovi završe sa istom vrednošću
> 4. Kasniji upis uvek pobedi po vremenu, pa se nijedan potvrđeni upis ne gubi


> [!question] Quiz — I don't know
> Your answer: I don't know
> Correct answer: 2
>
> Svaki čvor je sam odlučio da je upis prihvaćen i to javio klijentu. Kad promene stignu na drugi čvor, istom redu su dodeljene dve različite vrednosti, a obe su već potvrđene. Konačna vrednost može da bude samo jedna, pa jedan klijent ostaje sa potvrdom za upis koji više ne postoji. Pravilo „poslednji upis pobeđuje“ (last-write-wins) ne rešava problem, samo određuje koji upis nestaje. Zaključavanje pomaže samo unutar jednog čvora, ne između dva čvora.


> [!abstract] PI
> Zapamtio sam: sukob kod više lidera (multi-leader) ćemo naučiti ispočetka, od nule. Sada proveravam odakle tačno krećemo.


> [!question] Quiz
> Sada postoji samo jedan izvor, 3307, i on jedini prima upise. Klijenti X i Y u istom trenutku menjaju iznos računa 7: X na 100, Y na 200. Šta se dešava?
>
> 1. Oba se odbiju, jer izvor ne može da odluči koji je bio prvi
> 2. Jedan čeka na zaključanom redu, pa se dva upisa izvrše jedan za drugim
> 3. Oba se potvrde, a replike posle same biraju koja vrednost ostaje
> 4. Izvrše se paralelno, pa red 7 dobije vrednost iz oba upisa


> [!failure] Quiz — incorrect ✗
> Your answer: 3. Oba se potvrde, a replike posle same biraju koja vrednost ostaje
> Correct answer: 2
>
> Na jednom serveru InnoDB zaključava red. Ko prvi zaključa red, prvi i piše, a drugi čeka na zaključanom redu dok prvi ne komituje. Zato oba upisa uspevaju i izvrše se jedan za drugim. Izvor ih tim redom upisuje u binarni log, a replike ih primenjuju istim redom. Na ovom mestu postoji tačno jedan redosled i odluku o njemu donosi jedan server.


> [!abstract] PI
> Ovaj odgovor mi mnogo govori. Još jedno pitanje oko iste teme, da vidim koliko je široka ta praznina.


> [!question] Quiz
> Asinhrona replikacija, izvor 3307, replika 3308. Izvor je komitovao T1 (iznos = 100), a zatim T2 (iznos = 200), oba nad računom 7. Šta replika 3308 radi sa ove dve transakcije?
>
> 1. Proveri da li se T1 i T2 sukobljavaju i odbaci jednu od njih
> 2. Primeni samo T2, jer replika dobija konačno stanje reda
> 3. Primeni T1 pa T2 redom iz binarnog loga i završi na 200
> 4. Uporedi vremena T1 i T2 i zadrži vrednost sa kasnijim vremenom


> [!success] Quiz — correct ✓
> Your answer: 3. Primeni T1 pa T2 redom iz binarnog loga i završi na 200
> Correct answer: 3
>
> Replikacija u MySQL-u znači slanje loga i njegovo ponovno izvršavanje (lekcija 0002). Nit primene na replici izvršava transakcije onim redom kojim ih je izvor zapisao u binarni log. Replika ništa ne bira i ništa ne proverava. Redosled je već odredio jedini server koji prima upise.


> [!abstract] PI
> Ponovno izvršavanje loga si zapamtio. Praznina je u tome kako **jedan server** određuje redosled dva istovremena upisa. Prelazim na kvorum.


> [!question] Quiz
> Grupa od 5 čvorova prihvata upis tek kad ga potvrdi većina, odnosno najmanje 3 čvora. Mreža se podeli na deo sa 3 čvora i deo sa 2 čvora. Zašto pravilo većine sprečava da oba dela prihvataju upise?
>
> 1. Deo sa više čvorova brže šalje poruke, pa uvek prvi preuzme ulogu
> 2. Većina ima najnovije podatke, pa manji deo nema šta da upiše
> 3. Dve većine od pet čvorova uvek imaju bar jedan zajednički čvor, pa ne mogu da postoje istovremeno
> 4. Deo sa manje čvorova odmah gaši svoje servere čim primeti podelu


> [!success] Quiz — correct ✓
> Your answer: 3. Dve većine od pet čvorova uvek imaju bar jedan zajednički čvor, pa ne mogu da postoje istovremeno
> Correct answer: 3
>
> Svake dve većine od n čvorova imaju zajednički čvor: 3 + 3 = 6 > 5. Dve disjunktne grupe od po 3 čvora ne mogu da postoje, pa samo jedan deo mreže može da sakupi većinu. Manji deo nema većinu i zato ne može da prihvata upise. Ništa se ne gasi i ništa ne zavisi od brzine. Ovo je argument preseka kvoruma iz lekcije 0001.


> [!abstract] PI
> Osnovu kvoruma znaš. Sada pitanje znatno teže: šta tačno radi manji deo?


> [!question] Quiz
> Group Replication sa tri člana, 3307, 3308 i 3309, u režimu single-primary, a 3307 je primarni čvor. Procese 3308 i 3309 ubijemo (kill), pa 3307 ostaje sam, bez većine. Podrazumevana podešavanja važe. Šta 3307 radi sa SELECT upitom, a šta sa INSERT upitom?
>
> 1. SELECT i INSERT ostaju blokirani dok se većina ne vrati
> 2. SELECT i INSERT se izvrše, jer 3307 i dalje ima ulogu primarnog čvora
> 3. SELECT se odmah izvrši, a INSERT ostaje blokiran i ne završava se
> 4. SELECT se odmah izvrši, a INSERT odmah vrati grešku o kvorumu


> [!failure] Quiz — incorrect ✗
> Your answer: 2. SELECT i INSERT se izvrše, jer 3307 i dalje ima ulogu primarnog čvora
> Correct answer: 3
>
> Ovo je izmereno na našoj topologiji (ticket 11). SELECT na 3307 se vratio za 39 ms. INSERT je i posle 30 sekundi bio blokiran: nije komitovan, nije vratio grešku i nije bio vidljiv drugim sesijama. Čitanje ne traži dogovor grupe, jer čvor čita svoje lokalne podatke. Upis traži da ga većina prihvati, a većine nema, pa transakcija čeka unutar komitovanja. Podrazumevana vrednost `group_replication_unreachable_majority_timeout = 0` znači da čvor čeka neograničeno.


> [!abstract] PI
> Osnovno pravilo kvoruma znaš, ali ga nisi primenio na primarni čvor. Proveravam da li je to zato što GR zamišljaš kao asinhronu replikaciju, u kojoj izvor sam odlučuje o svakom upisu.


> [!question] Quiz
> Group Replication sa tri ispravna člana, a primarni čvor je 3307. Klijent izvršava COMMIT na 3307. Kada 3307 sme da vrati OK klijentu?
>
> 1. Kad većina grupe primi transakciju i grupa se složi o njenom redosledu
> 2. Kad sva tri člana primene transakciju i ona postane vidljiva na njima
> 3. Čim 3307 sam upiše transakciju u svoj binarni log, kao izvor
> 4. Kad jedna replika potvrdi prijem, kao kod semisinhrone replikacije


> [!success] Quiz — correct ✓
> Your answer: 1. Kad većina grupe primi transakciju i grupa se složi o njenom redosledu
> Correct answer: 1
>
> U Group Replication-u primarni čvor ne odlučuje sam. Transakcija se šalje grupi i komituje se tek kad je većina primi i kad se grupa složi o redosledu. Zato bez većine nema komitovanja. Primarni čvor u ovom modelu određuje gde se prihvataju upisi, ali ne odlučuje sam da li je upis komitovan. Primena na svim članovima nije uslov: oni mogu da kasne. Na tome se zasniva pitanje nivoa konzistentnosti na kraju lekcije.


> [!abstract] PI
> Pravilo znaš: upis traži većinu. Nisi izveo šta iz toga sledi kad većine nema. Sada pitanje o tome šta bi se desilo bez tog pravila.


> [!question] Quiz
> Zamisli klaster sa dva čvora koji nema pravilo većine: svaki čvor koji izgubi vezu sa drugim nastavlja sam da prihvata upise. Mreža se prekine na 10 minuta. Kako se zove stanje u kome se klaster tada nalazi?
>
> 1. Kašnjenje replikacije, jer jedan čvor zaostaje za drugim
> 2. Failover, jer jedan čvor preuzima ulogu onog koji je otkazao
> 3. Konačna konzistentnost, jer se razlike same izjednače posle prekida
> 4. Split brain, jer dve nezavisne celine prihvataju upise i razilaze se


> [!success] Quiz — correct ✓
> Your answer: 4. Split brain, jer dve nezavisne celine prihvataju upise i razilaze se
> Correct answer: 4
>
> Split brain znači da se grupa razdvoji na dve nezavisne celine i da obe prihvataju upise. Podaci se tada razilaze i posle oporavka mreže nema jedne tačne verzije, pa je to multi-leader sukob u najgorem obliku. Kašnjenje replikacije ima samo jedan izvor upisa, pa razilaženja nema. Konačna konzistentnost ne uključuje automatsko spajanje sukobljenih upisa.


> [!abstract] PI
> Šta je split brain, znaš. Sada nešto što još nismo radili, multi-primary. Ako ne znaš, slobodno izaberi „Ne znam“.


> [!question] Quiz
> Group Replication u režimu multi-primary: sva tri člana primaju upise. U istom trenutku 3307 menja račun id = 1, a 3308 menja račun id = 2. Obe izmene su u istoj tabeli `invoices`. Šta se dešava?
>
> 1. Obe se poništavaju, jer grupa ne zna koja je bila prva
> 2. Druga čeka dok prva ne oslobodi zaključanu tabelu
> 3. Obe transakcije se komituju, jer ne menjaju isti red
> 4. Jedna se poništava, jer obe menjaju istu tabelu


> [!question] Quiz — I don't know
> Your answer: I don't know
> Correct answer: 3
>
> Sukob postoji samo kad dve istovremene transakcije menjaju isti red. Grupa to proverava preko primarnih ključeva redova koje svaka transakcija menja, a ne preko imena tabele. Ovo je izmereno u ticket-u 11: id 1 i id 2 su komitovani i oba su vidljiva na sva tri člana. Danas ćemo izvesti zašto je to tako.


> [!abstract] PI
> Ovo je gornja granica za certification, i očekivao sam je. Ostaje još jedna oblast, modeli konzistentnosti iz poglavlja 2.


> [!question] Quiz
> Klijent upiše red na izvor, a odmah zatim isti klijent pročita taj red sa replike i ne vidi ga, jer replika još nije primenila upis. Koja garancija je narušena, ako je navedemo najužim imenom?
>
> 1. Konačna konzistentnost
> 2. Uzročna konzistentnost
> 3. Monotona čitanja
> 4. Read-your-writes (čitanje sopstvenih upisa)


> [!success] Quiz — correct ✓
> Your answer: 4. Read-your-writes (čitanje sopstvenih upisa)
> Correct answer: 4
>
> Isti klijent ne vidi sopstveni upis, a to je tačno definicija narušenog read-your-writes. Monotona čitanja se tiču dva čitanja, u kojima drugo vidi stariju verziju od prvog. Konačna konzistentnost ovde nije narušena, jer replika će na kraju primeniti upis. Uzročna konzistentnost je šira garancija koja uključuje i RYW, pa nije najuže ime.


> [!abstract] PI
> Ovo je tačno. Sada teže pitanje o istoj temi.


> [!question] Quiz
> Klijent X upiše red i dobije OK. Nešto kasnije **drugi** klijent Y pročita taj red sa drugog čvora i ne vidi ga. Koji od navedenih modela je najslabiji model koji zabranjuje ovakvo ponašanje?
>
> 1. Read-your-writes (čitanje sopstvenih upisa)
> 2. Monotona čitanja
> 3. Linearizabilnost (stroga konzistentnost)
> 4. Konačna konzistentnost


> [!failure] Quiz — incorrect ✗
> Your answer: 4. Konačna konzistentnost
> Correct answer: 3
>
> Read-your-writes i monotona čitanja su sesijske garancije: obe govore samo o operacijama jednog klijenta, pa ne obećavaju ništa klijentu Y. Konačna konzistentnost dozvoljava da Y privremeno vidi staru vrednost. Tek linearizabilnost zahteva da svako čitanje koje počne posle potvrđenog upisa vidi taj upis, bez obzira na to koji klijent čita i sa kog čvora. Ova razlika je ključna za poslednji deo lekcije: AFTER i BEFORE daju ovu garanciju svim klijentima, a ne samo klijentu koji je upisao red.


> [!abstract] PI
> Ovaj odgovor pokazuje da treba da proverim šta za tebe znači „konačna konzistentnost“. Jedno kratko pitanje o tome.


> [!question] Quiz
> Šta konačna konzistentnost (eventual consistency) obećava?
>
> 1. Klijent uvek vidi sopstvene upise, a drugi klijenti ih vide kasnije
> 2. Svako čitanje posle potvrđenog upisa vidi taj upis na svakoj replici
> 3. Replika nikad ne vraća vrednost stariju od one koju je već vratila
> 4. Ako upisi prestanu, sve replike posle nekog vremena imaju istu vrednost


> [!success] Quiz — correct ✓
> Your answer: 4. Ako upisi prestanu, sve replike posle nekog vremena imaju istu vrednost
> Correct answer: 4
>
> Konačna konzistentnost obećava samo konvergenciju: kad upisi prestanu, replike se posle nekog vremena izjednače. Ne kaže koliko to traje i ne zabranjuje nijedno zastarelo čitanje pre toga. Zato je najslabiji model, a „konačna“ znači „na kraju“, ne „definitivna“. Ostale tri opcije opisuju jače modele: linearizabilnost, read-your-writes i monotona čitanja.


> [!abstract] PI
> Provera znanja je gotova i granice su jasne. Pre plana imam jedno pitanje o cilju, jer od odgovora zavisi kako ćemo raditi.


> [!question] Question — Demonstracije
> Ko pokreće demonstracije nad našom topologijom tokom časa?
>
> 1. Ja pokrećem, ti tumačiš (Recommended)
> 2. Ti pokrećeš sam
> 3. Kombinovano

> [!question] Question — Cilj
> Gde je težište ove lekcije za odbranu?
>
> 1. Sva četiri dela, vrhunac na kraju (Recommended)
> 2. Više vremena na teoriji
> 3. Više vremena na merenjima


> [!example] Answer
> **Ko pokreće demonstracije nad našom topologijom tokom časa?**
> Ja pokrećem, ti tumačiš (Recommended)
>
> **Gde je težište ove lekcije za odbranu?**
> Sva četiri dela, vrhunac na kraju (Recommended)


> [!abstract] PI
> ## Plan lekcije
>
> **Pristup.** Provera znanja je pokazala tri stvari. Pravilo da se svake dve većine seku znaš sigurno. Znaš i šta je split brain, i znaš da u Group Replication-u komitovanje traži većinu. Nedostaje ti, međutim, korak koji sve ovo spaja. Kod jednog servera nisi znao da redosled dva istovremena upisa određuje zaključavanje reda. Kod više lidera nisi znao zašto nastaje sukob. Iz pravila većine nisi izveo da upis na manjem delu mreže ostaje blokiran. Zato lekciju gradim od tog korena: **ko sme da odluči o redosledu upisa**. Na tome stoje sva četiri dela.
>
> 1. **Certification** izvodimo sokratovski. Ako svi članovi vide iste transakcije istim redom, svaki od njih može sam da presudi o sukobu i da dobije isti ishod, bez glasanja. Iz toga slede pravilo „prvi po redosledu pobeđuje“, zahtev za primarnim ključem i sukob na nivou reda. Sledi demonstracija: par sukoba, pa `no_pk_demo`.
> 2. **Kvorum**: upis koji većina ne primi ne može da dobije svoje mesto u redosledu. Zato manjina čeka i ne razilazi se od većine. Rezultate iz ticket-a 11 ne pokrećemo ponovo, jer bi to trajalo predugo i zahtevalo ubijanje procesa. Prvo predviđaš ishod, pa ga uporedimo sa izmerenim.
> 3. **Single-primary i multi-primary**: kad tačno vredi platiti cenu sukoba.
> 4. **Vrhunac.** Komitovanje znači da je većina **primila** transakciju, a ne da su je svi **primenili**. To je ponovo „odluka ≠ vidljivost“ iz lekcije 0004. Sledi pitanje ko čeka: onaj ko upisuje (`AFTER`) ili onaj ko čita (`BEFORE`). Svaki nivo onda povezujemo sa modelom iz poglavlja 2 i uživo pokazujemo kako `BEFORE` zatvara zastarelo čitanje.
>
> **Ispravka koju je donela provera izvora.** Merni zapis iz ticket-a 11 označava `EVENTUAL` kao podrazumevanu vrednost. U MySQL-u 8.4 to **nije tačno**. Podrazumevana vrednost je `BEFORE_ON_PRIMARY_FAILOVER`, promenjena u verziji 8.4.0. To potvrđuju refman i release notes, prvi stepenik lestvice izvora. U normalnom radu ta vrednost se ponaša kao `EVENTUAL`, pa izmereni brojevi važe, ali oznaka „podrazumevano“ nije tačna. Na kraju ću je ispraviti na tom mestu u zapisu. Takođe, ticket 11 **nije merio `BEFORE`**, pa će današnja demonstracija biti njegovo prvo merenje.
>
> ```mermaid
> graph TD
>   R1["Jedan server: zaključavanje reda određuje redosled"]
>   R2["Svake dve većine se seku"]
>   R3["GR: svi članovi dobijaju transakcije istim redom (Paxos)"]
>   D1["Više lidera: dve nezavisne odluke, pa sukob"]
>   D2["Certification: skup upisa + 'prvi po redosledu pobeđuje'"]
>   D2b["Zahtev za PK; sukob na nivou reda; greška 1180"]
>   D3["Bez većine nema mesta u redosledu: manjina blokira, nema split brain"]
>   D4["Single- i multi-primary: kada vredi multi-primary"]
>   D5["Komitovanje = većina primila ≠ svi primenili"]
>   G["Nivoi group_replication_consistency ↔ modeli iz poglavlja 2"]
>   R1 --> D1
>   D1 --> D2
>   R3 --> D2
>   D2 --> D2b
>   R2 --> D3
>   R3 --> D3
>   D2 --> D4
>   R1 --> D4
>   D3 --> D5
>   D5 --> G
>   D4 --> G
> ```
>
> Ako se slažeš sa planom, napiši „dalje“ i počinjemo prvim korenom, R1.


> [!quote] YOU
> Moze dalje


> [!abstract] PI
> ## Koren R1: na jednom serveru redosled određuje zaključavanje reda
>
> **Zašto počinjemo odavde.** Ceo današnji problem glasi „ko određuje redosled dva upisa u isti red“. Pre nego što pogledamo slučaj sa više servera, treba da bude jasno kako to radi jedan server, jer tamo problema nema.
>
> **Bezuslovna istina.** Na jednom serveru InnoDB zaključava svaki red koji transakcija menja i drži to zaključavanje do kraja transakcije, odnosno do `COMMIT`-a ili `ROLLBACK`-a. Ako dve transakcije žele da menjaju **isti red**, zaključavanje dobija samo jedna. Druga **čeka**.
>
> ```
> 3307 (the only source)
> X: UPDATE invoices SET amount=100 WHERE id=7;   -- X gets the row lock on id=7
> Y: UPDATE invoices SET amount=200 WHERE id=7;   -- Y WAITS on the lock
> X: COMMIT;                                       -- lock released, X is in the binlog first
> Y: ... proceeds, COMMIT;                         -- Y is in the binlog second
> final: amount = 200 everywhere
> ```
>
> Oba upisa uspevaju, ali **jedan posle drugog**. Redosled nije nešto što treba otkriti naknadno. Redosled je **odluka jednog servera**, doneta u trenutku zaključavanja, i ona ulazi u binarni log upravo tim redom.
>
> **Veza sa onim što već znaš.** Sa prethodnim pitanjem si pokazao da replika samo izvršava binarni log redom kojim je zapisan. Sada vidiš i odakle taj redosled dolazi. Izabrao si odgovor „replike posle same biraju“, ali replike nemaju šta da biraju: kad redosled stigne do njih, odluka je već doneta. **Kod jednog lidera sukob je nemoguć zato što o redosledu odlučuje samo jedan server.** Zapamti ovu rečenicu, jer se ceo ostatak lekcije svodi na pitanje šta se dešava kad tog jednog servera nema.
>
> Napiši „dalje“.


> [!quote] YOU
> Dalje, mozda da probamo da ne moram dalje da pisem svaki put nego lepo mi daj sve ovako objasnjenje i samo na kraju kviz pa cu ja kad zavrsim sa citanjem da odgovorim na kviz


> [!abstract] PI
> Važi. Od sada ide ovako: objašnjenje, a odmah ispod njega kviz, u istoj poruci. Kviz čeka dok ne završiš čitanje. Kviz za R1:


> [!question] Quiz
> Postoji samo izvor 3307. Transakcija X je izvršila `UPDATE invoices … WHERE id=7`, ali još nije komitovala. Transakcija Y sada izvršava `UPDATE invoices … WHERE id=7`. Šta je tačno?
>
> 1. Y odmah vraća grešku, jer dve transakcije ne smeju menjati isti red
> 2. Y se izvrši odmah, a redosled u logu određuje vreme komitovanja
> 3. Y čeka na zaključanom redu, a redosled u binarnom logu biće X pa Y
> 4. Y se izvrši odmah, a replike posle odluče koja vrednost ostaje


> [!success] Quiz — correct ✓
> Your answer: 3. Y čeka na zaključanom redu, a redosled u binarnom logu biće X pa Y
> Correct answer: 3
>
> X drži zaključavanje reda id = 7 do svog COMMIT-a, pa Y čeka na njemu. Tek kad X oslobodi red, Y nastavlja. U binarni log zato prvo ulazi X, a zatim Y. Redosled je odredio jedan server, a replike ga samo izvršavaju. Y ne dobija grešku, nego čeka. Greška može da se javi tek ako čekanje traje duže od innodb_lock_wait_timeout.


> [!abstract] PI
> ## D1: zašto kod više lidera nastaje sukob
>
> **Zašto nam ovo treba.** Upravo smo videli da kod jednog lidera sukob ne može da nastane, jer o redosledu odlučuje jedan server. Multi-primary režim u Group Replication-u ukida upravo to: upise primaju **svi** čvorovi. Treba da vidimo šta se tačno pokvari, jer je certification lek baš za taj kvar.
>
> **Izvođenje.** Uzmimo dva izvora, A (3307) i B (3308), od kojih svaki prima upise i šalje svoj log drugom. Zaključavanje reda iz R1 i dalje postoji, ali **samo unutar jednog servera**. InnoDB na A ne zna ništa o zaključavanjima na B. Pogledaj šta se dešava kad X i Y istovremeno menjaju red 7:
>
> ```
>             A (3307)                          B (3308)
> X: UPDATE id=7 -> 100   lock on A      Y: UPDATE id=7 -> 200   lock on B
> X: COMMIT  -> OK to X                  Y: COMMIT  -> OK to Y
>         ---- ship X to B ---->   <---- ship Y to A ----
> A applies Y: id=7 = 200                B applies X: id=7 = 100
>                   ⚡ A and B now disagree, and BOTH clients were told OK
> ```
>
> Svaki server je sam doneo odluku o redosledu: A je zaključio „X je prvi“, a B „Y je prvi“. Svaki je svoju odluku potvrdio klijentu **pre nego što je drugi server uopšte saznao za nju**. Kad se logovi razmene, svaki server primeni tuđu promenu preko svoje. Na kraju A ima 200, a B ima 100: podaci su se **razišli**.
>
> **Može li ovo da se popravi naknadno?** Može da se izabere pobednik, na primer pravilom „poslednji upis pobeđuje“ (last-write-wins), pa se oba čvora izjednače. Ali tada jedan klijent ima OK za upis koji je nestao. Popravka posle potvrde ne vraća izgubljenu potvrdu, samo bira **koji** potvrđeni upis se gubi.
>
> **Bezuslovna istina koju odavde nosimo.** **Sukob kod više lidera nastaje zato što dva servera nezavisno odluče o redosledu istog reda i obe odluke potvrde klijentima.** Nije problem u tome što ima više servera, već u tome što je odluka doneta na više mesta, a potvrđena pre dogovora.
>
> **Veza sa R1.** Kod jednog lidera odluka nastaje na jednom mestu. Ovde je ista odluka doneta na dva mesta. U ovom primeru se ne dešava ništa više od toga.
>
> Sada pitanje, iz kojeg izlazi prvi korak ka certification-u: šta mora da se promeni da se nijedan **potvrđeni** upis ne izgubi, a da oba čvora i dalje primaju upise?


> [!question] Quiz
> A i B i dalje oba primaju upise. Koja promena garantuje da se nijedan upis kome je klijent dobio OK nikad ne izgubi?
>
> 1. Čvorovi šalju svoje logove jedan drugom brže, odmah posle komitovanja
> 2. Čvorovi posle razmene logova izaberu pobednika po vremenu komitovanja
> 3. Svaki čvor drugom šalje stanje redova umesto loga transakcija
> 4. Čvorovi se dogovore o redosledu transakcije pre nego što klijentu vrate OK


> [!success] Quiz — correct ✓
> Your answer: 4. Čvorovi se dogovore o redosledu transakcije pre nego što klijentu vrate OK
> Correct answer: 4
>
> Potvrđeni upis se gubi zato što je OK poslat pre dogovora. Zato dogovor mora da dođe pre OK. Ako se čvorovi pre potvrde slože da je X prvi, onda Y još nije potvrđen i može da se poništi, a klijent Y dobija grešku umesto lažnog OK. Izbor pobednika po vremenu i dalje dolazi posle potvrde. Brže slanje samo sužava prozor, ali ga ne zatvara. Slanje stanja umesto loga menja samo ono što se šalje, ne trenutak odluke.


> [!abstract] PI
> ## R3 i D2: certification
>
> **Zašto nam ovo treba.** Upravo si izveo uslov: čvorovi moraju da se dogovore o redosledu **pre** nego što klijentu vrate OK. Dogovor više servera je skup, pa treba videti kako Group Replication postiže da se on obavi samo jednom i da posle toga svaki član odlučuje sam.
>
> **Bezuslovna istina R3.** Članovi grupe ne šalju transakcije jedan drugom direktno. Svaku transakciju predaju **komunikacionom sloju grupe**, a on je isporučuje svim članovima, i to **svima istim redosledom**. Refman:
>
> > *"The communication layer provides a set of guarantees such as atomic message and total order message delivery."* — [refman 8.4, §20.1.1.2](https://dev.mysql.com/doc/refman/8.4/en/group-replication-summary.html)
>
> Taj sloj se zove XCom i, prema refman-u, predstavlja „Paxos variant“ ([§20.3.2](https://dev.mysql.com/doc/refman/8.4/en/group-replication-limitations.html)). To je konsenzus iz poglavlja 2: većina se dogovara o tome koja poruka zauzima koje mesto u nizu. Kako Paxos to postiže unutra, danas ne ulazimo. Za nas je bitan samo rezultat: **svi članovi vide isti niz transakcija, istim redom.** Ovo prihvati kao datost.
>
> **Izvođenje: šta član radi sa tim nizom.** Transakcija T se prvo izvrši **lokalno** na članu koji ju je primio, bez ikakvog dogovora. Kad klijent pošalje `COMMIT`, član u poruku grupi upiše i T-ov **skup upisa** (write-set). Skup upisa je spisak jedinstvenih identifikatora redova koje je T izmenila, odnosno vrednosti primarnog ključa. Poruka zatim dobija svoje mesto u zajedničkom nizu.
>
> Svaki član, kad dođe do T u nizu, postavlja isto pitanje:
>
> > Da li je neka transakcija koja je u nizu **pre** T, a koju T **nije videla** dok se izvršavala, menjala **isti red** kao T?
>
> - Ako nije, T prolazi i komituje se na svim članovima.
> - Ako jeste, T se poništava na svim članovima. Pobeđuje transakcija koja je **prva u nizu**.
>
> Refman to naziva *„distributed first commit wins rule“* i kaže da *„the transaction that was ordered first commits on all servers, and the transaction ordered second aborts“* ([§20.1.1.2](https://dev.mysql.com/doc/refman/8.4/en/group-replication-summary.html)). Obrati pažnju na reč **ordered**: „prvi“ znači prvi u zajedničkom nizu, a ne prvi po satu.
>
> Ovaj postupak je **certification**, na srpskom provera saglasnosti transakcija.
>
> **Veza sa R1 i D1.** Kod jednog lidera redosled određuje zaključavanje na jednom serveru (R1). Kod naivnog multi-leader rešenja redosled se određuje na dva mesta i nastaje sukob (D1). Group Replication redosled određuje **na jednom mestu**, u zajedničkom nizu (R3), a svaki član iz tog niza izvodi presudu. To je tvoj uslov iz prethodnog pitanja: dogovor je postignut pre OK, jer klijent dobija OK tek kad T prođe proveru.
>
> ```
> local exec (no coordination) -> COMMIT -> write-set to group -> total order (majority, Paxos)
>                                                         |
>                every member independently: "earlier unseen T' touched same row?"
>                                 no -> commit everywhere      yes -> abort everywhere
> ```
>
> **Napomena.** Ovaj pristup se naziva optimističkim, jer se transakcija izvršava bez dogovora u nadi da sukoba neće biti, a provera dolazi tek na kraju. To je osobina ovog dizajna, a ne jedini mogući izbor. Drugi sistemi zaključavaju unapred, preko celog klastera.
>
> Sada pitanje: zašto članovi, posle dogovora o redosledu, **ne moraju** da glasaju o tome da li T prolazi?


> [!question] Quiz
> Svaki član grupe sam odlučuje da li transakcija T prolazi proveru saglasnosti, bez ikakvog glasanja. Zašto svi članovi uvek donesu istu odluku?
>
> 1. Članovi uporede vremena komitovanja, a ona su na svima ista
> 2. Primarni čvor proveri T i javi ostalima šta je odlučio
> 3. Svi imaju isti niz transakcija i isto pravilo, pa nužno dobiju isti ishod
> 4. Svaki član ima zaključavanja svih redova na svim ostalim članovima


> [!success] Quiz — correct ✓
> Your answer: 3. Svi imaju isti niz transakcija i isto pravilo, pa nužno dobiju isti ishod
> Correct answer: 3
>
> Provera je determinističko pravilo nad ulazom koji je isti na svim članovima: isti niz transakcija i isti skupovi upisa. Isti ulaz i isto pravilo daju isti izlaz, pa za glasanje nema potrebe. Dogovor je potreban samo jednom, oko redosleda, i to obavlja Paxos. U multi-primary režimu nema primarnog čvora koji bi presuđivao. Satovi ne određuju redosled. Zaključavanja i dalje postoje samo lokalno, kao u D1.


> [!abstract] PI
> Prelazim na posledice certification-a, sa demonstracijama. Prvo prebacujem našu topologiju u stanje grupe.


> [!abstract] PI
> ## D2b: šta sledi iz certification-a
>
> Tri posledice slede direktno iz onoga što si upravo izveo. Ništa ovde ne treba učiti napamet.
>
> **1. Svaka tabela mora da ima primarni ključ.** Skup upisa je spisak **identifikatora redova**. Ako tabela nema primarni ključ niti jedinstveni ključ čije kolone ne dozvoljavaju NULL, red nema identifikator, pa nema šta da se upiše u skup upisa. Tada provera saglasnosti ne može da utvrdi da li dve transakcije menjaju isti red. Refman ovo navodi kao zahtev: *„Every table that is to be replicated by the group must have a defined primary key, or primary key equivalent where the equivalent is a non-null unique key.“* ([§20.3.1](https://dev.mysql.com/doc/refman/8.4/en/group-replication-requirements.html)).
>
> Upravo sam to pokrenuo na grupi koja radi (`examples/01-group-replication/41-no-pk-live.js`):
>
> ```
> CREATE TABLE poliklinika.no_pk_demo (label VARCHAR(40) NOT NULL, amount INT NOT NULL) ENGINE=InnoDB;
> -- accepted
> INSERT INTO poliklinika.no_pk_demo VALUES ('x', 1);
> ERROR 3098 (HY000): The table does not comply with the requirements by an external plugin.
> ```
>
> Tabela može da se **napravi**, ali upis u nju se **odbija**. „External plugin“ u poruci je sam Group Replication, koji proverava svaki upis pre izvršavanja. `dba.checkInstanceConfiguration` za istu tabelu vraća `status = error` i navodi razlog: *„Tables that do not follow these requirements will be readable but not updateable when used with Group Replication.“* Kad sam tabelu obrisao, isti poziv je vratio `status = ok`. Tabela `no_pk_demo` sada ne postoji.
>
> **2. Sukob postoji na nivou reda, ne tabele.** Skup upisa sadrži identifikatore **redova**, a ne imena tabela. Zato dve transakcije u istoj tabeli `invoices` dolaze u sukob samo ako dele bar jedan red. Ovo je odgovor na pitanje na koje si na početku izabrao „Ne znam“.
>
> **3. Ko je „prvi“, određuje redosled u nizu, a ne trenutak u kome je transakcija otvorena.** Transakcija ulazi u zajednički niz tek na `COMMIT`-u, kad pošalje svoj skup upisa. Pre toga grupa ne zna da ona postoji.
>
> Sada demonstracija, ali prvo tvoje predviđanje. Topologija je u **multi-primary** režimu: sva tri člana su `PRIMARY` i primaju upise. Raspored je sledeći:
>
> ```
> t=0 s   A on 3307: BEGIN; UPDATE invoices SET amount = amount + 100 WHERE invoice_id = 1;
>                    SELECT SLEEP(6);            -- holds the transaction open
> t=2 s   B on 3308: BEGIN; UPDATE invoices SET amount = amount + 999 WHERE invoice_id = 1; COMMIT;
> t=6 s   A on 3307: COMMIT;
> ```


> [!question] Quiz
> Multi-primary režim, red invoice_id = 1. A je na 3307 otvorila transakciju u t = 0 s i izmenila red, ali komituje tek u t = 6 s. B je na 3308 izmenila isti red i komitovala u t = 2 s. Šta se dešava?
>
> 1. A se komituje, jer je prva otvorila transakciju
> 2. Obe se komituju, a red dobija vrednost iz B
> 3. B se komituje, a A se poništava na svom COMMIT-u
> 4. B čeka na zaključanom redu dok A ne komituje


> [!success] Quiz — correct ✓
> Your answer: 3. B se komituje, a A se poništava na svom COMMIT-u
> Correct answer: 3
>
> B ulazi u zajednički niz u t = 2 s, a A tek u t = 6 s. B je zato prva u nizu, prolazi proveru saglasnosti i komituje se na svim članovima. A je menjala isti red i nije videla B, pa gubi. To što je A prva otvorila transakciju nije važno, jer grupa za nju saznaje tek na njenom COMMIT-u. B ne čeka, jer je zaključavanje koje drži A lokalno na 3307 (D1), a B se izvršava na 3308.


> [!abstract] PI
> ## Demonstracija: par sukoba nad `poliklinika.invoices`
>
> Predvideo si tačno. Ovo je izlaz skripte `examples/01-group-replication/34-conflict-pair.ps1`, pokrenute malopre:
>
> ```
> -- SAME row (invoice_id = 1)
> A(3307)  [6041 ms]  ERROR 1180 (HY000): Got error 149 - 'Lock deadlock; Retry transaction' during COMMIT
> B(3308)  [32 ms]    B COMMIT returned
> row 1 afterwards:   2243.05 on 3307, 3308 and 3309      <- only B's +999 survived
>
> -- DIFFERENT rows (A: invoice_id = 1, B: invoice_id = 2), identical timing
> A(3307)  [6026 ms]  A COMMIT returned
> B(3308)  [27 ms]    B COMMIT returned
> both rows on all three members: 2343.05 / 2078.31
>
> COUNT_CONFLICTS_DETECTED: 0 on 3307 and 3308
> ```
>
> Tri stvari se vide u ovom izlazu.
>
> **1. Prvi u nizu pobeđuje, a članovi konvergiraju.** B je prošla, A je poništena, i sva tri člana imaju istu vrednost. Na sva tri člana preživeo je samo B-ov upis (+999). Nema razilaženja i nema potvrđenog upisa koji je nestao, jer A nikad nije dobila OK. Ovo je uslov koji si izveo u D1.
>
> **2. Sukob se proverava na nivou reda.** Sa redovima 1 i 2, u istoj tabeli i sa istim vremenima, obe transakcije su komitovane.
>
> **3. Greška nije ona koju očekuješ.** Ovo je **izmereni nalaz**, a ne nešto što se može izvesti, pa ga ne izvodi. Na osnovu certification-a očekivali bismo poruku tipa „certification failed“. Umesto toga A dobija `ERROR 1180 … 'Lock deadlock; Retry transaction' during COMMIT`, a brojač `COUNT_CONFLICTS_DETECTED` ostaje 0. Ticket 11 je to izmerio u četiri različita rasporeda i nijednom nije dobio grešku 3101 (`ER_TRANSACTION_ROLLBACK_DURING_COMMIT`). Danas smo dobili isto.
>
> Objašnjenje: B je proverena i stigla je na 3307 da bude primenjena, ali je tamo zatekla A, koja lokalno drži zaključavanje istog reda. Primena transakcije koja je već prošla proveru ima prednost, pa 3307 **lokalno** poništava A, pre nego što A uopšte pošalje svoj skup upisa. Do provere saglasnosti A zato nikad ne stiže, i brojač ostaje 0.
>
> Izvor ovog objašnjenja je četvrti stepenik lestvice izvora: refman ne opisuje grešku koju klijent vidi, a MySQL bug **78705** („Improve Client Error For Certification Failures“) postoji upravo zbog ove nejasne poruke. Za odbranu je važno ovo: **mehanizam se zove certification, ali aplikacija vidi „deadlock, pokušaj ponovo“**, i zato mora da ume da ponovi transakciju.
>
> *Napomena: iznosi u redovima 1 i 2 rastu svakim pokretanjem skripte. Na kraju sesije ću ih vratiti na vrednosti koje su imali pre današnjih upisa.*


> [!question] Quiz
> Aplikacija radi nad Group Replication-om u multi-primary režimu. Na COMMIT dobija ERROR 1180 '… Lock deadlock; Retry transaction' during COMMIT. Šta to znači i šta aplikacija treba da uradi?
>
> 1. Grupa je izgubila većinu, pa treba sačekati da se kvorum vrati
> 2. Dva člana su se zaključala jedan drugom, pa treba sačekati da grupa izabere član
> 3. Transakcija je komitovana na većini, pa treba samo sačekati da je primene svi
> 4. Druga transakcija nad istim redom je prešla prva, pa ovu treba ponoviti od BEGIN


> [!success] Quiz — correct ✓
> Your answer: 4. Druga transakcija nad istim redom je prešla prva, pa ovu treba ponoviti od BEGIN
> Correct answer: 4
>
> Ova greška znači da je druga transakcija nad istim redom prva ušla u zajednički niz i komitovana je na svim članovima. Naša transakcija je lokalno poništena i nije komitovana nigde, pa je aplikacija mora ponoviti od BEGIN, nad novim stanjem reda. Pravog deadlock-a između članova nema, jer su zaključavanja lokalna. Gubitak kvoruma se ne javlja kao greška: upis tada ostaje blokiran, što je naredni deo lekcije.


> [!abstract] PI
> ## D3: kvorum, ili zašto manjina blokira a ne razilazi se
>
> **Zašto nam ovo treba.** U proveri znanja si za čvor 3307, kad ostane sam, rekao da će izvršiti i SELECT i INSERT, „jer je i dalje primarni čvor“. Sada imamo sve što je potrebno da se izvede zašto to nije tačno.
>
> **Izvođenje.** Iz R3 i D2 znamo da transakcija može da se komituje tek kad dobije **mesto u zajedničkom nizu**. To mesto dodeljuje Paxos, a Paxos dodeljuje mesto tek kad poruku prihvati **većina** članova. To je konsenzus-kvorum iz poglavlja 2. Iz toga sledi lanac:
>
> ```
> no majority reachable  ->  message cannot get a place in the order
>                        ->  certification cannot run on it
>                        ->  COMMIT can neither succeed nor fail  ->  it WAITS
> ```
>
> Uloga primarnog čvora ovde ništa ne menja. Primarni čvor određuje **gde se upisi prihvataju**, ali ne odlučuje sam o komitovanju.
>
> **Zašto nema split brain-a.** Ovo je tvoj koren R2: svake dve većine se seku, pa samo **jedan** deo mreže može da ima većinu. Najviše jedan deo, dakle, može da komituje upise, a drugi deo čeka. Dve celine ne mogu istovremeno da prihvataju upise, pa podaci ne mogu da se raziđu. **Manjina blokira umesto da se razilazi**, i to je ono što Group Replication bira unutar jednog klastera. Refman: *„When a majority of group members is lost, the group is unable to progress and blocks because it cannot secure majority or quorum.“* ([§20.7.8](https://dev.mysql.com/doc/refman/8.4/en/group-replication-network-partitioning.html))
>
> **Izmereno na našoj topologiji (ticket 11).** Procesi 3308 i 3309 su ubijeni, a 3307 je ostao sam:
>
> | Iskaz na 3307 | Rezultat |
> |---|---|
> | `SELECT COUNT(*) FROM poliklinika.patients` | vraćen za **39 ms** |
> | `INSERT INTO poliklinika.heartbeat …` | **i posle 30 s blokiran**, klijent ubijen |
> | `SELECT` traženog reda iz druge sesije | **0 redova**, blokirani upis se ne vidi |
>
> Čitanje se izvršava, jer ne traži mesto u nizu: čvor čita svoje lokalne podatke. Ta lokalna kopija može da bude **zastarela**, ako na drugom delu mreže većina i dalje prima upise. Kod nas to nije bio slučaj, jer su druga dva čvora bila ubijena.
>
> **Dva podrazumevana podešavanja koja treba da znaš kao takva.**
> - `group_replication_unreachable_majority_timeout = 0` znači „čekaj zauvek“. Ako se zada broj sekundi, posle tog vremena se blokirane transakcije poništavaju, a čvor prelazi u stanje `ERROR` ([refman, sistemske promenljive](https://dev.mysql.com/doc/refman/8.4/en/group-replication-system-variables.html)). To da je podrazumevana vrednost 0 je **projektna odluka**, a ne nešto što se izvodi.
> - Gašenje čvora komandom `topology.ps1 stop` **nije pad**. Član koji se uredno ugasi šalje grupi poruku da odlazi, grupa se svede na dva člana i većina se računa od dva. Član čiji je proces ubijen ništa ne javlja: grupa ga i dalje računa, samo što je on `UNREACHABLE`. Zato se gubitak kvoruma pokazuje samo ubijanjem procesa.
>
> **Sudbina blokiranog upisa.** To je najoštrija posledica, i povezuje se sa lekcijom 0004. Operator je ručno pokrenuo `cluster.forceQuorumUsingPartitionOf('127.0.0.1:3307')`, čime je proglasio da 3307 sam čini novu grupu. Upis zadat u 14:40:56 tada je **komitovan**, oko dva minuta kasnije, iako je njegov klijent odavno bio ubijen. Upis nije izgubljen i nije poništen, nego je čekao unutar komitovanja, a o njegovoj sudbini je odlučio **operator**, ne istek vremena. Alat pri tom upozorava: *„To avoid a split-brain scenario, ensure that all other members of the cluster are removed or joined back to the group that was restored.“* Prisilnim kvorumom operator preuzima na sebe odgovornost koju je pravilo većine do tada nosilo umesto njega.


> [!question] Quiz
> Group Replication sa četiri člana. Mreža se podeli na dva dela od po dva člana, a svi procesi i dalje rade. Šta se dešava sa upisima?
>
> 1. Upise prima onaj deo koji prvi primeti podelu mreže
> 2. Upisi su blokirani na oba dela, jer nijedan deo nema većinu
> 3. Upise primaju oba dela, a sukobe rešava certification kad se mreža vrati
> 4. Upise prima deo sa primarnim čvorom, a drugi deo je blokiran


> [!success] Quiz — correct ✓
> Your answer: 2. Upisi su blokirani na oba dela, jer nijedan deo nema većinu
> Correct answer: 2
>
> Većina od četiri člana su tri. Deo sa dva člana nema većinu, pa ni jedan ni drugi deo ne može da dodeli mesto u zajedničkom nizu. Upisi su blokirani na oba dela. Primarni čvor ne daje pravo na komitovanje. Certification ne rešava sukobe posle podele mreže, nego proverava transakcije koje su već dobile mesto u nizu. Zato se biraju neparni brojevi članova: četiri člana podnose otkaz jednog, kao i tri, a pri podeli 2/2 ostaju bez upisa.


> [!abstract] PI
> ## D4: single-primary ili multi-primary
>
> **Zašto nam ovo treba.** Sada znamo cenu multi-primary režima: transakcije se poništavaju na COMMIT-u, a aplikacija mora da ih ponavlja. Ostaje pitanje šta se dobija za tu cenu.
>
> **Izvođenje iz onoga što već imamo.** **Single-primary** je podrazumevani režim (`group_replication_single_primary_mode = ON`, [refman](https://dev.mysql.com/doc/refman/8.4/en/group-replication-system-variables.html)). Sekundarni članovi imaju `super_read_only = 1`, pa svi upisi idu na jednog člana. Tu se vraća koren R1: istovremene upise u isti red raspoređuje lokalno zaključavanje na tom jednom serveru, i oni stižu u zajednički niz **već raspoređeni**. Sukob iz D1 ne može da nastane, pa aplikacija ne dobija grešku 1180 zbog upisa sa drugog člana.
>
> Šta onda multi-primary dodaje? Prođimo kroz razloge koji deluju ubedljivo.
>
> - **Više propusnosti upisa?** Ne, i to sledi iz modela. Svaki član mora da primeni **svaki** upis, jer su svi članovi pune kopije. Tri primarna čvora ne dele posao upisa: svaki ga radi ceo, samo uz dodatnu proveru sukoba.
> - **Automatski failover?** Single-primary ga već ima: *„If the existing primary leaves the group, whether voluntarily or unexpectedly, a new primary is elected automatically.“* ([§20.1.3.1](https://dev.mysql.com/doc/refman/8.4/en/group-replication-single-primary-mode.html)). Ovde treba biti precizan u poređenju sa asinhronom replikacijom. Refman opisuje Asynchronous Connection Failover, koji **automatski preusmerava vezu replike** na drugi izvor sa spiska ([§19.4.9](https://dev.mysql.com/doc/refman/8.4/en/replication-asynchronous-connection-failover.html)), ali ga ne opisuje kao unapređenje replike u izvor. Ovo je provereno na prvom stepeniku lestvice izvora. Zato ne treba reći „asinhrona replikacija nema automatski failover“, nego tačno ovo: unapređenje novog izvora u Group Replication-u izvodi sama grupa izborom, a Asynchronous Connection Failover samo preusmerava vezu.
> - **Šta zaista ostaje:** upis je moguć na **bilo kom** članu u svakom trenutku, bez pauze za izbor novog primarnog čvora i bez preusmeravanja klijenata.
>
> Za to se plaća cena: poništavanja na „vrućim“ redovima koje više članova menja, logika ponavljanja u aplikaciji, i ograničenja koja refman navodi za multi-primary ([§20.3.2](https://dev.mysql.com/doc/refman/8.4/en/group-replication-limitations.html)). Izolacija `SERIALIZABLE` se odbija, strani ključevi sa `CASCADE` nisu podržani, a istovremeni DDL i DML nad istim objektom na različitim serverima nisu podržani.
>
> **Zaključak**, odnosno ocena iz memoa 05, ovde izvedena: **multi-primary se isplati samo kad je dostupnost upisa na svakom članu važnija od svega ostalog i kad su sukobi retki**, to jest kad različiti članovi uglavnom menjaju **različite redove**. Refman ovu preporuku ne daje izričito: proverio sam stranice o režimima i ograničenjima i takvu rečenicu nisam našao. To je dakle naš zaključak, a ne citat.


> [!question] Quiz
> Koja od sledećih situacija najbolje opravdava multi-primary režim u Group Replication-u?
>
> 1. Tri člana zajedno treba da podnesu tri puta više upisa nego jedan server
> 2. Aplikacija zahteva izolaciju SERIALIZABLE i automatski izbor novog primarnog čvora
> 3. Sve tri ordinacije stalno menjaju isti red sa brojem slobodnih termina
> 4. Svaka od tri ordinacije upisuje račune samo za svoje pacijente, a upis ne sme da čeka izbor primarnog čvora


> [!failure] Quiz — incorrect ✗
> Your answer: 1. Tri člana zajedno treba da podnesu tri puta više upisa nego jedan server
> Correct answer: 4
>
> Kad članovi menjaju različite redove, sukoba skoro nema, pa multi-primary daje svoju jedinu pravu korist: upis je moguć na svakom članu, bez pauze. Propusnost upisa ne raste, jer svaki član primenjuje svaki upis. Isti „vrući“ red je najgori slučaj, jer stalno izaziva poništavanja i ponavljanja. SERIALIZABLE se u multi-primary režimu odbija, a automatski izbor novog primarnog čvora već postoji u single-primary režimu.


> [!abstract] PI
> Ovde moram i nešto da ispravim. Ja sam ovu tvrdnju formulisao preoštro, a tvoj odgovor pokazuje i gde je stvarna zabluda.
>
> ## Zašto tri primarna čvora ne daju tri puta više upisa
>
> **Prebrojmo posao.** Neka svaka od tri ordinacije šalje 100 upisa u sekundi, i to svaka na svoj član:
>
> ```
> member   executes locally   applies from the others   rows written to its own disk
> 3307     100                200 (from 3308 + 3309)    300
> 3308     100                200                       300
> 3309     100                200                       300
> ```
>
> Svaki član **upisuje svih 300 redova** u svoju tabelu, svoj redo log i svoj binarni log, jer je svaki član **pun primerak** baze. Da upis u red ne bi stigao i na ostale članove, oni ne bi bili replike. Ako jedan server može da upiše najviše 300 redova u sekundi, grupa od tri multi-primary člana može ukupno da primi najviše oko 300 upisa u sekundi, a ne 900. Uska grla su disk i primena kod svakog člana, i nijedno se ne deli.
>
> **Ispravka moje tvrdnje.** Rekao sam da propusnost „ne raste“. Preciznije je ovako. Deo posla se zaista raspodeli, jer samo član koji prima upis **izvršava** iskaz: parsira ga, traži redove, računa `WHERE`. Ostali primenjuju gotove izmene redova, a to je obično jeftinije. Kod teških upita sa složenim uslovima multi-primary zato može da donese nešto. Ono što se **ne** deli je fizički upis svakog reda na svakom članu, i zato propusnost ne raste **srazmerno broju članova**. Ovo je izvedeno iz modela pune replikacije, a ne preuzeto iz dokumentacije, i u ovoj sesiji nije mereno.
>
> **Odakle dolazi zabluda.** Za **čitanja** važi baš suprotno: svaki član ima sve podatke, pa tri člana zaista mogu da opsluže oko tri puta više čitanja. To je skaliranje čitanja iz poglavlja 7. Lako je preneti istu intuiciju na upise, ali za upise ona ne važi, jer upis mora da stigne do **svih** članova, a čitanje do **jednog**.
>
> Zato posle svega ostaje jedina korist koju smo izveli: **na svakom članu može da se upisuje u svakom trenutku**. Isplati se samo kad članovi menjaju različite redove.


> [!question] Quiz
> Single-primary grupa od tri člana jedva stiže da upiše sve što stiže na primarni čvor 3307, a disk je na 100 % opterećenja. Šta će se desiti ako se grupa prebaci u multi-primary režim i upisi raspodele na sva tri člana?
>
> 1. Svaki član i dalje upisuje sve redove, pa disk ostaje usko grlo na svakom članu
> 2. Svaki član upisuje trećinu redova, pa se opterećenje diska smanji na trećinu
> 3. Svaki član upisuje samo redove koje menjaju njegovi klijenti, pa se posao deli
> 4. Sekundarni članovi više ne moraju da primenjuju upise, pa se opterećenje smanji


> [!success] Quiz — correct ✓
> Your answer: 1. Svaki član i dalje upisuje sve redove, pa disk ostaje usko grlo na svakom članu
> Correct answer: 1
>
> Svaki član je pun primerak baze, pa svaki red, ma na kom članu da je upisan, mora fizički da se upiše na svakom članu. Opterećenje diska po članu ostaje isto, a dolazi i provera sukoba. Raspodela upisa na članove raspoređuje samo izvršavanje iskaza, ne i fizički upis redova. Za čitanja bi ovo zaista pomoglo, jer čitanje traži samo jedan član.


> [!abstract] PI
> ## D5: komitovanje znači da je većina primila transakciju, a ne da su je svi primenili
>
> **Zašto nam ovo treba.** Do sada smo gledali **upise**: ko sme da komituje i šta se dešava pri sukobu. Poslednji deo lekcije bavi se **čitanjima**, a za njega je potrebna jedna precizna rečenica o tome šta OK u Group Replication-u tačno znači.
>
> **Izvođenje.** Pogledaj ponovo lanac iz D2. Klijent dobija OK kad transakcija **dobije mesto u nizu i prođe proveru saglasnosti**. Za to je dovoljno da je većina **primila** poruku, a ne da je svaki član **primenio** izmene na svoje tabele. Primena na svakom članu je poseban korak, koji obavlja njegova nit primene, svojim tempom, posle odluke:
>
> ```
> primary 3307:  COMMIT -> ordered + certified by majority -> OK to client   (t = 16 ms)
> secondary 3309:                 received ............ applying 5000 rows ...... visible
>                                           ^ a read here sees the OLD state
> ```
>
> Ovo već znaš iz lekcije 0004: **odluka ≠ vidljivost**. Tamo je odluku donosio binarni log, a vidljivost je određivao InnoDB commit. Ovde odluku donosi grupa, a vidljivost na **svakom pojedinom članu** određuje njegova primena. Razlika je u tome što je odluka sada sigurnija, jer je većina primila transakciju i nijedan otkaz je ne briše. Vidljivost na sekundarnom članu, međutim, i dalje kasni za odlukom.
>
> **Šta iz toga sledi.** Klijent koji upiše red na primarni čvor i odmah ga pročita sa sekundarnog može da ne vidi sopstveni upis. To je narušavanje read-your-writes, isto kao kod asinhrone replike iz poglavlja 3. Razlikuje se samo **koliko dugo** prozor traje: kod Group Replication-a to su milisekunde primene, a ne sekunde kašnjenja replikacije.
>
> Sada tvoje predviđanje za prvu demonstraciju. Topologija je ponovo u **single-primary** režimu, a primarni čvor je 3307. Skripta `42-ryw-before.js` drži dve otvorene sesije unutar jednog procesa: na 3307 upisuje transakciju od 5 000 redova, a **odmah posle** OK-a, nekoliko mikrosekundi kasnije, sa 3309 čita poslednji red te transakcije. To radi 40 puta. Nivo `group_replication_consistency` je podrazumevani za 8.4, `BEFORE_ON_PRIMARY_FAILOVER`, a u normalnom radu, bez otkaza primarnog čvora, on se ponaša kao `EVENTUAL`.


> [!question] Quiz
> Single-primary, primarni čvor 3307, podrazumevani nivo konzistentnosti. Klijent upiše 5 000 redova na 3307, dobije OK, i nekoliko mikrosekundi kasnije pročita poslednji red sa 3309. Ovo se ponovi 40 puta. U koliko čitanja će red nedostajati?
>
> 1. U skoro svih 40, jer 3309 još primenjuje transakciju kad stigne čitanje
> 2. Ni u jednom, jer sekundarni član odbija čitanje dok ne primeni sve
> 3. Ni u jednom, jer je OK stigao tek kad je većina primila transakciju
> 4. U oko polovine, jer 3309 nekad bude u većini, a nekad ne


> [!success] Quiz — correct ✓
> Your answer: 1. U skoro svih 40, jer 3309 još primenjuje transakciju kad stigne čitanje
> Correct answer: 1
>
> Kad većina primi transakciju, odluka je doneta, ali 3309 tek treba da primeni 5 000 redova, a to traje nekoliko milisekundi. Čitanje stiže nekoliko mikrosekundi posle OK-a, dakle pre nego što primena završi. Izmereno danas: 40 od 40 zastarelih čitanja u prvom pokretanju i 40 od 40 u drugom. Prijem transakcije ne znači da je ona primenjena. Sekundarni član ne odbija čitanje, nego vraća svoje trenutno lokalno stanje.


> [!abstract] PI
> ## Vrhunac: ko čeka, i kako se nivoi povezuju sa modelima iz poglavlja 2
>
> **Zašto nam ovo treba.** Prozor između odluke i vidljivosti sada postoji i izmeren je. Ostaje pitanje kako ga zatvoriti. Ovde dolazimo do okosnice rada: MySQL ne bira umesto tebe, nego ti daje podešavanje.
>
> **Izvođenje: zatvoriti prozor znači da neko mora da čeka.** Zastarelo čitanje nastaje kad čitanje na 3309 stigne **pre** nego što 3309 primeni upis. Postoje samo dva mesta na kojima može da se čeka, kao što su kod semisync-a postojale samo dve tačke čekanja:
>
> 1. **Čeka onaj ko upisuje.** OK se ne vraća dok **svi** članovi ne primene transakciju. Kad klijent dobije OK, red je već vidljiv svuda, pa svako čitanje, ma ko čitao i sa kog člana, vidi upis.
> 2. **Čeka onaj ko čita.** Pre nego što izvrši čitanje, član sačeka da primeni **sve transakcije koje su u nizu pre** tog čitanja. Čitanje tada vidi sve što je komitovano pre nego što je ono počelo.
>
> MySQL nudi oba načina, i zbir dva načina, kao nivoe promenljive `group_replication_consistency`. Definicije iz refman-a ([§20.5.3.2](https://dev.mysql.com/doc/refman/8.4/en/group-replication-configuring-consistency-guarantees.html), [sistemske promenljive](https://dev.mysql.com/doc/refman/8.4/en/group-replication-system-variables.html)):
>
> | Nivo | Ko čeka | Refman, doslovno |
> |---|---|---|
> | `EVENTUAL` | niko | *„Neither read-only nor read/write transactions wait for preceding transactions to be applied before executing.“* |
> | `BEFORE_ON_PRIMARY_FAILOVER` (**podrazumevani u 8.4**) | samo novi primarni čvor, posle failover-a | dok se otkaz ne desi, ponaša se kao `EVENTUAL` |
> | `AFTER` | **onaj ko upisuje** (način 1) | *„A read/write transaction waits until its changes have been applied to all of the other members. This value has no effect on read-only transactions.“* |
> | `BEFORE` | **onaj ko čita** (način 2) | *„A read-only transaction waits for all preceding transactions to complete before being executed.“* |
> | `BEFORE_AND_AFTER` | oba | zbir prethodna dva |
>
> **Promena u 8.4 koju treba izgovoriti na odbrani.** Do verzije 8.4.0 podrazumevani nivo je bio `EVENTUAL`. Release notes 8.4.0 kažu: *„The default value of the group_replication_consistency system variable is now BEFORE_ON_PRIMARY_FAILOVER; previously, this was EVENTUAL.“* Na našoj topologiji sam proverio: `@@group_replication_consistency` je `BEFORE_ON_PRIMARY_FAILOVER` na sva tri člana. Merni zapis iz ticket-a 11 je `EVENTUAL` pogrešno označio kao podrazumevani, i to ću ispraviti. Nivo `BEFORE_ON_PRIMARY_FAILOVER` sprečava samo da novi primarni čvor, odmah posle failover-a, vrati podatke starije od onih koje je imao prethodni primarni čvor. Dok primarni čvor radi, **ne zatvara** prozor sa sekundarnog člana. To je ono što si upravo video: 40 od 40.
>
> **Važna osobina: nivo važi za transakciju, a ne za ceo sistem.** Može da se postavi za sesiju (`SET SESSION group_replication_consistency = …`), a važi za transakcije te sesije. Ovo je projektna odluka i ne izvodi se iz modela. Zato je druga demonstracija postavljena ovako: onaj ko upisuje **ništa ne menja**, a samo sesija koja čita na 3309 prelazi na `BEFORE`.
>
> Predvidi rezultat:


> [!question] Quiz
> Isti eksperiment: 40 puta upis od 5 000 redova na 3307, pa odmah čitanje sa 3309. Onaj ko upisuje ostaje na podrazumevanom nivou, a samo sesija koja čita na 3309 postavlja group_replication_consistency = 'BEFORE'. Šta će se promeniti?
>
> 1. Zastarela čitanja padnu na nulu, a raste vreme upisa, dok vreme čitanja ostaje isto
> 2. Zastarela čitanja padnu na nulu, a raste vreme čitanja, dok vreme upisa ostaje isto
> 3. Zastarela čitanja padnu na nulu, a vreme čitanja i vreme upisa ostanu ista
> 4. Zastarela čitanja ostanu ista, jer BEFORE važi samo za transakcije koje upisuju


> [!success] Quiz — correct ✓
> Your answer: 2. Zastarela čitanja padnu na nulu, a raste vreme čitanja, dok vreme upisa ostaje isto
> Correct answer: 2
>
> Sa nivoom BEFORE čeka onaj ko čita: pre SELECT-a, 3309 primeni sve transakcije koje su u nizu pre tog čitanja, uključujući upis od 5 000 redova. Čitanje zato vidi red, ali traje onoliko koliko traje ta primena. Onaj ko upisuje se ne menja, pa ni njegovo vreme ne raste. Da je postavljen AFTER na strani onoga ko upisuje, cenu bi platio on. BEFORE važi i za transakcije koje samo čitaju: refman izričito kaže da read-only transakcija čeka na prethodne.


> [!abstract] PI
> ## Rezultat, i povezivanje nivoa sa modelima
>
> Predvideo si tačno. Ovo je izlaz skripte `examples/01-group-replication/42-ryw-before.js` iz dva današnja pokretanja. Svako ima 40 iteracija, upis je od 5 000 redova, a čita se sa 3309 odmah posle OK-a:
>
> | Nivo **sesije koja čita** | Zastarela čitanja (1. / 2. pokretanje) | Medijana upisa | Medijana čitanja |
> |---|---|---|---|
> | `BEFORE_ON_PRIMARY_FAILOVER` (podrazumevani) | **40/40** · **40/40** | 16 · 16 ms | 0 · 0 ms |
> | `EVENTUAL` | 39/40 · 40/40 | 16 · 15 ms | 0 · 0 ms |
> | `BEFORE` | **0/40** · **0/40** | 16 · 16 ms | **16 · 14 ms** |
>
> Ovo je prvo merenje nivoa `BEFORE` na našoj topologiji, jer ticket 11 ga nije merio. Merenje iz ticket-a 11 iste je postavke, ali se tamo menjao nivo **onoga ko upisuje**: `AFTER` je doneo 0 zastarelih čitanja uz medijanu upisa od 29 ms umesto 16 ms (+81 %), a `BEFORE_AND_AFTER` 0 zastarelih čitanja uz 31 ms (+94 %). Zajedno, ova dva merenja daju potpunu sliku: **prozor se zatvara u oba slučaja, a cenu plaća onaj ko čeka.** Kod `BEFORE` je to onaj ko čita (oko 15 ms po čitanju), a kod `AFTER` onaj ko upisuje (oko 13 ms po upisu). Cena je približno ista i jednaka je vremenu primene 5 000 redova. Menja se samo **ko** je plaća.
>
> Ovim se zatvara i druga polovina primera read-your-writes iz ticket-a 08. U poglavlju 7 asinhrona replika daje zastarelo čitanje, a ovde ga `BEFORE` zatvara.
>
> **Povezivanje sa modelima iz poglavlja 2.** Ovo je most od profesorovog rečnika do podešavanja u MySQL-u. Refman ne koristi reči „linearizable“ ni „read your writes“: proverio sam stranice o nivoima, i „strong consistency“ se javlja samo u opisima scenarija. Leva kolona je dakle iz refman-a, a desna je **naše povezivanje**, izvedeno iz definicija:
>
> | Nivo | Šta garantuje | Model iz poglavlja 2 |
> |---|---|---|
> | `EVENTUAL` / `BEFORE_ON_PRIMARY_FAILOVER` u normalnom radu | samo to da će svaki član na kraju primeniti upis | **konačna konzistentnost**: read-your-writes nije garantovan (40/40) |
> | `BEFORE` na strani onoga ko čita | **to** čitanje vidi sve što je komitovano pre njega, ma ko da je upisao i na kom članu | za to čitanje: **stroga konzistentnost** (linearizabilnost) u svom zahtevu za čitanje, a read-your-writes sledi kao poseban slučaj |
> | `AFTER` na strani onoga ko upisuje | posle OK-a, **svako** naredno čitanje na **svakom** članu vidi taj upis | read-your-writes **i za druge klijente**. Tvoj klijent Y iz provere znanja više ne vidi staro stanje |
> | `BEFORE_AND_AFTER` | oba | najjača kombinacija, i najskuplja (+94 %) |
>
> Zašto `AFTER` ne nazivam linearizabilnošću? Dok onaj ko upisuje još čeka, upis se primenjuje na članove **jedan po jedan**. Čitanje na članu koji je već primenio upis vidi novu vrednost, a čitanje u istom trenutku na članu koji još nije vidi staru. Linearizabilnost to zabranjuje, a `AFTER` to izričito ne isključuje. Ovo je izvedeno iz definicije u refman-u i nije mereno.
>
> **Okosnica rada, sada na merenju.** MySQL ne isporučuje jedan model konzistentnosti. Isporučuje **podešavanje koje važi za svaku transakciju posebno**, i operator za svaku sesiju bira gde na skali od konačne do stroge konzistentnosti sistem stoji, kao i ko plaća cenu. Podrazumevana vrednost u 8.4 je, u normalnom radu, konačna konzistentnost.
>
> Poslednje pitanje, o tvom klijentu Y:


> [!question] Quiz
> Single-primary grupa. Aplikacija za naplatu upisuje račune na 3307 i nju možeš da menjaš. Alat za izveštaje čita sa 3309 i njega ne možeš da menjaš. Izveštaj mora da vidi svaki račun za koji je naplata dobila OK. Koje podešavanje to postiže?
>
> 1. AFTER u sesijama aplikacije za naplatu, jer onaj ko upisuje čeka da svi članovi primene upis
> 2. BEFORE_ON_PRIMARY_FAILOVER, jer je to podrazumevani nivo u 8.4 i štiti od zastarelih čitanja
> 3. BEFORE u sesijama aplikacije za naplatu, jer onaj ko upisuje čeka na prethodne transakcije
> 4. EVENTUAL u sesijama izveštaja, jer će 3309 na kraju ipak primeniti svaki upis


> [!success] Quiz — correct ✓
> Your answer: 1. AFTER u sesijama aplikacije za naplatu, jer onaj ko upisuje čeka da svi članovi primene upis
> Correct answer: 1
>
> Sesije alata za izveštaje ne možeš da menjaš, pa BEFORE na strani onoga ko čita ne dolazi u obzir. Ostaje da čeka onaj ko upisuje: sa AFTER, naplata dobija OK tek kad je račun primenjen na svim članovima, pa ga izveštaj na 3309 sigurno vidi. BEFORE na strani onoga ko upisuje tera ga da čeka prethodne transakcije pre svog upisa, a ne posle, pa ništa ne garantuje čitanju koje dolazi kasnije. BEFORE_ON_PRIMARY_FAILOVER deluje samo posle failover-a: danas je dao 40/40 zastarelih čitanja. EVENTUAL ne garantuje ništa o trenutku u kome se upis vidi.


> [!abstract] PI
> Sada merni zapis, zapis o učenju, indeks, ispravka zapisa 0002 i sitne izmene u README fajlovima.


> [!abstract] PI
> Now I'll edit several files: the 0002 record, the README index, the examples README, `TEACHING.md`, and `GLOSSARY.md`.


> [!abstract] PI
> Lekcija 05 je gotova i trebalo bi da ti se otvorila u pregledaču. Sva četiri dela su prošla. Na tri mesta si odgovorio pogrešno ili sa „ne znam“, pa smo ih prošli ponovo, i svako potvrdno pitanje posle toga si rešio. Topologija je vraćena u stanje mirovanja **async**, a server na portu 3306 nije diran.
>
> **Šta smo našli na topologiji danas:**
> - **Isti red na dva člana:** jedna transakcija prođe, a druga dobije `ERROR 1180 … Lock deadlock` (a ne grešku 3101). Brojač `COUNT_CONFLICTS_DETECTED` ostaje 0. **Različiti redovi u istoj tabeli:** obe transakcije se komituju. Ovo je peto merenje sa istim ishodom.
> - **Tabela `no_pk_demo` u grupi koja radi:** `CREATE TABLE` prolazi, a `INSERT` se odbija greškom `ERROR 3098`. Tabela je posle obrisana.
> - **Nivo `BEFORE` je prvi put izmeren:** zastarelih čitanja je 0/40 u oba pokretanja. Čitanje traje oko 15 ms umesto 0 ms, a vreme upisa se ne menja. Ticket 11 je za `AFTER` izmerio da upis raste sa 16 na 29 ms. Dakle, prozor se zatvara u oba slučaja, a podešavanje bira ko plaća cenu.
>
> **Dve ispravke koje treba da znaš za pisanje:**
> - **Podrazumevani nivo u MySQL 8.4 je `BEFORE_ON_PRIMARY_FAILOVER`, a ne `EVENTUAL`.** To potvrđuju release notes za 8.4.0, a proverio sam i na našoj topologiji. Ticket 11 je to pogrešno označio i ispravio sam na tom mestu. Brojevi iz ticket-a 11 i dalje važe.
> - **Moja tvrdnja o multi-primary režimu bila je preoštra.** Rekao sam da propusnost upisa „ne raste“. Tačno je da ne raste **srazmerno broju članova**: na članove se deli samo izvršavanje iskaza, a fizički upis svakog reda radi svaki član. Ovo je izvedeno iz modela, a nije mereno.
>
> **Novi fajlovi:**
> - `lessons/0005-group-replication.html`, sa šest figura u `viz/` i kvizom od 9 pitanja
> - `reference/group-replication.html`
> - `learning-records/0007-group-replication-lesson.md`
> - `.scratch/replikacija/measurements/0007-group-replication-lesson.md`, sa sirovim izlazima u `raw/0007-*.txt`
> - `examples/01-group-replication/41-no-pk-live.js` i `42-ryw-before.js`
>
> **Izmenjeni fajlovi:**
> - `learning-records/README.md`: novi red u indeksu i nova trajna ograničenja
> - `GLOSSARY.md`: novi termini, na primer „zajednički niz“ i „prvi po redosledu pobeđuje“
> - zapis 0002 i merni zapis 0002: ispravljena oznaka podrazumevanog nivoa
> - README u folderu primera i ticket 17
>
> **Tvoje novo pravilo:** od sada ide objašnjenje, a odmah ispod njega kviz, bez „napiši dalje“. Upisao sam ga u `../TEACHING.md`, pa važi i za sve sledeće lekcije.
>
> **Sledeće:** pisanje poglavlja 5 za `rad.md`, u posebnoj sesiji. Na početku te sesije biće tri pitanja za ponavljanje:
> - zašto 3307 blokira upis kad ostane sam;
> - zašto multi-primary ne skalira upise;
> - koji nivo izabrati kad aplikaciju koja čita ne možeš da menjaš.
>
> Ako ti nešto iz lekcije nije jasno, pitaj ovde.
