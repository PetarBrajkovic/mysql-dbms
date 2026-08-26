---
title: "Obrada upita (Query Processing) u MySQL-u"
author: "Petar Brajković"
bibliography: references.bib
csl: ieee.csl
---

# 1. Uvod

Relacione baze podataka nude korisniku deklarativan jezik: SQL upitom opisuje se *šta* se traži
kao rezultat, ali ne i *kako* se do tog rezultata dolazi. Sistem za upravljanje bazom podataka
(SUBP), s druge strane, ume da izvrši isključivo konkretne fizičke procedure: čitanje i upisivanje
stranica na disku, prolazak kroz B+ stablo, sken tabele nad neuređenim fajlom. Obrada upita (query
processing) obuhvata sve što SUBP radi da bi premostio taj jaz između deklarativnog opisa i fizičkog
izvršenja; upravo je teret efikasnog odgovaranja na upite time prebačen sa korisnika na sistem
[@ramakrishnan2003].

Jaz se premošćuje optimizacijom na dva nivoa jednog istog problema. Na
višem, logičkom nivou, polazni izraz relacione algebre preformuliše se u ekvivalentan izraz koji se
brže izvršava: spuštanjem selekcija naniže, izmenom redosleda spoja ili sažimanjem operacija menja se
*oblik* izračunavanja, ali nikada sam rezultat. Na nižem, fizičkom nivou, za svaki operator bira se
konkretan algoritam i pristupni put: sken tabele naspram skena preko indeksa, odnosno spoj sa
ugnježdenom petljom, Sort-Merge spoj ili Hash spoj. Pošto ne postoji univerzalno superiorna tehnika,
najpovoljniji izbor zavisi od svojstava samih podataka. Oba nivoa vođena su
istim merilom, cenom (procenom količine posla, pre svega ulazno-izlaznih operacija), i taj
zajednički cilj čini ih dvama nivoima jednog problema, a ne dvama odvojenim problemima
[@ramakrishnan2003].

Kombinovanjem logičkih i fizičkih izbora jedan nepromenjen SQL upit grana se na više planova
izvršenja koji vraćaju identičan rezultat, ali čija se cena razlikuje za nekoliko redova veličine:
selektivan indeks dodirne šačicu stranica, dok sken cele tabele pročita milione redova. Zadatak
SUBP-a jeste da među tim ekvivalentnim planovima pronađe i izabere najefikasniji
[@ramakrishnan2003]. MySQL taj izbor poverava optimizatoru upita zasnovanom na ceni
(cost-based optimizer), koji procenjuje cenu razmatranih planova i zadržava najjeftiniji
[@mysql84refman].

![Slika 1.1: Dva ekvivalentna plana izvršenja istog SQL upita, različite cene: sken preko indeksa (A)
naspram skena cele tabele (B).](figures/01-uvod-01-jedan-upit-dva-plana.png)

Slika 1.1 prikazuje ovu pojavu na konkretnom upitu nad sintetičkom tabelom `wide_events`. Isti upit
`SELECT notes FROM wide_events WHERE country_code = 'US'` MySQL izvršava skenom preko indeksa
`idx_country_code`, dok se zabranjivanjem tog indeksa dobija sken cele tabele, skuplji plan koji
vraća isti skup od približno 3,5 miliona torki. Iako oba plana daju istovetan rezultat, optimizator
zadržava jeftiniju varijantu; upravo je ta logika izbora predmet poglavlja koja slede.

Ostatak rada prati istu nit, put od deklarativnog SQL upita do njegovog fizičkog izvršenja u
MySQL-u:

- U poglavlju 2 opisuje se **arhitektura obrade upita u MySQL-u**: komponente koje premošćuju jaz
  (parser, optimizator, izvršni mehanizam i katalog) i način na koji ih MySQL povezuje.
- U poglavlju 3 dva nivoa optimizacije prikazuju se opipljivo, kao **put od SQL-a do plana
  izvršavanja**, od upita, preko preformulacije relacione algebre, do fizičkog plana nad stvarnim
  primerom.
- Poglavlje 4 uvodi **EXPLAIN i EXPLAIN ANALYZE**, alate kojima se izabrani plan čini vidljivim i
  kojima se procenjena cena poredi sa onim što se pri izvršavanju zaista dogodilo.
- Poglavlje 5 objašnjava kako se izabrani plan izvršava kroz **model iteratora (iterator model) i
  pipeline operatora**: operatori povlače torke jedan od drugog, torku po torku.
- Poglavlje 6 razmatra **vektorizovano izvršavanje**, grupnu i kolonski orijentisanu alternativu
  izvršavanju torku po torku, kao i položaj MySQL-a u odnosu na nju.
- Poglavlje 7 ispituje **paralelno izvršavanje upita**, korišćenje više procesorskih jezgara za
  jedan upit i stvarne granice paralelnosti u MySQL-u.
- Poglavlje 8 obrađuje **keširanje i ponovnu upotrebu planova**: pitanje može li se izabrani plan
  ponovo iskoristiti umesto da se računa iznova i šta MySQL zapravo kešira (keš plana, plan cache).
- Poglavlje 9 donosi **zaključak**, provlačeći nit do kraja, od deklarativnog SQL-a nazad do
  fizičkog izvršenja.

# 2. Arhitektura obrade upita u MySQL-u

U prethodnom poglavlju obrada upita opisana je kao jaz između deklarativnog SQL-a i njegovog
fizičkog izvršenja. MySQL taj jaz premošćuje arhitektonskom odlukom kakvu većina drugih sistema
nema: sam sistem podeljen je na dva sloja, sa standardizovanim interfejsom između njih. Iznad je
serverski sloj, koji razume SQL: prihvata konekciju, parsira naredbu, optimizuje je i izvršava
izabrani plan. Ispod je mehanizam skladištenja *(storage engine)*, u nastavku kraće motor, koji
razume torke i stranice na disku, a o SQL-u ne zna ništa [@mysql84refman]. Ta podela nije stvar
interpretacije, već je izričito dokumentovana: modularna arhitektura pruža standardan skup usluga
zajedničkih svim motorima, dok su motori komponente koje stvarno izvršavaju radnje nad podacima na
fizičkom nivou [@mysql84refman].

Zbog te zamenljivosti organizacija se naziva modularna arhitektura motora *(pluggable storage engine
architecture)*: motor se priključuje i menja, a serverski sloj iznad njega ostaje isti. MySQL 8.4 uz
InnoDB isporučuje još desetak motora, među kojima su MyISAM, Memory, CSV i Archive, ali je InnoDB
podrazumevani i jedini koji se u ovom radu razmatra [@mysql84refman]. Pouzdan test kojim se utvrđuje
da li neka osobina pripada motoru ili serverskom sloju jednostavan je i proverljiv: menja li se ta
osobina kada se ista tabela prebaci na drugi motor? Priručnik na to pitanje odgovara i sam, jednom
fusnotom uz tabelu poređenja motora: oznaku „implementirano u serveru, a ne u mehanizmu
skladištenja” nose tačno dva reda, replikacija i izrada rezervne kopije, dok sve ostalo, poput
transakcija, MVCC-a *(viševerzijska kontrola konkurentnosti)*, granularnosti zaključavanja i
klasterovanog indeksa, varira od motora do motora i stoga ne može pripadati zajedničkom sloju
[@mysql84refman].

![Slika 2.1: Arhitektura MySQL-a: serverski sloj i mehanizmi skladištenja. Preuzeto iz priručnika
[@mysql84refman], Figure 18.3.](figures/02-arhitektura-00-mysql-architecture-official.png)

Slika 2.1 prikazuje tu podelu onako kako je crta sam priručnik. Sve što serverski sloj radi smešteno
je u jedinstven proces, dok su motori zasebni i zamenljivi moduli ispod njega, povezani sa sistemom
datoteka. Za obradu upita bitna je samo granica između tog procesa i modula ispod njega: to je
linija preko koje naredba prelazi iz sveta SQL-a u svet torki i stranica [@mysql84refman].

Put jedne naredbe kroz serverski sloj ima jasan redosled, a koraci nose imena koja postoje u izvornom
kodu MySQL-a 8.4. Nit dodeljena konekciji čita komandu sa mreže, najpre kroz funkciju `do_command`,
a potom `dispatch_command`; tek ulazna tačka `dispatch_sql_command` započinje obradu SQL-a: tekst se
parsira u sintaksno stablo, imena tabela i kolona se razrešavaju i trajno transformišu, optimizator
bira redosled spoja i pristupni put po ceni, a izvršilac izabrani plan pretvara u stablo iteratora
[@mysqlsource84]. Kroz sve korake putuje jedan isti objekat, `THD`, u kodu opisan kao deskriptor
niti i konekcije. Sistemska promenljiva `thread_handling` podrazumevano ima vrednost
`one-thread-per-connection`, dakle jedna nit po konekciji [@mysql84refman; @mysqlsource84]. Ta
činjenica biće bitna u poglavlju 7, jer je paralelnost u MySQL-u pre svega između konekcija, a ne
unutar jednog upita.

Interfejs između dva sloja nije apstrakcija na papiru, nego konkretna C++ klasa `handler`, koju
izvorni kod opisuje kao interfejs za motore koji se dinamički učitavaju; uz nju stoji `handlerton`,
po jedna instanca za ceo motor, dok `handler` radi po pojedinačnoj tabeli [@mysqlsource84]. Značaj te
klase za obradu upita najbolje se vidi na iteratoru koji čita celu tabelu: u svom telu on ne radi
ništa nalik čitanju diska, već poziva metodu motora `ha_rnd_next` nad pokazivačem `table()->file`,
koji je tipa `handler`, i čeka da mu motor vrati sledeću torku [@mysqlsource84]. Kako je motor tu
torku pronašao, iz bafer pula *(buffer pool)*, sa diska ili silaskom kroz B+ stablo, serverski sloj
ne zna niti treba da zna. U tome i jeste suština podele: serverski sloj odlučuje koje torke želi i
kojim redom da ih spoji, a motor odlučuje kako se torka fizički pronalazi, kešira, zaključava i u
kojoj se verziji čita [@mysql84refman].

Ta podela, međutim, na dva mesta namerno propušta, a oba se mogu pokazati na živom serveru. Prvo je
spuštanje uslova u indeks *(index condition pushdown, ICP)*. Da je granica savršeno čista, motor bi
vraćao torke a serverski sloj bi ih filtrirao, ali bi tada i torke koje će svakako biti odbačene
morale da pređu granicu. Da to izbegne, serverski sloj deo uslova iz `WHERE` klauzule prosleđuje
motoru, metodom `idx_cond_push`, kroz koju prolazi `Item*`, čvor izraza iz serverskog sloja; motor
taj uslov proverava nad torkom indeksa i tek ako je zadovoljen dohvata punu torku iz tabele
[@mysql84refman; @mysqlsource84].

![Slika 2.2: Plan upita sa uključenim spuštanjem uslova u indeks (ICP). Plameni grafikon iz `EXPLAIN
ANALYZE FORMAT=JSON`, izmereno na živom serveru (MySQL
8.4.11).](figures/02-arhitektura-01-icp-ukljucen.png)

![Slika 2.3: Isti upit sa isključenim spuštanjem uslova, sa zasebnim čvorom `Filter` u
planu.](figures/02-arhitektura-02-icp-iskljucen.png)

Slike 2.2 i 2.3 prikazuju isti upit nad tabelom `wide_events`, sa uključenim i sa isključenim
spuštanjem uslova. Pristupni put je u oba slučaja isti sken opsega preko istog indeksa, pa se menja
samo broj čvorova u planu. Kada je spuštanje isključeno (Slika 2.3), iznad skena stoji zaseban čvor
`Filter`, koji obavlja serverski sloj: sken mu dodaje 499.297 torki, a filter propušta njih 165.707,
pa je 333.590 torki prešlo granicu samo da bi odmah bilo odbačeno. Kada je spuštanje uključeno (Slika
2.2), čvor `Filter` nestaje jer isti uslov proverava motor, nad torkom indeksa, pre nego što uopšte
dohvati široku torku; rezultat je istovetan, a razlika je jedino u tome koji sloj obavlja filtriranje
[@mysql84refman]. Upravo zato je ovo najuverljiviji dokaz da granica postoji: ona se u planu vidi kao
pojava, odnosno nestanak jednog čvora.

Drugo mesto na kome podela propušta jeste statistika kojom optimizator procenjuje koliko će torki
neki korak vratiti: odgovor stiže sa obe strane granice, iz dva izvora koji se mogu, ali i ne moraju
slagati. Motor daje kardinalnost indeksa, to jest broj različitih vrednosti, i to procenom: InnoDB
je dobija uzorkovanjem stranica indeksa, a ne čitanjem svih torki, pa se ta vrednost čuva u
motorovoj tabeli `mysql.innodb_index_stats` [@mysql84refman]. Serverski sloj, sa svoje strane,
održava histogram, raspodelu vrednosti po kanticama, koji se izričito traži naredbom
`ANALYZE TABLE ... UPDATE HISTOGRAM` i čuva u rečniku podataka *(data dictionary)*, odvojeno od
motora [@mysql84refman]. Na koloni `country_code` sintetičke tabele razlika je merljiva: motor iz
uzorka od 16 stranica, od ukupno 5.082, procenjuje 14 različitih vrednosti, dok server histogramom
nalazi tačnih 15 i, što je važnije, beleži da vrednost `US` zauzima oko 70% tabele, dok bi se iz same
kardinalnosti mogla izvesti tek ravnomerna raspodela od približno 7% po vrednosti [@mysql84refman].
Pravilo koje sažima ovu podelu glasi: statistika indeksa pripada motoru, a histogrami kolona
serverskom sloju.

Time su određene dve komponente na kojima počivaju naredna poglavlja: serverski sloj, koji SQL upit
pretvara u plan, i motor, koji taj plan izvršava nad stvarnim torkama. Poglavlje 3 ulazi u prvu od
njih i prati put od SQL naredbe do plana izvršavanja, od preformulacije relacione algebre do fizičkog
plana nad konkretnim primerom.

# 3. Od SQL-a do plana izvršavanja

Prethodno poglavlje pokazalo je *gde* se obrada upita odvija: u serverskom sloju, iznad šava prema
motoru. Ovo poglavlje pokazuje *šta se u tom sloju odlučuje*, kojim redom i po kom kriterijumu. Teza
je jednostavna i vodi kroz celo poglavlje: MySQL obradu deli na pet imenovanih faza, a svaka odluka
koja uopšte ima alternativu razrešava se jednim brojem, cenom [@mysql84refman].

## 3.1. Pet faza obrade

Put naredbe kroz serverski sloj, u poglavlju 2 izložen samo u grubim crtama, deli se na pet faza od
kojih svaka ima svoj modul i svoju ulaznu funkciju u izvornom kodu MySQL-a. Parser (`parse_sql()`)
pretvara tekst naredbe u stablo raščlanjivanja *(parse tree, AST)*, isključivo po gramatici.
Razrešavanje ili priprema (`Query_block::prepare()`) traži imena tabela i kolona u rečniku podataka i
nad stablom izvodi trajne transformacije. Optimizator (`JOIN::optimize()`) priprema uslove,
procenjuje broj torki i bira strategije. Planer (`Optimize_table_order`), kao podfaza optimizatora,
bira redosled spoja i pristupni put po tabeli. Izvršilac (`sql_executor.cc`) izabrani plan pretvara u
stablo iteratora koje povlači torku po torku [@mysqlsource84]. Ta podela nije naknadna rekonstrukcija:
svih pet imena su imena modula u dokumentaciji izvornog koda (Parser, Query Resolver, Query
Optimizer, Query Planner, Query Executor) [@mysqlsource84].

Sam server, uz to, ume da ispiše imena svojih faza. Kada se uključi trag optimizatora *(optimizer
trace)*, na njegovom vrhu stoje tačno tri koraka: `join_preparation`, `join_optimization` i
`join_execution` [@mysql84refman]. Ta tri koraka poklapaju se sa pet faza tako što `join_optimization`
obuhvata i optimizator i planer (planer nema svoj zaseban korak), dok parser ostaje van traga, jer
trag počinje tek kada stablo već postoji. Trag optimizatora je promenljiva sesije, podrazumevano
isključena, i predstavlja glavni prozor u odluke optimizatora do kraja rada; njegovo detaljno čitanje
tema je poglavlja 4 [@mysql84refman].

![Slika 3.1: Pet faza obrade upita i granica cene, sa preslikavanjem na tri koraka u tragu
optimizatora.](figures/03-od-sql-a-do-plana-04-pet-faza-pregled.png)

Slika 3.1 prikazuje tih pet faza poređanih odozgo naniže, sa jednom linijom povučenom preko sredine.
Sve iznad te linije menja oblik naredbe i radi se jednom, a sve ispod nje bira se po ceni i ponavlja
pri svakom izvršavanju. Upravo je ta granica okosnica celog poglavlja.

## 3.2. Parser i razrešavanje: transformacije bez cene

Prva faza gleda samo tekst naredbe. Priručnik je o tome sažet: parser obrađuje SQL naredbu kao niz
znakova i gradi njen prikaz u obliku stabla, bez ikakve provere da tabela ili kolona postoji
[@mysql84refman].
Granica prema sledećoj fazi može se i izmeriti. Naredba koja istovremeno ima sintaksnu grešku i
pogrešno ime kolone vraća samo sintaksnu grešku (`ERROR 1064`), jer se do provere imena u rečniku
podataka ne stiže dok stablo nije napravljeno [@mysql84refman]. Redosled faza time nije stvar
tumačenja, već merljiva činjenica.

Najveće iznenađenje ovog poglavlja krije se u drugoj fazi. Očekivalo bi se da logičko prepisivanje
upita (pretvaranje podupita u spoj, spajanje izvedenih tabela, izbacivanje suvišnih uslova) pripada
optimizatoru. U MySQL-u ne pripada: ne postoji zasebna faza prepisivanja, već trajne transformacije
stabla žive u fazi razrešavanja, uz razrešavanje imena [@mysqlsource84]. Komentar iznad same funkcije
`Query_block::prepare()` nabraja te transformacije, među njima transformaciju poluspoja *(semijoin)* i
transformaciju izvedenih tabela, rame uz rame sa razrešavanjem imena [@mysqlsource84].

Razlog tom smeštaju je životni vek memorije. Imenovani zadatak WL#7082 namerno je preselio trajne
transformacije iz `JOIN::optimize()` u `JOIN::prepare()`, uz obrazloženje da se optimizacija izvršava
pri svakom pokretanju, sa memorijom koja se potom oslobađa, pa bi trajna izmena stabla iz nje bila,
rečima zadatka, komplikovana i sklona greškama [@mysqlwl7082]. Priručnik istu granicu potvrđuje sa
korisničke strane, jednom rečenicom: poluspoj je transformacija u fazi pripreme [@mysql84refman].

Ta granica deli dve vrste odluka koje se lako brkaju. Trajna transformacija menja oblik naredbe, radi
se jednom po naredbi i nema cenu: ne bira se poređenjem, nego se izvede kad god su uslovi za nju
ispunjeni. Strategija se, nasuprot tome, bira po ceni pri svakom izvršavanju, kao najjeftinija među
kandidatima. Isti podupit `IN (SELECT)` pokazuje obe strane: njegova transformacija u poluspoj
pripada pripremi i nema cenu, dok izbor strategije tog poluspoja (na primer FirstMatch,
MaterializeLookup ili DuplicatesWeedout) pripada optimizaciji i vodi se cenom svakog kandidata
[@mysql84refman]. Treba, međutim, biti precizan: nije svaka prepravka uslova trajna. Propagacija
jednakosti, kojom optimizator iz `f.film_id = 42 AND fa.film_id = f.film_id` izvodi i
`fa.film_id = 42`, radi se u optimizaciji, pri svakom pokretanju, i ne dira stablo naredbe
[@mysqlsource84]. Tačna formulacija stoga glasi: u pripremi su trajne transformacije, a ne sve
transformacije.

## 3.3. Model cene

Od granice cene nadalje svaka odluka sa alternativom razrešava se jednim brojem, pa vredi tačno znati
šta je taj broj. Cena u MySQL-u nije ni vreme u sekundama ni ocena na nekoj skali, nego zbir nekoliko
konstanti pomnoženih izmerenim veličinama. Te konstante nisu skrivene u kodu: nose ih dve obične
tabele u bazi `mysql`, koje se čitaju običnim upitom i mogu se izmeniti [@mysql84refman]. Podela na
dve tabele prati šav iz poglavlja 2: `server_cost` sadrži serverske konstante (na primer
`row_evaluate_cost` = 0,1 po torki), a `engine_cost` konstante po motoru (na primer
`io_block_read_cost` = 1,0 po pročitanoj stranici) [@mysql84refman].

Zbog te strukture cena je proverljiva aritmetika. Cena skena tabele `wide_events` sastavlja se kao
zbir procesorskog dela (0,1 pomnoženo brojem torki) i ulazno-izlaznog dela (1,0 pomnoženo brojem
stranica), što na tabeli od približno 4,9 miliona torki i 89.216 stranica daje cenu reda 580.000,
upravo onu koju server i prijavljuje [@mysql84refman]. Jedan ulaz tog računa je stanje bafer pula:
stranica koja je već u memoriji košta `memory_block_read_cost` = 0,25 umesto 1,0, pa se ista cena
razlikuje između dva pokretanja istog upita [@mysql84refman]. Ta zavisnost od trenutnog stanja
memorije objašnjava zašto se u nastavku porede odnosi cena, a ne njihove apsolutne vrednosti.

## 3.4. Prva odluka po ceni: pristupni put

Za svaku tabelu planer bira pristupni put: sken tabele, sken opsega *(range scan)* preko indeksa,
pretragu po jednakosti i slično. Funkcija koja to radi opisana je kao pronalaženje najboljeg
pristupnog puta za proširenje delimičnog plana, čime se naglašava da je reč o koraku u pretrazi, a ne
o izolovanoj odluci [@mysqlsource84]. Rasprostranjena zabluda je da optimizator uzima indeks kad god
indeks postoji; on zapravo bira jeftiniji od dva izračunata puta, a koji je jeftiniji zavisi od broja
torki koje filter obuhvata [@mysql84refman].

![Slika 3.2: Ukrštanje cene skena tabele i cene skena opsega preko indeksa za isti upit, pri
rastućem opsegu.](figures/03-od-sql-a-do-plana-01-ukrstanje-cena.png)

Slika 3.2 prikazuje obe cene za upit `SELECT notes FROM wide_events WHERE customer_id BETWEEN 1 AND N`,
pri rastućem N. Cena skena tabele je konstantna, jer sken čita celu tabelu bez obzira na uslov, dok
cena skena opsega raste sa brojem obuhvaćenih torki i u jednoj tački pretekne konstantu. Na
posmatranom serveru indeks pobeđuje do granice od 10.000 torki, a gubi od 11.000. U tragu optimizatora
odbijeni indeks nosi oznaku `cause: "cost"`, koja znači da kandidat nije neupotrebljiv, nego uredno
izračunat i skuplji od pobednika [@mysql84refman]. Upravo zato ovaj primer vredi: pokazuje da je česta
pritužba da optimizator ne koristi zadati indeks najčešće tačna odluka doneta po ceni, a ne kvar. Da
upit traži samo kolonu `customer_id`, indeks bi ga pokrivao, cena mu ne bi rasla tako brzo i do
ukrštanja ne bi ni došlo, što je isti nalaz koji se u uvodnom poglavlju pokazao suprotnim od
očekivanog.

## 3.5. Druga odluka po ceni: redosled spoja

Kod jedne tabele postoji nekoliko kandidata za pristupni put; kod više tabela broj mogućih redosleda
spoja raste faktorijelno, pa se odluka pretvara u pretragu. Priručnik navodi da većina optimizatora,
uključujući MySQL-ov, sprovodi manje-više iscrpnu pretragu među svim planovima, uz upozorenje da kod
velikih upita vreme provedeno u optimizaciji lako postane glavno usko grlo [@mysql84refman]. Ceo
algoritam stoji u tom „manje-više”: spoljna petlja je pohlepna pretraga *(greedy search)*
(`greedy_search()`), ali svaki njen korak radi ograničeno iscrpan pogled unapred
(`best_extension_by_limited_search()`), dubok onoliko koliko nalaže promenljiva
`optimizer_search_depth` [@mysqlsource84].

Podrazumevana vrednost te dubine je 62, što je `MAX_TABLES + 1` (uz `MAX_TABLES` = 61), pa je
istovremeno i najveća moguća vrednost: MySQL podrazumevano ne ograničava dubinu pretrage
[@mysqlsource84]. Efekat ograničavanja može se pokazati na upitu nad šest tabela baze `sakila`. Sa
podrazumevanom dubinom optimizator kreće od tabele sa selektivnim filterom i dalje se širi tako da je
svaki korak pretraga po indeksu vođena već pribavljenom kolonom. Sa dubinom svedenom na 1, pohlepni
izbor kreće od male tabele bez ijednog uslova, uslov spoja spada na kraj kao zaseban filter, a plan
postaje udžbenički loš, iako su podaci, indeksi i upit isti [@mysql84refman]. Odnos cena dva plana je
reda 150 prema 1, i taj odnos, a ne apsolutne cene zavisne od stanja bafer pula, jeste ono što je
stabilno.

## 3.6. Šta je ostavljeno za naredna poglavlja

Tri teme su ovde dodirnute, a namerno nedovršene, da poglavlje ne bi preuzelo posao narednih.
Čitanje `EXPLAIN` ispisa kao dijagnostike, zajedno sa razlikom između procenjenog i stvarnog broja
torki, predmet je poglavlja 4; ovde je `EXPLAIN` korišćen samo kao prozor u odluku. Način na koji se
izabrani plan izvršava, kroz stablo iteratora, obrađuje poglavlje 5. Najzad, hipergrafski optimizator
spoja *(hypergraph join optimizer)*, novi planer koji bi trebalo da zameni opisanu pretragu, postoji
u kodu MySQL-a 8.4, ali je u izdanjima koja nisu razvojna isključen već pri prevođenju: pokušaj da se
uključi vraća grešku, a ne upozorenje [@mysql84refman]. U ovom radu navodi se kao dokumentovana
činjenica vezana za verziju 8.4, a ne kao nešto što je demonstrirano.

# 4. EXPLAIN i EXPLAIN ANALYZE

Poglavlje 3 pokazalo je kako se plan bira. Ovo poglavlje pokazuje kako se izabrani plan čita. Alat je
naredba `EXPLAIN`, koja se primenjuje na naredbe `SELECT`, `DELETE`, `INSERT`, `REPLACE`, `UPDATE` i
`TABLE` [@mysql84refman]. Pre bilo kakve dijagnostike, međutim, ide rečnik: koje formate ispisa ta
naredba ima, šta znači svaka njena kolona i šta tačno tvrdi ono jedno polje u koje se prvo gleda. Tim
redom ide i poglavlje: najpre se čita procena koju `EXPLAIN` ispisuje, potom se ta procena poredi sa
izmerenim izvršavanjem, i najzad se u tragu optimizatora traži ono što ispis nikada ne prikazuje, a to
su odbačeni planovi.

## 4.1. Tri formata ispisa, dva oblika plana

`EXPLAIN` ima tri formata ispisa: podrazumevani tabelarni format, `FORMAT=JSON` i `FORMAT=TREE`
[@mysql84refman]. Lako je pretpostaviti da su to tri pogleda na istu stvar, pa da je izbor između njih
stvar ukusa. Nije: dva od tri formata prikazuju plan po tabeli, a treći po iteratoru, i ta razlika
određuje šta se u ispisu uopšte može videti.

Razlika se meri prebrojavanjem. Isti spoj tabela `customer` i `payment` nad bazom `sakila` u
tabelarnom formatu daje dva reda, po jedan za svaku tabelu, a u obliku stabla četiri čvora, jer su i
filter i sam spoj operacije, a ne osobine tabele. Filter u tabelarnom ispisu nema svoj red: sabijen je
u reč `Using where` u koloni `Extra` i u broj u koloni `filtered`. Most između dva oblika je aritmetika
koju priručnik izričito propisuje, `rows` pomnoženo sa `filtered` i podeljeno sa 100 [@mysql84refman].
Na posmatranom planu 16.500 torki pomnoženo sa 33,33 procenta daje 5.499, a to je tačno procena broja
torki čvora `Filter` u stablu; `FORMAT=JSON` verzije 1 isti broj daje gotov, u polju
`rows_produced_per_join` [@mysql84refman]. Ono što tabelarni format ostavlja čitaocu da izračuna,
stablo prikazuje kao zaseban čvor.

![Slika 4.1: Isti upit i isti plan u tri formata ispisa naredbe
`EXPLAIN`.](figures/04-explain-01-tri-formata-jedan-plan.png)

Podela na dva oblika nije, međutim, podela na tekstualni i mašinski čitljiv ispis. Počev od verzije
8.3 postoji i druga verzija JSON formata, koja umesto oblika po tabeli daje isto stablo iteratora koje
ispisuje `FORMAT=TREE`, a bira se promenljivom sesije `explain_json_format_version` [@mysql84refman].
Na serveru na kome su rađeni primeri u ovom radu (8.4.11) podrazumevana vrednost te promenljive je 1,
dok se vrednost 2 prihvata i proizvodi stablasti oblik. Uz drugu verziju ide i zamka koju svako
navođenje JSON ispisa mora da uzme u obzir: ključ `access_type` postoji u obe verzije, ali u njima ne
znači isto. U verziji 1 on nosi tip pristupa *(access type)* iz tabelarnog ispisa, dok u verziji 2 nosi
vrstu iteratora (`table`, `filter`, `join`, `index`), a tip pristupa se seli u ključ
`index_access_type` [@mysqlblogjson]. Svaki JSON ispis naveden kao dokaz stoga mora da imenuje i svoju
verziju.

## 4.2. Kolone koje nose odluku

Tabelarni ispis ima dvanaest kolona, ali one nisu jednako važne [@mysql84refman]. Kolone `id`,
`select_type`, `table` i `partitions` identifikuju blok upita i tabelu, kolone `possible_keys`,
`key_len` i `ref` opisuju izabrani pristup, a odluku optimizatora nose četiri: `type` (kojim se putem
dolazi do tabele), `key` (koji je indeks izabran), `rows` (procena broja torki koje pristup pročita) i
`filtered` (procena, u procentima, koliko ih preživi uslov) [@mysql84refman]. Kolona `Extra` prihvata
sve što se ni u jednu od ostalih nije uklopilo.

Tri česta pogrešna čitanja tog ispisa mogu se proveriti u svega nekoliko naredbi. Prvo, kolone `key` i
`key_len` odgovaraju na različita pitanja i tek zajedno određuju šta pristup radi: `key` imenuje
indeks, a dužina ključa (`key_len`) kaže koliko je njegovih bajtova stvarno iskorišćeno
[@mysql84refman]. Primarni ključ tabele `film_actor` složen je od kolona `actor_id` i `film_id`, dakle
2 + 2 bajta. Upit sa uslovom samo nad prvom kolonom prijavljuje `key: PRIMARY` i `key_len: 2`, koristi
levi prefiks ključa i vraća devetnaest torki po pretrazi, dok upit sa uslovom nad obe kolone
prijavljuje `key_len: 4` i najviše jednu torku. U oba slučaja kolona `key` ispisuje isto ime, pa bi bez
dužine ključa izgledalo da se dešava isto.

Drugo, indeks naveden u koloni `possible_keys` uz `key: NULL` ne znači da je indeks neupotrebljiv. Da
jeste, među kandidate ne bi ni ušao. Reč je o odluci po ceni iz poglavlja 3, viđenoj sa strane ispisa:
o istom onom kandidatu koji u tragu optimizatora nosi oznaku `cause: "cost"` [@mysql84refman]. Treće,
broj koji ulazi u narednu tabelu plana nije `rows`, nego proizvod kolona `rows` i `filtered`. Dva upita
nad tabelom `payment`, sa istim indeksom i istom procenom od 32 torke, razlikuju se samo po jednom
dodatnom uslovu, a taj uslov spušta `filtered` sa 100,00 na 33,33 i u istom trenutku menja `Extra` iz
`Using index` u `Using where`.

## 4.3. Lestvica tipova pristupa

Kolona `type` uzima tačno dvanaest vrednosti, a priručnik ih navodi poređane od najboljeg tipa ka
najgorem [@mysql84refman]. Slika 4.2 prikazuje svih dvanaest, svaku izmerenu na zasebnom upitu nad
bazom `sakila`, uz boju koja ih grupiše po tome koliko torki jedan pristup može da vrati.

![Slika 4.2: Dvanaest vrednosti kolone `type`, poređanih redosledom iz priručnika i obojenih po broju
torki koje jedan pristup može da vrati.](figures/04-explain-02-lestvica-tipova-pristupa.png)

Iz slike se vidi ono što se iz samog spiska ne vidi: te grupe se ne poklapaju sa redosledom iz
priručnika. Tip `unique_subquery`, osmi po redu, vraća najviše jednu torku, isto što i treći po redu
`eq_ref`, a stoji pet mesta niže. Redosled je, dakle, praktično uputstvo, a ne merna skala, i lestvica
nije redosled cena. Tip `range` nad pedeset torki jeftiniji je od tipa `ref` nad pet miliona torki, a
`ALL` nad tabelom od tri reda najjeftinije je što postoji. Tip pristupa govori o obliku pristupa, to
jest o tome koliko torki jedna pretraga može da vrati, dok cenu računa model cene iz poglavlja 3.

Parovi koji se najčešće mešaju razlikuju se po jednoj jedinoj osobini. Tipovi `eq_ref` i `ref` oba su
pretraga po indeksu *(index lookup)*, ali prvi koristi ceo primarni ili jedinstveni ključ, pa vraća
najviše jednu torku po torki prethodne tabele, dok drugi koristi indeks koji nije jedinstven ili samo
levi prefiks složenog ključa, pa ih može vratiti više [@mysql84refman]. Tipovi `const` i `eq_ref` oba
vraćaju najviše jednu torku, ali se `const` čita jednom za ceo upit, pre ostatka plana, jer se poredi
sa konstantom, dok se `eq_ref` čita iznova za svaku torku prethodne tabele [@mysql84refman]. Tipovi
`index` i `ALL` oba čitaju celu strukturu od početka do kraja, a `index` je jeftiniji samo zato što je
indeks manji od torki [@mysql84refman].

Dva tipa sa lestvice, `unique_subquery` i `index_subquery`, sa podrazumevanim podešavanjima ne mogu se
ni videti, a razlog dolazi pravo iz poglavlja 3. Transformacija u poluspoj prepisuje podupit iz
klauzule `IN` u običan spoj još u fazi pripreme, dakle pre nego što se tip pristupa uopšte bira
[@mysql84refman]. Isti upit nad tabelama `actor` i `film_actor` sa podrazumevanim podešavanjima
prijavljuje dva reda sa `id: 1` i oznakom `SIMPLE`, bez ijednog podupita; kada se transformacija
isključi promenljivom `optimizer_switch`, u ispisu se pojavljuje blok sa `id: 2`, oznakom
`DEPENDENT SUBQUERY` i tipom `unique_subquery`. To je zaključak poglavlja 3 viđen sa druge strane: ono
što transformacija ukloni ne može se pojaviti u koloni `type`. Isključivanje poluspoja ovde je, treba
naglasiti, sredstvo posmatranja, a ne savet za podešavanje, jer proizvodi lošiji plan.

## 4.4. Kolona `Extra` i granica procene

U koloni `Extra` završava sve što se nije uklopilo u ostale kolone, pa u njoj završe i najkorisnije
reči celog ispisa. Tri vrednosti koje liče, a znače različite stvari, opisuju istu radnju na tri
različita mesta. `Using index` znači da su sve tražene kolone u indeksu, pa se tabela ne čita uopšte,
što je pokrivajući indeks *(covering index)*; `Using index condition` znači da je uslov spušten u motor
i proveren nad zapisom indeksa, dakle spuštanje uslova u indeks iz poglavlja 2; `Using where` znači da
serverski sloj filtrira torke koje mu je motor već predao [@mysql84refman]. Šav iz poglavlja 2 time
postaje vidljiv u jednoj jedinoj reči ispisa.

Druge vrednosti te kolone su upozorenja. `Using temporary` znači da se gradi privremena tabela, obično
zbog klauzule `DISTINCT` ili `GROUP BY`, a `Using filesort` da traženo uređenje ne isporučuje nijedan
indeks, nego se sortiranje obavlja posebno [@mysql84refman]. Pojava obe vrednosti u istom redu
najskuplji je od uobičajenih ishoda, jer se rezultat mora ceo materijalizovati pre sortiranja. Ime
`filesort` pritom vara: MySQL sortira u memoriji kad god rezultat u nju staje, a na disk prelazi tek
kada ne staje [@mysql84refman].

Sve pročitano u ovom delu poglavlja, međutim, jeste procena. `EXPLAIN` nad naredbom `SELECT` ne
izvršava upit, pa su `rows` i `filtered` procene koje umeju i da promaše, a ispis prikazuje samo
pobednika i ćuti o poraženim kandidatima [@mysql84refman]. Koliko je torki stvarno prošlo kroz plan
meri se naredbom `EXPLAIN ANALYZE`, dok se odbačeni planovi i njihove cene čitaju iz traga
optimizatora; time se bave naredni odeljci.

# 5. Iterator model i pipeline operatora

# 6. Vektorizovano izvršavanje

# 7. Paralelno izvršavanje upita

# 8. Keširanje i ponovna upotreba planova

# 9. Zaključak

# Reference
