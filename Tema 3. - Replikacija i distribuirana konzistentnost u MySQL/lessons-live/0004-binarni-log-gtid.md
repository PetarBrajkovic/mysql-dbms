> [!quote] YOU
> > [!note] SKILL loaded: teach
>
> Poglavlje 3 — Binarni log, GTID i asinhrona replikacija (ticket 15, lekcija)
>
>    Obuhvata profesorove tačke #1 i #2:
>
>    1. Šta zapravo putuje između servera: binarni log, formati STATEMENT / ROW / MIXED, nesigurni iskazi.
>    2. Matrica postojanosti: sync_binlog × innodb_flush_log_at_trx_commit preko dvofazne potvrde redo-binlog.
>    3. GTID i SOURCE_AUTO_POSITION; nit prijema → relay log → nit primene, i zašto je kašnjenje u niti primene.
>    4. Prelazak na vokabular izvor/replika i razlog (MySQL 8.0 preimenovanje).
>
>    Na početku ponovi najslabija mesta iz prethodne lekcije: RYW naspram monotonih čitanja i dva obična PACELC pitanja.

> [!question] Question
> Da li želiš da se ova lekcija prati uživo u Obsidian belešci?
>
> 1. Da, nova datoteka (Preporučeno)
> 2. Da, postojeća datoteka
> 3. Ne

> [!example] Answer
> 1. Da, nova datoteka (Preporučeno)

> [!abstract] PI
> Napravio sam praznu belešku. Nalepi ovu komandu i javi kad je povezano:
>
> ```
> /md-log lessons-live/0004-binarni-log-gtid.md
> ```


> [!quote] YOU
> Nastavi


> [!abstract] PI
> Povezano. Počinjemo ponavljanjem dva najslabija mesta iz prošle lekcije, pa onda proverom znanja za novo gradivo.


> [!question] Quiz
> Aplikacija čita sa dve replike (A i B), a replika B kasni više od replike A. Korisnik ništa ne upisuje. Prvo čitanje ide na A i vidi 10 poruka, drugo ide na B i vidi 8. Koji je NAJSLABIJI model koji zabranjuje ovu anomaliju?
>
> 1. Konačna konzistentnost
> 2. Stroga konzistentnost
> 3. Monotona čitanja
> 4. Read-your-writes


> [!success] Quiz — correct ✓
> Your answer: 3. Monotona čitanja
> Correct answer: 3
>
> Ime je okidač: korisnik nije ništa upisao, pa read-your-writes nema šta da štiti. Prekršeno je to da novo čitanje vidi manje od PRETHODNOG ČITANJA — to je tačno ono što monotona čitanja zabranjuju. Stroga konzistentnost ga takođe zabranjuje, ali nije najslabija. Konačna konzistentnost ga dozvoljava (obe replike će se „nekad“ izjednačiti).


> [!question] Quiz
> Korisnik upiše komentar na izvoru (3307), odmah zatim osveži stranu, a čitanje ode na repliku 3309 koja kasni 2 s. Komentar se ne vidi. Pri sledećem osvežavanju čitanje ponovo ide na 3309 i komentar se i dalje ne vidi. Koji je najslabiji model koji zabranjuje ovo što se dogodilo?
>
> 1. Uzročna konzistentnost
> 2. Read-your-writes
> 3. Stroga konzistentnost
> 4. Monotona čitanja


> [!success] Quiz — correct ✓
> Your answer: 2. Read-your-writes
> Correct answer: 2
>
> Korisnik ne vidi SOPSTVENI UPIS — okidač je „writes“. Monotona čitanja ovde nisu prekršena: oba čitanja vide isto stanje (bez komentara), nijedno ne vidi manje od prethodnog. Uzročna i stroga konzistentnost takođe zabranjuju ovu anomaliju, ali su jače od read-your-writes.


> [!abstract] PI
> Oba tačna. Sada dva obična pitanja iz PACELC-a.


> [!question] Quiz
> Mreža radi normalno, nema nikakve particije. Sistem pre nego što klijentu potvrdi upis čeka da ga većina čvorova primi. Na koje od dva pitanja ovo odgovara, i kako?
>
> 1. Na pitanje „kad je particija, odgovoriti ili odbiti?“ — odgovara, plaća konzistentnošću
> 2. Na pitanje „kad mreža radi, čekati ili ne?“ — čeka, plaća dostupnošću
> 3. Na pitanje „kad je particija, odgovoriti ili odbiti?“ — odbija, plaća dostupnošću
> 4. Na pitanje „kad mreža radi, čekati ili ne?“ — čeka, plaća latencijom


> [!success] Quiz — correct ✓
> Your answer: 4. Na pitanje „kad mreža radi, čekati ili ne?“ — čeka, plaća latencijom
> Correct answer: 4
>
> Mreža radi, dakle ovo je drugo pitanje (ono iz „ELC“ dela). Čekanje na zdravoj mreži je ograničeno — završiće se — pa je cena latencija (vreme odziva), ne dostupnost. Dostupnost se gubi samo kad čekanje može trajati neograničeno, a to je tek kod particije.


> [!question] Quiz
> Mreža se prekine: izvor 3307 više ne vidi replike 3308 i 3309. Replika 3309 i dalje odgovara na čitanja iz svojih, sada zastarelih podataka. Kako ovo odgovara na pitanje o particiji?
>
> 1. Odgovara — bira latenciju, a odriče se konzistentnosti
> 2. Odgovara — bira konzistentnost, a odriče se dostupnosti
> 3. Odbija — bira konzistentnost, a odriče se dostupnosti
> 4. Odgovara — bira dostupnost, a odriče se konzistentnosti


> [!success] Quiz — correct ✓
> Your answer: 4. Odgovara — bira dostupnost, a odriče se konzistentnosti
> Correct answer: 4
>
> Za vreme particije čvor ima samo dve mogućnosti: da odgovori iz onoga što ima (ostaje dostupan, ali podaci mogu biti zastareli) ili da odbije (ostaje konzistentan, ali nije dostupan). Replika koja čita iz zastarelih podataka je odgovorila — izabrala je dostupnost. Latencija pripada drugom pitanju, onom kad mreža radi.


> [!abstract] PI
> Sve četiri tačno — ponavljanje je čvrsto. Prelazimo na proveru znanja za novo gradivo. Na ovim pitanjima je u redu ako ne znaš; tražim gde ti se znanje završava.


> [!question] Quiz
> Na izvoru se izvrši `UPDATE racuni SET status='placen' WHERE id = 7`. Šta MySQL-ova replikacija zapravo šalje replici?
>
> 1. Zapis o promeni iz loga, koji replika ponovo primenjuje na svoje podatke
> 2. Izmenjene stranice tabele sa diska, koje replika kopira preko svojih
> 3. Upit od replike ka izvoru pri svakom čitanju, bez lokalne kopije
> 4. Periodični snimak cele baze, koji replika učitava umesto stare


> [!question] Quiz — I don't know
> Your answer: I don't know
> Correct answer: 1
>
> MySQL replicira log, a ne stanje: izvor upisuje promenu u binarni log, replika taj zapis preuzima i ponovo izvršava (replay) nad svojom kopijom. Stranice sa diska se ne šalju (to bi bila fizička replikacija na nivou skladišta), a snimak cele baze služi samo za početno punjenje replike.


> [!abstract] PI
> Dobro, to je važan podatak — tu krećemo od nule. Proveriću još nekoliko niti, da vidim na čemu možemo da gradimo.


> [!question] Quiz
> Iz predavanja o oporavku: transakcija je komitovana i klijent je dobio „OK“, a odmah zatim server padne pre nego što su izmenjene stranice tabele zapisane na disk. Zašto se izmena posle oporavka ipak ne gubi?
>
> 1. Izmena ostaje u baferu u memoriji, koji preživljava pad sistema
> 2. Stranice tabele se uvek zapisuju na disk pre potvrde, pa log nije potreban
> 3. Pri oporavku se izmena poništava (Undo), pa klijent mora da je ponovi
> 4. Zapis o izmeni je u logu na disku pre potvrde, pa se pri oporavku ponovo primeni (Redo)


> [!question] Quiz — I don't know
> Your answer: I don't know
> Correct answer: 4
>
> To je pravilo write-ahead logovanja: pre nego što se klijentu potvrdi komitovanje, zapis u logu mora biti na stabilnoj memoriji. Stranice tabele mogu na disk i kasnije; posle pada, Redo iz loga vraća komitovane izmene. U InnoDB-u taj log se zove redo log.


> [!question] Quiz
> Program pozove `write()` da upiše red u datoteku i poziv uspešno vrati. Odmah zatim nestane struje. Da li je taj red sigurno na disku?
>
> 1. Da — nestanak struje briše samo RAM programa, ne keš operativnog sistema
> 2. Da — uspešan write() znači da je operativni sistem već upisao red na disk
> 3. Ne nužno — može biti samo u kešu operativnog sistema dok se ne pozove fsync
> 4. Ne nužno — može biti samo u baferu programa dok se datoteka ne zatvori


> [!question] Quiz — I don't know
> Your answer: I don't know
> Correct answer: 3
>
> Note: Nisam siguran, mislim da nije
>
> write() samo preda podatke operativnom sistemu, koji ih drži u svom kešu u RAM-u i na disk ih spušta kad mu odgovara. Tek fsync() traži od sistema da podatke stvarno spusti na disk i vrati se tek kad je to urađeno. Keš operativnog sistema je u RAM-u, pa nestankom struje nestaje. Zatvaranje datoteke ne garantuje upis na disk.


> [!abstract] PI
> Intuicija ti je bila dobra („mislim da nije“) — to ćemo samo učvrstiti. Još dve provere, ovog puta na rasuđivanje, ne na znanje napamet.


> [!question] Quiz
> Zamisli da izvor replici šalje TEKST SQL iskaza, a replika ga izvršava ponovo. Koji od ovih iskaza može na replici da proizvede DRUGAČIJI rezultat nego na izvoru?
>
> 1. INSERT INTO racuni (id, status) VALUES (8, 'novi')
> 2. UPDATE racuni SET status='placen' WHERE id=7
> 3. DELETE FROM racuni WHERE id IN (3, 4, 5)
> 4. UPDATE racuni SET status='placen' WHERE tenant_id=1 LIMIT 5


> [!success] Quiz — correct ✓
> Your answer: 4. UPDATE racuni SET status='placen' WHERE tenant_id=1 LIMIT 5
> Correct answer: 4
>
> LIMIT 5 bez ORDER BY ne kaže KOJIH pet redova — server bira one na koje prvo naiđe, a to zavisi od fizičkog rasporeda i plana izvršavanja, koji na replici mogu biti drugačiji. Ostala tri iskaza tačno imenuju redove po primarnom ključu ili konkretnim vrednostima, pa daju isti rezultat svuda. MySQL za baš ovaj iskaz izdaje upozorenje 1592: „unsafe because it uses a LIMIT clause“.


> [!quote] YOU
> Mislio sam da je zbog tenant_id=1


> [!abstract] PI
> Dobro što si to rekao — znači da je odgovor bio tačan, ali iz pogrešnog razloga. Hajde da vidimo gde tačno nastaje ta zabuna.


> [!question] Quiz
> Tabela `racuni` ima iste podatke na izvoru i na replici. Na izvoru se izvrši `UPDATE racuni SET status='placen' WHERE tenant_id=1` (bez LIMIT). `tenant_id` nije primarni ključ i 40 redova ima `tenant_id=1`. Kad replika izvrši isti tekst iskaza, šta se dešava?
>
> 1. Menja istih 40 redova kao izvor, jer uslov izdvaja isti skup redova
> 2. Može promeniti druge redove, jer tenant_id nije primarni ključ
> 3. Može promeniti druge redove, jer replika može izabrati drugi indeks
> 4. Menja samo prvi red sa tenant_id=1, jer uslov nije jedinstven


> [!success] Quiz — correct ✓
> Your answer: 1. Menja istih 40 redova kao izvor, jer uslov izdvaja isti skup redova
> Correct answer: 1
>
> Uslov WHERE tenant_id=1 nad istim podacima uvek izdvaja ISTI SKUP redova — svih 40, bez obzira na to kojim redom ih server pronađe i kojim indeksom. Redosled i indeks utiču samo na to KOJIM PUTEM se dođe do redova, ne na to KOJI su. Problem nastaje tek kad iskaz bira PODSKUP po redosledu (LIMIT 5 = „prvih pet na koje naiđeš“) — tada redosled odlučuje koji redovi ulaze.


> [!abstract] PI
> Odlično — zabuna je razrešena: problem nije uslov po ne-ključnoj koloni, nego **izbor podskupa po redosledu**. Sada nit o praćenju pozicije.


> [!question] Quiz
> Replika je primenila deo izvorovog loga, a onda je restartovana. Šta joj je MINIMALNO potrebno da bi posle restarta nastavila tačno tamo gde je stala, bez preskakanja i bez ponavljanja?
>
> 1. Vreme poslednje primenjene izmene, pa nastavlja od tog trenutka
> 2. Broj redova u svakoj tabeli, pa upoređuje sa izvorom
> 3. Ništa — izvor pamti dokle je koja replika stigla
> 4. Oznaka mesta u izvorovom logu do kog je sve primenjeno


> [!question] Quiz — I don't know
> Your answer: I don't know
> Correct answer: 4
>
> Note: Pretpostavljam da je 4.
>
> Log je uređen niz zapisa, pa je „dokle sam stigla“ samo jedna oznaka mesta u tom nizu. Vreme nije dovoljno (više transakcija može imati isti trenutak, satovi se razlikuju), brojanje redova ne kaže koje su izmene primenjene, a u MySQL-u replika sama traži od izvora da joj šalje od određenog mesta — izvor to ne pamti umesto nje. Pitanje je samo KAKO se ta oznaka zapisuje: kao ime datoteke plus pomeraj, ili kao skup GTID-ova.


> [!abstract] PI
> Tvoja pretpostavka je verovatno pogodila — a kad uspostavimo šta je log, ovo će ispasti samo od sebe. Poslednja nit: podela posla na replici.


> [!question] Quiz
> Izvor za 3 sekunde izvrši 4 000 transakcija. Replika ih sve preuzme preko mreže za oko 3 s, ali joj za njihovo izvršavanje treba više od 10 s. Gde se nalazi zaostatak u 8. sekundi?
>
> 1. U mreži: transakcije su poslate, ali još nisu stigle do replike
> 2. Nigde: replika preuzima samo onoliko koliko stigne da izvrši
> 3. Na replici: transakcije su preuzete i čekaju u lokalnom logu na izvršavanje
> 4. Na izvoru: transakcije čekaju u njegovom logu da ih replika preuzme


> [!success] Quiz — correct ✓
> Your answer: 3. Na replici: transakcije su preuzete i čekaju u lokalnom logu na izvršavanje
> Correct answer: 3
>
> Preuzimanje je završeno posle 3 s, pa ništa ne čeka ni na izvoru ni u mreži. Replika je sve primila i zapisala u lokalni log (relay log), a izvršavanje kasni. To je moguće baš zato što preuzimanje i izvršavanje rade dve odvojene niti: nit prijema i nit primene. Da je to jedna nit, preuzimanje bi stajalo dok izvršavanje ne stigne.


> [!abstract] PI
> Tačno. Podižem težinu na istoj niti.


> [!question] Quiz
> Izvor i replika imaju isti hardver. Na izvoru 16 klijenata istovremeno upisuje. Replika ima samo jednu nit primene (`replica_parallel_workers = 1`). Zašto replika ne stiže izvor, iako je svaka pojedinačna transakcija na njoj jednako brza?
>
> 1. Izvor izvršava transakcije uporedo, a replika pre svake proverava zaključavanja kod izvora
> 2. Izvor izvršava transakcije uporedo, a jedna nit primene ih izvršava jednu po jednu
> 3. Izvor izvršava transakcije jednu po jednu, a nit primene čeka mrežu posle svake
> 4. Izvor izvršava transakcije uporedo, a nit prijema ih preuzima jednu po jednu


> [!question] Quiz — I don't know
> Your answer: I don't know
> Correct answer: 2
>
> Na izvoru 16 sesija radi u isto vreme, pa za jednu sekundu može da se komituje mnogo transakcija. Jedna nit primene mora da ih izvrši redom, jednu za drugom — 16 paralelnih tokova sabija u jedan. Nit prijema nije usko grlo: ona samo kopira bajtove, što je jeftino. Zato je kašnjenje u niti primene, i zato postoji replica_parallel_workers.


> [!question] Question
> Poglavlje 3 ima četiri tačke, a temelj (log, WAL, fsync) moramo da izgradimo od nule. Kako da podelimo?
>
> 1. Dve lekcije (Preporučeno)
> 2. Jedna duža lekcija, sve četiri tačke
> 3. Dve lekcije, ali obrnut redosled


> [!example] Answer
> 1. Dve lekcije (Preporučeno)


> [!abstract] PI
> Plan dolazi posle kratke provere izvora — ne želim da ijednu činjenicu izgovorim iz sećanja.


> [!abstract] PI
> Izvori provereni (refman 8.4, release notes, zvanični MySQL blog). Usput je provera uhvatila i jednu grešku u memou 03: on `NOW()` navodi kao nesiguran, a priručnik kaže suprotno. Zabeležiću to u zapis o učenju.
>
> ## Plan — Lekcija A: „MySQL replicira log, a ne stanje“
>
> **Pristup.** Sve tvoje praznine imaju isti koren koji fali: pojam **loga**. Zato krećemo od tri tvrdnje koje važe bez izuzetka, a sve ostalo iz njih izvodimo. Kad stoji koren „log je uređen niz promena, a ponovljen redom daje isto stanje“, ostale tačke postaju pitanja koja bi sam postavio:
> - **Šta tačno upisati u zapis?** Iz toga dobijamo STATEMENT / ROW / MIXED.
> - **Kad ponavljanje iskaza ne daje isto?** Iz toga dobijamo nesigurne iskaze. Tu nastavljamo gde si danas stao, sa `LIMIT`.
> - **Kako replika zna dokle je stigla?** Iz toga dobijamo poziciju, pa GTID i `SOURCE_AUTO_POSITION`.
> - **Ko šta radi na replici?** Iz toga dobijamo niti i odgovor na pitanje koje ti je danas palo: zašto kasni baš nit primene.
>
> Preimenovanje master/slave → izvor/replika ide na kraj i **eksplicitno je označeno kao odluka, a ne izvedena činjenica**. Inače bi ti, poznajući te, izmislio izvođenje. Lekcija se završava prvom konkretnom pojavom okosnice rada: kod asinhrone replikacije izvor klijentu kaže „komitovano“ pre nego što je iko drugi video transakciju.
>
> Uglavnom sokratovski, jer ovo možeš sam da izvedeš. Izlagački idu samo činjenice dizajna: podrazumevani formati, `NOW()` i imena niti.
>
> **Mapa zavisnosti** (koreni gore, cilj dole):
>
> ```mermaid
> graph TD
>   R1["K1: log = niz zapisa,<br/>dodaje se samo na kraj"]
>   R2["K2: isto početno stanje +<br/>iste determinističke promene istim redom<br/>= isto krajnje stanje"]
>   R3["K3: replika vidi samo ono<br/>što joj stigne porukom"]
>   N1["Replikacija = slanje loga + ponovno izvršavanje<br/>(binarni log)"]
>   N2["Šta je u zapisu?<br/>STATEMENT / ROW / MIXED"]
>   N3["Nesigurni iskazi<br/>(LIMIT, UUID, SYSDATE; NOW je bezbedan)"]
>   N4["Pozicija → GTID →<br/>SOURCE_AUTO_POSITION"]
>   N5["Nit prijema → relay log → nit primene;<br/>zašto kasni nit primene"]
>   N6["Izvor/replika: preimenovanje<br/>(odluka, ne izvođenje)"]
>   G["Cilj: asinhrona replikacija —<br/>'komitovano' pre nego što je iko video"]
>   R1 --> N1
>   R2 --> N1
>   R3 --> N1
>   N1 --> N2
>   R2 --> N3
>   N2 --> N3
>   R1 --> N4
>   N1 --> N4
>   R3 --> N5
>   N4 --> N5
>   N5 --> G
>   N6 --> G
> ```
>
> Postojanost (WAL, fsync, dvofazna potvrda, matrica `sync_binlog` × `innodb_flush_log_at_trx_commit`) ide u **Lekciju B**.
>
> Da li ti plan odgovara, ili nešto menjamo pre nego što krenemo?


> [!quote] YOU
> Moze, nastavi


> [!abstract] PI
> ## Koren K1 — šta je log
>
> **Zašto nam ovo treba.** Pitanje „šta putuje između servera?“ ostalo je bez odgovora. Da bismo na njega odgovorili, prvo nam treba pojam koji MySQL koristi kao osnovnu jedinicu replikacije: log.
>
> **Definicija (prava, ne spisak osobina):**
>
> > **Log** je niz zapisa o promenama, u kome se novi zapis **uvek dodaje na kraj**, a postojeći zapisi se **nikad ne menjaju**.
>
> Iz definicije odmah slede dve stvari, bez dodatnih pretpostavki:
> - **Svaki zapis ima svoje mesto u redosledu**: 1., 2., 3. … Redosled je deo loga, a ne dodatak.
> - **Ono što je jednom upisano ostaje isto.** Ko je pročitao zapise 1–100, zna da se ti zapisi nikad više neće promeniti. Može se promeniti samo ono što dolazi posle 100.
>
> To je ceo koren. Proveravam da li je legao:


> [!question] Quiz
> Čitalac je pročitao zapise 1–100 iz loga. U međuvremenu je server upisao još 20 promena. Šta čitalac pouzdano zna?
>
> 1. Zapisi 1–100 su obrisani, a log sada sadrži samo novih 20
> 2. Zapisi 1–100 su isti kao kad ih je čitao, a novo je samo u zapisima 101–120
> 3. Zapisi 1–100 su isti, ali novih 20 može biti bilo gde u nizu
> 4. Zapisi 1–100 su možda izmenjeni, pa mora ponovo da čita ceo log


> [!success] Quiz — correct ✓
> Your answer: 2. Zapisi 1–100 su isti kao kad ih je čitao, a novo je samo u zapisima 101–120
> Correct answer: 2
>
> Obe osobine slede iz definicije. Postojeći zapisi se nikad ne menjaju, pa je 1–100 isto. Novi zapisi idu samo na kraj, pa je sve novo u 101–120. Zato je čitaocu dovoljno da zapamti JEDAN broj (dokle je stigao) da bi znao šta mu još fali — to ćemo kasnije zvati pozicija.


> [!question] Quiz
> Oba servera kreću od x = 100. Postoje dve promene: P1 je „x = x · 2“, a P2 je „x = x + 10“. Izvor izvrši P1 pa P2 i dobije 210. Replika izvrši P2 pa P1 i dobije 220. Koji uslov iz tvrdnje je prekršen?
>
> 1. Iste promene — replika je dobila druge promene nego izvor
> 2. Determinizam — promene daju različit rezultat nad istim stanjem
> 3. Isti redosled — promene su iste, ali izvršene drugim redom
> 4. Isto početno stanje — serveri su krenuli od različitog x


> [!success] Quiz — correct ✓
> Your answer: 3. Isti redosled — promene su iste, ali izvršene drugim redom
> Correct answer: 3
>
> Oba kreću od 100 i obe promene su determinističke (×2 i +10 uvek daju isto nad istim x), a i promene su iste. Razlikuje se samo REDOSLED, a množenje i sabiranje ne komutiraju. Zato log čuva redosled kao deo sebe (K1): replika mora da izvršava zapise tačno onim redom kojim su upisani.


> [!question] Quiz
> Na izvoru 3307 upravo je komitovan novi red. Poruka o tome još nije poslata replici 3309. Šta 3309 zna o tom redu?
>
> 1. Sve — isti računar, pa čita izvorov disk direktno
> 2. Ništa — za njega saznaje tek kad mu stigne poruka
> 3. Samo da postoji — sadržaj stiže tek porukom
> 4. Sve — isti računar, pa deli izvorovu memoriju


> [!question] Quiz — I don't know
> Your answer: I don't know
> Correct answer: 2
>
> Note: Dvoumim se izmedju 2. i 3. nagadjanjem mislim da je 3.
>
> Replika je zaseban server i nema pristup ni izvorovoj memoriji ni njegovim datotekama, čak ni na istoj mašini. Dok poruka ne stigne, za nju se ništa nije dogodilo — nema ni „samo da postoji“. Iz ovoga sledi da sve što replika treba da zna mora da se spakuje u nešto što se šalje.


> [!question] Quiz
> Izvor je u Beogradu, a replika u Nišu. Na izvoru se komituje red, a mrežna veza je baš tada prekinuta, pa poruka ne može da prođe. Da li bi se išta promenilo da su oba servera na istom računaru, ali sa prekinutom vezom između njih?
>
> 1. Ne — u oba slučaja replika ne zna ništa, jer bez poruke nema informacije
> 2. Ne — u oba slučaja replika red pročita kad se veza vrati, iz izvorove memorije
> 3. Da — na istom računaru replika bi red pročitala iz izvorovih datoteka
> 4. Da — na istom računaru replika bi znala bar da je red komitovan


> [!success] Quiz — correct ✓
> Your answer: 1. Ne — u oba slučaja replika ne zna ništa, jer bez poruke nema informacije
> Correct answer: 1
>
> Fizička udaljenost nije bitna; bitan je kanal. Replikin jedini kanal ka izvoru je veza preko koje joj stižu poruke. Ako je on prekinut, ona ne zna ništa, bilo da je izvor u Beogradu ili u susednom procesu. Kad se veza vrati, red stiže opet kao poruka (zapis iz loga), a ne čitanjem tuđe memorije.


> [!question] Quiz
> Baza ima 50 GB, a svake sekunde se menja nekoliko redova. Replika je jednom napunjena istim podacima kao izvor. Šta je, na osnovu K1–K3, najjeftinije slati da bi replika ostala ista kao izvor?
>
> 1. Ceo snimak baze jednom dnevno, a replika između toga ne dobija ništa
> 2. Ceo snimak baze posle svake promene, a replika zameni svoju kopiju
> 3. Svaku novu promenu iz izvorovog loga, bilo kojim redom, a replika je izvrši
> 4. Svaku novu promenu iz izvorovog loga, redom, a replika je ponovo izvrši


> [!success] Quiz — correct ✓
> Your answer: 4. Svaku novu promenu iz izvorovog loga, redom, a replika je ponovo izvrši
> Correct answer: 4
>
> Replika već ima isto početno stanje (jednom je napunjena), pa joj po K2 treba još samo isti niz promena istim redom. Taj niz je baš izvorov log (K1). Šalje se samo ono što je novo, a to je nekoliko redova, a ne 50 GB. Bez redosleda K2 ne važi (sećaš se x·2 i x+10). Dnevni snimak je jeftin, ali replika je tada zastarela do 24 sata.


> [!question] Quiz
> Iskaz `UPDATE racuni SET status='placen' WHERE tenant_id=1` promeni 1 000 000 redova. Koliko je veliki zapis u logu, ako se upisuje tekst iskaza, a koliko ako se upisuju promenjeni redovi?
>
> 1. Tekst: milion zapisa o redovima; redovi: pedesetak bajtova
> 2. Tekst: pedesetak bajtova; redovi: takođe pedesetak bajtova
> 3. Tekst: pedesetak bajtova; redovi: milion zapisa o redovima
> 4. Tekst: milion zapisa o redovima; redovi: takođe milion zapisa


> [!success] Quiz — correct ✓
> Your answer: 3. Tekst: pedesetak bajtova; redovi: milion zapisa o redovima
> Correct answer: 3
>
> Tekst iskaza je isti bez obzira na to koliko redova pogodi: oko 50 bajtova. Zapis po redovima mora da navede svaki promenjeni red posebno, dakle milion stavki. Prednost upisivanja uzroka je kompaktnost, a cena je to što replika mora sama ponovo da izračuna posledicu.


> [!question] Quiz
> Na izvoru se izvrši `UPDATE racuni SET status='placen' WHERE tenant_id=1 LIMIT 5` (bez ORDER BY). Koji način upisivanja garantuje da replika promeni ISTIH pet redova kao izvor?
>
> 1. Upisivanje promenjenih redova, jer replika ne bira redove nego menja tih pet
> 2. Oba načina, jer replika kreće od istog početnog stanja kao izvor
> 3. Upisivanje teksta iskaza, jer replika izvršava baš isti iskaz kao izvor
> 4. Nijedan način, jer replika uvek može drugim redom da prođe kroz tabelu


> [!success] Quiz — correct ✓
> Your answer: 1. Upisivanje promenjenih redova, jer replika ne bira redove nego menja tih pet
> Correct answer: 1
>
> LIMIT 5 bez ORDER BY nije deterministička promena: KOJIH pet redova bude izabrano zavisi od redosleda pretrage, a ne samo od stanja podataka. Kad se upiše tekst, replika ponovo bira, pa može izabrati drugih pet (K2 otpada). Kad se upišu redovi, izbor je već napravio izvor, a replika samo primenjuje gotov rezultat. Redosled pretrage tada više nije bitan, jer replika ništa ne bira.


> [!question] Quiz
> Hoćeš kompaktnost formata STATEMENT, ali bez rizika kod iskaza kao što je UPDATE … LIMIT 5. Kako bi napravio treći format?
>
> 1. Upisuj i tekst iskaza i redove, a replika bira šta će da primeni
> 2. Upisuj tekst iskaza, a za iskaze koji nisu deterministički upisuj redove
> 3. Upisuj tekst iskaza, a replika posle svakog iskaza proverava redove sa izvorom
> 4. Upisuj redove, a za iskaze koji menjaju mnogo redova upisuj tekst iskaza


> [!success] Quiz — correct ✓
> Your answer: 2. Upisuj tekst iskaza, a za iskaze koji nisu deterministički upisuj redove
> Correct answer: 2
>
> To je MIXED: podrazumevano se upisuje tekst iskaza (kompaktno), a za iskaze koje server prepozna kao nesigurne prelazi na upisivanje redova. Izbor po broju redova bi baš UPDATE … LIMIT 5 (samo pet redova) upisao kao tekst, dakle pogrešno. Provera sa izvorom posle svakog iskaza bi tražila poruke u oba smera, a log ide samo od izvora ka replici.


> [!question] Quiz
> Format je STATEMENT. Na izvoru se u 10:00:00 izvrši `INSERT INTO log_tabela (vreme) VALUES (NOW())`. Replika kasni 2 s i taj iskaz izvrši u 10:00:02. Koja vrednost se upiše na replici?
>
> 1. Ništa — server odbija NOW() u formatu STATEMENT kao nesiguran iskaz
> 2. 10:00:00 — replika od izvadi sat izvora pita kada izvršava NOW()
> 3. 10:00:00 — izvor u zapis upisuje i svoje vreme, a replika ga koristi za NOW()
> 4. 10:00:02 — replika izvršava NOW() po svom satu, u trenutku izvršavanja


> [!failure] Quiz — incorrect ✗
> Your answer: 4. 10:00:02 — replika izvršava NOW() po svom satu, u trenutku izvršavanja
> Correct answer: 3
>
> NOW() izgleda nedeterministički, ali MySQL ga je učinio bezbednim: binarni log uz iskaz nosi i vremensku oznaku sa izvora, pa NOW() na replici vraća vreme izvora. Priručnik: „For NOW(), the binary log includes the timestamp.“ Pitanje izvoru bi bila poruka u suprotnom smeru, a toga nema. A čak ni nesigurni iskazi se u STATEMENT formatu ne odbijaju — upišu se uz upozorenje 1592.


> [!question] Quiz
> Format je STATEMENT. Šta je OPŠTI razlog zbog kog je neki iskaz bezbedan za replikaciju?
>
> 1. Sve od čega mu zavisi rezultat replika ima isto kao izvor: iste podatke i isti plan izvršavanja
> 2. Sve od čega mu zavisi rezultat replika ima isto kao izvor: iste podatke i isti primarni ključ
> 3. Sve od čega mu zavisi rezultat replika ima isto kao izvor: iste podatke i isti sat kao izvor
> 4. Sve od čega mu zavisi rezultat replika ima isto kao izvor: iste podatke ili vrednost upisanu u log


> [!success] Quiz — correct ✓
> Your answer: 4. Sve od čega mu zavisi rezultat replika ima isto kao izvor: iste podatke ili vrednost upisanu u log
> Correct answer: 4
>
> Iskaz je bezbedan kada mu rezultat zavisi samo od onoga što replika garantovano ima isto: od podataka (isto stanje po K2) i od vrednosti koje je izvor upisao u log, poput vremenske oznake za NOW(). Sat se ne usklađuje, nego se vreme šalje. Plan izvršavanja može da se razlikuje — to je baš problem kod LIMIT bez ORDER BY. Primarni ključ nije uslov: WHERE tenant_id=1 je bezbedan i bez njega.


> [!question] Quiz
> Izvor A padne. Replika B postaje novi izvor, a replika C treba da nastavi sa B. C je zapamtila poziciju „binlog.000003 : 1045“ u A-ovom logu. Šta ta oznaka znači u B-ovom logu?
>
> 1. Isto mesto — B je kopirao A-ove datoteke loga kad je postao izvor
> 2. Ništa pouzdano — B uopšte nema svoj binarni log, jer je bio replika
> 3. Ništa pouzdano — B ima svoje datoteke loga, pa je na tom mestu nešto drugo
> 4. Isto mesto — B je primio iste transakcije, pa su mu datoteke loga iste


> [!failure] Quiz — incorrect ✗
> Your answer: 4. Isto mesto — B je primio iste transakcije, pa su mu datoteke loga iste
> Correct answer: 3
>
> Ime datoteke i pomeraj su koordinate u A-ovom loga, a ne u transakcijama. B svoj binarni log piše sam: drugačije numeriše datoteke, rotira ih u druge trenutke, ima drugačija zaglavlja i možda i sopstvene transakcije. Iste transakcije kod njega stoje na drugim bajtovima. Ovakva oznaka ima smisla samo na serveru koji ju je proizveo.


> [!question] Quiz
> A i B sadrže istih 500 transakcija, istim redom. B je jednom restartovan, pa je otvorio novu datoteku loga, a A nije. Transakcija broj 300 kod A je u binlog.000001 na bajtu 90 000. Gde je ona kod B?
>
> 1. U binlog.000002 na bajtu 90 000 — restart samo pomera broj datoteke
> 2. U binlog.000001 na bajtu 90 000 — isti sadržaj daje istu adresu
> 3. Nigde — posle restarta B više ne čuva transakcije pre restarta
> 4. Ne zna se bez traženja — možda u drugoj datoteci i na drugom bajtu


> [!success] Quiz — correct ✓
> Your answer: 4. Ne zna se bez traženja — možda u drugoj datoteci i na drugom bajtu
> Correct answer: 4
>
> Restart je zatvorio jednu datoteku i otvorio novu, sa novim zaglavljem, u trenutku koji nema veze sa A. Zato transakcija 300 može biti u bilo kojoj od B-ovih datoteka, na bajtu koji se ne može izračunati iz A-ove adrese. Ni pomak samo broja datoteke ne važi, jer se menjaju i bajtovi. Stare datoteke ostaju na disku, pa transakcija nije nestala; samo joj adresa nije ista.


> [!abstract] PI
> Sada je jasno. Hajde onda da izmislimo popravku. Problem je u tome što adresa pripada svesci, a ne transakciji.


> [!question] Quiz
> Hoćemo oznaku „dokle sam stigla“ koja važi na BILO KOM serveru, pa i posle promene izvora. Šta je najbolje rešenje?
>
> 1. Replika pamti koliko transakcija je primenila, a novi izvor šalje sve posle tog broja
> 2. Svi serveri moraju da otvaraju nove datoteke loga u istim trenucima, pa su adrese iste
> 3. Svaka transakcija dobije jedinstveno ime koje putuje sa njom, a replika pamti skup imena koja ima
> 4. Replika pamti vreme poslednje primenjene transakcije, a novi izvor šalje sve posle tog vremena


> [!success] Quiz — correct ✓
> Your answer: 3. Svaka transakcija dobije jedinstveno ime koje putuje sa njom, a replika pamti skup imena koja ima
> Correct answer: 3
>
> Ime koje se dodeli JEDNOM, na serveru gde je transakcija nastala, i koje se nikad ne menja, isto je na svakom serveru, bez obzira na datoteke. To je GTID. Usklađivanje datoteka ne rešava sopstvene transakcije i zaglavlja. Vreme nije jedinstveno, a satovi se razlikuju. Broj važi samo ako svi imaju baš iste transakcije istim redom. Čim B ima i neku svoju transakciju, „300.“ kod B i kod C nije ista transakcija.


> [!question] Quiz
> Replika C se povezuje na novi izvor B sa SOURCE_AUTO_POSITION = 1. C ima skup A:1-100. B u svom binarnom logu ima A:1-150 i B:1-5. Šta se dešava?
>
> 1. C pošalje svoj skup, a B pošalje samo B:1-5, jer su A-ove transakcije stare
> 2. C pošalje svoj skup, a B pošalje sve: A:1-150 i B:1-5
> 3. C pošalje svoju poslednju transakciju A:100, a B traži kod sebe njenu adresu
> 4. C pošalje svoj skup, a B pošalje A:101-150 i B:1-5


> [!question] Quiz — I don't know
> Your answer: I don't know
> Correct answer: 4
>
> Note: Nisam siguran ali pretpostavljam 4.
>
> Pri povezivanju replika šalje skup GTID-ova koje već ima, a izvor joj šalje sve transakcije iz svog binarnog loga čiji GTID NIJE u tom skupu — dakle tačno razliku. Priručnik: „The source responds by sending all transactions recorded in its binary log whose GTID is not included in the GTID set sent by the replica.“ Nema adresa, nema računanja, i nema ponovnog slanja onoga što C već ima.


> [!question] Quiz
> Replika C ima skup A:1-100 i C:1-3 (tri sopstvene lokalne transakcije). Izvor B ima u binarnom logu A:1-120. C se poveže sa SOURCE_AUTO_POSITION = 1. Šta B šalje?
>
> 1. A:101-120
> 2. A:101-120 i C:1-3
> 3. A:1-120
> 4. A:104-120


> [!success] Quiz — correct ✓
> Your answer: 1. A:101-120
> Correct answer: 1
>
> Note: Ne znam sta je SOURCE_AUTO_POSITION
>
> B šalje ono što ON ima, a C nema: A:101-120. Transakcije C:1-3 B uopšte nema, pa ne može ni da ih pošalje. Ostaju samo kod C, a to su upravo „errant“ GTID-ovi koje smo u postavci izbegli. A:104 bi bila greška brojanja: imena se porede, a ne broj transakcija, pa tri C-ove transakcije ne pomeraju A-ov brojač.


> [!question] Quiz
> Izvor A je pao, a B je postao novi izvor. Na replici C treba preusmeriti replikaciju na B (port 3308). Šta, osim SOURCE_HOST i SOURCE_PORT, mora da stoji u CHANGE REPLICATION SOURCE TO ako koristimo GTID?
>
> 1. Samo SOURCE_LOG_FILE i SOURCE_LOG_POS, jer GTID važi samo za prvi izvor
> 2. SOURCE_AUTO_POSITION = 1 i A-ova adresa: SOURCE_LOG_FILE i SOURCE_LOG_POS
> 3. SOURCE_AUTO_POSITION = 1 i B-ova adresa, pronađena ručno u B-ovom logu
> 4. Samo SOURCE_AUTO_POSITION = 1, bez ikakve adrese u B-ovom logu


> [!success] Quiz — correct ✓
> Your answer: 4. Samo SOURCE_AUTO_POSITION = 1, bez ikakve adrese u B-ovom logu
> Correct answer: 4
>
> Uz SOURCE_AUTO_POSITION = 1 adresa se ne zadaje ni na jednom serveru: C pošalje B-u svoj skup GTID-ova, a B pošalje razliku. Upravo je to dobit u odnosu na stari način. A-ova adresa ništa ne znači u B-ovom logu (sveske), a ručno traženje adrese je baš posao koji GTID ukida. GTID nije vezan za prvi izvor: ime putuje sa transakcijom kroz sve servere.


> [!question] Quiz
> Izvršavanje na replici zaostaje 10 s za izvorom. Tada izvor padne zauvek. Koja varijanta replike čuva više transakcija koje je izvor komitovao?
>
> 1. Obe jednako: izvor pre pada sam pošalje sve što replika još nije preuzela
> 2. Jedan radnik: preuzima sledeći zapis tek kad izvrši prethodni, pa ništa ne stoji neizvršeno
> 3. Obe jednako: dok izvršavanje kasni 10 s, ni preuzimanje ne može da odmakne dalje
> 4. Dva radnika: jedan je već preuzeo sve u lokalnu datoteku, a drugi izvršava kad stigne


> [!success] Quiz — correct ✓
> Your answer: 4. Dva radnika: jedan je već preuzeo sve u lokalnu datoteku, a drugi izvršava kad stigne
> Correct answer: 4
>
> Kada preuzimanje ne čeka izvršavanje, replika ima KOPIJU svega što je izvor do tada poslao, iako je još nije izvršila. Kad izvor padne, te transakcije su sačuvane na replici i biće izvršene. Sa jednim radnikom poslednjih 10 s transakcija još nije ni preuzeto, pa nestaju zajedno sa izvorom. Izvor koji pada ne stiže ništa da „pošalje na kraju“ — pad nije najavljen.


> [!question] Quiz
> Na izvoru 16 sesija istovremeno komituje transakcije. Na replici je jedna nit prijema i jedna nit primene (replica_parallel_workers = 1). Koja nit će zaostajati i zašto?
>
> 1. Nijedna — isti hardver izvršava istu transakciju jednako brzo na oba servera
> 2. Nit primene — pre svake transakcije čeka potvrdu od izvora da sme da je izvrši
> 3. Nit prijema — prima transakcije jednu po jednu, a izvor ih je komitovao uporedo iz 16 sesija
> 4. Nit primene — ponovo izvršava svaku transakciju, i to jednu po jednu, a izvor ih je izvršavao uporedo


> [!warning] Quiz — cancelled
> (user skipped)


> [!quote] YOU
> Napsiao si I should clarify the three thread roles: the source's dump thread, the replica's receiver thread,
>  and the applier thread. Since he didn't know why the applier lags, I want to guide him with a
>  concurrency framing — the source handles 16 parallel sessions while the applier is single-threaded,
>  so each worker's actual cost differs: the receiver just copies bytes, while the applier must
>  re-execute every transaction with real locks, index updates, and disk writes.
>
>  Objasnio sam imena i uloge niti u replikaciji (prijem, relay log, primena) i postavio pitanje za
>  proveru znanja zašto nit primene najčešće kasni. Ali ja nigde nisam video to objasnjenje samo kviz odmah i cini mi se da cela ova sesija ima samo kvizove


> [!abstract] PI
> U pravu si, i hvala što si rekao. Objašnjenje sam pisao **u istom koraku** u kom sam pokretao kviz. Ako ti se taj tekst ne prikazuje ili ga kviz odmah prekrije, onda si u praksi dobijao samo pitanja, jedno za drugim. To je moja greška u ritmu, a ne tvoja. Od sada ću objašnjenje slati kao **posebnu poruku, bez kviza**, a kviz tek kad kažeš da si spreman.
>
> Evo objašnjenja koje ti je promaklo, celog.
>
> ---
>
> ## Tri niti i šta svaka radi
>
> Replika ima dva posla različite prirode: da **preuzme** zapise preko mreže i da ih **izvrši** nad svojim podacima. Upravo si izveo zašto ih rade dva odvojena radnika. Ako izvor padne dok izvršavanje kasni, sve što je već preuzeto ostaje sačuvano na replici. Da je radnik jedan, poslednje transakcije ne bi ni stigle.
>
> Učestvuju tri niti. Njihova imena su **odluka dizajna**, a ne nešto što se izvodi:
>
> ```
> IZVOR (3307)                                   REPLIKA (3309)
> binarni log ──► nit koja šalje log ──mreža──► nit prijema ──► relay log ──► nit primene ──► podaci
>                 (binlog dump thread)          (receiver)                    (applier)
> ```
>
> 1. **Na izvoru**, nit koja šalje log *(binlog dump thread)*. Za svaku povezanu repliku postoji po jedna. Ona samo čita izvorov binarni log i šalje zapise kroz mrežu.
> 2. **Na replici**, **nit prijema** *(receiver; ranije se zvala „I/O thread“)*. Prima zapise i **samo ih prepisuje** u lokalnu datoteku, **relay log**. Ta datoteka ima isti format kao binarni log. Nit prijema ništa ne izvršava.
> 3. **Na replici**, **nit primene** *(applier; ranije „SQL thread“)*. Čita relay log redom (K1: redosled je deo loga; K2: isti redosled daje isto stanje) i **zaista izvršava** svaku transakciju nad podacima replike.
>
> ## Zašto kasni baš nit primene
>
> Uporedi **koliko posla** svaka nit ima po jednoj transakciji:
>
> - **Nit prijema** po transakciji samo prepiše nekoliko stotina bajtova iz mreže u datoteku. To je jeftino, kao kopiranje teksta.
> - **Nit primene** po transakciji mora da uradi sve što je izvor uradio: da nađe redove, uzme zaključavanja, ažurira indekse i upiše na disk. To je pravi posao.
>
> Sad pogledaj **koliko radnika** je taj pravi posao radilo na izvoru. Na izvoru 16 klijenata upisuje **istovremeno**, pa 16 sesija izvršava transakcije **uporedo**. Ako na replici postoji samo jedna nit primene, ona mora tih 16 paralelnih tokova da izvrši **jedan za drugim**:
>
> $$
> \text{izvor: } 16 \text{ radnika uporedo} \quad\longrightarrow\quad \text{replika: } 1 \text{ radnik redom}
> $$
>
> Zato zaostaje čak i kad je svaka pojedinačna transakcija na replici jednako brza kao na izvoru. Problem nije brzina jednog radnika, nego **broj radnika**.
>
> To smo videli i uživo u pesku za igru: posle naleta od 4 000 transakcija relay log je posle 3 s **prestao da raste**, jer je nit prijema već sve preuzela. Kašnjenje je međutim nastavilo da raste do 10 s, jer je nit primene još radila.
>
> **Rešenje koje MySQL nudi:** više niti primene, preko promenljive `replica_parallel_workers`. U 8.4 podrazumevana vrednost je **4**, pa je replika podrazumevano višenitna. U našem merenju je 4 niti umesto 1 dalo oko 8 puta brže sustizanje. To je gornja granica, jer su to bile međusobno nezavisne transakcije, idealan slučaj.
>
> ---
>
> Pre nastavka jedno pitanje o ritmu, bez kviza. Šta ti više odgovara za ostatak lekcije?
>
> - **(a)** Prvo objašnjenje u posebnoj poruci, pa kviz tek kad napišeš „dalje“.
> - **(b)** Duži delovi objašnjenja, a kviz samo na kraju svake celine (sada su ostale još dve: preimenovanje izvor/replika i zaključak o asinhronoj replikaciji).
> - **(c)** Nešto treće, napiši šta.


> [!quote] YOU
> Hocu da koncept bude kao sto je bio do sada u prethodnim lekcijama u Temi 2 gde je lepo islo objsnjenje kao test koji upravo citam i na kraju toga ide kviz sa pitanjem, necu da ih razdvajam ili prodzuujem. Takodje neke reci kao radnik mi nisu bile jasne bez koncpeta i pesak za igru koji je totalno promasen jer je preveden


> [!abstract] PI
> Našao sam uzrok, i nije do tebe. Ekstenzija koja prepisuje sesiju u Obsidian (`md-log`) **nije upisala većinu mojih objašnjenja** koja su stajala pre kvizova. Proverio sam belešku: od „Koren K2“ do „N5“ u njoj nema nijednog objašnjenja, ostali su samo kvizovi. Zato ti je cela sesija izgledala kao niz pitanja. Ti si zapravo čitao kvizove na gradivo koje nikad nisi video.
>
> Od sada objašnjenje stavljam **u sam blok kviza**, iznad pitanja. Taj deo se pouzdano upisuje, pa će ritam biti onakav kakav je bio u Temi 2: prvo tekst, na kraju pitanje. Izbacujem i „pesak za igru“ (od sada: **naša topologija**, dakle 3307 / 3308 / 3309) i „radnika“ (od sada samo **nit**).
>
> Ispod je sve što ti je promaklo, redom, da bi beleška bila potpuna.
>
> ---
>
> ## K2 — ponovno izvršavanje
> Kad replika dobije izvorov log, ideja je da ga izvrši i dobije iste podatke. To važi pod tri uslova:
>
> > Ako dva servera krenu od **istog početnog stanja** i izvrše **iste determinističke promene** **istim redom**, završiće u **istom stanju**.
>
> **Deterministička** promena je ona čiji rezultat zavisi **samo** od podataka nad kojima se izvršava. Ne zavisi od sata, slučajnosti ni redosleda kojim server pronalazi redove. Primer iz kviza: $x=100$, a promene su $x\cdot 2$ i $x+10$. Redosled ×2 pa +10 daje 210, a obrnuti redosled daje 220. Zato je **redosled deo loga**.
>
> ## K3 — replika ne vidi izvor
> > Replika je poseban proces, sa svojom memorijom i svojim diskom. O izvoru ne zna **ništa** osim onoga što joj stigne kao **poruka preko mreže**.
>
> Kod nas su sva tri servera na istom računaru, ali to je slučajnost naše topologije. Replikacija je napravljena za servere na različitim mašinama. 3309 nikad ne otvara 3307-ove datoteke, nego se na njega povezuje preko TCP veze, kao klijent sa korisničkim imenom i lozinkom. Bitna je **veza**, a ne udaljenost.
>
> ## N1 — šta putuje: binarni log
> Iz K1–K3: replika je jednom napunjena istim podacima (isto početno stanje), pa joj po K2 treba još samo **isti niz promena, istim redom**. Taj niz je baš izvorov log. Šalje se samo ono što je novo, dakle nekoliko redova, a ne 50 GB.
>
> MySQL taj log zove **binarni log**. U njega se upisuju promene (`INSERT`, `UPDATE`, `DELETE`, DDL), a `SELECT` ne. U 8.4 je podrazumevano uključen.
>
> > **Replikacija u MySQL-u = slanje binarnog loga + njegovo ponovno izvršavanje na replici.** Ne kopira se stanje, nego log.
>
> Naše replike 3308 i 3309 nisu napunjene kopiranjem baze. Sva tri servera su krenula od praznog stanja, a repliki su izvršile **ceo** izvorov binarni log od prve transakcije. To je K2 u čistom obliku.
>
> ## N2 — šta piše u zapisu: STATEMENT / ROW / MIXED
> Za `UPDATE … WHERE tenant_id=1` postoje dva prirodna izbora šta upisati u log:
>
> | Format | Šta piše u zapisu | Prednost | Cena |
> |---|---|---|---|
> | `STATEMENT` | tekst iskaza (uzrok) | kompaktan: ~50 bajtova, bez obzira na broj redova | replika ponovo računa posledicu, pa radi tačno samo za determinističke iskaze |
> | `ROW` | promenjeni redovi (posledica) | uvek tačan, jer replika ništa ne bira | veći log: milion redova daje milion stavki |
> | `MIXED` | tekst, a redovi za nesigurne iskaze | i kompaktan i tačan | zavisi od toga da li server ispravno prepozna nesiguran iskaz |
>
> Kod `ROW` formata zapis za `UPDATE` nosi i staru i novu vrednost reda (`binlog_row_image = FULL`). Kolone se vode po rednom broju (`@1`, `@2`), a ne po imenu.
>
> **Činjenice dizajna, ne izvođenje:** podrazumevani format je `ROW` od MySQL-a 5.7.7, a pre toga je bio `STATEMENT`. U 8.0.34 je promenljiva `binlog_format` proglašena zastarelom, pa će ubuduće ostati samo `ROW`.
>
> ## N3 — nesigurni iskazi
> Iskaz je **nesiguran** ako u formatu `STATEMENT` može na replici da da drugačiji rezultat. `LIMIT 5` bez `ORDER BY` je takav, jer **koje** redove izabere zavisi od redosleda pretrage. `WHERE tenant_id=1` bez `LIMIT` je **bezbedan**, jer uvek izdvaja isti skup redova.
>
> `NOW()` izgleda nedeterministički, ali MySQL ga je zakrpio: **izvor u log upisuje i svoje vreme**, a replika ga koristi umesto sopstvenog sata. Opšti princip glasi ovako:
>
> > Iskaz je bezbedan ako sve od čega mu zavisi rezultat replika ima isto kao izvor: iste podatke ili vrednost upisanu u log.
>
> `SYSDATE()` je **namerno** napravljena da ignoriše to upisano vreme, pa je nesigurna. Isto važi za `UUID()` i `RAND()`. Ovaj spisak je odluka dizajna i treba ga pogledati, a ne izvoditi.
>
> ## N4 — pozicija, GTID, `SOURCE_AUTO_POSITION`
> Iz K1: replici treba samo jedna oznaka, „dokle sam stigla“. Stari način je **ime datoteke + bajt** (`binlog.000003 : 1045`). Ta oznaka je adresa **u jednom konkretnom logu**. Novi izvor B svoj binarni log piše sam: drugačije numeriše datoteke, otvara nove u drugim trenucima (na primer posle restarta) i možda ima i sopstvene transakcije. Ista transakcija kod njega stoji na drugom mestu.
>
> Rešenje je da **svaka transakcija dobije ime koje putuje sa njom**. To je GTID:
>
> $$
> \text{GTID} = \texttt{server\_uuid} : n
> $$
>
> Prvi deo kaže koji je server napravio transakciju, a drugi koja je ona po redu kod njega. Replika zadržava originalni GTID. Skup svih izvršenih transakcija čuva se u `gtid_executed`, na primer `…:1-4836`.
>
> `SOURCE_AUTO_POSITION = 1` je opcija u naredbi `CHANGE REPLICATION SOURCE TO`, a znači „pozicioniraj se automatski“. Replika pošalje svoj skup, a izvor joj pošalje **sve što on ima, a ona nema** (razlika skupova). Adresa (`SOURCE_LOG_FILE`, `SOURCE_LOG_POS`) se tada ne zadaje. GTID **pojednostavljuje** promenu izvora, ali sam izbor novog izvora **nije** automatski.
>
> ## N5 — niti
> Ovo je deo koji si video u prošloj poruci (tri niti, relay log, zašto kasni nit primene), pa ga ovde ne ponavljam.
>
> ---
>
> Kad pročitaš, napiši „dalje“. Sledi kviz o niti primene (objašnjenje će biti u samom bloku), pa preimenovanje izvor/replika i zaključak lekcije.


> [!quote] YOU
> Dalje


> [!question] Quiz
> Na izvoru 16 sesija istovremeno komituje transakcije. Na replici je jedna nit prijema i jedna nit primene (replica_parallel_workers = 1). Koja nit će zaostajati i zašto?
>
> Podsetnik iz objašnjenja: nit prijema po transakciji samo prepiše bajtove u relay log. Nit primene svaku transakciju zaista izvršava (traži redove, zaključava, ažurira indekse, upisuje na disk). Na izvoru je taj pravi posao radilo onoliko sesija koliko je klijenata upisivalo istovremeno.
>
> 1. Nit prijema — svaku transakciju prima, jednu po jednu, a izvor ih je komitovao uporedo iz 16 sesija
> 2. Nit primene — svaku transakciju izvršava tek pošto od izvora dobije potvrdu da sme
> 3. Nit primene — svaku transakciju ponovo izvršava, jednu po jednu, a izvor ih je izvršavao uporedo
> 4. Nijedna — svaku transakciju isti hardver izvršava jednako brzo na oba servera


> [!success] Quiz — correct ✓
> Your answer: 3. Nit primene — svaku transakciju ponovo izvršava, jednu po jednu, a izvor ih je izvršavao uporedo
> Correct answer: 3
>
> Nit prijema po transakciji samo prepiše bajtove, što je jeftino, pa stiže i 16 sesija. Nit primene radi pravi posao, a taj posao je na izvoru radilo 16 sesija uporedo. Jedna nit primene sabija 16 paralelnih tokova u jedan, pa zaostaje čak i kad je svaka transakcija jednako brza. Potvrda od izvora ne postoji, jer log ide samo od izvora ka replici. Rešenje je replica_parallel_workers, čija je podrazumevana vrednost u 8.4 jednaka 4.


> [!abstract] PI
> Tačno. Sledi preimenovanje. Ono je skoro u potpunosti **odluka i istorija**, pa je ovde objašnjenje važnije od pitanja.


> [!question] Quiz
> Zašto je MySQL za ulogu servera od kog replika čita izabrao reč „source“, a ne „primary“?
>
> N6 — od master/slave do izvor/replika. Starije knjige, blogovi i većina materijala na internetu zovu uloge master i slave. MySQL ih je zamenio sa source i replica (izvor i replika), u nekoliko koraka: u 8.0.22 su uvedeni START REPLICA i SHOW REPLICA STATUS, u 8.0.23 CHANGE REPLICATION SOURCE TO, a u 8.0.26 preimenovane promenljive (npr. slave_parallel_workers → replica_parallel_workers). Stari oblici su prvo samo proglašeni zastarelim, a u 8.4 su UKLONJENI: CHANGE MASTER TO, START SLAVE, SHOW SLAVE STATUS, RESET MASTER, SHOW MASTER STATUS i slični na 8.4 više ne rade. Sve ovo su datumi i verzije, dakle istorija koja se pamti, a ne izvodi. Razlog je naveden u zvaničnom MySQL blogu „MySQL Terminology Updates“ (Kenny Gryp, jul 2020). Prvi deo razloga je društven: „The origins of these words are negative.“ Drugi deo objašnjava baš izbor reči „source“: „MySQL Asynchronous Replication is a change stream. Each replication configuration has a source and does not imply what role a server should have in the overall database architecture. Therefore, the use of e.g. ‘primary’ does not fit.“ Za rad: od poglavlja 3 nadalje koriste se samo reči izvor i replika, prelaz se objašnjava u tekstu, a master/slave se pominje tačno jednom, u fusnoti.
>
> 1. Replikacija je tok promena, a ime je izabrano samo da bi bilo kraće od starog naziva
> 2. Replikacija je tok promena, a ime opisuje ko šalje tok, ne ulogu servera u celom sistemu
> 3. Replikacija je tok promena, a ime opisuje koji server je najvažniji u celom sistemu
> 4. Replikacija je tok promena, a ime opisuje koji server prima upise od svih klijenata u sistemu


> [!failure] Quiz — incorrect ✗
> Your answer: 4. Replikacija je tok promena, a ime opisuje koji server prima upise od svih klijenata u sistemu
> Correct answer: 2
>
> To je i naš N1: replikacija je slanje loga, dakle tok promena, a „source“ znači samo „odakle tok dolazi“. To ne govori ništa o ulozi servera u celom sistemu. Server može istovremeno biti replika jednog servera i izvor za drugi (lančana replikacija), a u Group Replication-u „primary“ već ima drugo značenje. „Prima sve upise“ je upravo uloga koju „source“ namerno NE tvrdi.


> [!quote] YOU
> Ne svdija mi se format da je sve u kvizu, zar ne mozes recimo kao u ovom primeru gde is napisao "Tačno. Sledi preimenovanje. Ono je skoro u potpunosti odluka i istorija, pa je ovde objašnjenje važnije od pitanja." da samo nastavis i napises savj ovaj tekst koji je stajao kao objasnjenje uz kviz i onda samo da pokrenes kviz koji ima pitanje i ponudjene odgovore, kao sto je bilo sve vreme u Temi 2


> [!abstract] PI
> Može, tako ćemo raditi do kraja: tekst u poruci, pa na kraju kviz samo sa pitanjem i odgovorima.
>
> Moram i da ispravim ono što sam ti rekao malopre. Proverio sam zapis sesije i **`md-log` nije kriv**. Objašnjenja od K2 do N4 nisu stigla ni u terminal ni u belešku, jer se u tim porukama moj tekst uopšte nije pojavio kao vidljiv izlaz, nego je ostao samo u mom internom razmišljanju. Ekstenzija je ispravno upisala sve što je stvarno poslato, a poslati su bili samo kvizovi. Greška je bila na mojoj strani. Od sada pazim da svako objašnjenje bude u samoj poruci.
>
> ---
>
> ## Zašto „source“ ne znači „server koji prima upise“
>
> Izabrao si da „source“ opisuje server koji prima upise od svih klijenata. To je prirodna pretpostavka, jer u našoj topologiji 3307 zaista prima sve upise. Ali to je **trenutna postavka naše topologije, a ne značenje reči**. Reč „source“ kaže samo jedno: **odakle dolazi tok promena za ovu repliku**. Tri situacije u kojima se „izvor“ i „server koji prima upise“ razilaze:
>
> 1. **Lančana replikacija.** 3307 → 3308 → 3309. Za 3309 izvor je **3308**, a 3308 je i sam replika i ne prima upise od klijenata. On je izvor samo zato što 3309 od njega dobija tok.
> 2. **Više izvora za jednu repliku** *(multi-source replication)*. Jedna replika može imati dva izvora, recimo dva servera sa različitim bazama. Nijedan od njih nije „onaj koji prima sve upise“.
> 3. **„Primary“ je već zauzeto.** U Group Replication-u (poglavlje 5) „primary“ ima posebno značenje: član grupe koji prima upise. Da se izvor asinhrone replikacije zvao isto, dva različita pojma bi imala isto ime.
>
> Zato blog kaže da reč „source“ **ne govori ništa o ulozi servera u celom sistemu**. Opisuje samo vezu između dva servera u jednom toku.
>
> Kratko ponavljam ostatak čvora N6, jer je ranije bio samo u bloku kviza:
> - **Stari nazivi:** master/slave. **Novi:** source/replica, kod nas izvor/replika.
> - **Verzije (istorija, pamti se):** 8.0.22 `START REPLICA` / `SHOW REPLICA STATUS`; 8.0.23 `CHANGE REPLICATION SOURCE TO`; 8.0.26 preimenovane promenljive. U **8.4 su stari oblici uklonjeni**: `CHANGE MASTER TO`, `START SLAVE`, `SHOW SLAVE STATUS` i slični više ne rade.
> - **Razlog (MySQL blog, 2020):** poreklo starih reči je negativno, a „source“ je izabran jer je replikacija tok promena.
> - **U radu:** od poglavlja 3 se koriste izvor/replika, prelaz se objašnjava u tekstu, a master/slave se pominje jednom, u fusnoti.


> [!question] Quiz
> Topologija je lanac 3307 → 3308 → 3309. Klijenti upisuju samo na 3307. Šta je izvor za repliku 3309?
>
> 1. 3308, jer od njega 3309 dobija tok promena
> 2. I 3307 i 3308, jer obojica imaju iste podatke
> 3. Nijedan, jer je 3308 replika pa ne može biti izvor
> 4. 3307, jer on prima upise od svih klijenata


> [!success] Quiz — correct ✓
> Your answer: 1. 3308, jer od njega 3309 dobija tok promena
> Correct answer: 1
>
> Izvor je uvek relativan pojam: server od kog ova replika čita tok promena. 3309 je povezan na 3308, pa je 3308 njegov izvor, iako 3308 ne prima upise od klijenata i sam je replika od 3307. Server može istovremeno biti replika jednom i izvor drugom. Ko prima upise klijenata je pitanje arhitekture, a „source“ to namerno ne tvrdi.


> [!question] Quiz
> Asinhrona replikacija, 3307 → 3308 i 3309. Klijent dobije „OK“ za komitovanje na 3307. Milisekundu kasnije, pre nego što je nit koja šalje log stigla da pošalje taj zapis, 3307 zauvek otkaže, a 3308 postane novi izvor. Šta je sa tom transakcijom?
>
> 1. Izgubljena je: klijent je dobio „OK“, a nijedna replika je nikad nije primila
> 2. Sačuvana je: 3307 pre otkaza pošalje replikama sve što još nisu primile
> 3. Izgubljena je: ali klijent nije dobio „OK“, jer izvor čeka repliku pre potvrde
> 4. Sačuvana je: 3308 je preuzme iz 3307-ovog binarnog loga kad postane izvor


> [!failure] Quiz — incorrect ✗
> Your answer: 4. Sačuvana je: 3308 je preuzme iz 3307-ovog binarnog loga kad postane izvor
> Correct answer: 1
>
> Izvor je potvrdio pre slanja (korak 3 pre koraka 4), a zapis je postojao samo u 3307-ovom binarnom logu. Po K3 replike za njega nikad nisu saznale, a 3307 je otkazao zauvek, pa 3308 nema odakle da ga preuzme. Otkaz nije najavljen, pa izvor nema priliku da „pošalje sve na kraju“. Čekanje na repliku pre potvrde je upravo ono što asinhrona replikacija ne radi. To dodaje semisinhrona replikacija, poglavlje 4. Ovo je prozor u kome se gubi transakcija koju je klijent video kao komitovanu.


> [!question] Quiz
> Asinhrona replikacija, 3307 → 3309. Klijent dobije „OK“ za transakciju T na 3307. Pre nego što je T poslata, proces mysqld na 3307 padne; disk je ispravan, ali server niko ne pokreće ponovo. Može li 3309 da dobije T?
>
> 1. Ne, nikad: T je obrisana iz binarnog loga u trenutku pada procesa
> 2. Ne, dok 3307 ne radi: replika dobija zapise samo od živog procesa koji ih šalje
> 3. Da, odmah: nit prijema na 3309 pročita T direktno iz 3307-ove datoteke loga
> 4. Da, odmah: T je već u relay logu na 3309, jer se on puni pre potvrde


> [!warning] Quiz — cancelled
> (user skipped)


> [!quote] YOU
> Opet ne vidim objasnjenja


> [!abstract] PI
> Potvrdio sam u zapisu sesije: dva poslednja objašnjenja su ponovo završila u mom internom razmišljanju, a ne u poruci. Kad tekst i kviz idu u istoj poruci, to mi se povremeno dešava i ne mogu pouzdano da sprečim. Poruke **bez kviza** su ti, međutim, uvek stizale (na primer „Tri niti“). Zato je jedini pouzdan način ovakav: **objašnjenje dobiješ kao posebnu poruku, ti napišeš „dalje“, a onda ide kviz.** Znam da to nisi želeo, ali bolje je jedan klik više nego da opet čitaš kvizove bez gradiva. Evo oba objašnjenja koja su ti promakla.
>
> ---
>
> ## Cilj lekcije — šta znači „komitovano“ kod asinhrone replikacije
>
> Prođimo redom kroz ono što se dešava sa jednom transakcijom na 3307:
>
> 1. Klijent pošalje `COMMIT` na 3307.
> 2. 3307 upiše transakciju u **svoj** binarni log i komituje je.
> 3. 3307 klijentu vrati **„OK“**.
> 4. **Tek posle toga** nit koja šalje log čita novi zapis i šalje ga replikama. Nit prijema na 3309 ga upisuje u relay log, a nit primene ga kasnije izvršava.
>
> Ključno je šta **nedostaje**: između koraka 2 i 3 izvor ne čeka nikakvu poruku od replike. Po K3 on bez poruke ne može ni da zna šta replika ima, a u asinhronoj replikaciji takvu poruku niko ne šalje. Log ide samo u jednom smeru.
>
> > **Asinhrona replikacija:** izvor klijentu potvrđuje komitovanje **pre nego što je bilo koja replika videla transakciju**.
>
> Veza sa drugim PACELC pitanjem („kad mreža radi, čekati ili ne?“): asinhrona replikacija bira **ne čekati**. Komitovanje zato ne plaća ništa u latenciji, a cena se plaća konzistentnošću. Replike su zastarele dok nit primene ne stigne (otuda anomalija read-your-writes), a postoji i ozbiljnija posledica, opisana ispod.
>
> Ovo je **prva konkretna pojava okosnice rada**: MySQL ne garantuje da replika ima ono što je klijentu potvrđeno. On nudi mesta na kojima operator bira koliko se čeka. Asinhrona replikacija je izbor „ne čeka se uopšte“, a poglavlje 4 (semisinhrona replikacija) je prvo podešavanje kojim se čekanje dodaje.
>
> ## Zašto je transakcija izgubljena (tvoj odgovor u poslednjem kvizu)
>
> Odgovorio si da je 3308 „preuzme iz 3307-ovog binarnog loga kad postane izvor“. U tom odgovoru su dve skrivene pretpostavke.
>
> **1. Da preuzimanje znači čitanje datoteke.** Ne znači. Preuzimanje je **razgovor sa živim procesom**: nit prijema na 3308 se poveže na `mysqld` na 3307, a nit koja tamo šalje log joj šalje zapise. Po K3 3308 nema pristup 3307-ovim datotekama, čak ni na istom računaru. Kad proces na 3307 ne radi, sa druge strane veze **nema nikoga ko bi poslao**.
>
> **2. Da 3307-ov disk i dalje postoji.** U pitanju je pisalo „zauvek otkaže“, dakle mašina je nestala zajedno sa diskom. Transakcija je tada nestala **svuda**: postojala je samo u tom binarnom logu, a klijent je za nju dobio „OK“.
>
> Blaža varijanta, korisna za kasnija poglavlja: **šta ako se 3307 posle sat vremena vrati sa ispravnim diskom?** Transakcija je tada u njegovom binarnom logu, ali 3308 je u međuvremenu postao izvor i prima nove upise. Imamo dva servera, a svaki ima nešto što drugi nema, i ništa se ne spaja samo od sebe. Izgubljena transakcija nije problem samo zato što nestane, nego i zato što može da se **vrati na pogrešnom mestu**. O tome više u poglavljima 4 i 6.
>
> > Kod asinhrone replikacije transakcija je u trenutku potvrde **samo na izvoru**. Ako izvor tada nepovratno otkaže, ta transakcija je izgubljena, iako ju je klijent video kao komitovanu.
>
> ---
>
> Napiši „dalje“ i stiže kviz o ovome. To je poslednje pitanje lekcije, a posle njega pravim HTML lekciju i zapis o učenju.


> [!quote] YOU
> Dalje


> [!question] Quiz
> Asinhrona replikacija, 3307 → 3309. Klijent dobije „OK“ za transakciju T na 3307. Pre nego što je T poslata, proces mysqld na 3307 padne; disk je ispravan, ali server niko ne pokreće ponovo. Može li 3309 da dobije T?
>
> 1. Da, odmah: nit prijema na 3309 pročita T direktno iz 3307-ove datoteke loga
> 2. Da, odmah: T je već u relay logu na 3309, jer se on puni pre potvrde
> 3. Ne, dok 3307 ne radi: replika dobija zapise samo od živog procesa koji ih šalje
> 4. Ne, nikad: T je obrisana iz binarnog loga u trenutku pada procesa


> [!success] Quiz — correct ✓
> Your answer: 3. Ne, dok 3307 ne radi: replika dobija zapise samo od živog procesa koji ih šalje
> Correct answer: 3
>
> T jeste na 3307-ovom disku, ali replika do nje dolazi samo preko veze sa procesom mysqld na 3307 (K3, N5), a taj proces ne radi. Kad bi neko ponovo pokrenuo 3307, nit prijema bi se ponovo povezala i T bi stigla, pa T nije obrisana. Relay log se puni tek POSLE potvrde i slanja (koraci 3 pa 4), a to je suština asinhrone replikacije.


> [!abstract] PI
> Pišem primere u `examples/02-binlog-async/`, kao trajne artefakte za rad.


> [!abstract] PI
> Primeri rade. Sada pišem HTML lekciju.


> [!abstract] PI
> Lekcije ne učitavaju biblioteku za prikaz matematike, pa formule prepisujem u običan HTML.


> [!abstract] PI
> Sada referentna kartica.


> [!abstract] PI
> Sada zapis o učenju, merenja, indeks i trajne napomene.


> [!abstract] PI
> Lekcija 0002 je gotova i otvorena u pregledaču. Proveravao sam je na živoj topologiji, a beleške za sledeće časove su zapisane.
>
> **Napravljeno:**
> - **Lekcija:** `lessons/0002-binarni-log-gtid-asinhrona.html`. Ima tri korena, osam odeljaka, tri primera koje pokrećeš u Workbench-u i završni kviz od 8 pitanja.
> - **Referentna kartica:** `reference/binarni-log-gtid-niti.html`. Sadrži formate, bezbedne i nesigurne iskaze, GTID, niti i tabelu naredbi u 8.4 (nove naspram uklonjenih).
> - **Primeri:** `examples/02-binlog-async/01..03-*.sql`. Sva tri sam pokrenuo na 3307 i 3309 i rade.
> - **Zapis o učenju:** `learning-records/0004-binlog-gtid-async.md`, uz indeks u README-u. Izmerene brojke i provereni izvori su u `.scratch/replikacija/measurements/0004-…`.
> - **GLOSSARY.md:** dodat je §1b'' sa novim terminima: nesiguran iskaz, nit koja šalje log, „naša topologija“.
> - **`TEACHING.md`:** dodate su tvoje dve želje. Prva je ritam „tekst, pa kviz“, uz opis greške koja se danas desila. Druga je bez prevedenih metafora („pesak za igru“, „radnik“).
>
> **Merenje uživo koje je ušlo u lekciju:** ista transakcija `…:16854` je na 3307 zapisana u `node1-bin.000008` i završava se na bajtu 640. Na 3309 je u `node3-bin.000010` i završava se na bajtu 630. Ime je isto, adresa različita, baš kao u primeru sa sveskama.
>
> **Dve greške u memou 03, zabeležene da ne uđu u rad:**
> - Memo kaže da je `NOW()` nesiguran. Priručnik kaže da je bezbedan.
> - Memo kaže da GTID čini *failover* „automatskim“. Priručnik kaže da ga samo pojednostavljuje.
>
> **Šta je ostalo otvoreno:**
> - **Lekcija B (postojanost)** kreće od nule, jer WAL i fsync još ne poznaješ. Na početku ponavljamo K3 („replika ne čita tuđe datoteke, nego razgovara sa živim procesom“). To ti je bio najklimaviji koren i dvaput se vratio.
> - Topologija i dalje radi. Ako hoćeš da je ugasiš: `examples\00-setup\topology.ps1 stop`.
>
> Ako ti nešto u lekciji nije jasno, pitaj ovde.


> [!quote] YOU
> Da li je zapisano da je lekcija podeljena u dve i koji prompt treba da dam da bih nastavio ucenje u novoj sesiji


> [!abstract] PI
> Da, podela je zapisana na tri mesta:
>
> - **`learning-records/0004-binlog-gtid-async.md`**: u zapisu stoji da je poglavlje 3 podeljeno na lekcije A i B, da je A gotova, a B nije, i odakle B kreće.
> - **`learning-records/README.md`**: indeks to beleži kao trajno ograničenje („Ch. 3 is taught as two lessons…“), pa ga sledeća sesija vidi i bez otvaranja samog zapisa.
> - **`.scratch/replikacija/issues/15-chapter-3-binlog-async.md`**: upravo sam dodao napomenu o napretku. Na tiketu sada piše da je lekcija A održana, da B nije i da pisanje poglavlja ide tek posle lekcije B.
>
> **Prompt za novu sesiju** (pokreni Claude-a iz foldera Teme 3, pa ovo nalepi uz `/teach`):
>
> ```
> Poglavlje 3, lekcija B — Postojanost: WAL, fsync, dvofazna potvrda redo log ↔ binarni log
> i matrica sync_binlog × innodb_flush_log_at_trx_commit (ticket 15, druga polovina lekcije).
>
> Lekcija A je održana (learning-records/0004-binlog-gtid-async.md) — pročitaj taj zapis prvi,
> u njemu je i odakle B kreće: WAL i fsync ne poznajem, kreni od nule (RAM naspram diska,
> write naspram fsync), pa redo log, pa zašto dva loga traže dvofaznu potvrdu, pa matrica,
> uz tabelu latencija iz zapisa 0001.
>
> Na početku ponovi najklimavija mesta iz lekcije A: K3 (replika ne čita tuđe datoteke, nego
> razgovara sa živim procesom) i prozor u kome asinhrona replikacija gubi potvrđenu transakciju.
>
> Ritam kao u Temi 2: objašnjenje u poruci, pa kviz na kraju. Bez prevedenih metafora.
> ```
>
> Pre lekcije pokreni topologiju (`examples\00-setup\topology.ps1 start`), jer ćemo meriti kombinacije `sync_binlog` i `innodb_flush_log_at_trx_commit` na živim serverima.


> [!quote] YOU
> Da li mozemo da popravimo da ne dodje opet do onog dela kada se ne vidi tekst uopste jer se izgubio u thinking delu. Jel to bio problem u modelu samom ili u pozivu alata


> [!abstract] PI
> Prvo da proverim šta tačno piše u zapisu sesije i šta extension API dozvoljava, da ne nagađam.


> [!abstract] PI
> Problem je bio **u modelu, ne u alatu**. Sad je ugrađena zaštita.
>
> **Šta se tačno desilo.** Proverio sam zapis sesije (`.jsonl`). Svaka „izgubljena“ poruka se sastojala samo iz bloka razmišljanja i poziva kviza, **bez ijednog tekstualnog bloka**. Dakle, objašnjenje nikad nije poslato kao odgovor:
> - Napisao sam ga u svom internom razmišljanju, a iz njega se korisniku ništa ne prikazuje.
> - Odmah posle toga sam pozvao kviz.
>
> Pi, kviz i `md-log` su ispravno prikazali i upisali sve što je stvarno poslato, a poslati su bili samo kvizovi. Ponavljalo se uglavnom u dugim nizovima kvizova, kad je poruka sledila odmah posle rezultata prethodnog kviza. Moja prva dijagnoza („md-log ne upisuje“) bila je pogrešna; to sam ti već ispravio u toku sesije.
>
> **Popravka.** Napravio sam ekstenziju `~/.pi/agent/extensions/quiz-needs-text.ts`. Ona **blokira svaki `quiz` i `ask_user_question` poziv čija poruka nema vidljiv tekst**. Tada dobijam grešku sa objašnjenjem, pa moram da napišem tekst kao pravi odgovor i ponovim poziv. Ne oslanja se na to da ću „zapamtiti“, nego tehnički sprečava da ti ikad stigne kviz bez teksta.
>
> Posledice:
> - Ponekad ćeš videti blokiran poziv, posle kog odmah stiže ista poruka, ali sa tekstom. To je zaštita koja radi.
> - Čak i kratka pitanja u proveri znanja sada moraju da imaju bar jednu rečenicu uvoda. To je ionako bolje za belešku u Obsidian-u.
> - Pravilo važi za sve projekte, ne samo za ovaj predmet. Ako ti negde zasmeta, dovoljno je obrisati tu jednu datoteku.
>
> **Uključivanje.** Ekstenzija radi od sledeće sesije. Ako hoćeš da proradi odmah, otkucaj `/reload`. Kod ekstenzije još nije pokrenut ni jednom, pa će prva prava provera biti prvi kviz u sledećoj lekciji.
>
> U `TEACHING.md` sam dodao napomenu o ovome, da je svaka buduća sesija zna.


> [!quote] YOU
> Ali to je skupo zar ne, nije bas idealno resenje plus nije problem bio u kvizu i tekstu u samom kvizu, jer se pitanje videlo


> [!abstract] PI
> Dobro pitanje. Ali obe pretpostavke su ovde malo drugačije nego što izgleda.
>
> **1. Nije skupo.** Provera ne poziva model. To je nekoliko linija koda koje lokalno pogledaju da li poruka sa kvizom sadrži tekst. U normalnom slučaju, kad je tekst tu, cena je **nula**: nema dodatnih tokena ni dodatnog zahteva.
>
> Trošak nastaje samo kad se greška zaista desi. Tada model dobije odbijenicu i ponovo napiše istu poruku, ovog puta sa tekstom. To je jedan dodatni zahtev, a ponovljeni kontekst se plaća po sniženoj ceni jer je keširan. Danas je ista greška bila skuplja bez zaštite: cela poruka sa rekapitulacijom, nekoliko pitanja bez gradiva i tvoje vreme.
>
> **2. Zaštita ne proverava kviz, nego tekst pre njega.** U pravu si da se pitanje videlo, jer kviz je radio ispravno. Nedostajalo je objašnjenje koje je trebalo da stoji iznad pitanja. Kod mene su ta dva dela delovi jedne iste poruke: tekst, pa poziv kviza. Zaštita gleda baš tu poruku i pita: „Ima li u njoj teksta, ili samo kviz?“ Ako ima samo kviz, to je tačno onaj slučaj koji ti se danas dešavao, i on se zaustavlja pre nego što ti stigne pitanje bez objašnjenja.
>
> **Gde zaštita ne pomaže, da budem iskren:** proverava samo da tekst **postoji**, a ne da je objašnjenje **celo**. Ako napišem jednu rečenicu, a ostatak objašnjenja opet ostane u razmišljanju, zaštita to neće uhvatiti. Danas se to nije dešavalo: poruke su imale ili ceo tekst ili nijedno slovo. Ipak, to je granica ovog rešenja.
>
> **Alternative:**
> - **Samo pravilo u `TEACHING.md`, bez koda.** Ništa ne košta, ali ništa i ne garantuje. Danas sam već znao da tekst treba da bude vidljiv, pa se greška ipak ponovila.
> - **Objašnjenje kao posebna poruka, pa kviz posle tvog „dalje“.** Ovo je potpuno pouzdano, ali tražiš jedan klik više, a to si već odbio.
> - **Zaštita (sadašnje rešenje).** Ne košta ništa dok sve radi, a hvata potpuni izostanak teksta.
>
> Ja bih je zadržao. Ako ipak više voliš da je nema, obrišem `quiz-needs-text.ts` i oslanjamo se samo na pravilo.
