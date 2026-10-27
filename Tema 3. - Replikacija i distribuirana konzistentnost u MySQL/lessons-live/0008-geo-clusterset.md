> [!quote] YOU
> > [!note] SKILL loaded: teach
>
> Lesson 0006 – ch. 6, Geo-distribuirana replikacija i InnoDB ClusterSet.
>    Lesson half of .scratch/replikacija/issues/18-chapter-6-geo-clusterset.md. Its "Must contain" list is the scope.
>    No rad.md prose this session.
>    Follow ../TEACHING.md's reading protocol. Previous record: 0007. ClusterSet numbers: 0002.
>    Re-run examples/01-group-replication/20, 38, 39, 40 live (3306 untouched).
>    At the end: write the lesson, the learning record and the measurements file, add a Progress entry to ticket 18, then commit and push.

> [!question] Question — Obsidian
> Da li da ovu lekciju preslikavam uživo u Obsidian?
>
> 1. Da, nova datoteka (Recommended)
> 2. Da, postojeća datoteka
> 3. Ne

> [!question] Question — Naglasak
> Na šta da lekcija stavi najveći naglasak (svih šest stavki iz tiketa 18 ostaju u obimu)?
>
> 1. CAP isplata (Recommended)
> 2. Switchover vs failover
> 3. Zašto ne GR preko regiona

> [!example] Answer
> **Da li da ovu lekciju preslikavam uživo u Obsidian?**
> Da, nova datoteka (Recommended)
>
> **Na šta da lekcija stavi najveći naglasak (svih šest stavki iz tiketa 18 ostaju u obimu)?**
> CAP isplata (Recommended)

> [!abstract] PI
> ClusterSet je podignut na našoj topologiji (3307+3308 = primarni klaster `poliklinikaCluster`, 3309 = replika-klaster `drCluster`, stanje `HEALTHY`). Izvori su provereni.
>
> Javi kad je `/md-log lessons-live/0008-geo-clusterset.md` povezan, pa krećemo sa proverom znanja.


> [!quote] YOU
> Povezano, pocni


> [!abstract] PI
> Krećemo sa proverom znanja — nekoliko kratkih pitanja da nađem gde ti je ivica. Nije ocena, nego mapa: „Ne znam“ je sasvim korisan odgovor.
>
> Prvo jedno pitanje iz Poglavlja 5, ali posmatrano kroz CAP.


> [!question] Quiz
> Grupa od tri člana (3307, 3308, 3309), single-primary, primarni čvor je 3307. Procesi na 3308 i 3309 su ubijeni. Upis na 3307 visi i ne vraća OK, dok čitanje na 3307 radi. Koji je CAP izbor time napravljen?
>
> 1. Tolerancija na particiju je žrtvovana, a konzistentnost je sačuvana
> 2. Latencija je izabrana, a konzistentnost za upis je žrtvovana
> 3. Konzistentnost je izabrana, a dostupnost za upis je žrtvovana
> 4. Dostupnost je izabrana, a konzistentnost za upis je žrtvovana


> [!failure] Quiz — incorrect ✗
> Your answer: 4. Dostupnost je izabrana, a konzistentnost za upis je žrtvovana
> Correct answer: 3
>
> Manjina ne može da dobije mesto u zajedničkom nizu, pa odbija da potvrdi upis, a ne rizikuje razilaženje. Odbiti zahtev znači žrtvovati dostupnost da bi se sačuvala konzistentnost. Tolerancija na particiju nije nešto što se bira: particija se jednostavno dogodi. Latencija je deo PACELC-a i tiče se rada bez particije (grana E), a ovde particija postoji.


> [!abstract] PI
> Zanimljivo, ovo je važna koordinata. Pre nego što bilo šta objasnim, hoću da vidim odakle dolazi taj izbor. Jedno pitanje o samoj definiciji.


> [!question] Quiz
> U CAP teoremi (Gilbert i Lynch), kada se za sistem kaže da je „dostupan“ (available)?
>
> 1. Kad svaki zahtev dobije odgovor u ograničenom vremenu
> 2. Kad većina čvorova radi i može da prihvati zahteve
> 3. Kad svaki zahtev ka čvoru koji radi dobije odgovor, čitanje i upis
> 4. Kad bar jedna vrsta zahteva, čitanje ili upis, dobija odgovor


> [!failure] Quiz — incorrect ✗
> Your answer: 1. Kad svaki zahtev dobije odgovor u ograničenom vremenu
> Correct answer: 3
>
> Gilbert i Lynch: „every request received by a non-failing node in the system must result in a response“. Svaki zahtev, ne samo čitanje, i bilo koji čvor koji radi, ne samo većina. Nema vremenske granice: odgovor mora jednom da stigne, ali definicija ne kaže kada. Zato upis koji visi na 3307 (čvor radi) znači da sistem po CAP-u nije dostupan.


> [!question] Quiz
> ClusterSet: primarni klaster (3307+3308, Group Replication) šalje transakcije replika-klasteru (3309) asinhronim kanalom. Klijent je na 3307 dobio OK za transakciju T. Odmah zatim oba čvora primarnog klastera nestanu, a operater na 3309 pokrene prinudni failover. Šta važi za T?
>
> 1. T čeka, jer failover ne sme dok se primarni ne vrati
> 2. T može da bude izgubljena, jer OK nije čekao 3309
> 3. T je sačuvana, jer ju je većina grupe već potvrdila
> 4. T je sačuvana, jer je GTID automatski donosi na 3309


> [!question] Quiz — I don't know
> Your answer: I don't know
> Correct answer: 2
>
> Većina koja je potvrdila T je većina unutar primarnog klastera (3307+3308), a oba čvora su nestala. Kanal ka 3309 je asinhron, pa OK nije čekao 3309: isti prozor gubitka kao kod asinhrone replikacije iz Poglavlja 3. GTID je ime transakcije i ne može da donese nešto što nijedan živi čvor nema. Prinudni failover upravo ne čeka primarni klaster; zato i postoji.


> [!abstract] PI
> To je čista praznina, i to je u redu: tu je sklopljeno nešto što još nismo spajali. Proveriću da li je deo ispod nje čvrst — samo asinhrona replikacija, bez klastera.


> [!question] Quiz
> Obična asinhrona replikacija: izvor 3307, replika 3308. Klijent dobija OK za transakciju T na 3307, a 3307 odmah zatim padne pre nego što je nit koja šalje log poslala T. 3308 postaje novi izvor. Šta je sa T?
>
> 1. T je na 3308, jer se binarni log kopira pre OK
> 2. T je na 3308, jer OK dolazi tek kad replika primi T
> 3. T nema na 3308, iako je klijent za nju dobio OK
> 4. T nema na 3308, ali klijent nije ni dobio OK za nju


> [!success] Quiz — correct ✓
> Your answer: 3. T nema na 3308, iako je klijent za nju dobio OK
> Correct answer: 3
>
> Kod asinhrone replikacije izvor potvrđuje klijentu čim sam komituje i nikad ne čeka repliku. Ako padne pre slanja, T postoji samo na disku mrtvog izvora: klijent ima OK, a novi izvor nema T. To je prozor gubitka iz lekcije 0002.


> [!abstract] PI
> Ta osnova stoji. Znači, praznina nije u asinhronoj replikaciji, nego u sklapanju „grupa unutra, asinhrono između“. Sledeća nit je switchover naspram failover-a, iz Poglavlja 4.


> [!question] Quiz
> Po definiciji iz Poglavlja 4, po čemu se switchover suštinski razlikuje od failover-a?
>
> 1. Kod switchover-a stari izvor je ugasio operater, a ne kvar
> 2. Kod switchover-a stari izvor je živ i može da preda sve transakcije
> 3. Kod switchover-a novi izvor bira grupa glasanjem, bez operatera
> 4. Kod switchover-a replika se unapređuje bez provere GTID skupova


> [!success] Quiz — correct ✓
> Your answer: 2. Kod switchover-a stari izvor je živ i može da preda sve transakcije
> Correct answer: 2
>
> Switchover je planirana promena uloga: stari izvor radi, pa se može zaustaviti upis, sačekati da replika primeni sve i tek onda zameniti uloge — ništa se ne gubi. Failover dolazi posle otkaza: stari izvor ne može ništa da preda, pa sve što nije stiglo do replike ostaje van novog izvora. Ko pokreće prelaz (operater ili automatika) nije ono što ih razlikuje.


> [!abstract] PI
> Ovo stoji. Idem korak dalje: šta ako stari primarni klaster nije mrtav, nego samo odsečen?


> [!question] Quiz
> ClusterSet: primarni klaster u Beogradu (3 člana, svi rade), replika-klaster u Nišu (3 člana, svi rade). Pukne samo veza Beograd–Niš. Operater u Nišu, misleći da je Beograd pao, pokrene prinudni failover. Šta je realan rizik?
>
> 1. Niš odbija failover, jer Beograd još uvek ima većinu
> 2. Oba klastera primaju upise i njihovi podaci se razilaze
> 3. Nema rizika, jer kvorum grupe sprečava dva primarna klastera
> 4. Nema rizika, jer se Beograd sam prebacuje u režim samo za čitanje


> [!success] Quiz — correct ✓
> Your answer: 2. Oba klastera primaju upise i njihovi podaci se razilaze
> Correct answer: 2
>
> Kvorum važi unutar jedne grupe: Beograd ima većinu svoje grupe, Niš ima većinu svoje. Između klastera nema zajedničkog kvoruma ni zajedničkog niza, pa nijedan mehanizam ne zabranjuje da oba prihvataju upise. Odsečeni Beograd ne zna da je smenjen. Shell to sam kaže pri forcePrimaryCluster: „a split-brain can happen“, i nudi fenceAllTraffic()/fenceWrites() da operater ručno ogradi stari klaster.


> [!abstract] PI
> Odlično. Poslednja nit: zašto ne razvući jednu grupu preko regiona.


> [!question] Quiz
> Zamisli jednu Group Replication grupu od tri člana: Frankfurt, Virdžinija, Singapur, sa povratnim putovanjem između regiona oko 100–200 ms. Šta se dešava sa svakim upisom?
>
> 1. Samo prvo komitovanje čeka, a posle je niz već dogovoren
> 2. Komitovanje ne čeka, jer se primena kod ostalih radi asinhrono
> 3. Samo čitanja čekaju, jer moraju da provere većinu
> 4. Svako komitovanje čeka bar jedno povratno putovanje do drugog regiona


> [!failure] Quiz — incorrect ✗
> Your answer: 2. Komitovanje ne čeka, jer se primena kod ostalih radi asinhrono
> Correct answer: 4
>
> Komitovanje u grupi traži da većina prihvati mesto transakcije u zajedničkom nizu, i to za svaku transakciju posebno. Sa tri člana većina su dva, pa primarni čeka bar jednog udaljenog člana: bar jedno povratno putovanje između regiona po komitovanju. Primena kod ostalih jeste kasnija (odluka ≠ vidljivost), ali dogovor o redosledu nije. Čitanja na podrazumevanom nivou ništa ne čekaju.


> [!abstract] PI
> Ovo je drugi zanimljiv trag. Proveriću da li je problem u samom komitovanju u grupi ili samo u tome kako se ono preslikava na udaljenost.


> [!question] Quiz
> Grupa od tri člana na našoj topologiji, nivo EVENTUAL. Šta mora da se desi pre nego što primarni čvor 3307 klijentu vrati OK za COMMIT?
>
> 1. Svi članovi moraju da prime transakciju i njeno mesto u nizu
> 2. Samo 3307 mora da komituje, a ostali je dobijaju posle
> 3. Većina članova mora da primi transakciju i njeno mesto u nizu
> 4. Većina članova mora da primeni transakciju na svoje podatke


> [!success] Quiz — correct ✓
> Your answer: 3. Većina članova mora da primi transakciju i njeno mesto u nizu
> Correct answer: 3
>
> Komitovanje u grupi = većina je primila transakciju i njeno mesto u zajedničkom nizu (XCom/Paxos), pa svaki član deterministički sertifikuje isti niz. Primena na podatke ostalih je kasnije — to je razlika odluke i vidljivosti iz lekcije 0005. Zato čak i EVENTUAL čeka mrežu: čeka većinu za redosled, ne za primenu.


> [!question] Quiz
> Opšti slučaj, bez MySQL-a: tokom particije mreže čvor dobije upis, ali ga ne prihvati (ne vrati OK), da se podaci na dve strane ne bi razišli. Šta je po CAP-u tu žrtvovano?
>
> 1. Konzistentnost, da bi se sačuvala dostupnost
> 2. Latencija, da bi se sačuvala dostupnost
> 3. Tolerancija na particiju, da bi se sačuvala konzistentnost
> 4. Dostupnost, da bi se sačuvala konzistentnost


> [!success] Quiz — correct ✓
> Your answer: 4. Dostupnost, da bi se sačuvala konzistentnost
> Correct answer: 4
>
> Zahtev ka čvoru koji radi nije dobio odgovor, pa je dostupnost po definiciji narušena. Dobitak je to što se dve strane ne razilaze, a to je konzistentnost.


> [!abstract] PI
> Mapa je gotova. Evo gde ti je ivica:
>
> | Nit | Pod (stoji) | Plafon (puca) |
> |---|---|---|
> | CAP | definicija dostupnosti; apstraktno „odbijen upis = žrtvovana dostupnost“ | primena na grupu: kad čitanje radi, a upis visi, izabrao si „dostupnost“ |
> | Gubitak podataka | prozor gubitka kod asinhrone replikacije | sklapanje „grupa unutra + asinhrono između“: „ne znam“ |
> | Prelaz uloga | switchover i failover; split brain između klastera | — |
> | Grupa i razdaljina | OK čeka da većina primi transakciju | to čekanje nisi preveo u cenu koja raste sa razdaljinom („primena je asinhrona, pa se ne čeka“) |
>
> ## Plan
>
> Krećemo od tri tvrdnje koje već imaš ili koje se prihvataju bez ograda: **zajednički niz (i kvorum) postoji samo unutar jedne grupe**, **asinhroni kanal ne čeka primaoca** i **signal ima konačnu brzinu** (oko 200 km po milisekundi u optičkom vlaknu). Iz njih izvodimo, redom:
>
> 1. **Zašto ne jedna grupa preko regiona.** Svako komitovanje plaća povratno putovanje do udaljene većine. Pored toga, spora veza izgleda kao otkaz (detekcija 5 s + `group_replication_member_expel_timeout`).
> 2. **Šta MySQL radi umesto toga: ClusterSet.** Grupa unutar jednog centra, asinhroni kanal `clusterset_replication` između centara. Replika-klasteri samo čitaju, pa ne mogu da se raziđu.
> 3. **Tvoja praznina:** šta OK znači kada se te dve stvari slože.
> 4. **Switchover naspram prinudnog failover-a**, uživo na našoj topologiji (skripte 38, 39 i 40): `INVALIDATED`, upozorenje o split brain-u, ograđivanje.
> 5. **Vrhunac:** ista grupa bira konzistentnost unutar klastera (ovde ispravljamo prvo pitanje), a ClusterSet bira dostupnost između klastera, rečima samog proizvođača. Dva citata stoje jedan pored drugog, a okosnica rada sledi iz njih.
>
> Uglavnom Sokratovski, jer sve ovo možeš sam da izvedeš. Fiziku izlažem ja, jer je to samo jedna činjenica.
>
> ```mermaid
> graph TD
>   R1[Niz i kvorum samo unutar jedne grupe]
>   R2[Asinhroni kanal ne čeka primaoca]
>   R3[Signal: ~200 km/ms]
>   R4[CAP dostupnost: svaki zahtev dobija odgovor]
>   D1[GR preko regiona: RTT po komitovanju + izbacivanje članova]
>   D2[ClusterSet: GR unutra, asinhrono između, replike samo čitaju]
>   D3[OK = većina primarnog klastera; prozor gubitka između]
>   D4[Switchover 478 ms bez gubitka / prinudni failover ručno, INVALIDATED, split brain]
>   D5[Ista grupa: C unutra, A između — okosnica rada]
>   R1 --> D1
>   R3 --> D1
>   D1 --> D2
>   R2 --> D2
>   R1 --> D3
>   R2 --> D3
>   D2 --> D3
>   D3 --> D4
>   D4 --> D5
>   R4 --> D5
>   R1 --> D5
> ```
>
> Važi li ovako? Kad kažeš „da“, krećem od prvog čvora.


> [!quote] YOU
> Pre nego sto pocenmo hocu da vidim zasto u ovoj sesiji dobijam error Error: DEEPGRAM_API_KEY not set in environment a kad otvorim neku drugu radi. I takodje ne vidim mermaid diagram  Mermaid diagram not rendered: node "D3": label is missing its closing `]` (+1 more)


> [!abstract] PI
> Oba problema imaju jednostavan uzrok.
>
> **1. `DEEPGRAM_API_KEY not set`.** Ključ jeste podešen, ali kao korisnička promenljiva okruženja u Windows-u (`User: True`). Ovaj Pi proces ga ne vidi (`Process: False`). Program dobija promenljive okruženja samo jednom, kad se pokrene, od programa koji ga je pokrenuo. Ovu sesiju si verovatno otvorio iz terminala (ili VS Code-a / Windows Terminal-a) koji je bio pokrenut **pre** nego što je ključ podešen. Druge sesije su otvorene iz novijeg prozora, pa ga vide.
>
> Kako da popraviš: potpuno zatvori aplikaciju terminala (sve prozore i kartice, ne samo jednu karticu), otvori je ponovo i vrati se u ovu sesiju sa `pi --resume`. Topologija i ClusterSet ostaju podignuti, jer su to posebni procesi.
>
> **2. Mermaid.** U oznakama čvorova bili su znakovi koje Mermaid tumači kao sintaksu: `;` mu znači kraj iskaza, a `/` i `~` uz `[` znače drugi oblik čvora. Popravljeno je tako što su sve oznake u navodnicima. Proverio sam da se dijagram sada iscrtava:
>
> ```mermaid
> graph TD
>   R1["Niz i kvorum samo unutar jedne grupe"]
>   R2["Asinhroni kanal ne čeka primaoca"]
>   R3["Signal: oko 200 km po ms"]
>   R4["CAP dostupnost: svaki zahtev dobija odgovor"]
>   D1["GR preko regiona: RTT po komitovanju, izbacivanje članova"]
>   D2["ClusterSet: GR unutra, asinhrono između, replike samo čitaju"]
>   D3["OK = većina primarnog klastera, prozor gubitka između"]
>   D4["Switchover 478 ms bez gubitka, prinudni failover ručno, INVALIDATED, split brain"]
>   D5["Isti proizvod: C unutra, A između = okosnica rada"]
>   R1 --> D1
>   R3 --> D1
>   D1 --> D2
>   R2 --> D2
>   R1 --> D3
>   R2 --> D3
>   D2 --> D3
>   D3 --> D4
>   D4 --> D5
>   R4 --> D5
>   R1 --> D5
> ```
>
> (Usput sam ispravio i oznaku D5: „isti proizvod“, a ne „ista grupa“.)
>
> Kad restartuješ ili kad kažeš da nastavljamo ovako, i ako je plan u redu, krećem od prvog čvora.


> [!quote] YOU
> Okay We can continue now. I will reply in English since the Deepgram only recognizes English, but you will continue in Serbian.


> [!abstract] PI
> U redu: ti na engleskom, ja nastavljam na srpskom.
>
> ---
>
> ## Čvor R3 — signal ima konačnu brzinu
>
> **Zašto nam ovo treba sada.** U proveri znanja si tačno rekao da OK u grupi čeka da većina primi transakciju. Ali na pitanje o grupi Frankfurt–Virdžinija–Singapur izabrao si „komitovanje ne čeka“. Ono što te dve stvari spaja je jedna fizička činjenica. Na našoj topologiji je nikad ne vidiš, jer su sva tri čvora na istoj mašini.
>
> **Bezuslovna istina.** Svetlost u optičkom vlaknu ne putuje brzinom svetlosti u vakuumu (~300 000 km/s), nego oko trećinu sporije, jer je indeks prelamanja stakla oko 1,47. To je **oko 200 000 km/s, odnosno oko 200 km po milisekundi**. Nijedan softver, protokol ni novac to ne menja. Stvarni put kabla je uz to duži od vazdušne linije, pa je ovo **donja granica**.
>
> ```
> 1 smer:   razdaljina / (200 km/ms)
> povratno putovanje (RTT) = 2 × to        ← najmanje, pre bilo kakve obrade
> ```
>
> Na našoj topologiji (loopback, ista mašina) RTT je reda mikrosekundi. Zato su sve izmerene cene u grupi (16 ms za komitovanje) cene diska i obrade, a ne razdaljine.


> [!question] Quiz
> Dva data centra su udaljena 1000 km, mereno tačno duž optičkog kabla. Koliko je najmanje moguće povratno putovanje (RTT) između njih, bez ikakve obrade?
>
> 1. Oko 0,1 ms
> 2. Oko 1 ms
> 3. Oko 10 ms
> 4. Oko 100 ms


> [!success] Quiz — correct ✓
> Your answer: 3. Oko 10 ms
> Correct answer: 3
>
> U jednom smeru 1000 km / 200 km po ms = 5 ms, a povratno putovanje je dvostruko: 10 ms. To je fizička donja granica; ruteri, svičevi i stvarni put kabla je samo povećavaju. 1 ms bi bio rezultat sa brzinom ~2000 km/ms, deset puta brže od svetlosti u staklu.


> [!question] Quiz
> Grupa od tri člana: Frankfurt (primarni), Virdžinija (RTT ~90 ms od Frankfurta) i Singapur (RTT ~160 ms od Frankfurta). Koliko najmanje čeka svako komitovanje na primarnom čvoru, samo zbog mreže?
>
> 1. Oko 0 ms, jer se čeka samo lokalni disk
> 2. Oko 90 ms, do najbližeg drugog člana
> 3. Oko 160 ms, do najdaljeg člana
> 4. Oko 250 ms, do oba člana redom


> [!warning] Quiz — cancelled
> (user skipped)


> [!quote] YOU
> I can't see the explanation before the quiz. It worked on the last one. Now it stopped working.


> [!abstract] PI
> Ovaj potez služi samo kao test za md-log: proveravam da li se tekst posle poziva alata upisuje u log.


> [!abstract] PI
> ## Čvor D1 — zašto ne jedna grupa preko regiona
>
> **Zašto nam treba.** Na osnovu Poglavlja 5 deluje prirodno da se tri člana grupe razmeste u tri regiona: ako jedan region nestane, većina ostaje i grupa nastavlja. Proverimo koliko to košta.
>
> **Sastavi dve stvari koje već imaš:**
>
> 1. (iz lekcije 0005, potvrđeno u proveri znanja) Pre nego što 3307 vrati OK za COMMIT, **većina** članova mora da primi transakciju i njeno mesto u zajedničkom nizu. Primena kod ostalih je kasnije. Odluka se čeka, vidljivost ne.
> 2. (R3) Svaka poruka između regiona traje najmanje razdaljina / 200 km po ms.
>
> Tvoja greška iz provere znanja („primena je asinhrona, pa se ne čeka“) bila je tačna rečenica pogrešno primenjena. Asinhrona je **primena**. **Dogovor o redosledu** nije asinhron i obavlja se preko mreže za **svaku** transakciju.
>
> ```
> Frankfurt (primarni) ---- ~90 ms RTT ---- Virdžinija
>         \--------------- ~160 ms RTT ---- Singapur
> (RTT vrednosti su pretpostavke za primer, ne merenje)
> ```


> [!abstract] PI
> Objašnjenje za D1 sam sada ručno upisao u Obsidian (treba da se vidi iznad ove poruke). Ako se to ponovi, i dalje ću proveravati log pre svakog kviza i dopisivati ono što fali. Kviz:


> [!question] Quiz
> Grupa od tri člana: Frankfurt (primarni), Virdžinija (RTT ~90 ms od Frankfurta) i Singapur (RTT ~160 ms od Frankfurta). Koliko najmanje čeka svako komitovanje na primarnom čvoru, samo zbog mreže?
>
> 1. Oko 0 ms, jer se čeka samo lokalni disk
> 2. Oko 90 ms, do najbližeg drugog člana
> 3. Oko 160 ms, do najdaljeg člana
> 4. Oko 250 ms, do oba člana redom


> [!warning] Quiz — cancelled
> (user skipped)


> [!quote] YOU
> None depended manually that MD log is not consistent with what was shown in the prompt I think The solution might be just to print the explanation then I'll just type next or something, and then you'll show the quiz.


> [!abstract] PI
> Dogovoreno, i upisao sam to kao trajno pravilo: objašnjenje, pa ti napišeš „next“, pa tek onda kviz. Ponavljam D1 čisto:
>
> ---
>
> ## Čvor D1 — zašto ne jedna grupa preko regiona
>
> **Zašto nam treba.** Na osnovu Poglavlja 5 deluje prirodno da se tri člana grupe razmeste u tri regiona: ako jedan region nestane, većina ostaje i grupa nastavlja. Proverimo koliko to košta.
>
> **Sastavi dve stvari koje već imaš:**
>
> 1. (iz lekcije 0005, potvrđeno u proveri znanja) Pre nego što 3307 vrati OK za COMMIT, **većina** članova mora da primi transakciju i njeno mesto u zajedničkom nizu. Primena kod ostalih je kasnije. Odluka se čeka, vidljivost ne.
> 2. (R3) Svaka poruka između regiona traje najmanje razdaljina / 200 km po ms.
>
> Tvoja greška iz provere znanja („primena je asinhrona, pa se ne čeka“) bila je tačna rečenica pogrešno primenjena. Asinhrona je **primena**. **Dogovor o redosledu** nije asinhron i obavlja se preko mreže za **svaku** transakciju.
>
> ```
> Frankfurt (primarni) ---- ~90 ms RTT ---- Virdžinija
>         \--------------- ~160 ms RTT ---- Singapur
> (RTT vrednosti su pretpostavke za primer, ne merenje)
> ```
>
> Pitanje koje sledi: koliko najmanje čeka svako komitovanje na Frankfurtu, samo zbog mreže? Razmisli unapred: koga tačno Frankfurt mora da sačeka?
>
> Napiši „next“ kad budeš spreman za kviz.


> [!quote] YOU
> next


> [!question] Quiz
> Grupa od tri člana: Frankfurt (primarni), Virdžinija (RTT ~90 ms od Frankfurta) i Singapur (RTT ~160 ms od Frankfurta). Koliko najmanje čeka svako komitovanje na primarnom čvoru, samo zbog mreže?
>
> 1. Oko 0 ms, jer se čeka samo lokalni disk
> 2. Oko 90 ms, do najbližeg drugog člana
> 3. Oko 160 ms, do najdaljeg člana
> 4. Oko 250 ms, do oba člana redom


> [!success] Quiz — correct ✓
> Your answer: 2. Oko 90 ms, do najbližeg drugog člana
> Correct answer: 2
>
> Većina od tri su dva, a sam Frankfurt je jedan od njih. Potreban mu je još jedan član, pa čeka onog koji prvi odgovori: Virdžiniju, ~90 ms. Singapur ne mora da odgovori (160 ms bi važilo da se čekaju svi). Poruke idu paralelno, a ne redom (zato nije 250 ms). Ni 0 ms nije tačno: dogovor o redosledu se uvek čeka. Ovih ~90 ms je donja granica za SVAKO komitovanje.


> [!abstract] PI
> Tačno. Frankfurt je sam sebi prvi glas, pa čeka samo najbližeg člana. Na svakom komitovanju plaća ~90 ms, a na našoj topologiji je ta cena praktično nula.
>
> ## D1, drugi deo — spora veza izgleda kao otkaz
>
> Cena po komitovanju je prvi razlog. Drugi je opasniji. Grupa mora nekako da zaključi da je član otkazao. Ona to ne zna, nego **pretpostavlja iz tišine**:
>
> ```
> član ćuti 5 s                  → nastaje sumnja (fiksni period detekcije)
> sumnja traje još N s           → član se izbacuje iz grupe
> N = group_replication_member_expel_timeout   (podrazumevano 5 s u 8.4)
> ```
>
> Iz refman-a 8.4 (sistemske promenljive Group Replication-a): promenljiva određuje *„the period of time in seconds that a Group Replication group member waits after creating a suspicion, before expelling from the group the member suspected of having failed. The initial 5-second detection period before a suspicion is created does not count as part of this time.“*
>
> Međuregionalna veza ne mora da padne da bi „ćutala“ desetak sekundi: zagušenje, preusmeravanje rute, kratak prekid kod provajdera. Grupa ne može da razlikuje spor član od mrtvog, pa izbacuje zdrav član. Taj član posle mora ponovo da se priključi i da sustigne propušteno. Ako se to ponavlja, članstvo stalno „treperi“. Možeš da povećaš vremensko ograničenje, ali onda grupa sporije primećuje **pravi** otkaz. To je kompromis, a ne rešenje.
>
> Zato refman 8.4 u zahtevima za infrastrukturu kaže otvoreno:
>
> > *„MySQL Group Replication is designed to be deployed in a cluster environment where server instances are very close to each other.“*
> > *„The performance and stability of a group can be impacted by both network latency and network bandwidth.“*
>
> Napomena da ne bi tražio izvođenje gde ga nema: **5 s je izbor projektanata**, a ne posledica nečega. Podrazumevana vrednost `group_replication_member_expel_timeout` se menjala kroz verzije, i to je podesiva odluka.
>
> **Zaključak čvora D1:** grupa se plaća mrežom na svakom komitovanju i pretpostavlja da tišina znači smrt. Oba izbora su dobra unutar jednog data centra, a loša preko regiona. Zato je potrebna druga konstrukcija za veliku razdaljinu, i to je sledeći čvor.
>
> Pitanje koje sledi: šta grupa preko regiona radi kad međuregionalna veza zakoči.
>
> Napiši „next“.


> [!quote] YOU
> next


> [!question] Quiz
> Grupa od tri člana u tri regiona, sva tri ispravna. Veza do Singapura zakoči na 12 s (zagušenje, ne pad), a podešavanja su podrazumevana za 8.4. Šta se najverovatnije desi?
>
> 1. Singapur bude izbačen, iako je ispravan, pa mora ponovo da se priključi
> 2. Ništa se ne desi, jer grupa razlikuje spor član od mrtvog
> 3. Singapur nastavi kao zaseban primarni čvor i prima upise
> 4. Grupa blokira sve upise dok se veza do Singapura ne vrati


> [!success] Quiz — correct ✓
> Your answer: 1. Singapur bude izbačen, iako je ispravan, pa mora ponovo da se priključi
> Correct answer: 1
>
> 5 s tišine stvara sumnju, a posle još 5 s (expel timeout) član se izbacuje: ukupno 10 s, manje od 12. Grupa ne razlikuje spor član od mrtvog, pa izbacuje ispravan. Upisi ne blokiraju, jer Frankfurt i Virdžinija i dalje čine većinu. Singapur ne može da primi upis jer je manjina (1 od 3), pa nema split brain-a.


> [!abstract] PI
> ## Čvor D2 — šta MySQL radi umesto toga: InnoDB ClusterSet
>
> **Zašto nam treba.** Iz D1 imamo dva zahteva koji se međusobno guraju:
>
> - **unutar** jednog data centra želimo grupu, jer je RTT mali, a dobijamo kvorum, certification i automatski izbor primarnog čvora;
> - **između** data centara ne smemo da čekamo udaljenu stranu pri svakom komitovanju.
>
> Imaš već alat koji ne čeka primaoca: **asinhroni kanal** (R2, lekcija 0002). Sklapanje je očigledno: **grupa u svakom data centru, a između njih asinhroni kanal.** To je InnoDB ClusterSet. MySQL Shell manual ga ovako uvodi:
>
> > *„MySQL InnoDB ClusterSet provides disaster tolerance for InnoDB Cluster deployments by linking a primary InnoDB Cluster with one or more replicas of itself in alternate locations, such as different datacenters.“*
>
> i za vezu:
>
> > *„Asynchronous replication channels replicate transactions from the primary cluster to the replica clusters.“* — kanal se zove `clusterset_replication`.
>
> Ovo je ujedno **odgovor na memo 07**, koji je tvrdio da MySQL nema posebnu funkciju za geo-distribuciju. ClusterSet je dokumentovan u **MySQL Shell manual-u**, ne u refman-u, i zato ga je memo promašio.
>
> **Na našoj topologiji** (podignuto na početku sesije): klaster `poliklinikaCluster` = 3307 + 3308 je „data centar A“, a klaster `drCluster` = samo 3309 je „data centar B“. Klaster sme da ima jednog člana, i samo zato ClusterSet može da radi na jednoj mašini. Jedino što ne možemo da pokažemo je stvarna razdaljina, a to je fizika (D1), a ne funkcija koja fali.
>
> **Problem koji ostaje — razmisli pre kviza.** Dva klastera, svaki ima svoj primarni čvor, a svaki primarni čvor ume da prihvati upis. Iz lekcije 0005 znaš šta se desi kad dva lidera odlučuju o redosledu nezavisno. Unutar grupe to rešava zajednički niz, ali (R1) **zajednički niz postoji samo unutar jedne grupe**, a između klastera ide samo asinhroni kanal.
>
> Pitanje koje sledi: koje najjednostavnije pravilo čini sukobe između klastera nemogućim, a da se pri tom ne uvede čekanje preko regiona?
>
> Napiši „next“.


> [!quote] YOU
> next


> [!question] Quiz
> ClusterSet: dva klastera, između njih samo asinhroni kanal, bez zajedničkog niza. Koje pravilo čini sukobe upisa između klastera nemogućim, bez čekanja preko regiona?
>
> 1. Upise primaju svi klasteri, a pobeđuje kasniji po satu
> 2. Upise prima samo jedan klaster, a svi ostali samo čitaju
> 3. Upise primaju svi klasteri, ali svaki samo za svoje tabele
> 4. Upise primaju svi klasteri, a sukobe rešava certification


> [!success] Quiz — correct ✓
> Your answer: 2. Upise prima samo jedan klaster, a svi ostali samo čitaju
> Correct answer: 2
>
> Sukob traži dva upisivača. Ako upise prima samo jedan klaster, na nivou ClusterSet-a postoji jedan upisivač, pa je redosled njegov red zaključavanja i certification unutar njegove grupe, i nema šta da se razilazi. Certification između klastera traži zajednički niz, dakle čekanje preko regiona, a upravo to ne želimo. „Kasniji po satu“ je strategija drugih sistema koja tiho baca upise; MySQL to ne radi. Podela tabela po klasterima je ručno deljenje podataka (sharding), a to je van obima.


> [!abstract] PI
> Tačno, i to je arhitektonsko rešenje ClusterSet-a. Sukob između regiona se ne rešava, nego se **sprečava**: postoji samo jedan klaster koji prima upise. Unutar njega redosled određuju zaključavanje i certification, a ostali klasteri samo kopiraju.
>
> Proverio sam to uživo na našoj topologiji, pre ovog čvora:
>
> ```
> ClusterSet poliklinikaCS: HEALTHY - All Clusters available.
>   poliklinikaCluster: role=PRIMARY global=OK
>   drCluster: role=REPLICA global=OK receiver=ON applier=APPLIED_ALL source=127.0.0.1:3307
>   port 3307 super_read_only=0  INSERT -> ACCEPTED
>   port 3308 super_read_only=1  INSERT -> REFUSED: ... running with the --super-read-only option
>   port 3309 super_read_only=1  INSERT -> REFUSED: ... running with the --super-read-only option
>   3309 kanali: clusterset_replication = ON, group_replication_applier = ON
> ```
>
> Kako se ovo čita: na 3309 rade **dva** kanala istovremeno. `clusterset_replication` je asinhroni dovod iz drugog klastera, a `group_replication_applier` je unutrašnji kanal njegove grupe. 3308 odbija upis iz drugog razloga: on je sekundarni član u svojoj grupi (Poglavlje 5). 3309 ga odbija jer je **ceo njegov klaster** replika.
>
> ---
>
> ## Čvor D3 — šta OK znači kad se dve stvari slože
>
> Ovo je pitanje na koje si u proveri znanja odgovorio „ne znam“. Sada imaš sve delove.
>
> Kad 3307 vrati OK za transakciju T, pitaj se **ko je T već primio**:
>
> ```
> klijent ──COMMIT──> 3307 ──(niz, čeka većinu)──> 3308      ← OK čeka ovo
>                      │
>                      └──(clusterset_replication, asinhrono)──> 3309   ← OK ovo NE čeka
> ```
>
> - **Unutar** primarnog klastera važi ono iz Poglavlja 5: OK znači da je većina (ovde 3307 + 3308) primila T i njeno mesto u nizu.
> - **Prema** replika-klasteru važi ono iz Poglavlja 3 (R2): kanal je asinhroni, pa OK ne čeka 3309.
>
> Garancija koju klijent dobija od OK-a je, dakle, **garancija grupe**, i važi samo za **onaj kvar koji grupa preživljava**: pad manjine u istom data centru. Ako nestane ceo data centar A, a replika-klaster B dobije ulogu primarnog, sve što je bilo u asinhronom kanalu „u letu“ nalazi se **samo na mrtvim mašinama**. To je tačno prozor gubitka iz lekcije 0002, samo pomeren za nivo više: ranije između dva servera, sada između dva klastera.
>
> Pitanje koje sledi je ono isto iz provere znanja, kada si rekao „ne znam“.
>
> Napiši „next“.


> [!quote] YOU
> next


> [!question] Quiz
> ClusterSet: primarni klaster (3307+3308) šalje transakcije replika-klasteru (3309) asinhronim kanalom. Klijent je na 3307 dobio OK za transakciju T. Odmah zatim oba čvora primarnog klastera nestanu, a operater na 3309 pokrene prinudni failover. Šta važi za T?
>
> 1. T može da bude izgubljena, jer OK nije čekao 3309
> 2. T je sačuvana, jer je GTID automatski donosi na 3309
> 3. T je sačuvana, jer ju je većina grupe već potvrdila
> 4. T čeka, jer failover ne sme dok se primarni ne vrati


> [!success] Quiz — correct ✓
> Your answer: 1. T može da bude izgubljena, jer OK nije čekao 3309
> Correct answer: 1
>
> Većina koja je potvrdila T je većina unutar primarnog klastera (3307+3308), a oba čvora su nestala. Kanal ka 3309 je asinhron, pa OK nije čekao 3309: isti prozor gubitka kao kod asinhrone replikacije, samo između klastera. GTID je ime transakcije i ne može da donese nešto što nijedan živi čvor nema. Prinudni failover upravo ne čeka primarni klaster; zato i postoji.


> [!abstract] PI
> Ovaj put je tačno: gap iz provere znanja je zatvoren. Sada pokrećem uživo prelaze uloga za čvor D4, prvo kontrolisani switchover (skripta 38).


> [!abstract] PI
> Izvršio sam sve tri skripte (38, 39, 40) na našoj topologiji. 3306 nisam dirao.
>
> ## Čvor D4 — switchover naspram prinudnog failover-a, uživo
>
> Iz Poglavlja 4 imaš definiciju (potvrđenu u proveri znanja): **kod switchover-a stari izvor je živ i može da preda sve**, a kod failover-a nije. Pogledaj kako ClusterSet doslovno sprovodi tu razliku.
>
> ### Switchover — `setPrimaryCluster('drCluster')`, skripta 38
>
> Shell je ispisao korake. Ovo su ključni:
>
> ```
> ** Waiting for the promoted cluster to apply pending received transactions...
> * Synchronizing transaction backlog at 127.0.0.1:3309
> ** Acquiring global lock at PRIMARY
> ** Acquiring global lock at SECONDARIES
> * Synchronizing remaining transactions at promoted primary
> Cluster 'drCluster' was promoted to PRIMARY of the clusterset.
>    switchover took 539 ms          (povratak: 444 ms)
> ```
>
> Upravo to je tvoja definicija u akciji: stari primarni je živ, pa se **zaključa** (globalni lock, nema novih upisa), 3309 **sustigne sve**, i tek onda se uloge zamene. Prozor gubitka iz D3 se zatvara tako što se sačeka da se isprazni. Posle prelaza 3307 odbija upis, a 3309 ga prima. U tiketu 11 (0002) isto je trajalo 478 / 398 ms.
>
> ### Prinudni failover — skripta 39: 3307 i 3308 ubijeni, bez urednog gašenja
>
> **Pre bilo kakve akcije operatera:**
>
> ```
> 3309 super_read_only = 1
> write REFUSED
> clusterset status = UNAVAILABLE : Primary Cluster is not reachable from the Shell, assuming it to be unavailable.
> ```
>
> 3309 se **nije sam unapredio** i odbija upis. Prinudni failover je u Shell manual-u opisan kao ručni postupak (`forcePrimaryCluster()`), i tako se i ponašao. Ovo je **projektantska odluka**, a ne zakon prirode. Razlog za nju, međutim, već imaš iz provere znanja: replika-klaster ne može da razlikuje „Beograd je mrtav“ od „veza do Beograda je pukla“. Automatsko unapređenje u drugom slučaju bi napravilo dva primarna klastera.
>
> **Operater pokreće `forcePrimaryCluster('drCluster')`:**
>
> ```
> None of the instances of the PRIMARY cluster 'poliklinikaCluster' could be reached.
> ** Checking whether target cluster has the most recent GTID set
> PRIMARY cluster failed-over to 'drCluster'.
> Former PRIMARY cluster 'poliklinikaCluster' was INVALIDATED,
>    transactions that were not yet replicated may be lost.
> In case of network partitions and similar, the former PRIMARY Cluster 'poliklinikaCluster'
>    may still be online and a split-brain can happen. To avoid it, use <Cluster>.fenceAllTraffic() ...
>    failover took 21617 ms           (tiket 11: 23 064 ms)
> clusterset status = AVAILABLE ;  drCluster = PRIMARY ;  poliklinikaCluster = INVALIDATED
> ```
>
> Pročitaj ovo kroz D3. Shell ne može da pita mrtvi klaster šta je imao, pa proverava samo da li **među živima** 3309 ima najnoviji GTID skup. Ono što je bilo „u letu“ ostaje na mrtvim diskovima, i alat to sam kaže: *„may be lost“*. Shell manual to piše kao opšte pravilo:
>
> > *„There is no guarantee that data will be preserved in the event of an emergency failover.“*
>
> ### Popravka — skripta 40
>
> Kad su 3307 i 3308 ponovo podignuti, **ostali su `INVALIDATED` / `OFFLINE`** i nisu se sami vratili. Bilo je potrebno sledeće, redom: `rebootClusterFromCompleteOutage` → `rejoinCluster` → `setPrimaryCluster` nazad → `rejoinInstance(3308)`. Na kraju je stanje `HEALTHY`, a red `dr-after`, upisan na 3309 dok je bio primarni, postoji na sva tri čvora: stari klaster je preuzeo **novu** istoriju, a ne obrnuto.
>
> | | Switchover | Prinudni failover |
> |---|---|---|
> | Stari primarni | živ, zaključan, preda sve | mrtav ili odsečen |
> | Ko pokreće | operater | operater (3309 sam ne sme) |
> | Trajanje (danas) | 539 ms | 21 617 ms |
> | Gubitak | ništa | ono što je bilo u kanalu |
> | Posle | sve `OK` | stari klaster `INVALIDATED`, ručna popravka |
>
> Pitanje koje sledi: zašto se stari klaster označava sa `INVALIDATED` i ne pušta se da se sam vrati.
>
> Napiši „next“.


> [!quote] YOU
> next


> [!question] Quiz
> Posle forcePrimaryCluster('drCluster') stari primarni klaster je označen sa INVALIDATED, i kad se njegovi čvorovi podignu ne vraćaju se sami u ClusterSet. Zašto?
>
> 1. Može da ima transakcije koje novi primarni nema, pa sme nazad tek posle provere operatera
> 2. Može da ima manje članova od novog, pa sme nazad tek kad dobije većinu
> 3. Može da ima stariju verziju MySQL-a, pa sme nazad tek posle nadogradnje
> 4. Može da ima drugačiji GTID format, pa sme nazad tek posle konverzije imena


> [!success] Quiz — correct ✓
> Your answer: 1. Može da ima transakcije koje novi primarni nema, pa sme nazad tek posle provere operatera
> Correct answer: 1
>
> Transakcije koje su komitovane na starom primarnom, a nisu stigle kroz asinhroni kanal (D3), postoje samo na njegovim diskovima. Novi primarni je u međuvremenu nastavio svoju istoriju. Kad bi se stari sam priključio, dve istorije bi se tiho spojile ili sudarile. INVALIDATED je ograda: Shell manual kaže da se stari primarni označava kao invalidated „for safety“, jer konzistentnost podataka nije zagarantovana. Verzija, broj članova i format GTID-a nemaju veze sa ovim (GTID je isti format svuda, samo različiti UUID-ovi).


> [!abstract] PI
> Tačno. `INVALIDATED` je ograda oko istorije koja se možda razišla. Ostaje poslednji čvor, vrhunac celog rada.
>
> ## Čvor D5 — isti proizvod, suprotni CAP izbori na dva nivoa
>
> ### Prvo, ispravka prvog pitanja iz provere znanja
>
> U pitanju 1 (grupa, 3308 i 3309 ubijeni, upis na 3307 visi, čitanje radi) izabrao si „dostupnost“. Kasnije si apstraktno tačno rekao da odbijen ili zadržan upis znači žrtvovanu dostupnost. Šta je zbunilo: **čitanje je radilo**. Ključ je da se CAP izbor procenjuje **po operaciji**, a ne za sistem u celini:
>
> - **upis** na 3307 nije dobio odgovor, iako čvor radi → za upise **dostupnost je žrtvovana**, a dobitak je da se nijedan upis ne razilazi;
> - **čitanje** je dobilo odgovor. U pravoj particiji, gde većina na drugoj strani nastavi sa upisima, to čitanje bi moglo da vrati zastarele podatke. Za čitanja manjina, dakle, bira dostupnost. Ovo je **naše izvođenje** iz rada grupe, a ne rečenica iz manual-a.
>
> Tvoja intuicija nije bila pogrešna, samo je primenjena na pogrešnu operaciju. Rad se odnosi na **upise**, jer se razilaženje dešava samo kroz njih. Refman 8.4 (Group Replication Background):
>
> > *„If there is a network partition, resulting in a split where members are unable to reach agreement, then the system does not progress until this issue is resolved.“*
>
> ### Drugo, ista pitanja na nivou ClusterSet-a
>
> Ceo primarni klaster je nestao ili je odsečen. Replika-klaster ima dve mogućnosti:
>
> - ostati samo za čitanje (kao 3309 pre operatera: `UNAVAILABLE`, upis odbijen) → konzistentnost;
> - preuzeti upise bez starog klastera (`forcePrimaryCluster`) → dostupnost, uz cenu „may be lost“ i „split-brain can happen“.
>
> ClusterSet je napravljen da omogući ovo drugo, i proizvođač to kaže sam, u Shell manual-u:
>
> > *„It is important to know that InnoDB ClusterSet prioritizes availability over data consistency in order to maximize disaster tolerance.“*
>
> Isto važi i **bez** particije, u normalnom radu: između klastera se ne čeka (asinhroni kanal), pa replika-klaster može da kasni. Kratka latencija se kupuje zastarelošću. Unutar klastera je obrnuto: svako komitovanje čeka većinu.
>
> ### Stavi ih jedno pored drugog
>
> | | Unutar klastera (Group Replication) | Između klastera (ClusterSet) |
> |---|---|---|
> | Kad se izgubi veza | manjina blokira upise | replika-klaster sme da preuzme upise |
> | Bira | konzistentnost | dostupnost |
> | U normalnom radu | čeka većinu (plaća latenciju) | ne čeka (prihvata zastarelost) |
> | Rečima proizvođača | „does not progress until this issue is resolved“ | „prioritizes availability over data consistency“ |
>
> **Isti proizvod, suprotni izbori na dva nivoa, i oba rečima proizvođača.** Pogledaj još jednom ko je u D4 zapravo napravio izbor dostupnosti: ne MySQL, nego **operater** koji je pokrenuo `forcePrimaryCluster`. Dok on to nije uradio, 3309 je birao konzistentnost (odbijao upis).
>
> To je okosnica rada iz `GLOSSARY.md` §0: *MySQL ne isporučuje model konzistentnosti — isporučuje log i skup podesivih tačaka potvrde, pa je konzistentnost odluka operatora, a ne svojstvo sistema.* Ovde je ta tačka bukvalno jedna komanda.
>
> Pitanje koje sledi: ko i gde bira dostupnost u ClusterSet-u.
>
> Napiši „next“.


> [!quote] YOU
> next


> [!question] Quiz
> ClusterSet: primarni klaster u Beogradu je odsečen, a replika-klaster u Nišu radi. Dok niko ništa ne pokrene, Niš odbija upise. Kada i čijom odlukom ClusterSet prelazi sa izbora konzistentnosti na izbor dostupnosti?
>
> 1. Kad MySQL Router preusmeri upise na Niš
> 2. Kad većina članova oba klastera izglasa Niš
> 3. Kad operater pokrene forcePrimaryCluster na Nišu
> 4. Kad Niš posle isteka vremena sam preuzme upise


> [!success] Quiz — correct ✓
> Your answer: 3. Kad operater pokrene forcePrimaryCluster na Nišu
> Correct answer: 3
>
> Izbor dostupnosti je jedna komanda operatera: forcePrimaryCluster. Na našoj topologiji 3309 je ostao super_read_only = 1 i UNAVAILABLE sve dok je nismo pokrenuli. Između klastera nema zajedničkog glasanja (zajednički niz postoji samo unutar grupe), a Router samo prati ko je primarni; on ne može da napravi upisivača od klastera koji je samo za čitanje. Zato je konzistentnost ovde bukvalno odluka operatera.


> [!abstract] PI
> Ceo graf je izgrađen. Ostaje još jedno pitanje za proveru: varijanta prvog pitanja iz provere znanja, da vidimo da li je ta greška stvarno ispravljena. Nema novog objašnjenja, pa ide odmah.


> [!question] Quiz
> Grupa od pet članova, single-primary, primarni je A. Mreža se podeli: A i B na jednoj strani, C, D i E na drugoj. Za UPIS koji klijent pošalje na A, koji je CAP izbor?
>
> 1. Dostupnost: upis na A prolazi, jer je A i dalje primarni
> 2. Konzistentnost: upis na A visi, jer A i B nisu većina
> 3. Dostupnost: upis na A prolazi, jer čitanje na A radi
> 4. Konzistentnost: upis na A se odbija greškom 1180


> [!success] Quiz — correct ✓
> Your answer: 2. Konzistentnost: upis na A visi, jer A i B nisu većina
> Correct answer: 2
>
> A i B su 2 od 5, manjina, pa upis ne dobija mesto u zajedničkom nizu i visi. Grupa bira konzistentnost za upise. Uloga primarnog kaže gde se upisi primaju, a ne ko odlučuje (lekcija 0005). To što čitanje na A radi tiče se čitanja, ne upisa: CAP se procenjuje po operaciji. Greška 1180 je poraz u sukobu upisa (certification), a ne gubitak kvoruma; ovde upis ne dobija grešku, nego ne dobija ništa.


> [!abstract] PI
> Svih pet figura sam pregledao i ispravne su. Sada snimam primer za proveru stanja kao trajnu skriptu i gledam strukturu referentne kartice.


> [!abstract] PI
> Now the index, glossary, ticket, examples README.


> [!abstract] PI
> Lekcija 06 je naučena, zapisana, commitovana i pushovana (`0a21023`). Otvorio sam je u pregledaču.
>
> **Kako je prošlo.** Sva tri mesta gde si pogrešio u proveri znanja ispravljena su tokom lekcije, a na kraju si tačno odgovorio i na ponovljena pitanja:
> - **CAP se procenjuje po operaciji.** U grupi koja je izgubila većinu upis visi, i to je izbor konzistentnosti, iako čitanje i dalje radi.
> - **Šta pokriva OK u ClusterSet-u.** Samo većinu primarnog klastera. Transakcije koje su još u asinhronom kanalu mogu da se izgube. Na ovo si u proveri znanja odgovorio „ne znam“.
> - **Grupa preko regiona.** Svako komitovanje čeka bar jedno povratno putovanje do udaljenog člana. Primena kod ostalih je asinhrona, ali dogovor o redosledu nije.
>
> **Uživo na našoj topologiji (3306 nisam dirao):**
> - Switchover je trajao 539 ms, a povratak 444 ms, bez gubitka podataka.
> - Prinudni failover je trajao 21 617 ms. Pre komande, 3309 se nije sam unapredio i odbijao je upis. Posle nje, stari klaster je ostao `INVALIDATED`.
> - Popravka je uspela, ali je 3308 posle skripte 40 morao ručno da se vrati u grupu (`rejoinInstance`). To skripta ne radi sama, pa sam to zapisao.
> - Na kraju je topologija vraćena u asinhrono stanje.
>
> **Šta treba proveriti pre pisanja poglavlja:** adrese Shell dokumentacije sa oznakom `8.4` trenutno prikazuju sadržaj verzije 26.7. Tačne reči citata treba ponovo proveriti pre nego što uđu u `rad.md`.
>
> **Novo pravilo za predavanje** (upisano u `TEACHING.md`): objašnjenje, pa ti napišeš „next“, pa tek onda kviz. Uzrok nestajanja teksta iz Obsidian-a nisam našao u `md-log.ts`. Dugačka objašnjenja poslata u istom potezu kao kviz nisu se upisivala, a kratka jesu. Ako hoćeš da se to popravi u samom proširenju, to je poseban zadatak.
>
> **Sledeće:** pisanje Poglavlja 6 u zasebnoj sesiji, oko 3 strane. Na početku idu tri pitanja za ponavljanje iz zapisa 0008.
>
> **Napravljeno ili izmenjeno u ovoj sesiji:**
> - `lessons/0006-geo-clusterset.html` (lekcija, pet figura iz `viz/viz-l06-*.png`, kviz od 8 pitanja)
> - `reference/clusterset.html` (nova referentna kartica)
> - `learning-records/0008-geo-clusterset.md` i red u `learning-records/README.md`
> - `.scratch/replikacija/measurements/0008-geo-clusterset.md` i `raw/0008-*.txt`
> - `examples/01-group-replication/43-clusterset-status.js` (nova skripta)
> - novi termini u `GLOSSARY.md` (§1b⁗''')
> - unos „Progress“ u tiketu 18
