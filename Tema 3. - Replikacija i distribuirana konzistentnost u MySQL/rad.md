---
title: "Replikacija i distribuirana konzistentnost u MySQL-u"
author: "Petar Brajković"
bibliography: references.bib
csl: ../ieee.csl
reference-section-title: "Reference"
---

<!--
  The body of the paper. One chapter appended per session, by the academic-research-writer
  skill under the rules in ../WRITING.md. Never hand-written and tidied afterwards.

  Do NOT set `lang: sr` here - it forces the IEEE reference list into Cyrillic.
  The title page is a separate file (naslovna.md) and is prepended by ../tools/make-docx.ps1.
-->

# 1. Uvod

# 2. Teorijski okvir: modeli konzistentnosti, CAP/PACELC i konsenzus

Replikacija podrazumeva da isti podatak postoji na više čvorova, pri čemu klijent čita sa jednog od
njih. Svi pojmovi ovog poglavlja izvode se iz dve osobine okruženja u kome se ti čvorovi nalaze.
Prvo, čvorovi nemaju zajedničku memoriju ni zajednički sat, pa se svaka informacija između njih
prenosi isključivo porukom, a prenos poruke traje vreme koje nije zanemarljivo [@lamport1978].
Drugo, u asinhronoj mreži poruka može i da se izgubi, a čvor koji odluke donosi samo na osnovu
primljenih poruka ne može da razlikuje poruku koja je izgubljena od poruke koja samo kasni, pa ni
čvor koji je pao od čvora koji je spor ili odsečen [@gilbert2002]. Iz ovih osobina neposredno sledi
da upis ne stiže na sve kopije istovremeno, pa se postavlja pitanje šta čitanje sa pojedinačne kopije
sme da vrati. Ovo poglavlje uvodi rečnik kojim se na to pitanje odgovara: modele konzistentnosti,
teoreme CAP i PACELC, modele replikacije i konsenzus. Nijedan MySQL mehanizam se ovde ne objašnjava;
kasnija poglavlja ovaj rečnik koriste bez ponovnog definisanja.

## Modeli konzistentnosti

Model konzistentnosti je ugovor između sistema i klijenta koji određuje koje vrednosti čitanje sme
da vrati dok se upisi šire kroz replike. Najjači takav ugovor je stroga konzistentnost (strong
consistency), formalno definisana kao linearizabilnost (linearizability). Herlihy i Wing je opisuju
kao privid da svaka operacija stupa na snagu trenutno, u nekoj tački između svog poziva i svog
odgovora [@herlihy1990], tako da se sistem ponaša kao da postoji samo jedna kopija podatka. Praktična
posledica je da, kada se upis završi i klijent dobije potvrdu, svako kasnije čitanje bilo kog
klijenta mora da vidi tu vrednost ili noviju. Stroga konzistentnost pritom ne zamrzava vrednost, već
zabranjuje samo povratak na stanje starije od već završenog upisa. Cena je ugrađena u samu
definiciju: replika koja odgovara na čitanje mora pre odgovora da zna da poseduje sve završene
upise, a to znanje može da stigne samo porukom.

Zbog te cene definisani su slabiji modeli, koji su međusobno ugnežđeni: jači model automatski
ispunjava sva obećanja slabijih, pa se pri analizi konkretne anomalije traži najslabiji model koji
je zabranjuje. Uzročna konzistentnost (causal consistency) oslanja se na Lamportovu relaciju
„desilo se pre“ (happened before) [@lamport1978] i zahteva da, ako je jedan upis mogao da utiče na
drugi, svi čvorovi vide prvi upis pre drugog, dok upisi koji nisu uzročno povezani smeju na
različitim čvorovima da se vide različitim redosledom. Ako jedan korisnik objavi pitanje, a drugi ga
pročita i na njega odgovori, uzročna konzistentnost zabranjuje da treći korisnik vidi odgovor bez
pitanja. Na dnu ove lestvice nalazi se konačna konzistentnost (eventual consistency), koja obećava
samo to da će, ako novih upisa više nema, sva čitanja na kraju vraćati poslednju upisanu vrednost
[@vogels2008]. Dok upisi traju, konačna konzistentnost ne ograničava šta čitanje vraća.

Između ovih krajnosti nalaze se sesijske garancije (session guarantees), koje Terry i saradnici
definišu za pojedinačnu sesiju klijenta, a ne za ceo sistem [@terry1994]. Read-your-writes (čitanje
sopstvenih upisa) zahteva da čitanja jedne sesije odražavaju njene prethodne upise, a monotona
čitanja (monotonic reads) da uzastopna čitanja odražavaju skup upisa koji se ne smanjuje
[@terry1994]. Dve garancije razlikuje ono što ih pokreće. Read-your-writes pokreće sopstveni upis
sesije: korisnik koji promeni lozinku, a zatim u sledećem čitanju, sa replike koja kasni, vidi staru
lozinku, doživljava upravo kršenje ove garancije. Monotona čitanja pokreće prethodno čitanje:
korisnik koji ništa ne menja, a posle osvežavanja stranice vidi stanje starije od onog koje je već
video, doživljava kršenje monotonih čitanja, iako je konačna konzistentnost i dalje ispunjena.
Anomaliju read-your-writes sedmo poglavlje meri na MySQL topologiji.

## CAP i PACELC

Brewer je 2000. godine izneo pretpostavku da distribuirani sistem ne može istovremeno da obezbedi
konzistentnost, dostupnost i toleranciju na particiju mreže [@brewer2000], a Gilbert i Lynch su je
dve godine kasnije formalizovali i dokazali [@gilbert2002]. U njihovoj formulaciji C označava upravo
strogu konzistentnost: mora postojati potpun redosled svih operacija u kome svaka operacija izgleda
kao da je izvršena u jednom trenutku. A označava dostupnost (availability): svaki zahtev koji primi
čvor koji nije pao mora da dobije odgovor, pri čemu se brzina odgovora ne meri. P, particija mreže
(network partition), opisuje mrežu kojoj je dozvoljeno da izgubi proizvoljno mnogo poruka između
čvorova [@gilbert2002]. Suština dokaza staje u jedan misaoni eksperiment. Veza između dva čvora je
prekinuta, a oba rade; klijent upiše novu vrednost na prvi čvor i dobije potvrdu, a drugi klijent
zatim traži istu vrednost od drugog čvora. Drugi čvor ima tačno dve mogućnosti. Ako odgovori, vraća
staru vrednost posle završenog upisa i time krši C. Ako čeka poruku od prvog čvora, a particija
potraje, živ čvor ne odgovara i time krši A. Teorema koju su dokazali Gilbert i Lynch upravo tvrdi da
u asinhronoj mreži nije moguće implementirati objekat za čitanje i upis koji garantuje i dostupnost i
atomičnu konzistentnost u svim izvršavanjima, uključujući i ona u kojima se poruke gube
[@gilbert2002].

Teorema se često prepričava kao pravilo „izaberi dva od tri“, a na to pogrešno čitanje upozorio je
i sam Brewer: formulacija „dva od tri“ bila je, po njegovim rečima, oduvek pogrešna jer pojednostavljuje
napetosti između svojstava [@brewer2012]. Particija nije svojstvo koje sistem bira ili odbacuje, već
događaj u mreži koji se dešava nezavisno od volje projektanta, pa se izbor svodi na C ili A, i to
samo dok particija traje. Dok mreža radi, CAP ne zabranjuje da sistem bude istovremeno strogo
konzistentan i dostupan. Iz istog razloga konačna konzistentnost ne krši teoremu: sistem koji se
odrekne stroge konzistentnosti time je tokom particije izabrao dostupnost. Najzad, sistem koji bira C
ne gubi dostupnost stalno, već samo tokom particije, i to samo na strani koja ne može da utvrdi da je
ažurna. Posebno treba razlikovati C iz CAP-a od konzistentnosti iz svojstava ACID. Konzistentnost
transakcije znači da ona čuva pravila baze, poput jedinstvenosti ključeva, dok C iz CAP-a označava
samo konzistentnost jedinstvene kopije, koju Brewer opisuje kao strogi podskup ACID konzistentnosti
[@brewer2012].

Ako CAP bez particije ništa ne zabranjuje, to ne znači da je stroga konzistentnost tada besplatna.
Čvor koji pre potvrde klijentu hoće da zna da upis postoji i na drugom čvoru mora da sačeka povratnu
poruku. Dok mreža radi, ta poruka sigurno stiže, samo kasnije, pa se ne gubi dostupnost, već se plaća
latencijom (latency), odnosno vremenom odziva. Abadi je ovu razliku formulisao kao proširenje teoreme
CAP, koje se može svesti na dva pitanja postavljena svakom sistemu. Prvo pitanje glasi: kada mreža
pukne, da li odsečeni čvor odgovara, rizikujući zastareo odgovor, ili odbija zahtev, čuvajući
konzistentnost? To pitanje je CAP. Drugo pitanje glasi: kada mreža radi, da li komitovanje čeka
druge čvorove, sporije ali konzistentno, ili ne čeka, brže ali uz rizik zastarelog čitanja? Abadi
naglašava da je ovaj drugi kompromis prisutan u svakom trenutku rada sistema, dok je CAP relevantan
samo u, kako navodi, verovatno retkom slučaju particije mreže [@abadi2012]. Skraćenica PACELC samo
beleži oba odgovora: ako postoji particija (P), bira se između dostupnosti (A) i konzistentnosti (C),
inače (E, else) između latencije (L) i konzistentnosti (C) [@abadi2012]. Po ovoj podeli Abadi
sisteme Dynamo, Cassandra i Riak u podrazumevanoj konfiguraciji svrstava u PA/EL, a sisteme
VoltDB/H-Store i Megastore u PC/EC [@abadi2012]. Za ovaj rad je presudno drugo pitanje: svako
podešavanje oblika „sačekaj X pre potvrde“ koje se razmatra u narednim poglavljima predstavlja
odgovor upravo na njega.

## Modeli replikacije

Prvo projektantsko pitanje kod replikacije jeste koliko čvorova sme da primi upis. Kleppmann
razlikuje tri odgovora, koja zajedno pokrivaju gotovo sve distribuirane baze podataka:
single-leader, multi-leader i leaderless replikaciju [@kleppmann2017]. Ovo poglavlje za uloge
čvorova koristi termine iz literature, *leader* i *follower*; od trećeg poglavlja, kada predmet
postane MySQL, prelazi se na nazive *izvor* i *replika*. Slika 2.1 prikazuje sva tri modela istim
vizuelnim jezikom. Kod single-leader replikacije upise prima tačno jedan čvor, a followeri primenjuju
njegov log, pa postoji jedan redosled upisa i nema sukoba; otvoreno ostaje pitanje šta se dešava
kada leader padne. Kod multi-leader replikacije upise nezavisno prima više čvorova, pa dva
istovremena upisa u isti podatak čine sukob, koji neko mora da razreši [@kleppmann2017]. Kod
leaderless replikacije, čiji je uzor Amazonov sistem Dynamo, klijent šalje upis direktno na više
replika i smatra ga uspešnim kada potvrdu pošalje njih W od ukupno N, dok čitanje pita R replika;
nijedan čvor ne određuje redosled upisa [@decandia2007].

![Slika 2.1: Tri modela replikacije razlikuju se samo po tome koji čvorovi primaju upise klijenata. Puna strelica označava upis klijenta, isprekidana prenos loga između čvorova.](figures/02-teorija-01-modeli-replikacije.png){width=100%}

<!--
  Absence claim (../../NOTES.md rule 1), checked 2026-10-07, recorded in
  .scratch/replikacija/measurements/0003-theory-framework.md:
  rung 1, refman 8.4 ch. 19-20: async, semisync, delayed, Group Replication single/multi-primary,
  all leader- or group-ordered; rung 2, MySQL Shell 8.4 (InnoDB Cluster, ReplicaSet, ClusterSet):
  all built on Group Replication or single-source async. NDB Cluster out of scope, not asserted.
  Wording kept narrow on purpose: "dokumentuje", "Community", "u stilu sistema Dynamo".
-->
Nijedan oblik replikacije koji dokumentuje MySQL 8.4 Community nije leaderless u stilu sistema Dynamo:
svaki se oslanja ili na jedan čvor koji prima upise ili na grupu čvorova koja se dogovara o
redosledu upisa [@mysql84refman; @mysqlshell84].

## Konsenzus

Single-leader replikacija mora da reši problem pada leadera, jer neki follower tada mora da preuzme
njegovu ulogu. Pošto čvor ne može da razlikuje leadera koji je pao od leadera koji je samo odsečen,
follower koji samostalno zaključi da je postao leader rizikuje da u sistemu istovremeno postoje dva
leadera koji primaju upise, odnosno split brain (razdvajanje grupe na dve nezavisne celine). Čvorovi
zato moraju da se slože oko toga ko je leader i šta se nalazi u logu, i to tako da se dve nezavisne
grupe čvorova ne mogu složiti različito; taj problem naziva se konsenzus. Klasično rešenje je
Lamportov algoritam Paxos [@lamport2001], a algoritam Raft, projektovan sa ciljem da bude
razumljiviji, deli konsenzus na tri potproblema: izbor leadera kada postojeći padne, replikaciju
loga sa leadera na ostale čvorove i bezbednost, odnosno garanciju da nijedan čvor ne primeni za isti
indeks loga drugu komandu od one koju je neki čvor već primenio [@ongaro2014].

Sva tri dela oslanjaju se na jednu činjenicu: svake dve većine istog skupa od N čvorova imaju bar
jedan zajednički čvor, jer zbir veličina dva skupa veća od N/2 premašuje N. Pri izboru leadera svaki
čvor u jednom mandatu (term) daje najviše jedan glas, a pobeđuje kandidat koji dobije većinu; dve
većine dele bar jednog glasača, pa u istom mandatu ne mogu postojati dva leadera [@ongaro2014]. Ulaz u
logu smatra se komitovanim kada ga sačuva većina čvorova, pa pad manjine ne zaustavlja sistem
[@ongaro2014]. Bezbednost obezbeđuje ograničenje pri izboru: čvor ne glasa za kandidata čiji je log
manje ažuran od njegovog, a pošto se većina glasača seče sa većinom koja čuva svaki komitovani ulaz,
novi leader neizbežno poseduje sve komitovane ulaze [@ongaro2014]. Protokol pritom nijednom ne
proverava da li je stari leader zaista pao, jer je to, kao što je pokazano, nemoguće znati, već se
oslanja isključivo na presek većina. Isti princip koristi MySQL Group Replication: prema priručniku,
da bi transakcija bila komitovana, većina grupe mora da se složi o njenom mestu u globalnom
redosledu transakcija, a u osnovi te tehnologije nalazi se implementacija algoritma Paxos
[@mysql84refman]. Tim mehanizmom bavi se peto poglavlje.

## Dva značenja kvoruma

Reč kvorum u literaturi označava dve različite stvari, a razliku je lako prevideti jer se obe
oslanjaju na istu aritmetiku preseka. Kod Dynamo-kvoruma uslov W + R > N obezbeđuje da se skup
replika koje su potvrdile upis i skup replika koje se čitaju seku, pa čitanje dodiruje bar jednu
repliku sa najnovijom verzijom [@decandia2007]. Presek, međutim, ne određuje redosled. Neka je
N = 3, W = 2 i R = 2, i neka dva klijenta istovremeno upišu različite vrednosti istog podatka: prvi
vrednost 100 na replike 1 i 2, a drugi vrednost 200 na replike 2 i 3, pri čemu na repliku 2 drugi
upis stigne pre prvog. Oba upisa dobijaju po dve potvrde, pa oba klijenta dobijaju potvrdu uspeha, a
replike završavaju sa vrednostima 100, 100 i 200. Čitanje sa replika 2 i 3 vraća obe vrednosti:
presek je ispunio svoje obećanje, ali nijedan čvor nikada nije odlučio koji je upis bio prvi, pa
Dynamo čuva obe verzije i njihovo spajanje prepušta aplikaciji [@decandia2007]. Abadi zato naglašava
da sistemi ovog tipa povećanjem R + W dobijaju više konzistentnosti po cenu latencije, ali ne mogu da
dostignu punu konzistentnost u smislu Gilberta i Lynch ni kada je R + W > N [@abadi2012]. Dynamo uz to
koristi i takozvani sloppy quorum, koji pri nedostupnosti replika upis smešta na prvih N ispravnih
čvorova, pa ni sam presek više nije zagarantovan [@decandia2007].

Konsenzus-kvorum koristi isti presek u drugu svrhu: većina koja je komitovala ulaz seče se sa svakom
sledećom većinom, pa se sistem većinom dogovara o mestu svakog upisa u jedinstvenom redosledu, a dva
istovremena upisa dobijaju dva različita mesta u logu umesto dve verzije istog podatka
[@ongaro2014]. Razlika se može sažeti u jednu rečenicu: oba sistema se oslanjaju na presek skupova
čvorova, ali se konsenzus većinom dogovara o redosledu transakcija, dok Dynamo-kvorum samo
obezbeđuje da čitanje dodirne svežu repliku. Kada se u ovom radu govori o sistemima zasnovanim na
kvorumu, misli se na konsenzus-kvorum, jer na njemu počiva Group Replication, dok Dynamo-kvorum služi
samo kao kontrast. Ovim je zaokružen rečnik kojim se u narednim poglavljima opisuje MySQL: svaki
njegov mehanizam replikacije biće smešten u jedan od tri modela, opisan modelom konzistentnosti koji
obezbeđuje i ocenjen prema tome kako odgovara na dva pitanja PACELC-a.
