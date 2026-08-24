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

![Slika 1.1: Jedan SQL upit, dva ekvivalentna plana izvršenja različite cene. Slobodan izbor
optimizatora (A) koristi indeks `idx_country_code` (procenjena cena ≈ 499373), dok zabranjivanje tog
indeksa (B) daje skuplji sken cele tabele (procenjena cena ≈ 575645); oba plana vraćaju isti rezultat
od približno 3,5 miliona torki.](figures/01-uvod-01-jedan-upit-dva-plana.png)

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

![Slika 2.1: Arhitektura MySQL-a sa modularnim mehanizmima skladištenja. Serverski sloj obuhvaćen je
jedinstvenim procesom (SQL interfejs, parser, optimizator, kešovi i baferi), dok su motori (InnoDB,
MyISAM, NDB Cluster, Memory) zasebni moduli ispod njega, povezani sa sistemom datoteka. Preuzeto iz
priručnika [@mysql84refman], Figure 18.3.](figures/02-arhitektura-00-mysql-architecture-official.png)

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

![Slika 2.2: Plan upita sa uključenim spuštanjem uslova u indeks (ICP): jedan čvor, sken opsega preko
indeksa `idx_customer_created`, sa uslovom označenim kao `with index condition` unutar samog skena.
Plameni grafikon dobijen iz `EXPLAIN ANALYZE FORMAT=JSON`, izmereno na živom serveru (MySQL
8.4.11).](figures/02-arhitektura-01-icp-ukljucen.png)

![Slika 2.3: Isti upit sa isključenim spuštanjem uslova: iznad skena se pojavljuje zaseban čvor
`Filter`, koji obavlja serverski sloj. Sken propušta 499.297 torki, a filter zadržava 165.707;
razlika od 333.590 torki prelazi granicu samo da bi bila odbačena.](figures/02-arhitektura-02-icp-iskljucen.png)

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

# 4. EXPLAIN i EXPLAIN ANALYZE

# 5. Iterator model i pipeline operatora

# 6. Vektorizovano izvršavanje

# 7. Paralelno izvršavanje upita

# 8. Keširanje i ponovna upotreba planova

# 9. Zaključak

# Reference
