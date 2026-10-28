> [!quote] YOU
> > [!note] SKILL loaded: teach
>
> Chapter 7 – Skaliranje čitanja i kašnjenje replikacije (ticket 19, lesson half). Read
>  .scratch/replikacija/issues/19-chapter-7-read-scaling.md, learning-records/README.md, records 0001 + 0007, and memo
>  06. Cover: lag defined and coming from the applier, not the receiver; the three reasons Seconds_Behind_Source is
>  unreliable vs the performance_schema timestamps; the read-your-writes and monotonic-reads problems on an async replica
>  (induced with SOURCE_DELAY, BEFORE only mentioned as the fix); WAIT_FOR_EXECUTED_GTID_SET() / SOURCE_POS_WAIT(); what
>  read scaling doesn't scale. Run live on 3307–3309 (start with topology.ps1, async state), including the one
>  natural-lag burst to figures/raw/*.csv. No chapter writing this session.

> [!question] Question — Obsidian
> Da li želiš da se ova lekcija prati uživo u Obsidian belešci?
>
> 1. Da, nova beleška (Recommended)
> 2. Da, postojeća beleška
> 3. Ne

> [!example] Answer
> Da, nova beleška (Recommended)

> [!abstract] PI
> Topologija radi: 3307 → 3308 i 3307 → 3309, obe niti su `ON`, `SOURCE_DELAY = 0` i 4 niti primene na obe replike. To je asinhrono stanje, a 3306 nismo dirali.
>
> Napravio sam praznu belešku. Nalepi ovo i javi kad se poveže:
>
> ```
> /md-log lessons-live/0009-skaliranje-citanja.md
> ```


> [!quote] YOU
> continue


> [!abstract] PI
> Počinjemo proverom znanja. Prvo nekoliko kratkih pitanja da vidim dokle sežeš, pa tek onda plan lekcije.


> [!question] Quiz
> Na 3307 se upisuje nalet od 4 000 malih transakcija. Replika 3308 ima jednu nit primene, mreža je loopback. Šta će se najverovatnije videti na 3308 posle nekoliko sekundi?
>
> 1. Relay log i nit primene zaostaju podjednako, korak u korak
> 2. Relay log je već primio ceo nalet, a nit primene još zaostaje
> 3. Relay log još prima nalet, a nit primene čeka na nove događaje
> 4. Nit prijema čeka da nit primene isprazni relay log


> [!success] Quiz — correct ✓
> Your answer: 2. Relay log je već primio ceo nalet, a nit primene još zaostaje
> Correct answer: 2
>
> Nit prijema samo kopira bajtove u relay log (jeftino, sekvencijalno). Nit primene mora da izvrši svaku transakciju i da je komituje, a to je skupo. Zato se kašnjenje gomila iza relay loga, na strani niti primene. Izmereno u ticketu 10: Relay_Log_Space je prestao da raste posle ~3 s, a kašnjenje je raslo dalje do 10 s.


> [!question] Quiz
> Šta tačno meri `Seconds_Behind_Source` u `SHOW REPLICA STATUS`?
>
> 1. Trenutno vreme replike minus vremenska oznaka događaja koji nit primene upravo obrađuje
> 2. Razliku između poslednjeg primljenog i poslednjeg primenjenog GTID-a, u sekundama
> 3. Broj sekundi potreban da nit primene isprazni ceo relay log
> 4. Trenutno vreme izvora minus vreme poslednje transakcije primenjene na replici


> [!question] Quiz — I don't know
> Your answer: I don't know
> Correct answer: 1
>
> Refman 8.4 (SHOW REPLICA STATUS): to je razlika između trenutne vremenske oznake replike i vremenske oznake koju je izvor upisao uz događaj koji nit primene trenutno obrađuje. Računa se na replici, njenim satom, i gleda samo nit primene. Iz te definicije proizlaze sve njegove slabosti.


> [!question] Quiz
> Klijent ništa ne upisuje. Pročita red sa 3308 (koja kasni 0,1 s) i vidi novu vrednost. Odmah zatim isti red pročita sa 3309 (koja kasni 3 s) i vidi staru vrednost. Koja garancija je prekršena?
>
> 1. Read-your-writes
> 2. Konačna konzistentnost
> 3. Nijedna, jer klijent ništa nije upisao
> 4. Monotona čitanja


> [!success] Quiz — correct ✓
> Your answer: 4. Monotona čitanja
> Correct answer: 4
>
> Klijent ništa nije upisao, pa read-your-writes nema na šta da se odnosi. Ali drugo čitanje vidi stanje starije od prvog: vreme je za tog klijenta „krenulo unazad“. To je kršenje monotonih čitanja. Konačna konzistentnost nije prekršena, jer 3309 će na kraju stići do iste vrednosti.


> [!question] Quiz
> Aplikacija je upravo komitovala upis na 3307 i hoće da ga pročita sa 3309, bez zastarelog rezultata. Šta joj treba da bi na 3309 sačekala tačno taj upis, ni manje ni više?
>
> 1. Vrednost Seconds_Behind_Source sa 3309, i na 3309 čekanje toliko sekundi pre čitanja
> 2. GTID tog upisa, uzet sa izvora posle COMMIT-a, i na 3309 čekanje dok ga gtid_executed ne sadrži
> 3. Ništa posebno, dovoljno je da sesija na 3309 postavi nivo izolovanosti SERIALIZABLE
> 4. GTID tog upisa, uzet sa 3309 posle COMMIT-a, i na 3309 čekanje dok ga relay log ne sadrži


> [!question] Quiz — I don't know
> Your answer: I don't know
> Correct answer: 2
>
> Samo izvor zna ime (GTID) transakcije koju je upravo komitovao. Replika mora da čeka da se ta transakcija primeni (gtid_executed), a ne samo primi (relay log): primljeno, a neprimenjeno, još nije vidljivo. To je upravo WAIT_FOR_EXECUTED_GTID_SET(). SERIALIZABLE je lokalna izolovanost na jednom serveru i ne zna ništa o tome šta replika još nije primenila.


> [!question] Quiz
> Na 3309 se GTID `…:4837` nalazi u `RECEIVED_TRANSACTION_SET` (tabela `replication_connection_status`), ali ga nema u `gtid_executed`. Šta `SELECT` na 3309 vidi od te transakcije?
>
> 1. Ništa, jer je transakcija samo u relay logu i još nije primenjena
> 2. Deo, jer nit primene vidljivo upisuje red po red dok radi
> 3. Sve, ali samo u sesiji koja koristi nivo izolovanosti READ UNCOMMITTED
> 4. Sve, jer je transakcija već stigla na repliku i nalazi se na disku


> [!success] Quiz — correct ✓
> Your answer: 1. Ništa, jer je transakcija samo u relay logu i još nije primenjena
> Correct answer: 1
>
> Relay log je fajl koji čeka na primenu, a ne podatak u tabelama. Upit vidi samo ono što je nit primene komitovala u InnoDB-u, odnosno ono što je u gtid_executed. Ni READ UNCOMMITTED to ne menja: on vidi nekomitovane redove u InnoDB-u, a ova transakcija u InnoDB još nije ni ušla. Zato važi „primljeno, a neprimenjeno“.


> [!question] Quiz
> Izvor 3307 sa jednom replikom stiže 1 000 upisa/s i 5 000 čitanja/s. Dodaju se još četiri replike za čitanje, a sva čitanja se ravnomerno raspoređuju na njih. Koliko upisa u sekundi sada mora da primeni svaka replika?
>
> 1. 250, jer izvor zadržava petinu upisa za sebe
> 2. 1 000, isto koliko i izvor
> 3. 0, jer replike za čitanje ne primaju upise
> 4. 200, jer se upisi dele na pet replika


> [!success] Quiz — correct ✓
> Your answer: 2. 1 000, isto koliko i izvor
> Correct answer: 2
>
> Replika je kopija celog skupa podataka, pa mora da ponovi svaki upis. Svaka replika primenjuje svih 1 000 upisa/s, bez obzira na to koliko replika ima. Dodavanjem replika dele se čitanja, a ne upisi. Ako nit primene neke replike ne može da izdrži 1 000/s, kašnjenje te replike raste bez granice.


> [!question] Quiz
> Izvor i replika su na identičnom hardveru. Na izvor upisuje 16 sesija istovremeno, a nezavisne transakcije idu u različite redove. Replika ima `replica_parallel_workers = 1`. Šta se dešava sa kašnjenjem pod stalnim opterećenjem?
>
> 1. Raste, jer replika radi serijski ono što je izvor radio paralelno
> 2. Ostaje blizu nule, jer replika ne mora da izvršava SELECT deo upita
> 3. Ostaje blizu nule, jer je hardver replike identičan hardveru izvora
> 4. Raste samo dok se relay log ne napuni, a onda se ustali


> [!question] Quiz — I don't know
> Your answer: I don't know
> Correct answer: 1
>
> Ista mašina ne znači isti posao po jedinici vremena. Izvor je 16 transakcija izvršavao uporedo, a jedna nit primene mora da ih izvrši jednu po jednu. Njena propusnost je gornja granica, a ako je brzina upisa iznad te granice, kašnjenje raste linearno. Zato se pravi više niti primene (ticket 10: 40,5 s → 4,95 s sa 4 niti, ali za idealan slučaj nezavisnih upisa).


> [!question] Question — Primeri
> Ko pokreće primere na topologiji tokom lekcije?
>
> 1. Ti pokrećeš, ja čitam (Recommended)
> 2. Ja pokrećem sam

> [!question] Question — POS_WAIT
> Koliko duboko da obradimo SOURCE_POS_WAIT()?
>
> 1. Kratko, kao stariji rođak (Recommended)
> 2. Ravnopravno sa GTID funkcijom


> [!example] Answer
> **Ko pokreće primere na topologiji tokom lekcije?**
> Ti pokrećeš, ja čitam (Recommended)
>
> **Koliko duboko da obradimo SOURCE_POS_WAIT()?**
> Kratko, kao stariji rođak (Recommended)


> [!abstract] PI
> ## Plan lekcije 07: Skaliranje čitanja i kašnjenje replikacije
>
> **Pristup.** Krećemo od onoga što već čvrsto znaš: transakcija koja je primljena, a nije primenjena, nije vidljiva, i kašnjenje se gomila iza relay loga. Na tome uvodimo pravu definiciju kašnjenja kao vremena za jednu transakciju. Zatim dolazi definicija `Seconds_Behind_Source` iz priručnika, i iz nje izvodimo sve tri njegove slabosti, umesto da ih učiš napamet. Odmah posle toga ide `performance_schema` kao merenje koje direktno odgovara definiciji kašnjenja. Tu ću ti pošteno reći šta ono **ne** rešava: i dalje poredi dva sata, samo što ih mi na jednoj mašini imamo kao jedan.
>
> Na ovom mestu pokrećem **jedini prirodni nalet** na 3309 sa jednom niti primene i snimam obe veličine u `figures/raw/*.csv`, a ti predviđaš rezultat pre nego što ga vidiš. Zatim sa `SOURCE_DELAY` izazivamo dve anomalije: read-your-writes na jednoj replici i monotona čitanja preko dve replike. Popravku izvodimo iz pitanja „šta replika mora da zna da bi čekala tačno moj upis?“. Odgovor je ime transakcije, odnosno `WAIT_FOR_EXECUTED_GTID_SET()`, a `SOURCE_POS_WAIT()` je ista ideja sa adresom umesto imena. `BEFORE` samo pominjemo i povezujemo sa poglavljem 5. Na kraju ide ono što ti je izmaklo u proveri znanja: zašto jedna nit primene zaostaje čak i na istom hardveru. To je druga stvar koju skaliranje čitanja ne skalira, pored upisa. `MySQL Router` dobija jednu rečenicu: ima `wait_for_my_writes`, isti princip čekanja, samo u posredniku.
>
> Iskreno upozorenje unapred: ne znam da li će se dve krive u prirodnom naletu zaista razići. Sa jednom niti primene `Seconds_Behind_Source` bi mogao lepo da prati pravo kašnjenje. Ako se to desi, prijaviću to onako kako jeste i nećemo nameštati sliku.
>
> ```mermaid
> graph TD
>   R1["✔ primljeno ≠ primenjeno;<br/>kašnjenje je iza relay loga"]
>   R2["Definicija: kašnjenje = komit na izvoru<br/>→ primena na replici, po transakciji"]
>   R3["Definicija Seconds_Behind_Source:<br/>sat replike − oznaka događaja u primeni"]
>   D1["3 slabosti, izvedene iz definicije:<br/>slep za prijem · dva sata · MT pozicija"]
>   D2["performance_schema: oznake po<br/>transakciji i po fazi (+ šta ne rešava)"]
>   L1["UŽIVO: prirodni nalet,<br/>obe krive → CSV"]
>   D3["SOURCE_DELAY → read-your-writes<br/>i monotona čitanja prekršeni"]
>   D4["Čekaj ime: WAIT_FOR_EXECUTED_GTID_SET<br/>adresu: SOURCE_POS_WAIT · BEFORE (pomen)"]
>   D5["Šta se ne skalira: upisi i<br/>propusnost niti primene"]
>   G(("Poglavlje 7<br/>spremno za pisanje"))
>   R1 --> R2 --> D2
>   R3 --> D1 --> D2 --> L1
>   R1 --> D3 --> D4 --> G
>   R2 --> D5 --> G
>   L1 --> G
> ```
>
> Da li je plan u redu? Ako jeste, krećem od R2.


> [!quote] YOU
> Moze


> [!abstract] PI
> ## Čvor R2: šta je tačno kašnjenje replikacije
>
> **Zašto nam treba.** „Replika kasni“ je nejasna rečenica. Kasni u čemu: u bajtovima, u događajima, u sekundama? Aplikaciju zanima samo jedno: **koliko su stari podaci koje čitam sa replike**. Na to pitanje može da se odgovori samo za konkretnu transakciju, pa i definicija mora da bude za konkretnu transakciju.
>
> **Definicija.** Za transakciju $T$:
>
> $$
> \text{kašnjenje}(T) = t_{\text{primenjena na replici}}(T) - t_{\text{komitovana na izvoru}}(T)
> $$
>
> To je razlika dva trenutka, od kojih svaki pripada jednoj transakciji. Ništa se ne „procenjuje“.
>
> **Razlaganje po fazama.** Između ta dva trenutka $T$ prolazi kroz dve faze koje već znaš iz lekcije 02:
>
> ```
> izvor COMMIT ──[prijem: mreža + upis u relay log]──▶ u relay logu ──[primena: izvrši + komituj]──▶ vidljiva
>     t₀                                                   t₁                                          t₂
>           kašnjenje prijema = t₁ − t₀                            kašnjenje primene = t₂ − t₁
>                           ukupno kašnjenje(T) = t₂ − t₀
> ```
>
> Ukupno kašnjenje je zbir dve faze. Na našoj topologiji (loopback) prijem traje delove milisekunde. Iz provere znanja znaš da je primena skupa faza: nit primene mora da izvrši i komituje svaku transakciju. Zato je na našoj topologiji **izvor kašnjenja nit primene, a ne nit prijema**. Na sporoj mreži udeo prijema raste. To ćemo iskoristiti za prvu slabost `Seconds_Behind_Source`.
>
> **Veza sa onim što već znaš.** U trenutku $t$ replika pokazuje stanje izvora iz trenutka $t - \text{kašnjenje}$. Ako klijent pročita red sa replike pre nego što prođe kašnjenje njegovog upisa, upis još nije u fazi „vidljiva“ ($t_2$), iako je možda već u relay logu ($t_1$). Tačno to si u proveri znanja nazvao „primljeno, a neprimenjeno“. Kašnjenje je dužina tog prozora.
>
> Napiši „next“ kad pročitaš, ili postavi pitanje.


> [!quote] YOU
> next


> [!question] Quiz
> Transakcija T je komitovana na 3307 u 10:00:00,000. U relay log na 3309 upisana je u 10:00:00,002, a nit primene ju je komitovala u 10:00:01,500. Koliko je kašnjenje replikacije za T i koja faza ga čini?
>
> 1. 2 ms, jer je T od tada već na replici
> 2. 1 498 ms, jer se prijem ne računa u kašnjenje
> 3. 1 500 ms, skoro ceo deo je kod niti primene
> 4. 1 500 ms, skoro ceo deo je kod niti prijema


> [!failure] Quiz — incorrect ✗
> Your answer: 2. 1 498 ms, jer se prijem ne računa u kašnjenje
> Correct answer: 3
>
> Kašnjenje je od komitovanja na izvoru do primene na replici: 01,500 − 00,000 = 1 500 ms. Od toga prijem traje 2 ms, a primena 1 498 ms. Prijem je deo kašnjenja, samo što je ovde mali. Opcija „2 ms“ meša „primljeno“ sa „vidljivo“: u 00,002 T je u relay logu, ali je SELECT još ne vidi.


> [!abstract] PI
> Ovaj promašaj je moja greška, jer sam napisao „izvor kašnjenja je nit primene“. Te reči su dve različite tvrdnje, pa ih razdvajam.
>
> **1. Definicija** kaže šta kašnjenje **jeste**. Ona ne bira fazu: meri se od $t_0$ (komit na izvoru) do $t_2$ (vidljivo na replici). Klijentu je potpuno svejedno gde je njegov upis proveo to vreme. Važno mu je samo to da ga za to vreme `SELECT` ne vidi. Zato se prijem **uvek** računa.
>
> **2. „Izvor kašnjenja je nit primene“** je **merenje na našoj topologiji**. Ono kaže koja faza ovde **čini veći deo** zbira. Na loopbacku prijem traje oko 2 ms, a primena oko 1 498 ms, pa skoro ceo zbir dolazi od primene. To je činjenica o našoj topologiji, a ne deo definicije.
>
> ```
>             prijem          primena
> loopback:   ▏2 ms           ████████████████ 1 498 ms      → ukupno 1 500
> spora mreža:████████ 800 ms ████████████████ 1 498 ms      → ukupno 2 298
> ```
>
> Na sporoj mreži, na primer između dva data centra, prijem može da postane veliki sabirak. Ako bi se on brisao iz definicije, upravo ta replika bi izgledala kao da ne kasni. To je tačno slabost koju ćemo naći u `Seconds_Behind_Source`.
>
> Napiši „next“.


> [!quote] YOU
> next


> [!question] Quiz
> Replika je u drugom data centru. Transakcija T je komitovana na izvoru u 12:00:00,000, u relay log replike stiže u 12:00:00,900, a primenjena je u 12:00:01,000. Koliko je kašnjenje replikacije za T?
>
> 1. 0 ms, jer nit primene ne zaostaje za prijemom
> 2. 900 ms, od komita na izvoru do relay loga
> 3. 1 000 ms, od komita na izvoru do primene
> 4. 100 ms, od upisa u relay log do primene


> [!success] Quiz — correct ✓
> Your answer: 3. 1 000 ms, od komita na izvoru do primene
> Correct answer: 3
>
> Kašnjenje je uvek t₂ − t₀ = 1 000 ms. Ovde se raspodela obrnula: prijem nosi 900 ms, a primena samo 100 ms. Ko meri samo primenu (100 ms), potceniće kašnjenje deset puta. Ko meri samo to da li nit primene zaostaje za relay logom, prijaviće 0. Upravo to radi Seconds_Behind_Source na sporoj mreži.


> [!abstract] PI
> ## Čvor R3: šta je tačno `Seconds_Behind_Source`
>
> **Zašto nam treba.** To je broj koji svi gledaju (`SHOW REPLICA STATUS`), i to je prvo što će profesor pitati: „Kako znate koliko replika kasni?“ Da bi se znalo kad mu se ne sme verovati, treba znati **šta on zaista računa**. Nećemo učiti spisak mana napamet, nego ćemo ih izvesti iz definicije.
>
> **Definicija** (refman 8.4, `SHOW REPLICA STATUS`, preveo sam je):
>
> > Kada replika aktivno obrađuje izmene, ovo polje pokazuje razliku između **trenutne vremenske oznake na replici** i **originalne vremenske oznake zapisane na izvoru za događaj koji se trenutno obrađuje** na replici.
> > Kada se nijedan događaj trenutno ne obrađuje, vrednost je **0**.
>
> „Događaj koji se trenutno obrađuje“ je događaj u **niti primene**. Prevedeno na naše oznake:
>
> ```
> Seconds_Behind_Source = sada (sat REPLIKE) − t₀ (sat IZVORA) onog što nit primene trenutno radi
>                         u celim sekundama;  ako nit primene nema šta da radi → 0
> ```
>
> Uporedi to sa definicijom iz R2:
>
> | | prava definicija (R2) | `Seconds_Behind_Source` |
> |---|---|---|
> | **kome se meri** | jednoj transakciji $T$ | onome što je **trenutno u niti primene** |
> | **od** | $t_0$, komit na izvoru | $t_0$, oznaka izvora |
> | **do** | $t_2$, vidljiva na replici | „sada“, po satu replike |
> | **jedinica** | koliko god je potrebno | cele sekunde |
> | **kad nema posla** | — | 0 |
>
> Na prvi pogled ovo zvuči razumno: „koliko je star posao koji nit primene upravo radi“. Ali pogledaj kolonu „kome se meri“. Gleda se **samo nit primene**. Ono što je još na putu ka relay logu ne postoji za ovu formulu. Odatle ćemo izvesti prvu slabost, a iz kolona „od/do“ drugu.
>
> Napiši „next“, pa ti dajem prvi korak izvođenja.


> [!quote] YOU
> next


> [!question] Quiz
> Spora mreža: nit prijema zaostaje 30 s za izvorom, a nit primene trenutno nema šta da radi, jer je relay log ispražnjen i čeka sledeći događaj. Šta prema definiciji pokazuje `Seconds_Behind_Source`?
>
> 1. 30, jer je toliko star događaj koji nit prijema prima
> 2. NULL, jer nit primene trenutno ne obrađuje nijedan događaj
> 3. 0, jer nit primene trenutno ne obrađuje nijedan događaj
> 4. Više od 30, jer se sabiraju zaostatak prijema i primene


> [!success] Quiz — correct ✓
> Your answer: 3. 0, jer nit primene trenutno ne obrađuje nijedan događaj
> Correct answer: 3
>
> Formula gleda samo ono što nit primene trenutno radi, a ona ovde nema posla, pa je vrednost 0. Replika je pritom 30 s iza izvora. Refman to kaže izričito: na sporoj mreži polje „često pokazuje 0, čak i kad nit prijema kasni za izvorom“, i „korisno je samo za brze mreže“. To je slabost 1: polje ne vidi fazu prijema. NULL dolazi tek kad nit primene ne radi uopšte (ili kad je relay log ispražnjen, a i nit prijema stoji), a ovde obe niti rade.


> [!abstract] PI
> Slabost 1 je izvedena: polje ne vidi fazu prijema. Sledeći korak izvođenja polazi od kolona „od/do“.


> [!question] Quiz
> Izvor i replika su na različitim mašinama. Pri pokretanju niti prijema sat replike je bio tačno usklađen sa satom izvora. Kasnije NTP pomeri sat replike 4 s unapred, a stvarno kašnjenje je ceo period 1 s. Šta pokazuje `Seconds_Behind_Source` posle pomeranja?
>
> 1. Oko 5, jer se pomeraj sata replike dodaje na stvarno kašnjenje
> 2. NULL, jer MySQL otkriva da se sat replike promenio od pokretanja
> 3. Oko 1, jer MySQL pri svakom računanju ponovo usklađuje dva sata
> 4. Oko 3, jer se pomeraj sata replike oduzima od stvarnog kašnjenja


> [!failure] Quiz — incorrect ✗
> Your answer: 4. Oko 3, jer se pomeraj sata replike oduzima od stvarnog kašnjenja
> Correct answer: 1
>
> Formula oduzima oznaku sa sata izvora od „sada“ po satu replike. Ako sat replike skoči 4 s unapred, „sada“ je veće za 4 s, pa polje pokazuje oko 1 + 4 = 5. Refman: razlika satova se izračuna jednom, kad se nit prijema pokrene, i pretpostavlja se da ostaje konstantna; „svaka promena, uključujući NTP ažuriranja“, čini rezultat manje pouzdanim. To je slabost 2: dva sata. Važna ograda za kasnije: svako merenje koje oduzima vreme izvora od vremena replike ima ovu slabost, i to važi i za performance_schema.


> [!abstract] PI
> Pojam si uhvatio: pomeraj sata kvari rezultat. Promašen je samo **smer**, pa ga izračunajmo brojevima.
>
> Neka je pravo vreme **12:00:10**. Nit primene radi transakciju komitovanu na izvoru u **12:00:09**, po satu izvora, koji je tačan. Stvarno kašnjenje je 1 s.
>
> ```
>                         sat izvora (oznaka t₀)   sat replike ("sada")   Seconds_Behind_Source
> pre NTP-a (usklađeni):        12:00:09               12:00:10              10 − 9 = 1
> posle NTP-a (+4 s):           12:00:09               12:00:14              14 − 9 = 5
> ```
>
> Pomeren je **sat replike**, a on daje „sada“, odnosno **umanjenik**. Oznaka $t_0$ je zapisana na izvoru i zalepljena za događaj u binarnom logu, pa se ne menja. Veći umanjenik znači veću razliku. Kad sat replike ide unapred, polje laže **naviše**. Kad ide unazad, laže **naniže**, i može da prikaže 0 ili čak da sakrije pravo kašnjenje.
>
> Pravilo koje se ne mora pamtiti, jer sledi iz formule: **pomeraj sata replike se prenosi u rezultat sa istim znakom.**
>
> Jedna ograda, da ne bi izveo previše. Refman kaže da se razlika satova „izračuna kad se nit prijema pokrene“ i da se zatim pretpostavlja da je konstantna. MySQL dakle pokušava da poništi **početnu** razliku, ali ne prati **kasnije** pomeraje. Zašto baš tako, a ne ponovo pri svakom računanju, priručnik ne obrazlaže. To je odluka u dizajnu, a ne nešto što sledi iz principa.
>
> Napiši „next“.


> [!quote] YOU
> next


> [!question] Quiz
> Isti par mašina. Pri pokretanju niti prijema satovi su bili usklađeni, a stvarno kašnjenje je ceo period 3 s. Zatim NTP vrati sat replike 5 s unazad. Šta tada pokazuje `Seconds_Behind_Source`?
>
> 1. Više od stvarnog: replika deluje kao da kasni 8 s
> 2. Tačno 3, jer pomeraj unazad MySQL automatski poništava
> 3. Tačno 3, jer se pomera samo sat replike, a ne izvora
> 4. Manje od stvarnog: replika deluje kao da ne kasni


> [!success] Quiz — correct ✓
> Your answer: 4. Manje od stvarnog: replika deluje kao da ne kasni
> Correct answer: 4
>
> „Sada“ po satu replike opadne za 5 s, pa razlika ispada 3 − 5 = −2. Polje ne prikazuje negativne vrednosti (u izvornom kodu se negativna razlika svodi na 0), pa replika koja stvarno kasni 3 s izgleda kao da ne kasni. Ovo je opasniji smer, jer lažno „0“ niko ne istražuje. Napomena: to da se negativno svodi na 0 nije citat iz priručnika. Bitan je smer greške (naniže), a on sledi iz formule.


> [!abstract] PI
> Slabost 2 je izvedena: dva sata, i pomeraj sata replike prelazi u rezultat sa istim znakom. Ostaje treća.
>
> ## Slabost 3: više niti primene
>
> U definiciji stoji „**događaj** koji se trenutno obrađuje“, u jednini. Formula pretpostavlja da nit primene radi jednu stvar. U 8.4 to po pravilu nije tako: `replica_parallel_workers` ima podrazumevanu vrednost **4** (refman, i potvrđeno na našim replikama). Na repliki tada istovremeno radi koordinator i četiri niti primene, i svaka može da drži drugu transakciju:
>
> ```
> relay log:   … T100 T101 T102 T103 T104 T105 …
> nit 1:            [T101 radi]
> nit 2:                 [T102 ✔ gotova]
> nit 3:                      [T103 radi]
> nit 4:                           [T104 ✔ gotova]
>              ▲
>      Exec_Source_Log_Pos = kraj T100: sve PRE ove tačke je sigurno primenjeno, bez rupa
> ```
>
> Koja od ovih transakcija je „događaj koji se trenutno obrađuje“? Nijedan odgovor nije prirodan. MySQL zato uzima jednu tačku: **`Exec_Source_Log_Pos`**, odnosno poziciju do koje je sve primenjeno bez rupa. Refman: kod više niti primene vrednost „se zasniva na `Exec_Source_Log_Pos` i zato možda ne odražava poziciju poslednje komitovane transakcije“.
>
> Priručnik ne kaže na koju stranu ova greška ide, pa ni ja ne tvrdim smer. Tvrdi se samo da broj ne odgovara nijednoj konkretnoj transakciji. Prava definicija iz R2 se uvek odnosi na konkretnu transakciju $T$.
>
> **Sve tri slabosti dolaze iz iste rečenice definicije:**
>
> | deo definicije | šta iz njega sledi |
> |---|---|
> | „događaj koji **nit primene** obrađuje“ | slabost 1: faza prijema je nevidljiva, pa na sporoj mreži prikazuje 0 |
> | „**sat replike** − oznaka **izvora**“ | slabost 2: dva sata, pomeraj ide pravo u rezultat |
> | „**događaj**“, u jednini | slabost 3: kod više niti nema jednog događaja, pa MySQL uzima `Exec_Source_Log_Pos` |
>
> Usput, dve sitnije osobine se takođe vide iz definicije: rezultat je u **celim sekundama**, a kašnjenje na našoj topologiji je ispod sekunde. Uz to, „nema posla“ daje **0**, i ta nula ne razlikuje repliku koja je stigla izvor od replike koja ne vidi šta joj stiže.
>
> Napiši „next“.


> [!quote] YOU
> next


> [!question] Quiz
> Kolega kaže: „Na našoj produkciji je mreža brza i satovi su usklađeni preko NTP-a, pa je `Seconds_Behind_Source` pouzdan.“ Replike rade sa podrazumevanim podešavanjima 8.4. Šta je tačno?
>
> 1. Nije, jer na brzoj mreži nit prijema uvek zaostaje za niti primene
> 2. Jeste, jer se kod više niti uzima transakcija koja je poslednja komitovana
> 3. Nije, jer sa 4 niti primene vrednost ne odgovara nijednoj konkretnoj transakciji
> 4. Jeste, jer su brza mreža i usklasaeni satovi jedina dva uslova iz priručnika


> [!success] Quiz — correct ✓
> Your answer: 3. Nije, jer sa 4 niti primene vrednost ne odgovara nijednoj konkretnoj transakciji
> Correct answer: 3
>
> Brza mreža otklanja slabost 1, a usklađeni satovi slabost 2. Slabost 3 dolazi iz podrazumevane vrednosti replica_parallel_workers = 4: računa se od Exec_Source_Log_Pos, tačke bez rupa, koja „možda ne odražava poziciju poslednje komitovane transakcije“. Kolega je sredio dva od tri uslova.


> [!abstract] PI
> (Ispravka: u jednoj opciji je stajao „usklasaeni“. Trebalo je „usklađeni“.)
>
> Sada pravo merenje. Pokrećem ga uživo: jedan upis na 3307, zatim čitam oznake na 3309.


> [!abstract] PI
> ## Čvor D2: `performance_schema` meri tačno definiciju iz R2
>
> **Zašto.** Sve tri slabosti nastaju zato što `Seconds_Behind_Source` **ne meri jednu transakciju**. Prava popravka je onda očigledna: zapamtiti $t_0$, $t_1$ i $t_2$ **za svaku transakciju** i oduzimati ih. MySQL to radi. Uz svaku transakciju izvor u binarni log upisuje oznaku svog komita (`original_commit_timestamp`), a replika uz nju beleži kada je transakciju stavila u relay log i kada je završila primenu.
>
> **Uživo, upravo sada:** jedan upis u `heartbeat` na 3307, zatim čitanje na 3309:
>
> ```
> GTID …:17704
> t₀  komit na izvoru       15:33:28.241950   LAST_QUEUED_TRANSACTION_ORIGINAL_COMMIT_TIMESTAMP
> t₁  upisana u relay log   15:33:28.242674   LAST_QUEUED_TRANSACTION_END_QUEUE_TIMESTAMP
> t₂  primenjena (nit 1)    15:33:28.248325   LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP
>
> kašnjenje prijema  = t₁ − t₀ = 0,724 ms
> kašnjenje primene  = t₂ − t₁ = 5,651 ms
> ukupno kašnjenje   = t₂ − t₀ = 6,375 ms      (Seconds_Behind_Source bi ovde rekao: 0)
> ```
>
> To je R2 doslovno: **jedna transakcija, po imenu (GTID), obe faze odvojeno, u mikrosekundama.** Prijem je ispod milisekunde, primena je skoro celo kašnjenje, kao što smo i rekli za loopback.
>
> Kako ovo rešava slabosti:
>
> | slabost | `performance_schema` |
> |---|---|
> | 1, slep za prijem | ✔ rešeno: prijem ima svoje oznake ($t_1$) u `replication_connection_status` |
> | 3, više niti | ✔ rešeno: `replication_applier_status_by_worker` ima red **po niti**, svaki sa svojim GTID-om |
> | cele sekunde | ✔ rešeno: mikrosekunde |
> | **2, dva sata** | ✘ **NIJE rešeno.** $t_0$ je zapisan satom izvora, a $t_1$ i $t_2$ satom replike. Ako se satovi razlikuju, razlikuje se i ovaj rezultat. |
>
> Poslednji red je važan za odbranu. Na **našoj** topologiji su sve tri instance na jednoj mašini i koriste jedan sat, pa je slabost 2 ovde nula po konstrukciji, a ne zato što ju je `performance_schema` popravio. Isto važi i za tabelu `heartbeat`: replika računa `NOW(6) − ts`, gde je `ts` upisan satom izvora. Na dve mašine sve ove metode zavise od NTP-a. Ako te profesor pita „a satovi?“, tačan odgovor je „ta slabost ostaje, i mi je nismo mogli da izmerimo, jer imamo jedan sat.“
>
> Napiši „next“.


> [!quote] YOU
> next


> [!question] Quiz
> Na dve različite mašine sat replike je 2 s ispred sata izvora, a stvarno kašnjenje je 10 ms. Šta pokazuje razlika `LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP − LAST_APPLIED_TRANSACTION_ORIGINAL_COMMIT_TIMESTAMP`?
>
> 1. Oko 10 ms, jer su obe oznake vezane za istu transakciju
> 2. Oko 2 010 ms, jer se oduzimaju oznake sa dva različita sata
> 3. Oko 2 010 ms, jer performance_schema ne vidi fazu prijema
> 4. Oko 10 ms, jer performance_schema meri u mikrosekundama


> [!failure] Quiz — incorrect ✗
> Your answer: 4. Oko 10 ms, jer performance_schema meri u mikrosekundama
> Correct answer: 2
>
> END_APPLY je zapisan satom replike, a ORIGINAL_COMMIT satom izvora. Pomeraj od +2 s prelazi pravo u rezultat, isto kao kod Seconds_Behind_Source. To što se obe oznake odnose na istu transakciju rešava slabosti 1 i 3, a ne slabost 2. Mikrosekunde daju preciznost, a ne tačnost: pogrešnu vrednost samo izmere na šest decimala.


> [!abstract] PI
> Ovde treba razdvojiti dve stvari koje se lako pomešaju: **preciznost** i **tačnost**.
>
> - **Preciznost** je to koliko sitno je zapisan broj: cele sekunde ili mikrosekunde.
> - **Tačnost** je to koliko je broj blizu istine.
>
> Mikrosekunde daju preciznost. Tačnost zavisi od toga **šta se oduzima od čega**. Pogledaj odakle dolazi svaka oznaka:
>
> ```
> ORIGINAL_COMMIT_TIMESTAMP   ← napisao IZVOR, svojim satom, u trenutku komita; putuje kroz binarni log
> END_APPLY_TIMESTAMP         ← napisala REPLIKA, svojim satom, kad je završila primenu
>
> sat izvora:    12:00:00.000000  (komit)
> sat replike:   12:00:02.010000  (primena; stvarno je prošlo 10 ms, ali sat replike žuri 2 s)
> razlika:       2,010000 s       ← šest tačnih decimala pogrešnog broja
> ```
>
> `performance_schema` nigde ne sazna da sat replike žuri. Samo pročita dva broja i oduzme ih. Isto tako i `Seconds_Behind_Source` oduzima „sada“ replike od oznake izvora. **Obe metode imaju isti umanjenik i umanjilac, sa dva sata.** Mikrosekunde samo čine grešku od 2 s vidljivom na šestoj decimali.
>
> Pravilo: **svako merenje koje oduzima oznaku jednog servera od oznake drugog nasleđuje razliku njihovih satova.** Nijedna kolona to ne popravlja. To popravlja samo usklađivanje satova (NTP), ili merenje na jednoj mašini, kao kod nas.
>
> Zašto je onda `performance_schema` ipak bolji? Zbog slabosti **1 i 3**: vidi i fazu prijema, i vezan je za **konkretnu transakciju po imenu**. To su pravi dobici. Satove ne popravlja ni jedna ni druga metoda.
>
> Napiši „next“.


> [!quote] YOU
> next


> [!question] Quiz
> Koja od ovih izmena bi zaista uklonila uticaj razlike satova na merenje kašnjenja između dve mašine?
>
> 1. Povećanje replica_parallel_workers da bi primena bila brža
> 2. Merenje kroz tabelu heartbeat umesto performance_schema
> 3. Usklađivanje satova obe mašine preko NTP-a pre merenja
> 4. Merenje kroz performance_schema umesto Seconds_Behind_Source


> [!success] Quiz — correct ✓
> Your answer: 3. Usklađivanje satova obe mašine preko NTP-a pre merenja
> Correct answer: 3
>
> Sve tri metode (Seconds_Behind_Source, performance_schema, heartbeat) oduzimaju oznaku izvora od oznake replike, pa sve nasleđuju razliku satova. Promena metode tu ne pomaže. Pomaže samo uklanjanje same razlike: NTP, ili jedna mašina kao kod nas. Više niti primene smanjuje stvarno kašnjenje, ali ne menja grešku merenja.


> [!abstract] PI
> Teorija je postavljena. Sada dolazi jedini **prirodni** nalet, pa pripremam skriptu. Prvo da vidim kako postojeće JS skripte otvaraju sesije.


> [!abstract] PI
> Pre pravog naleta pokrećem skriptu jednom na malom uzorku, samo da proverim da li radi. Pravi nalet ide posle tvog predviđanja.


> [!abstract] PI
> Skripta radi. Probni nalet sam pustio namerno malo (600 transakcija), samo da proverim mehaniku, i podatke iz njega neću tumačiti pre tvog predviđanja. Sada pravi eksperiment.
>
> ## Čvor L1: jedini prirodni nalet
>
> **Postavka** (`examples/04-read-scaling/10-lag-burst.ps1`):
>
> - 3309 radi **bez** `SOURCE_DELAY`, a nit primene je ograničena na **jednu** (`replica_parallel_workers = 1`).
> - Na 3307 se **istovremeno** otvara 4 sesije, i svaka upisuje 500 redova u `visits`, svaki u svojoj transakciji. Ukupno je 2 000 transakcija.
> - Sve vreme, na svakih 250 ms, jedna sesija upisuje red u `heartbeat` na 3307, a uzorkivač na 3309 beleži:
>   - `Seconds_Behind_Source`
>   - kašnjenje poslednje primenjene transakcije iz `performance_schema`, $t_2 - t_0$ (definicija R2)
>   - `Relay_Log_Space`, odnosno koliko bajtova čeka u relay logu
> - Sve ide u `figures/raw/07-skaliranje-01-kasnjenje.csv`.
>
> Ovo je kašnjenje koje niko nije namestio. Izvor komituje 4 sesije uporedo i spaja više komita u jedan fsync (grupno komitovanje), a jedna nit primene mora da ih ponovi jednu po jednu. To je tačno ono pitanje iz provere znanja na koje si odgovorio „ne znam“, samo pokrenuto uživo.
>
> Napiši „next“ i dobićeš pitanje za predviđanje, pa onda pokrećem.


> [!quote] YOU
> next


> [!question] Quiz
> Izvor 3307 završi svih 2 000 transakcija za oko sekundu. Nit primene na 3309 (jedna nit, bez SOURCE_DELAY) treba mnogo duže. Šta će `Relay_Log_Space` na 3309 raditi dok nit primene još radi?
>
> 1. Raste ravnomerno, korak u korak sa kašnjenjem, sve dok se nalet ne primeni
> 2. Brzo skoči, pa se skoro ne menja, dok kašnjenje i dalje raste
> 3. Ostaje blizu nule, jer nit prijema čeka da nit primene oslobodi relay log
> 4. Brzo skoči, pa opada ravnomerno kako nit primene troši relay log


> [!failure] Quiz — incorrect ✗
> Your answer: 1. Raste ravnomerno, korak u korak sa kašnjenjem, sve dok se nalet ne primeni
> Correct answer: 2
>
> Nit prijema samo kopira bajtove i završi za otprilike isto vreme kao izvor, pa relay log skoči i stane. Kašnjenje posle toga raste samo zbog niti primene. Zašto ne opada ravnomerno: MySQL relay log ne skraćuje red po red, nego briše cele fajlove tek kad su potpuno primenjeni (relay_log_purge), pa se Relay_Log_Space ne smanjuje tokom primene unutar jednog fajla. To je detalj implementacije, ne princip, ali objašnjava zašto ravan deo traje do kraja.


> [!abstract] PI
> Pokrećem pa da vidimo šta podaci kažu.


> [!abstract] PI
> Rezultat pravog naleta, uživo, bez `SOURCE_DELAY`. Sirovi podaci su u `figures/raw/07-skaliranje-01-kasnjenje.csv`, 360 uzoraka.
>
> ```
>  t (s)   SBS (s)   pravo kašnjenje (ms)   Relay_Log_Space (B)
>   3.7      0              2                  285 651     ← pre naleta
>   4.2      0            344                  707 793     ← nalet stiže
>   4.5      0            607                  968 650     ← nit prijema je ZAVRŠILA
>   5.9      2          1 931                  970 315     ← dalje samo +333 B po heartbeat redu
>  13.3     10          9 229                  979 639
>  35.5     31         31 025                1 006 000     ← vrh
>  36.8     14         11 462                  …           ← pražnjenje
>  37.9      0              2                  …           ← stigla je izvor
>  43–49     1            1–2                  …           ← replika je stigla izvor, a SBS kaže 1
> ```
>
> **1. Relay log (tvoj promašaj).** Relay log je skočio sa 285 KB na 969 KB za oko pola sekunde, a posle toga je rastao samo za 333 B po heartbeat redu. Za to vreme kašnjenje je raslo do **31 s**. Nit prijema je ceo nalet povukla za ~0,5 s. Ostalih 30 s je čisto kašnjenje **primene**. Ako je relay log rastao korak u korak sa kašnjenjem, to bi značilo da prijem ne stiže da prati. Ovde se desilo suprotno: prijem je završio skoro odmah, a niti primene je ostalo da radi. Zašto `Relay_Log_Space` ne opada dok se primenjuje: MySQL briše relay log po celim fajlovima, kad su potpuno primenjeni, a ne red po red. To je detalj implementacije.
>
> **2. Neravnoteža propusnosti.** Izvor je komitovao 2 000 transakcija za **598 ms** (oko 3 300 u sekundi, 4 sesije uz grupno komitovanje). Jedna nit primene ih je ponavljala oko 33 s (oko 60 u sekundi). Kašnjenje zato raste skoro tačno **1 s po sekundi**: nalet je stigao odjednom, a primena ide svojim tempom. Napomena: nisam merio zašto baš oko 16 ms po transakciji `visits` na repliki. Tvrdim samo odnos, ne uzrok tog broja.
>
> **3. `Seconds_Behind_Source` naspram pravog kašnjenja.** Dok kašnjenje raste, SBS ga prati prilično verno, uz grešku do oko 1 s, jer zaokružuje na cele sekunde. Na dva mesta se razilaze:
> - **pri pražnjenju** SBS **precenjuje** pravo kašnjenje za do **4,2 s** (14 naspram 11,5);
> - **kad je replika stigla izvor** (pravo kašnjenje 1–2 ms), SBS pokazuje **1** u **30 od 219** uzoraka, u nizovima od nekoliko sekundi.
>
> Deo te razlike sigurno objašnjavaju cele sekunde. Oznaka događaja u binarnom logu je u celim sekundama, pa razlika dve zaokružene vrednosti može da bude 1 i kad je prošlo 2 ms. Da li ostatak objašnjava slabost 3 (kontrolna tačka `Exec_Source_Log_Pos`, a i jedna nit primene u 8.4 radi uz koordinatora), **nisam proverio**. To je hipoteza, ne nalaz. Potvrđeno je samo ono što je izmereno: kaže 1 kad je pravo kašnjenje 2 ms.
>
> Ovo je ista pojava koju je ticket 10 video sa SBS = 3 na replici koja nije imala šta da radi.
>
> Napiši „next“.


> [!quote] YOU
> nex


> [!question] Quiz
> U ovom naletu: izvor je komitovao 2 000 transakcija za 0,6 s, a relay log na 3309 je sve primio za oko 0,5 s. Pravo kašnjenje je ipak dostiglo 31 s. Šta bi najdirektnije skratilo tih 31 s?
>
> 1. Više niti primene na 3309, npr. vraćanje replica_parallel_workers na 4
> 2. Veći relay log na 3309, da bi stalo više transakcija odjednom
> 3. Brža mreža između 3307 i 3309, da bi nit prijema brže primala
> 4. Merenje kroz performance_schema umesto kroz Seconds_Behind_Source


> [!success] Quiz — correct ✓
> Your answer: 1. Više niti primene na 3309, npr. vraćanje replica_parallel_workers na 4
> Correct answer: 1
>
> Nit prijema je završila za 0,5 s, pa mreža i veličina relay loga ovde nisu usko grlo. Svih 30 s posle toga troši nit primene. Samo veća propusnost primene skraćuje kašnjenje, recimo više niti primene za nezavisne transakcije (ticket 10: 40,5 s → 4,95 s sa 4 niti, idealan slučaj). Promena metode merenja menja broj na ekranu, ne kašnjenje.


> [!abstract] PI
> Sledeći čvor su anomalije. Pripremam skriptu sa `SOURCE_DELAY` na 3309.


> [!abstract] PI
> ## Čvor D3: dve anomalije na asinhronoj replici
>
> **Zašto `SOURCE_DELAY`.** Prirodno kašnjenje na loopbacku traje 1–2 ms, osim kad ga izazove nalet. Anomalija koja se pojavi samo ponekad ne može da se pokaže, a ni da se ponovi. Zato je na 3309 postavljeno `SOURCE_DELAY = 3`. Refman: transakcija primljena od izvora „se ne izvršava pre nego što prođe bar N sekundi od njenog komita na neposrednom izvoru“. Ovo je **izazvano** kašnjenje, i svaki natpis ispod slike to mora da kaže (GLOSSARY §5). Pravi namena te opcije je zaštita od ljudske greške (`DELETE` bez `WHERE`), a mi je koristimo za ponovljiv eksperiment.
>
> **Uživo** (`examples/04-read-scaling/20-ryw-async.js`, dva pokretanja, isti ishod):
>
> ```
> A. read-your-writes
>    3307: UPDATE … SET v = 1           GTID …:20843, komitovano, klijent dobio OK
>    3309: SELECT v  →  0               ← sopstveni upis nije vidljiv
>          u RECEIVED_TRANSACTION_SET?  true     (primljeno)
>          u gtid_executed?             false    (nije primenjeno)
>          SQL_Remaining_Delay = 4      (traži se 3 s; izmereno oko 4 s, priručnik kaže „bar N“)
>
> B. monotona čitanja
>    3307: UPDATE … SET v = 2
>    isti klijent čita 3308  →  v = 2
>    pa čita 3309            →  v = 1   ← vreme za klijenta ide unazad
> ```
>
> **Povezivanje sa onim što već znaš:**
> - **A** je tvoja dijagnoza iz provere znanja: „primljeno, a neprimenjeno“. Kašnjenje iz R2 je dužina tog prozora (ovde oko 4 s). Klijent je čitao unutar prozora. Anomaliju ne pravi replika koja „ne radi“. Pravi je **ruter koji upis šalje na izvor, a čitanje na repliku, bez čekanja.**
> - **B** ne traži nikakav upis tog klijenta. Dovoljno je da on čita sa dve replike koje različito kasne. Read-your-writes je ovde potpuno nebitan, a monotona čitanja su ipak prekršena.
> - Obe su **sesijske garancije** iz poglavlja 2 (Terry et al.). Asinhrona replika ne daje ni jednu ni drugu, nego samo konačnu konzistentnost: 3309 će na kraju stići do istog stanja.
>
> Za Group Replication ovaj prozor zatvara `group_replication_consistency = 'BEFORE'`, izmereno u poglavlju 5 (0 od 40 zastarelih čitanja). Poglavlje 7 samo upućuje napred na to. Asinhrona replikacija nema takav prekidač na serveru, pa sledeći čvor gradi alat za nju.
>
> Napiši „next“.


> [!quote] YOU
> next


> [!question] Quiz
> Aplikacija šalje sve upise na 3307, a svako čitanje na nasumično izabranu repliku (3308 ili 3309). Korisnik A samo čita i dva puta zaredom otvori istu stranicu. Koju anomaliju A može da vidi, iako nikad ništa ne upisuje?
>
> 1. Kršenje monotonih čitanja, ako drugo čitanje ode na repliku koja više kasni
> 2. Kršenje konačne konzistentnosti, jer dve replike nikad neće dostići isto stanje
> 3. Kršenje read-your-writes, ako drugo čitanje ode na repliku koja više kasni
> 4. Nijednu, jer korisnik koji samo čita ne može da vidi zastarele podatke


> [!success] Quiz — correct ✓
> Your answer: 1. Kršenje monotonih čitanja, ako drugo čitanje ode na repliku koja više kasni
> Correct answer: 1
>
> Bez sopstvenog upisa read-your-writes nema na šta da se primeni. Ali nasumični ruter može prvo da pošalje A na 3308 (novije stanje), a zatim na 3309 (starije), i tada A vidi kako stanje ide unazad. To je slučaj B iz eksperimenta. Konačna konzistentnost se ne krši, jer obe replike na kraju dođu do istog stanja. Zastarelo čitanje može da dobije i neko ko samo čita.


> [!abstract] PI
> ## Čvor D4: čekati tačno svoj upis
>
> **Problem.** Čitanje sa 3309 je zastarelo zato što je došlo **pre** nego što je upis primenjen. Uzimanje uvek sa izvora rešava problem, ali onda nema skaliranja čitanja. Druga mogućnost je da replika **sačeka** pa da tek onda odgovori. Čeka na šta? „Dok ne bude stigla izvor“ je preširoko: pod stalnim upisima replika možda nikad ne bude potpuno stigla izvor. Treba čekati **tačno moj upis**, ni manje ni više.
>
> **Kako identifikovati „moj upis“?** Iz lekcije 02 znaš dva načina da se označi transakcija u binarnom logu:
>
> | | čime se označava | MySQL funkcija na replici |
> |---|---|---|
> | **ime** | GTID, npr. `…:20843` | `WAIT_FOR_EXECUTED_GTID_SET(gtid_set, timeout)` |
> | **adresa** | fajl + pozicija, npr. `node1-bin.000017`, `1154451` | `SOURCE_POS_WAIT(file, pos, timeout)` |
>
> Postupak je u oba slučaja isti: **izvor kaže ime ili adresu odmah posle COMMIT-a → klijent to nosi do replike → replika blokira dok to ne primeni → tek onda SELECT.**
>
> Refman, `WAIT_FOR_EXECUTED_GTID_SET`: čeka „dok server ne primeni sve transakcije“ iz skupa, „odnosno dok ne važi `GTID_SUBSET(gtid_set, @@GLOBAL.gtid_executed)`“. Vraća **0** za uspeh i **1** za istek vremena. Pazi: čeka `gtid_executed` (primenjeno), a ne relay log (primljeno). Tačno ta razlika je pravila anomaliju.
>
> **Uživo, `SOURCE_DELAY = 3` na 3309 (izazvano):**
>
> ```
> C. WAIT_FOR_EXECUTED_GTID_SET(g, 1)    → 1 posle 1 001 ms    SELECT → v = 2   ✘ i dalje zastarelo
> D. WAIT_FOR_EXECUTED_GTID_SET(g, 10)   → 0 posle 4 009 ms    SELECT → v = 4   ✔ sopstveni upis
> E. SOURCE_POS_WAIT(file, pos, 10)      → 1 posle 4 312 ms    SELECT → v = 5   ✔  (1 = broj događaja koje je čekala)
> ```
>
> Iz ovoga slede tri stvari:
>
> 1. **Istek vremena ne rešava ništa sam po sebi.** Slučaj C je vratio 1, a SELECT je ipak bio zastareo. Funkcija samo javlja da nije uspela. Aplikacija mora da odluči šta dalje: da pročita sa izvora, da prijavi grešku, ili da svesno prihvati zastarelost. Ako se povratna vrednost ne proveri, anomalija ostaje.
> 2. **Cenu plaća čitalac**: oko 4 s ovde, odnosno otprilike jedno kašnjenje. Ista podela kao kod `BEFORE` u poglavlju 5: prozor se zatvara tako što **neko čeka**. Upis na izvoru nije usporen.
> 3. **Zašto je GTID bolji od adrese.** Adresa važi samo u binarnom logu **jednog** izvora. Posle failovera novi izvor ima druge fajlove i druge pozicije, pa stara adresa ništa ne znači. GTID je isto ime na svakom serveru (lekcija 02). Zato refman `SOURCE_POS_WAIT` opisuje kao funkciju za „kontrolu sinhronizacije izvora i replike“, a GTID funkcija nadgleda sve GTID-ove primenjene na serveru, iz svih kanala.
>
> **Monotona čitanja** se zatvaraju istim alatom (ovo je izvedeno, nije citat): klijent pamti najveći GTID skup koji je već video i pre svakog čitanja traži od replike da ga sačeka. Tada nijedna replika ne može da mu pokaže stanje starije od onoga što je već video.
>
> **MySQL Router** (jedan pasus u poglavlju): u režimu razdvajanja čitanja i upisa (`access_mode=auto`) ima opciju `wait_for_my_writes`, kod koje čitanja u sesiji „čekaju poslednju upisanu transakciju sesije“, uz istek vremena posle kog prelazi na izvor. To je isti princip, samo prebačen u posrednika.
>
> Napiši „next“.


> [!quote] YOU
> next


> [!question] Quiz
> Aplikacija posle upisa na 3307 pozove na 3309 `SELECT WAIT_FOR_EXECUTED_GTID_SET(g, 2)`, a odmah zatim SELECT, bez provere povratne vrednosti. Replika ima `SOURCE_DELAY = 3`. Šta korisnik vidi?
>
> 1. Svoj upis, jer funkcija ignoriše istek vremena dok upis ne bude primenjen
> 2. Grešku, jer funkcija posle isteka vremena prekida sesiju na 3309
> 3. Zastarelu vrednost, jer funkcija posle 2 s vrati 1 i ne čeka dalje
> 4. Svoj upis, jer funkcija posle 2 s vrati 1, a SELECT zatim čeka primenu


> [!failure] Quiz — incorrect ✗
> Your answer: 1. Svoj upis, jer funkcija ignoriše istek vremena dok upis ne bude primenjen
> Correct answer: 3
>
> Posle 2 s funkcija vrati 1 (istek vremena) i odmah pusti sesiju dalje. Upis će biti primenjen tek posle oko 3–4 s. SELECT ne zna ništa o čekanju i čita ono što trenutno postoji, a to je zastarela vrednost. To je slučaj C iz eksperimenta (timeout 1 s → v je ostao star). Bez provere povratne vrednosti istek vremena znači tihu anomaliju.


> [!abstract] PI
> Ovo je važna zabluda, pa je razložimo. Izgleda da `WAIT_FOR_EXECUTED_GTID_SET` doživljavaš kao **garanciju** („posle ovoga vidim svoj upis“). Funkcija je zapravo samo **čekanje sa gornjom granicom** koje na kraju javlja kako je prošlo.
>
> ```
> WAIT_FOR_EXECUTED_GTID_SET(g, 2):
>    ponavljaj:  da li je g ⊆ gtid_executed?   → da:  vrati 0   (uspeh)
>                da li su prošle 2 s?          → da:  vrati 1   (istek vremena)  ← i ništa više
>    ----------------------------------------------------------------------
> SELECT v …   ← ne zna da je bilo čekanja; čita ono što je trenutno primenjeno
> ```
>
> Tri činjenice koje se ne smeju pomešati:
>
> 1. **Funkcija ne menja ono što SELECT vidi.** Ona ne „rezerviše“ tvoj upis i ne tera nit primene da požuri. Samo zadržava **tvoju sesiju** dok uslov ne postane tačan ili dok ne istekne vreme.
> 2. **Posle 1 uslov i dalje nije ispunjen.** Upis je i dalje „primljen, a neprimenjen“. SELECT zato dobija staru vrednost, tačno kao u slučaju C uživo (timeout 1 s → `v = 2`, stara vrednost).
> 3. **Jedini način da se istek vremena „ignoriše“ je timeout = 0.** Refman: podrazumevani timeout je 0, „i tada funkcija uvek čeka dok sve transakcije iz skupa ne budu primenjene“. To je neograničeno čekanje. Ako replika stane, sesija visi zauvek. To je posebna, svesno izabrana vrednost, a ne ponašanje svakog timeouta.
>
> Odatle sledi i obrazac koji ide u rad: **proveri povratnu vrednost → 0: čitaj sa replike; 1: čitaj sa izvora** (ili javi grešku). Router-ov `wait_for_my_writes_timeout` radi upravo to: posle isteka vremena „prelazi na read_write odredište“.
>
> Napiši „next“.


> [!quote] YOU
> next


> [!question] Quiz
> Koji kod na 3309 garantuje da korisnik vidi svoj upis i da sesija nikad ne visi duže od 2 s, uz `SOURCE_DELAY = 3`?
>
> 1. Pozvati funkciju sa timeout 2; ako vrati 0, isti SELECT poslati na izvor 3307
> 2. Pozvati funkciju sa timeout 0; ako vrati 1, isti SELECT poslati na izvor 3307
> 3. Pozvati funkciju sa timeout 2; ako vrati 1, ponoviti SELECT na 3309
> 4. Pozvati funkciju sa timeout 2; ako vrati 1, isti SELECT poslati na izvor 3307


> [!failure] Quiz — incorrect ✗
> Your answer: 2. Pozvati funkciju sa timeout 0; ako vrati 1, isti SELECT poslati na izvor 3307
> Correct answer: 4
>
> Timeout 2 ograničava čekanje. Povratna vrednost 1 znači da upis na 3309 još nije primenjen, pa je jedino mesto gde se sigurno vidi izvor. Timeout 0 čeka neograničeno, pa krši uslov od 2 s (a „vrati 1“ se tada nikad ne desi). Ponovljeni SELECT na 3309 odmah posle 1 i dalje vidi staro. Vrednost 0 znači uspeh, pa slanje na izvor tada samo baca rad replike.


> [!abstract] PI
> Dva puta zaredom si izabrao rešenje sa **timeout 0**. Pretpostavljam da 0 čitaš kao „ne čekaj uopšte, samo proveri“. Tako radi mnogo API-ja, a i zdrav razum kaže „0 sekundi čekanja“. **Ovde je suprotno, i to je proizvoljna odluka u dizajnu, ne nešto što sledi iz principa:**
>
> | vrednost `timeout` | šta `WAIT_FOR_EXECUTED_GTID_SET` radi |
> |---|---|
> | **0** (podrazumevana, ili izostavljena) | čeka **neograničeno**, dok upis ne bude primenjen |
> | **N > 0** | čeka najviše N sekundi, pa vrati 1 |
>
> Refman doslovno: „podrazumevani timeout je 0 sekundi, i tada funkcija **uvek čeka** dok sve transakcije iz skupa ne budu primenjene.“ Zašto je MySQL odabrao baš to značenje, priručnik ne obrazlaže, pa ga ne izvodi, nego ga zapamti kao činjenicu. Ako ti treba „samo proveri, ne čekaj“, za to postoji druga funkcija: `GTID_SUBSET(g, @@GLOBAL.gtid_executed)`, koja odmah vraća 1 ili 0.
>
> Zato je timeout 0 u prethodnom pitanju dvostruko pogrešan:
> - sesija bi visila koliko god je potrebno (ovde oko 4 s, a ako replika stane, zauvek), pa je uslov „nikad duže od 2 s“ prekršen;
> - grana „ako vrati 1“ nikad ne bi bila izvršena, jer funkcija sa timeoutom 0 ne vraća 1.
>
> Napiši „next“.


> [!quote] YOU
> next


> [!question] Quiz
> Replika 3309 je zaustavila nit primene (`STOP REPLICA SQL_THREAD`), pa se upis g nikad neće primeniti. Šta radi `SELECT WAIT_FOR_EXECUTED_GTID_SET(g, 0)` na 3309?
>
> 1. Odmah vrati 0, jer 0 znači da se uslov ne proverava
> 2. Visi neograničeno, jer 0 znači čekanje dok g ne bude primenjen
> 3. Odmah vrati NULL, jer nit primene trenutno ne radi
> 4. Odmah vrati 1, jer 0 znači samo proveru bez čekanja


> [!success] Quiz — correct ✓
> Your answer: 2. Visi neograničeno, jer 0 znači čekanje dok g ne bude primenjen
> Correct answer: 2
>
> Timeout 0 je ovde „čekaj zauvek“. Nit primene stoji, g nikad ne uđe u gtid_executed, pa sesija visi. NULL kada nit primene ne radi je ponašanje SOURCE_POS_WAIT(), ne GTID funkcije: refman za WAIT_FOR_EXECUTED_GTID_SET navodi samo 0/1, a „svaki drugi neuspeh daje grešku“. Za proveru bez čekanja služi GTID_SUBSET(g, @@GLOBAL.gtid_executed).


> [!abstract] PI
> Proveravam to uživo, da ne bi ostalo kao izvedena tvrdnja: nit primene na 3309 zaustavljam, pa čekam sa timeoutom 3 umesto 0, da sesija ne bi visila.


> [!abstract] PI
> Moja provera nije bila dobra: `NOW()` ima istu vrednost tokom celog iskaza, pa vreme nije izmereno. Ponavljam sa `SYSDATE()`, koja se računa u trenutku poziva.


> [!abstract] PI
> Potvrđeno uživo, dok je nit primene na 3309 bila zaustavljena:
>
> ```
> WAIT_FOR_EXECUTED_GTID_SET(g, 3)            → čekala je ceo timeout (16:19:39.292 → 16:19:42.288), pa vratila 1
> SOURCE_POS_WAIT('node1-bin.000017', 4, 3)   → odmah NULL
> ```
>
> Znači: GTID funkcija pri zaustavljenoj niti primene **čeka do isteka vremena**. Sa timeoutom 0 visila bi neograničeno. To sam izveo iz ovog merenja i iz teksta priručnika, a sa 0 nisam pokrenuo, da sesija ne bi visila. `SOURCE_POS_WAIT` odmah vraća `NULL`, tačno kako refman kaže („ako replikaciona SQL nit nije pokrenuta“). To je jedina praktična razlika između dva rođaka koju smo videli uživo.
>
> ## Čvor D5: šta skaliranje čitanja ne skalira
>
> Imamo sve delove, pa samo ih sastavljamo:
>
> 1. **Upisi.** Svaka replika je kopija **celog** skupa podataka, pa ponavlja **svaki** upis (tvoj tačan odgovor u proveri znanja: 1 000/s na svakoj replici). Pet replika daje pet puta više kapaciteta za čitanje i **isti** kapacitet za upis, plus pet puta više ukupnog rada na primeni. Refman: skaliranje replikacijom „najbolje radi u okruženju sa velikim brojem čitanja i malim brojem upisa“.
>
> 2. **Propusnost niti primene.** Ovo je dublje ograničenje, i video si ga uživo: izvor je komitovao 2 000 transakcija za 0,6 s, uporedo, uz grupno komitovanje, a jedna nit primene ih je ponavljala oko 33 s. Ako je stalna brzina upisa na izvoru $W$ (transakcija u sekundi), a nit primene replike može najviše $A$, onda:
>
> $$
> W \le A \;\Rightarrow\; \text{kašnjenje ostaje ograničeno} \qquad\quad W > A \;\Rightarrow\; \text{kašnjenje raste za } \left(1 - \tfrac{A}{W}\right) \text{ s svake sekunde, bez granice}
> $$
>
>    Za nalet: $A \approx 60$/s naspram $W \approx 3\,300$/s, pa raste skoro 1 s u sekundi, kao što je i izmereno. Dodavanje replika ne podiže $A$. Svaka nova replika ima **istu** granicu, jer svaka mora da primeni svih $W$. $A$ podižu samo više niti primene, kad su transakcije nezavisne, ili brži disk.
>
> 3. **Veza sa anomalijama.** Kašnjenje je dužina prozora u kom se dešavaju read-your-writes i monotona čitanja (D3), i koliko čitalac plaća za `WAIT_FOR_EXECUTED_GTID_SET` (D4). Kad je $W > A$, prozor raste bez granice. Tada svako čekanje ističe, svaki prelazak na izvor šalje čitanja nazad na izvor, i skaliranje čitanja se samo od sebe raspada.
>
> Isto kao kod multi-primary u poglavlju 5: **više servera raspoređuje čitanja, ne posao primene upisa.**
>
> Napiši „next“.


> [!quote] YOU
> next


> [!question] Quiz
> Izvor stalno upisuje 2 000 transakcija/s. Svaka replika može da primeni najviše 1 500/s. Aplikacija koristi `WAIT_FOR_EXECUTED_GTID_SET(g, 1)` i prelazi na izvor kad funkcija vrati 1. Šta se dešava ako se broj replika poveća sa 2 na 10?
>
> 1. Kašnjenje opada, jer se 2 000 upisa u sekundi deli na deset replika
> 2. Svaka replika i dalje zaostaje sve više, pa uskoro skoro sva čitanja prelaze na izvor
> 3. Kašnjenje opada, jer svaka replika ima manje čitanja pa brže primenjuje
> 4. Kašnjenje ostaje isto, ali svako čitanje čeka kraće zbog više replika


> [!failure] Quiz — incorrect ✗
> Your answer: 4. Kašnjenje ostaje isto, ali svako čitanje čeka kraće zbog više replika
> Correct answer: 2
>
> Svaka replika mora da primeni svih 2 000/s, a može 1 500/s. Kašnjenje zato raste za 0,25 s svake sekunde na svakoj replici, bez obzira na to koliko ih ima. Kad kašnjenje pređe 1 s, svaki WAIT ističe i čitanje prelazi na izvor, pa deset replika ne pomaže ničim. Upisi se ne dele među replikama. Opcija „manje čitanja“ zvuči razumno: rasterećena replika zaista može malo brže da primenjuje, ali to ne podiže granicu niti primene sa 1 500 na 2 000 po pretpostavci zadatka.


> [!abstract] PI
> Tvoj izbor nosi dve tvrdnje, i obe treba proveriti. Izračunajmo ih.
>
> **1. „Kašnjenje ostaje isto.“** Neka replika svake sekunde dobija 2 000 novih transakcija, a primeni 1 500. Razlika ostaje u relay logu i gomila se:
>
> ```
> sekunda   stiglo ukupno   primenjeno ukupno   zaostatak (transakcija)   kašnjenje ≈ zaostatak / 2 000
>    1          2 000             1 500                  500                     0,25 s
>    2          4 000             3 000                1 000                     0,50 s
>    4          8 000             6 000                2 000                     1,00 s   ← WAIT(g, 1) počinje da ističe
>   60        120 000            90 000               30 000                    15,00 s
> ```
>
> Kašnjenje nije konstanta replike, kao `SOURCE_DELAY`. Ono je **zaostatak koji se akumulira** kad god $W > A$. U naletu si to video kao 1 s po sekundi, a ovde je to 0,25 s po sekundi.
>
> **2. „Čitanje čeka kraće zbog više replika.“** `WAIT_FOR_EXECUTED_GTID_SET` na replici čeka da **ta** replika primeni g. Koliko dugo, zavisi samo od zaostatka te replike. Ostalih devet je ne ubrzavaju, jer svaka ima **sopstveni**, isto toliko veliki zaostatak, pošto svaka primenjuje svih 2 000/s. Više replika znači više mesta na koja čitanje može da ode, ali je na **svakom** od njih kašnjenje isto.
>
> Ishod: posle oko 4 s svaka replika kasni više od 1 s, svaki WAIT ističe, i aplikacija sva čitanja vraća na izvor. Deset replika postaje deset kopija koje troše disk i niko ih ne čita.
>
> Napiši „next“.


> [!quote] YOU
> next


> [!question] Quiz
> Izvor stalno upisuje 800 transakcija/s, a svaka replika može da primeni najviše 1 000/s. Kratak nalet od 3 s podigne brzinu upisa na 1 600/s, pa se vrati na 800/s. Šta se dešava sa kašnjenjem na svakoj replici?
>
> 1. Poraste tokom naleta i posle njega nastavi da raste bez granice
> 2. Ne poraste, jer je prosečna brzina upisa ispod granice niti primene
> 3. Poraste tokom naleta, pa se posle njega postepeno smanji na blizu nule
> 4. Poraste tokom naleta i posle njega ostaje na dostignutoj vrednosti


> [!success] Quiz — correct ✓
> Your answer: 3. Poraste tokom naleta, pa se posle njega postepeno smanji na blizu nule
> Correct answer: 3
>
> Tokom naleta W = 1 600 > A = 1 000, pa zaostatak raste za 600 transakcija svake sekunde, ukupno 1 800. Posle naleta W = 800 < A = 1 000, pa replika svake sekunde smanji zaostatak za 200 i isprazni ga za oko 9 s. To je oblik iz našeg merenja: rast, vrh, pa pražnjenje. Kašnjenje bez granice raste samo kad je W > A stalno. Prosek ne sprečava rast, jer se zaostatak gomila u svakom trenutku kad je W > A.


> [!abstract] PI
> Grafik je urađen i provera prolazi. Ostale figure lekcije šaljem makerima, paralelno.


> [!abstract] PI
> Pregledam svaku figuru pre nego što je ugradim.


> [!abstract] PI
> Svih pet figura je čitljivo i tačno. Sledi šablon lekcije.


> [!abstract] PI
> Sada zapisi: zapis učenja, zapis merenja, indeks, README primera i ticket.


> [!abstract] PI
> Nema hrvatskih oblika („prijem“ je samo lažno poklapanje sa „prije“). Otvaram lekciju.


> [!abstract] PI
> Lekcija 07 je gotova, a topologija je vraćena u početno stanje: asinhrono, `SOURCE_DELAY = 0`, 4 niti primene, `visits` 180/180, privremene tabele i procedure obrisane. Poglavlje nisam pisao, kako je dogovoreno.
>
> **Šta je izmereno uživo (MySQL 8.4.11):**
>
> | Eksperiment | Rezultat |
> |---|---|
> | Jedna transakcija kroz `performance_schema` | prijem 0,724 ms, ukupno 6,375 ms; skoro sve kašnjenje je primena |
> | Prirodni nalet, 3309 sa jednom niti primene | izvor je komitovao 2 000 transakcija za 598 ms; kašnjenje je raslo do 31,0 s |
> | Relay log tokom naleta | stao je već na 4,5 s, znači da kasni nit primene, a ne nit prijema |
> | `Seconds_Behind_Source` naspram pravog kašnjenja | pri pražnjenju precenjuje do 4,2 s; u 31 od 360 uzoraka kaže 1 dok replika kasni samo 2 ms |
> | Read-your-writes i monotona čitanja (`SOURCE_DELAY = 3`) | obe anomalije su se pojavile, u dva pokretanja isto |
> | `WAIT_FOR_EXECUTED_GTID_SET` | uspeh posle oko 4 s; sa timeoutom od 1 s vrati 1, a čitanje ostaje zastarelo |
>
> Za vrednost 1 dok je kašnjenje 2 ms imam samo hipotezu za uzrok, nisam je proverio. U rad ide samo izmerena vrednost.
>
> Krive se jasno razilaze samo pri pražnjenju i kad replika miruje. Dok kašnjenje raste, `Seconds_Behind_Source` ga prati uz grešku do oko 1 s.
>
> **Šta je napravljeno:**
> - **Lekcija:** `lessons/0007-skaliranje-citanja.html`, sa 6 figura i kvizom od 8 pitanja. Pitanja su napravljena od tačaka na kojima si grešio.
> - **Referentni list:** `reference/kasnjenje-i-citanje.html`.
> - **Skripte:** u `examples/04-read-scaling/` (nalet, uzorkivač, anomalije). Sve same vraćaju topologiju u početno stanje.
> - **Slika 7.1:** napravio sam i sliku za rad, `figures/07-skaliranje-01-kasnjenje.png`, preko `tools/make-lag-plot.py`. Skripta prekida rad ako se dve krive ne razilaze. Sirovi podaci su u `figures/raw/07-skaliranje-01-kasnjenje.csv`.
> - **Zapisi:** `learning-records/0009-read-scaling-lag.md` (i nov red u indeksu) i `.scratch/replikacija/measurements/0009-read-scaling-lag.md`. Ažurirani su `GLOSSARY.md` (novi pojmovi za poglavlje 7) i ticket 19.
>
> **Za početak sledeće sesije (pisanje poglavlja 7), kratko ponavljanje tri tačke na kojima si grešio:**
> 1. Timeout 0 znači čekaj zauvek.
> 2. `performance_schema` ne rešava razliku satova između izvora i replike.
> 3. Kad izvor upisuje brže nego što replika primenjuje, više replika ne pomaže.
>
> Ako ti nešto u lekciji nije jasno, pitaj.
