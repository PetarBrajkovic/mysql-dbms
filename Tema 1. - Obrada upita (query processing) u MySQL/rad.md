---
title: "Obrada upita (Query Processing) u MySQL-u"
author: "Petar Brajković"
bibliography: references.bib
csl: ../ieee.csl
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
naspram skena cele tabele (B).](figures/01-uvod-01-jedan-upit-dva-plana.png){width=4.3in}

Slika 1.1 prikazuje ovu pojavu na konkretnom upitu nad sintetičkom tabelom `wide_events`. Isti upit
`SELECT notes FROM wide_events WHERE country_code = 'US'` MySQL izvršava skenom preko indeksa
`idx_country_code`, dok se zabranjivanjem tog indeksa dobija sken cele tabele, skuplji plan koji
vraća isti skup od približno 3,5 miliona torki. Iako oba plana daju istovetan rezultat, optimizator
zadržava jeftiniju varijantu; upravo je ta logika izbora predmet poglavlja koja slede.

Ostatak rada prati istu nit, put od deklarativnog SQL upita do njegovog fizičkog izvršenja u
MySQL-u:

- U poglavlju 2 opisuje se **arhitektura obrade upita u MySQL-u**, kao dva sloja sa dokumentovanim
  šavom: serverski sloj koji razume SQL i motor za skladištenje koji razume torke i stranice.
- Poglavlje 3 prati **put od SQL-a do plana izvršavanja** kroz pet faza obrade i pokazuje liniju
  ispod koje svaku odluku sa alternativom rešava cena.
- Poglavlje 4 uvodi **EXPLAIN i EXPLAIN ANALYZE**, alate kojima se izabrani plan čini vidljivim i
  kojima se procenjena cena poredi sa onim što se pri izvršavanju zaista dogodilo.
- Poglavlje 5 objašnjava kako se izabrani plan izvršava kroz **model iteratora (iterator model) i
  pipeline operatora**: operatori povlače torke jedan od drugog, torku po torku.
- Poglavlje 6 skuplja na jedno mesto tri tačke u kojima **MySQL ne prati obrazac** drugih sistema,
  vektorizovano izvršavanje, paralelno izvršavanje upita i keširanje i ponovnu upotrebu planova, i za
  svaku traži granicu na kojoj odrična tvrdnja prestaje da važi.
- Poglavlje 7 donosi **zaključak**: šta ti izbori zajedno znače i gde su drugi sistemi otišli dalje.

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
[@mysql84refman], Figure 18.3.](figures/02-arhitektura-00-mysql-architecture-official.png){width=3.6in}

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
činjenica biće bitna u odeljku 6.2, jer je paralelnost u MySQL-u pre svega između konekcija, a ne
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
8.4.11).](figures/02-arhitektura-01-icp-ukljucen.png){width=4.3in}

![Slika 2.3: Isti upit sa isključenim spuštanjem uslova, sa zasebnim čvorom `Filter` u
planu.](figures/02-arhitektura-02-icp-iskljucen.png){width=4.3in}

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
optimizatora.](figures/03-od-sql-a-do-plana-04-pet-faza-pregled.png){width=4.3in}

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
rastućem opsegu.](figures/03-od-sql-a-do-plana-01-ukrstanje-cena.png){width=4.1in}

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
[@mysql84refman]. To nisu tri pogleda na istu stvar: dva od tri formata prikazuju plan po tabeli, a
treći po iteratoru, i ta razlika određuje šta se u ispisu uopšte može videti.

Razlika se meri prebrojavanjem. Isti spoj tabela `customer` i `payment` nad bazom `sakila` u
tabelarnom formatu daje dva reda, po jedan za svaku tabelu, a u obliku stabla četiri čvora, jer su i
filter i sam spoj operacije, a ne osobine tabele. Filter u tabelarnom ispisu nema svoj red: sabijen je
u reč `Using where` u koloni `Extra` i u broj u koloni `filtered`. Most između dva oblika je aritmetika
koju priručnik izričito propisuje, `rows` pomnoženo sa `filtered` i podeljeno sa 100 [@mysql84refman].
Na posmatranom planu 16.500 torki pomnoženo sa 33,33 procenta daje 5.499, a to je tačno procena broja
torki čvora `Filter` u stablu; `FORMAT=JSON` verzije 1 isti broj daje gotov, u polju
`rows_produced_per_join` [@mysql84refman]. Ono što tabelarni format ostavlja čitaocu da izračuna,
stablo prikazuje kao zaseban čvor (Slika 4.1).

![Slika 4.1: Isti upit i isti plan u tri formata ispisa naredbe
`EXPLAIN`.](figures/04-explain-01-tri-formata-jedan-plan.png){width=4.3in}

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
[@mysql84refman]. Primarni ključ tabele `film_actor` složen je od kolona `actor_id` i `film_id`, po
2 bajta. Uslov samo nad prvom kolonom daje `key_len: 2`, dakle levi prefiks ključa, i devetnaest
torki po pretrazi, a uslov nad obe kolone `key_len: 4` i najviše jednu torku. Kolona `key` u oba
slučaja ispisuje isto ime, pa bi bez dužine ključa izgledalo da se dešava isto.

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
torki koje jedan pristup može da vrati.](figures/04-explain-02-lestvica-tipova-pristupa.png){width=4.1in}

Iz slike se vidi ono što se iz samog spiska ne vidi: te grupe se ne poklapaju sa redosledom iz
priručnika. Tip `unique_subquery`, osmi po redu, vraća najviše jednu torku, isto što i treći po redu
`eq_ref`, a stoji pet mesta niže. Redosled je, dakle, praktično uputstvo, a ne redosled cena. Tip
`range` nad pedeset torki jeftiniji je od tipa `ref` nad pet miliona torki, a
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

U koloni `Extra` završavaju i najkorisnije reči celog ispisa. Tri vrednosti koje liče, a znače
različite stvari, opisuju istu radnju na tri različita mesta. `Using index` znači da su sve tražene kolone u indeksu, pa se tabela ne čita uopšte,
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

## 4.5. Merenje umesto procene

Naredba `EXPLAIN ANALYZE` izvršava upit i uz svaki čvor stabla ispisuje drugu zagradu, u kojoj pored
procenjenih stoje i izmerene vrednosti [@mysql84refman]. U toj zagradi su tri podatka: `actual
time`, to jest dva vremena u milisekundama, do prve i do poslednje vraćene torke; `rows`, stvarni
broj torki koje je čvor vratio; i `loops`, broj ponavljanja tog čvora [@mysql84refman]. Ključ `rows`
tako se u istom redu pojavljuje dvaput, jednom kao procena a jednom kao merenje, i upravo njihovo
poređenje čini ovu naredbu dijagnostičkim alatom.

Dve granice te naredbe treba navesti odmah. Prva je da ona ispisuje samo stablo: priručnik navodi da
naredba uz `FORMAT=TRADITIONAL` ili `FORMAT=JSON` uvek vraća grešku [@mysql84refman], što na serveru
8.4.11 važi dok je promenljiva `explain_json_format_version` jednaka 1, dok se uz vrednost 2 JSON
ispis ipak dobija i u njemu stoje polja `actual_rows` i `actual_loops`; ovo poslednje navodi se kao
izmereno ponašanje sa imenovanom verzijom formata, a ne kao tvrdnja priručnika. Druga granica je da
izvršavanje ne menja podatke. Naredba prima `SELECT`, `TABLE` i višetabelarne oblike naredbi
`UPDATE` i `DELETE` [@mysql84refman], dok jednotabelarni `UPDATE` vraća `-> <not executable by
iterator executor>` bez ijednog čvora plana, a torke u oba slučaja ostaju nepromenjene, pa merenje
nije potrebno štititi transakcijom koja se poništava.

Osnovna dijagnostika koju to merenje omogućava jeste odstupanje procene od stvarnog broja torki
*(estimated versus actual rows)*. Meri se na istom upitu iz odeljka 4.1, u kome je iz tabelarnog
ispisa izvedena procena od 5.499 torki. Izvršavanje pokazuje da kroz čvor `Filter` prođe njih 114,
dakle 48 puta manje. Procena za sken tabele `payment` pritom nije promašena: procenjenih 16.500
naspram izmerenih 16.044 torki daje odstupanje od svega 1,03 puta. Promašaj je, dakle, lokalizovan
na jedan čvor i ima jasan uzrok: kolona `amount` nema ni indeks ni histogram, pa vrednost `filtered`
od 33,33 procenta nije merenje nego ugrađena pretpostavka za poređenje operatorom `>`
[@mysql84refman], dok je istina 114 od 16.044 torki, to jest 0,711 procenta.

Histogram je alat kojim se neravnomernost raspodele *(skew)* jedne kolone opisuje statistikom
[@mysql84refman]. Nad kolonom `amount`, koja nema indeks, on odstupanje zaista zatvara: posle
naredbe `ANALYZE TABLE payment UPDATE HISTOGRAM ON amount WITH 32 BUCKETS` vrednost `filtered` pada
sa 33,33 na 0,71 procenta, a procena sa 5.499 na 117 torki naspram izmerenih 114. Od trideset dve
tražene korpe *(bucket)* izgrađeno ih je devetnaest, tipa `singleton`. Nad indeksiranom kolonom isti
postupak ne menja ništa: procena za kolonu `country_code` tabele `wide_events` i pre i posle
histograma iznosi 2,45 miliona torki, jer optimizator, kada je kolona indeksirana, daje prednost
procenama optimizatora opsega *(range optimizer)* u odnosu na statistiku iz histograma
[@mysql84refman]. Sama ta procena promašuje izmereni broj od 3.500.177 torki za 1,43 puta.

Time se dolazi do pitanja gde je granica prevelikog odstupanja. Uobičajeno pravilo, po kome procena
koja promašuje više od tri puta zaslužuje pažnju, merenjem se pokazuje kao prag za proveru, a ne kao
presuda. Isti onaj upit sa odstupanjem od 48 puta, proširen na spoj pet tabela, daje isti redosled
spoja i sa histogramom i bez njega, a razlikuju se samo cene (9.373 naspram 1.926). Odstupanje,
dakle, znači da je odluka doneta na osnovu pogrešnog broja, ali ne i da je sama odluka pogrešna. Da
li jeste, vidi se tek kada se izabrani plan uporedi sa nekim drugim (Slika 4.3).

![Slika 4.3: Procena naspram stvarnog broja torki po čvorovima plana, i dejstvo histograma na koloni
bez indeksa i na koloni sa indeksom.](figures/04-explain-03-procena-naspram-stvarnog.png){width=4.3in}

## 4.6. Prosek po ponavljanju

Brojevi u izmerenoj zagradi čvora koji se nalazi unutar ugnježdene petlje nisu zbirovi nego proseci
po jednom ponavljanju [@mysql84refman]. Na spoju tabela `film`, `film_actor` i `actor`, sa uslovom
koji ostavlja 178 filmova, čvor `Covering index lookup on fa` prijavljuje `rows=5.48` i `loops=178`.
Razlomak u broju torki je znak da je reč o proseku: 178 ponavljanja puta 5,48 torki daje 975, a to
je upravo broj torki koji čvor spoja iznad njega prijavljuje (976). Ukupan doprinos jednog čvora
dobija se, dakle, tek množenjem sa `loops`, zbog čega čvor sa najmanjim prijavljenim vremenom ume da
bude najskuplji deo plana. Vreme se čita na isti način, jer i `actual time` meri jedno ponavljanje (Slika 4.4).

![Slika 4.4: Vrednosti `rows` i `actual time` kao proseci po ponavljanju: prijavljeno vreme jednog
ponavljanja naspram ukupnog vremena čvora.](figures/04-explain-04-loops-i-prosek.png){width=4.3in}

## 4.7. Plan koji ispis prikazuje kao savršen

Upit nad tabelom `wide_events` traži deset najstarijih torki koje ispunjavaju redak uslov nad
neindeksiranom kolonom, dakle `WHERE amount > 504.9 ORDER BY created_at LIMIT 10`. Uslov ispunjava
940 od pet miliona torki, to jest 0,0188 procenta, a optimizator i dalje pretpostavlja 33,33. U
`EXPLAIN` ispisu nijedna kolona nije upozorenje: `type: index`, `key: idx_created_at`, `rows: 10`,
bez vrednosti `Using filesort` i sa cenom oko 0,84, dakle manjom od jedan.

`EXPLAIN ANALYZE` nad istim upitom pokazuje da je sken preko indeksa pročitao 31.621 torku, dakle
3.162 puta više od procene, i da je to trajalo oko 2.853 milisekunde. Uzrok je sadejstvo klauzula
`ORDER BY` i `LIMIT`: plan čita indeks `idx_created_at` redom i staje kada skupi deset torki koje
prolaze filter, a pošto je uslov redak, do desete takve torke dolazi se tek posle 31.621 pročitane
torke. Procena od deset torki odnosi se na ono što plan vraća, a ne na ono što mora da pročita da bi
to vratio.

Da plan nije samo spor nego zaista loš, pokazuje poređenje sa alternativom. Kada se indeks oduzme
naredbom `IGNORE INDEX`, dobija se plan sa skenom cele tabele i sortiranjem, kome `EXPLAIN`
dodeljuje cenu 574.636, oko 686.000 puta veću, a koji se izvršava za oko 1.789 milisekundi, dakle
približno 1,6 puta brže. Model cene je jeftinijim proglasio sporiji plan, i to se bez izvršavanja
nije moglo videti. Apsolutna vremena razlikuju se od pokretanja do pokretanja, jer zavise od toga
koliko je stranica tabele zateknuto u baferu, dok odnos između dva plana ostaje isti.

Histogram ni ovde ne pomaže, iako procenu popravlja. Sa 64 i sa 1024 korpe nad kolonom `amount`
vrednost `filtered` pada sa 33,33 na 0,50 procenta, a procena u stablu sa 3,33 na 0,05 torki, dok
plan, broj pročitanih torki i vreme izvršavanja ostaju nepromenjeni. Razlog je što klauzula `LIMIT`
ograničava broj torki koji ulazi u cenu skena po redosledu indeksa na deset, i to pre nego što
ispravljena selektivnost stigne da taj broj podigne. Bolja statistika popravila je, dakle, procenu,
a nije promenila odluku (Slika 4.5).

![Slika 4.5: Isti upit u tri prikaza: procena koju ispisuje `EXPLAIN`, merenje koje dodaje `EXPLAIN
ANALYZE` i alternativni plan dobijen naredbom `IGNORE INDEX`.](figures/04-explain-05-los-plan.png){width=4.3in}

Ono što `EXPLAIN ANALYZE` ni ovde nije pokazalo jeste zašto je lošiji plan uopšte izabran. Ispis
meri jedan plan, onaj koji je pobedio, i ne pominje ni koje je alternative optimizator razmatrao ni
kolikom ih je cenom procenio. Taj podatak postoji, ali samo u tragu optimizatora, čime se bavi
naredni odeljak.

## 4.8. Trag optimizatora: odbačeni planovi i njihova cena

Trag optimizatora uključuje se sesijskim promenljivama `optimizer_trace_xxx`, a čita se iz tabele
`INFORMATION_SCHEMA.OPTIMIZER_TRACE` [@mysql84refman]. Ima tri faze traga, `join_preparation`,
`join_optimization` i `join_execution`, koje ne treba mešati sa pet faza obrade iz trećeg poglavlja:
parsiranje je gotovo pre nego što trag počne, a optimizacija i planiranje u njemu čine jedan blok.
Za razliku od naredbe `EXPLAIN ANALYZE`, koja mora da izvrši upit do kraja, trag se dobija i
praćenjem same naredbe `EXPLAIN`, pri čemu `join_optimization` ostaje istovetan, sa svim cenama.

Ono što trag dodaje jesu razmatrani planovi zajedno sa cenama. Time se zatvara pitanje otvoreno u
odeljku 4.2: za tabelu `film` indeks `idx_fk_original_language_id` stoji u koloni `possible_keys`,
dok je `key` jednak `NULL`, a trag pokazuje da je taj indeks ušao u korak `range_scan_alternatives`,
dobio cenu i bio odbačen sa `"chosen": false` i `"cause": "cost"`, u poređenju sa skenom cele
tabele. Odbačen plan tu više nije pretpostavka nego izmeren podatak.

Najviše, međutim, trag govori o lošem planu iz odeljka 4.7. U koraku `considered_execution_plans`
nad tabelom `wide_events` procenjen je tačno jedan pristupni put, sken cele tabele, cenom oko
578.000, dakle upravo onaj plan koji je u odeljku 4.7 dobijen naredbom `IGNORE INDEX`. Indeks
`idx_created_at` u tom koraku se ne pominje, jer nad kolonom `amount` indeksa nema. Tek kasniji
korak, `reconsidering_access_paths_for_index_ordering`, prijavljuje `"index_provides_order": true`,
`"index": "idx_created_at"` i `"plan_changed": true`, a njegov niz `"steps"` je prazan, što znači da
u tom koraku nijedna cena nije izračunata. Plan koji `EXPLAIN` prikazuje sa cenom 0,846 nije, dakle,
pobedio u poređenju: uvela ga je naknadna zamena plana zbog redosleda, a prikazana cena je posledica
izračunata posle zamene, a ne razlog za nju.

Okidač zamene je klauzula `LIMIT`, što se proverava njenim uklanjanjem. Bez nje trag prijavljuje
`"plan_changed": false`, a `EXPLAIN` daje `type: ALL` sa `Using filesort`, dakle plan koji je
pretraga po ceni zaista izabrala; sa `LIMIT 10000` zamena se ponovo dešava, pa nije presudna
veličina ograničenja nego njegovo postojanje. Time se objašnjava i nalaz iz odeljka 4.7, gde
histogram nad kolonom `amount` popravlja procenu a ne menja plan: odluka nije ni doneta na osnovu
procene (Slika 4.6).

![Slika 4.6: Trag optimizatora za upit iz odeljka 4.7, sa procenjenim pristupnim putevima i korakom
koji je plan zamenio.](figures/04-explain-08-zasto-bas-ovaj-plan.png){width=4.3in}

Trag ipak nije potpun zapis pretrage. Vrednost `"chosen": true` znači „najbolji do sada”, a ne
pobednika, pa se pobednik prepoznaje po manjoj vrednosti `cost_for_plan`, dok delimični planovi koji
otpadaju odsecanjem čim premaše najbolji nađeni ostaju zabeleženi samo kao `"pruned_by_cost": true`.
Uz to, trag je sesijski i iz druge sesije se ne vidi, a kada premaši vrednost promenljive
`optimizer_trace_max_mem_size`, postaje krnj, što se prijavljuje kolonom `MISSING_BYTES`
[@mysql84refman].

## 4.9. Plan tuđe sesije: EXPLAIN FOR CONNECTION

Trag ide dublje od naredbe `EXPLAIN`, ali ostaje u granicama sopstvene sesije. Suprotan smer pokriva
`EXPLAIN FOR CONNECTION`, koja preko broja veze (`connection_id`) ispisuje plan naredbe koja se u
tom trenutku izvršava u drugoj sesiji, i to bez njenog prekidanja [@mysql84refman]. Ispis je plitak,
jer daje isti sadržaj kao obična naredba `EXPLAIN`, a merenja nema: spoj sa `EXPLAIN ANALYZE` nije
dozvoljen i na serveru 8.4.11 vraća grešku 1235. Ako je ciljna veza besposlena, rezultat je prazan i
bez greške, a ako izvršava naredbu koja se ne može objasniti, vraća se greška 3012. Dve naredbe se,
dakle, ne preklapaju: trag do kraja objašnjava sopstvenu odluku, a `EXPLAIN FOR CONNECTION` daje
površan pogled na tuđu.

# 5. Iterator model i pipeline operatora

Poglavlje 3 pokazalo je kako se plan bira, a poglavlje 4 kako se izabrani plan čita i meri. Ostaje
pitanje šta se zapravo izvršava kada plan krene, i ono nije akademsko. Nad tabelom `wide_events` isti
uslov i isto ograničenje `LIMIT 10` jednom dovedu do toga da sken tabele pročita desetak torki, a
drugi put svih pet miliona, pri čemu je jedina razlika između ta dva slučaja jedna dodata klauzula
`ORDER BY`. Pristupni put je i u jednom i u drugom slučaju isti, pa objašnjenje mora da leži u načinu
na koji izvršilac poziva operatore, što je predmet ovog poglavlja.

## 5.1. Iterator: objekat sa tri metode

Model iteratora nije MySQL-ov izum. Potiče iz sistema Volcano, koji je opisao Graefe, i danas je
podrazumevani oblik izvršioca u relacionim sistemima [@graefe1994]. MySQL je Volcano model uveo
radnim zadatkom WL#11785, čiji je cilj bila jedna složiva apstrakcija iteratora, pozajmljena iz
sistema Volcano, koja zamenjuje šest dotadašnjih međusobno nespojivih apstrakcija za čitanje torki
(`QUICK_SELECT_I`, `READ_RECORD`, `QEP_TAB`, `QEP_operation`, `QEP_TAB::next_select` i
`Query_result`) [@mysqlwl11785].

Ta apstrakcija je klasa `RowIterator` sa tri metode. Metoda `Init()` inicijalizuje iterator, odnosno
premota ga na početak, i mora se pozvati pre prvog čitanja; metoda `Read()` vraća jednu torku, a
njena povratna vrednost je samo status, 0 za uspeh, -1 kada torki više nema i 1 za grešku; metoda
`UnlockRow()` otpušta zaključavanje nad torkom koja je pročitana pa odbačena [@mysqlsource84].

Dve stvari u tom potpisu lako se promaše, a obe su bitne. Prva: torka se ne vraća kao rezultat
funkcije, nego se smešta u bafer torke *(record buffer)* same tabele, `table->records[0]`. Volcano
model MySQL-u daje oblik toka upravljanja, dakle inicijalizaciju, čitanje i zatvaranje, dok torke i
dalje putuju kroz raniju konvenciju bafera; izvorni kod tu granicu i priznaje, navodeći da
apstrakcija nije potpuno zatvorena, jer izbor kolona koje se čitaju (`read_set`) ostaje na strukturi
`TABLE` [@mysqlsource84]. Druga: iterator sme da čita iz drugog iteratora, pa se od iteratora ne
gradi lanac nego stablo.

## 5.2. Stablo iteratora u ispisu FORMAT=TREE

Format ispisa `TREE`, u poglavlju 4 uveden kao drugi oblik plana, priručnik opisuje preciznije: u
njemu čvorovi predstavljaju iteratore [@mysql84refman]. Uvlačenje je odnos roditelj-dete, jer
roditeljski iterator poziva metodu `Read()` svog deteta, a dete mu vraća jednu torku. Stablo se zato
čita odozdo naviše kada se prati odakle podaci dolaze, a odozgo nadole kada se prati ko koga poziva.

Nad bazom `sakila`, upit koji spaja tabele `customer` i `rental`, grupiše po kupcu i vraća pet
vodećih rezultata, daje osam čvorova: `Limit`, `Sort`, `Stream results`, `Group aggregate`,
`Nested loop inner join`, pa dva ulaza spoja, `Filter` nad skenom indeksa po tabeli `customer` i
`Covering index lookup` po tabeli `rental`. To nije osam koraka koje server izvodi jedan za drugim,
nego osam objekata koji istovremeno postoje u memoriji, povezanih tako da koren stabla poziva
sledeći čvor, i tako sve do listova, koji jedini dodiruju tabelu preko `handler` interfejsa iz
poglavlja 2.

Preslikavanje ispisa na klase nije analogija nego mehanika: tekst ispisa generiše se u datoteci
`explain_access_path.cc`, a iterator se pravi u datoteci `access_path.cc`, i obe se granaju po istom
polju `path->type` [@mysqlsource84]. Zato svakom obliku ispisa odgovara tačno jedna klasa:
`Table scan on …` daje `TableScanIterator`, `Filter: …` daje `FilterIterator`, `Sort: …` daje
`SortingIterator`, `Limit: N row(s)` daje `LimitOffsetIterator`, `Nested loop … join` daje
`NestedLoopIterator`, a `Stream results` daje `StreamingIterator`. Kod skena indeksa klasa je
`IndexScanIterator`, čiji parametar šablona označava čitanje indeksa unatrag, a ne pokrivenost
indeksa, jer je pokrivenost svojstvo skupa `read_set` i klasu ne menja [@mysqlsource84].

Jedan red ispisa je izuzetak. Red `-> Hash`, koji stoji iznad ulaza Hash spoja, nije iterator nego
natpis na grani ka ulazu koji se hešira [@mysqlsource84]. Prepoznaje se i bez uvida u izvorni kod,
jer je jedini red u stablu bez ijednog broja uz sebe: iza njega ne stoji ni struktura čija bi se cena
procenila ni iterator čije bi se vreme merilo (Slika 5.1).

![Slika 5.1: Osam redova ispisa naredbe `EXPLAIN ANALYZE` i osam iteratora koji im odgovaraju:
kontrola ide nadole kroz pozive metode `Read()`, a torke se vraćaju nagore, jedna po
jedna.](figures/05-model-iteratora-01-stablo-iteratora.png){width=4.3in}

## 5.3. Vrednost `loops` je broj poziva metode `Init()`

Odeljak 4.6 uveo je `loops` kao broj ponavljanja čvora i tu se zaustavio. Izvorni kod kaže šta se
tačno broji: metoda `GetNumInitCalls()` klase `IteratorProfiler`, koja postoji zato da bi naredba
`EXPLAIN ANALYZE` imala odakle da čita, vraća broj poziva metode `Init()` nad tim iteratorom
[@mysqlsource84].

Time dva pravila iz poglavlja 4 postaju posledice, a ne konvencije ispisa. Prvo, `NestedLoopIterator`
za svaku torku spoljašnjeg ulaza pozove `Init()` pa `Read()` na unutrašnjem ulazu, pa je `loops` na
unutrašnjem čvoru jednak broju torki koje je izbacio spoljašnji čvor: u navedenom upitu to je 584,
tačno onoliko koliko u tabeli `customer` ima aktivnih kupaca. Drugo, pošto se merenja sabiraju kroz
sva ponavljanja a prikazuju po jednom ponavljanju, `rows` na unutrašnjem čvoru je prosek po
ponavljanju i zato sme da bude decimalan broj. Ukupan broj torki dobija se množenjem: prijavljeno
`rows=26.8` puta `loops=584` daje približno 15.651, prema 15.640 koliko prijavljuje sam čvor spoja, a
razlika potiče od zaokruživanja ispisane vrednosti.

## 5.4. Pipeline i blokirajući operatori

Ako torka nastaje tek kada je neko zatraži, nijedan operator ne zna unapred koliko će ih proizvesti,
nego prestaje da radi onda kada ga prestanu pozivati. To je izvršavanje na zahtev *(demand-driven)*,
i najkraće se dokazuje primerom iz uvoda ovog poglavlja.

Upit koji nad tabelom `wide_events` traži deset torki sa uslovom nad kolonom `amount` daje plan od
tri čvora, `Limit`, `Filter` i sken tabele, pri čemu sva tri prijavljuju deset torki, a upit traje
nekoliko milisekundi. Dodavanje klauzule `ORDER BY` nad istom kolonom ubacuje čvor `Sort` između
čvorova `Limit` i `Filter`, posle čega isti sken nad istom tabelom prijavljuje pet miliona torki, a
upit je oko šest stotina puta sporiji. Sken pri tome ne zna ništa o klauzuli `LIMIT` i nije
optimizovan da stane: on jednostavno prestaje da bude pozivan čim `Limit` dobije svojih deset torki,
pa je rano zaustavljanje posledica izvršavanja na zahtev. Čim se između njih ubaci `Sort`, koji ne
može da vrati prvu torku dok nije video sve torke svog deteta, isti sken se izvrši do kraja. Takav
operator naziva se blokirajući operator *(blocking operator)*, jer pipeline preseca na dva dela.

Blokada se u ispisu prepoznaje i bez poznavanja samih operatora. Naredba `EXPLAIN ANALYZE` po
iteratoru prijavljuje vreme do prve vraćene torke i ukupno vreme provedeno u tom iteratoru, što se u
ispisu vidi kao `actual time=prvo..poslednje` [@mysql84refman]. Kod pipeline operatora prva vrednost
je znatno manja od druge, jer torke izlaze postepeno, kako pristižu, dok se kod blokirajućeg
operatora dve vrednosti poklapaju, jer ništa nije izašlo dok sve nije ušlo. Oba potpisa vide se u
istom planu: čvor `Sort` prijavljuje vreme prve torke jednako vremenu poslednje, a čvor `Filter`
neposredno ispod njega prvu torku vraća posle nešto više od jedne desetine milisekunde, a poslednju
tek pred kraj upita. Blokiraju sortiranje, materijalizacija privremene tabele, agregacija preko
privremene tabele i faza gradnje Hash spoja, dok skenovi, pretrage po indeksu, `Filter`, `Limit` i
spoj sa ugnježdenom petljom rade u pipeline-u. Tu je i razlog zbog kog čvor `Stream results` uopšte
postoji: on je suprotnost materijalizaciji, jer se rezultat šalje klijentu kako nastaje, pa je
njegovo prisustvo u stablu znak da na tom mestu barijere nema (Slika 5.2).

![Slika 5.2: Isti sken tabele sa istim uslovom i istim ograničenjem `LIMIT 10`, bez klauzule
`ORDER BY` i sa njom.](figures/05-model-iteratora-02-pipeline-i-blokada.png){width=4.3in}

## 5.5. Struktura `AccessPath` je plan, iterator je izvršavanje

Ostaje pitanje odakle iteratori dolaze. Između planera iz poglavlja 3 i izvršioca stoji struktura
`AccessPath`, koju izvorni kod opisuje kao strukturu planiranja upita koja iteratorima odgovara jedan
prema jedan, jer sadrži gotovo tačno ono što je potrebno da se odgovarajući iterator instancira, uz
podatke koji su potrebni samo tokom planiranja, kao što je cena [@mysqlsource84]. Optimizator, dakle,
ne pravi iteratore nego stablo struktura `AccessPath`, namerno malih i fiksne veličine, kako bi
tokom pretrage jedna mogla da se zameni boljom bez nove alokacije; tek na kraju funkcija
`CreateIteratorFromAccessPath()` to stablo prevodi u stablo iteratora [@mysqlsource84]. Strukturu
`AccessPath` ne treba mešati sa pristupnim putem iz poglavlja 1 i 3: prva je konkretna struktura u
kodu, a drugi je pojam koji označava način na koji se dolazi do torki jedne tabele.

Time se zatvara i pitanje otvoreno u odeljku 4.8, gde je u tragu optimizatora sav sadržaj bio u fazi
`join_optimization`, dok je faza `join_execution` bila prazna. Razlog je što se u izvršavanju ne
donosi nijedna odluka koju bi trag imao da zabeleži: sve je odlučeno u trenutku kada je stablo
struktura `AccessPath` bilo gotovo, a posle toga se ono samo prevodi u objekte i pokreće.

Model iteratora je i polazna tačka narednog poglavlja. Pošto svaki poziv metode `Read()` vraća
najviše jednu torku, tvrdnja da MySQL upite ne izvršava vektorizovano prestaje da bude izolovana
činjenica i postaje posledica interfejsa opisanog ovde.

# 6. Gde MySQL ne prati obrazac

Prethodna poglavlja opisivala su šta MySQL radi. Ovo poglavlje skuplja na jedno mesto tri tvrdnje
suprotnog oblika: MySQL ne izvršava upit nad paketima torki, ne paralelizuje izvršavanje plana i ne
čuva izabrani plan za sledeće izvršenje. Odrična tvrdnja je slabija nego što izgleda, jer je obara
jedan jedini protivprimer, pa se nijedan od tri odeljka ne zaustavlja na obliku „nema", nego traži
granicu na kojoj to „nema" prelazi u „ima, ali samo pod ovim uslovima". Sve tri granice su izmerene
na živom serveru.

## 6.1. Vektorizovano izvršavanje

Vektorizovano izvršavanje znači da jedan poziv operatora ne obrađuje jednu torku nego paket torki
*(batch)*, najčešće nekoliko stotina do nekoliko hiljada njih, pa se režija poziva i interpretacije
izraza raspodeljuje na ceo paket umesto da se plaća po torki. Taj model izvršavanja opisan je u
sistemu MonetDB/X100, uz merenje koje pokazuje da klasičan Volcano izvršilac najveći deo vremena
troši upravo na tu režiju, a ne na sam izračun [@boncz2005]. Danas je uobičajen u sistemima
namenjenim analitičkom workloadu (OLAP): DuckDB, na primer, sve operatore gradi nad vektorom fiksne
veličine, čija podrazumevana vrednost `STANDARD_VECTOR_SIZE` iznosi 2.048 torki [@duckdbdocs]. Uz
vektorizaciju obično ide i kolonarno skladištenje *(columnar storage)*, jer se paket vrednosti jedne
kolone obrađuje bez skakanja kroz memoriju.

MySQL upite ne izvršava tako, i to nije zaseban podatak nego posledica interfejsa iz poglavlja 5:
metoda `Read()` po definiciji vraća jednu torku po pozivu [@mysqlwl11785].

Odsustvo vektorizacije ne može da se uključi i isključi da bi se izmerila razlika, jer je reč o
arhitektonskoj odluci, ali se njena posledica meri neposredno. Ako se svaki izraz izračunava jednom
za svaku torku, onda svaki dodatni predikat mora da doda približno konstantan iznos po torki,
nezavisno od toga koliko torki taj predikat propušta. Nad tabelom `wide_events` od pet miliona
torki, u jednoj niti, isti klasterovani sken sa šest predikata povezanih operatorom `AND` traje oko
1,4 puta duže nego isti sken bez ijednog predikata, a iz razlike između jednog i šest predikata
izlazi cena od približno 20 nanosekundi po torki po jednom predikatu. Kontrolno merenje pokazuje da
selektivnost tu ništa ne menja: predikat koji ne propušta gotovo nijednu torku (`amount > 999999`)
traje praktično isto koliko i predikat koji propušta većinu (`amount > 100`), jer se izraz izračuna
i za torku koja odmah otpada. Vektorizovani izvršilac bi tu istu proveru amortizovao kroz ceo paket
torki, a uz kolonarno skladištenje mogao bi i ceo paket da preskoči odjednom.

Iz toga ne sledi da je izvršavanje torku po torku mana. Ono daje kratko vreme do prve torke i malu
potrošnju memorije, što je upravo ono što traži transakcioni workload (OLTP), dakle veliki broj
kratkih upita koji dodiruju malo torki. Cena se plaća na suprotnom kraju, kod upita koji prolaze
kroz milione torki, i Oracle taj kompromis ne skriva nego ga rešava zasebnim proizvodom: HeatWave
podatke drži u memoriji u hibridnom kolonarnom formatu i upit izvršava tako što kroz plan gura
vektorske blokove, odnosno isečke kolonarnih podataka, od jednog operatora do drugog, što
dokumentacija izričito suprotstavlja obradi zasnovanoj na pojedinačnim torkama [@mysqlheatwave].
HeatWave je, međutim, zaseban izvršilac koji stoji pored MySQL-a, čiji iteratorski izvršilac ostaje
onakav kakav je opisan u poglavlju 5.

## 6.2. Paralelno izvršavanje upita

Poglavlje 2 zabeležilo je da promenljiva `thread_handling` podrazumevano ima vrednost
`one-thread-per-connection`, pa je paralelnost u MySQL-u pre svega paralelnost između konekcija.
Unutar jednog upita ipak postoji jedan oblik paralelizma, a tačna tvrdnja o njemu uža je i od
tvrdnje da MySQL nema paralelizam i od tvrdnje da paralelizuje upite.

Ono što postoji jeste paralelno čitanje klasterovanog indeksa, koje kontroliše sesijska promenljiva
`innodb_parallel_read_threads`. Priručnik tu mogućnost dokumentuje uz naredbu `CHECK TABLE` i navodi
dva uslova: promenljiva mora biti veća od 1, a stvarni broj radnih niti jednak je manjoj od dve
vrednosti, zadate vrednosti promenljive i broja podstabala indeksa koja treba pročitati
[@mysql84refman]. Radni zadatak koji je tu mogućnost uveo precizniji je o tome za koji upit ona
važi, jer u odeljku `Scope` izričito stoji da se podstabla indeksa čitaju paralelno samo ako je
zahtev nezaključavajući `SELECT COUNT(*)` [@mysqlwl11720]. Merenje pokazuje da su i uz taj jedan
oblik upita potrebna još dva uslova, koja radni zadatak ne pominje.

Prvi uslov je da se klasterovani indeks zaista i čita. Za `COUNT(*)` je svaki indeks pokrivajući, pa
optimizator bira najuži sekundarni, što se u ispisu vidi kao ime tog indeksa u koloni `key` uz
vrednost `Using index` u koloni `Extra`. Podrazumevani plan zato paralelno čitanje nikada i ne
dobije, a merenje kroz sve vrednosti promenljive daje ravnu liniju koja izgleda kao dokaz da
paralelizma nema. Zbog toga u primerima uz ovo poglavlje stoji `FORCE INDEX(PRIMARY)`: bez tog
nagoveštaja meri se pogrešan plan.

Drugi uslov je odsustvo predikata, i on je granica koju ovo poglavlje traži (Slika 6.1).

![Slika 6.1: Isti klasterovani sken tabele `wide_events`, bez klauzule `WHERE` i sa jednom takvom
klauzulom, kroz pet vrednosti promenljive `innodb_parallel_read_threads` (medijana od tri merenja,
MySQL 8.4.11).](figures/06-gde-mysql-ne-prati-obrazac-01-paralelni-sken-granica.png){width=4.3in}

Bez predikata, prelazak sa jedne na šesnaest niti daje ubrzanje od 2,9 puta; sa jednom jedinom
dodatom klauzulom `WHERE`, isto to ubrzanje iznosi 1,01 puta, dakle ništa. Objašnjenje nije
heuristika nego šav iz poglavlja 2. Kada nema ni predikata ni projekcije, InnoDB može sam da
prebroji torke u više podstabala i serverskom sloju vrati samo zbir, pa pojedinačne torke nikada ne
pređu granicu između dva sloja. Čim se pojavi `WHERE`, o predikatu odlučuje iterator na serverskom
sloju, pa svaka torka mora da pređe kroz `handler`, jedna po jedna, pozivima metode `Read()` iz
poglavlja 5, i to u jednoj niti. Granica MySQL-ovog paralelizma je, dakle, tačno na šavu između
serverskog sloja i motora, a poglavlja 2 i 5 je zajedno predviđaju.

Poređenje sa sistemom koji istu stvar rešava drugačije čini tu granicu oštrijom. U PostgreSQL-u
odluku donosi optimizator: kada zaključi da je paralelno izvršavanje najbrža strategija, u plan
ugrađuje čvor `Gather` ili `Gather Merge`, čije se podstablo izvršava u radnim procesima, a ako taj
čvor stoji u korenu plana, ceo upit se izvršava paralelno [@postgresql18]. U MySQL-u plan nikada
nije paralelan, nego je paralelno samo jedno čitanje ispod plana. Zato u ispisu naredbe `EXPLAIN` iz
poglavlja 4 i nema čvora koji bi paralelizam označavao: reč je o paralelizmu unutar operacije, a ne
o paralelizmu na nivou upita.

## 6.3. Keširanje i ponovna upotreba planova

Pitanje da li se izabrani plan čuva za sledeći put meša tri različite stvari, pa se odgovor dobija
tek kada se one razdvoje. Keš rezultata upita *(query cache)* čuvao je same rezultate i uklonjen je
u verziji 8.0, uz obrazloženje da je podrazumevano isključen još od verzije 5.6 i da se korisnicima
umesto njega preporučuje keširanje izvan servera [@mysqlblogqc]. Deljeni keš plana čuvao bi planove
izvršenja između sesija i u MySQL-u ne postoji. Keš pripremljene naredbe *(prepared statement)* čuva
unutrašnju strukturu naredbe i postoji, ali samo u okviru jedne sesije.

Kako izgleda sistem koji deljeni keš plana ima, vidi se kod Oracle-a. U njegovom deljenom pulu
*(shared pool)* za svaku naredbu stoji po jedna deljena SQL oblast, dostupna svim korisnicima, a u
njoj i stablo raščlanjivanja i plan izvršenja; privatne oblasti pojedinačnih sesija pokazuju na istu
deljenu oblast, pa dve sesije koje izvršavaju isti upit dele jedan plan [@oracleconcepts]. U
MySQL-u zajedničke oblasti te vrste nema,
i to se najkraće vidi na pripremljenoj naredbi: naredba pripremljena u jednoj sesiji u drugoj ne
postoji ni pod kojim imenom, pa se njeno izvršenje odbija greškom `ERROR 1243 (HY000)`.

Priručnik je o tome šta MySQL zaista kešira izričit. Keševe pripremljenih naredbi i uskladištenih
programa server održava po sesiji, naredbe keširane u jednoj sesiji nisu dostupne drugim sesijama, a
kada se sesija završi, server ih odbacuje; ono što se pri tome kešira jeste unutrašnja struktura u
koju je naredba pretvorena, dakle stablo raščlanjivanja sa razrešenim imenima, a ne plan izvršenja
[@mysql84refman].

Da se plan zaista ne kešira, može se pokazati alatom iz odeljka 4.8. Ako je plan sačuvan, drugo
izvršenje iste pripremljene naredbe nema šta da upiše u trag optimizatora. Tri izvršenja jedne
naredbe sa parametrom nad kolonom `country_code`, međutim, daju tri zasebna traga, svaki sa
sopstvenom procenom broja torki i sopstvenom cenom. Razlike među njima nisu male: vrednost `US`
pokriva oko 71% torki u tabeli, a svaka od ostalih zemalja oko 2%, pa je procena za `US` oko
dvanaest puta veća od procena za druge dve vrednosti, sa srazmerno većom cenom. Optimizacija se,
dakle, obavlja nad stvarnom vrednošću parametra, a ne jednom za sve vrednosti: MySQL ne pravi
generički plan, pa nema ni mehanizam koji bi generički i konkretni plan poredio. Tvrdnja je time
jača od one sa kojom je odeljak počeo, jer plan nije samo nedeljen između sesija, nego se iznova
izvodi pri svakom izvršenju.

Ostaje pitanje šta je onda ta unutrašnja struktura, a odgovor daje ponovna priprema. Priručnik
navodi da server prati promene metapodataka tabela na koje se pripremljena naredba odnosi i da
naredbu pri sledećem izvršenju automatski priprema ponovo, dakle ponovo je raščlanjuje i iznova
gradi unutrašnju strukturu, uz najviše tri pokušaja [@mysql84refman]. Na maloj probnoj tabeli to se
vidi u jednom potezu: pripremljena naredba oblika `SELECT * FROM t` prvi put vraća dve kolone, a
posle naredbe `ALTER TABLE ... ADD COLUMN` isti, nepromenjeni tekst naredbe vraća tri kolone, dok
brojač `Com_stmt_reprepare` odlazi sa nule na jedinicu. Znak `*` je, dakle, bio razrešen u konkretnu
listu kolona i zapamćen, pa promena te liste poništava zapamćenu strukturu. Keširano je upravo ono
što priručnik naziva unutrašnjom strukturom, a plan koji bi tu strukturu izvršio nije deo onoga što
se pamti.

Precizan oblik tvrdnje kojom se poglavlje zatvara zato glasi: MySQL nema ni keš rezultata upita ni
deljeni keš plana, ali ima sesijski keš pripremljene naredbe, dok se plan izvršenja izvodi iznova
pri svakom izvršenju, nad stvarnom vrednošću parametra. Sva tri odeljka time završavaju na istom
mestu: odrična tvrdnja o sistemu tačna je samo uz uslove pod kojima je proverena.

# 7. Zaključak

Rad je pratio jednu nit: put deklarativnog SQL upita do njegovog fizičkog izvršenja u MySQL-u. Uvod
je taj put postavio kao jaz koji se premošćuje optimizacijom na dva nivoa jednog istog problema,
logičkom preformulacijom izraza i fizičkim izborom algoritma i pristupnog puta, a oba nivoa vodi
isto merilo, cena [@ramakrishnan2003]. Poglavlja koja slede daju tom opisu mehanizam:
dvoslojnu arhitekturu sa šavom na klasi `handler`, pet faza obrade i liniju ispod koje svaku odluku
sa alternativom rešava cena, ispis kojim se izabrani plan čini vidljivim i merenje kojim se procena
proverava, i stablo iteratora u kome plan postaje kod koji se izvršava.

Poglavlje 6 ostavlja sintezu: tri odrične tvrdnje iz njega nisu tri odvojene odluke nego jedna
ista, viđena sa tri strane. Metoda `Read()` po pozivu vraća najviše jednu torku, pa
vektorizovanog izvršavanja nema. O predikatu odlučuje iterator na serverskom sloju, pa torke moraju
da pređu granicu između dva sloja jedna po jedna i paralelnost staje na prvoj klauzuli `WHERE`.
Optimizacija se obavlja nad stvarnom vrednošću parametra pri svakom izvršenju, pa nema plana koji bi
se sačuvao i delio. MySQL, dakle, obradu upita drži usko vezanu za pojedinačnu torku i za
pojedinačno izvršenje.

Taj izbor nije propust nego kompromis. Izvršavanje torku po torku daje kratko vreme do prve torke i
malu potrošnju memorije, optimizacija pri svakom izvršenju daje plan skrojen prema stvarnoj
vrednosti parametra umesto generičkog, a paralelnost između konekcija ostavlja jezgra ostalim
konekcijama: sve tri osobine odgovaraju transakcionom workloadu (OLTP). Cena se plaća kod upita koji prolaze kroz milione
torki, gde se režija od približno 20 nanosekundi po torki po predikatu nema kroz šta raspodeliti, a
paralelno čitanje se gubi čim se pojavi prvi predikat.

Na tom suprotnom kraju drugi sistemi su otišli dalje. Vektorizovani izvršioci istu režiju
raspodeljuju na paket torki [@boncz2005; @duckdbdocs], PostgreSQL paralelizuje sam plan čvorom
`Gather` [@postgresql18], a Oracle plan drži u deljenom pulu dostupnom svim sesijama
[@oracleconcepts]. Nijedan od njih, međutim, ne polazi sa drugog mesta: model iteratora
koji MySQL zadržava jeste Volcano model [@graefe1994], koji i vektorizovani izvršioci menjaju samo
u jednoj tački, u broju torki po pozivu. Odgovor MySQL-a na
analitički workload nije izmena tog izvršioca nego zaseban izvršilac pored njega [@mysqlheatwave].

Ostaje i pouka o načinu na koji se o sistemu zaključuje. Ispis naredbe `EXPLAIN` postaje dijagnoza
tek uz merenje pored sebe, a razlika između 2,9 i 1,01 puta pokazuje da je i tvrdnja o tome šta sistem ne radi tačna samo uz uslove pod kojima je proverena. U narednim
izdanjima očekivano se menja izbor plana, jer hipergrafski optimizator spoja u kodu
verzije 8.4 već postoji, ali je pri prevođenju isključen [@mysql84refman]; model izvršavanja iz
poglavlja 5 time se ne menja.

# Reference
