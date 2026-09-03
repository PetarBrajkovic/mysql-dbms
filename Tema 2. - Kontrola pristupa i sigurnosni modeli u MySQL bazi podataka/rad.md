---
title: "Kontrola pristupa i sigurnosni modeli u MySQL bazi podataka"
author: "Petar Brajković"
bibliography: references.bib
csl: ../ieee.csl
---

<!--
  The body of the paper. One chapter appended per session, by the academic-research-writer
  skill under the rules in ../WRITING.md. Never hand-written and tidied afterwards.

  Do NOT set `lang: sr` here - it forces the IEEE reference list into Cyrillic.
  The title page is a separate file (naslovna.md) and is prepended by ../tools/make-docx.ps1.
-->

# 1. Uvod

Kontrola pristupa predstavlja jedan od centralnih bezbednosnih mehanizama svakog sistema za
upravljanje bazama podataka: dok autentifikacija (provera identiteta) utvrđuje ko se povezuje na
sistem, kontrola pristupa (autorizacija) određuje koje operacije taj subjekat sme da izvrši nad kojim
objektom, i time neposredno štiti tajnost i integritet podataka [@ramakrishnan2003]. Razlika između
politike pristupa, kao pravila o tome ko sme šta da radi, i mehanizma sigurnosti, kao tehničkog
sredstva kojim se to pravilo sprovodi, jeste polazna tačka svakog ozbiljnog razmatranja bezbednosti
baza podataka: isti mehanizam može sprovoditi različite politike, a promena politike ne zahteva
nužno promenu mehanizma [@ramakrishnan2003]. Klasična teorija razlikuje diskrecionu kontrolu
pristupa (DAC), u kojoj vlasnik objekta samostalno odlučuje kome dodeljuje prava, od obavezne
kontrole pristupa (MAC), u kojoj centralni autoritet nameće sigurnosne klase koje korisnik ne može
da zaobiđe niti da prenese drugom korisniku [@ramakrishnan2003].

Ovaj rad razmatra kontrolu pristupa i sigurnosne modele u sistemu MySQL, čiji je sistem
privilegija u potpunosti diskrecion i zasnovan na objektima: svako pravo pristupa dodeljuje se
eksplicitnom naredbom `GRANT` određenom korisničkom nalogu nad određenim objektom, ne postoji
mehanizam eksplicitnog uskraćivanja prava, a odsustvo dodeljenog prava jedini je oblik zabrane koji
sistem poznaje [@mysql84refman]. Osnovna teza rada glasi da je MySQL isključivo DAC sistem i da se
svaki savremeniji zahtev sa profesorove liste tema, kontrola pristupa zasnovana na ulogama u punom
smislu, bezbednost na nivou reda (RLS) i izolacija u multi-tenant okruženjima, ili sastavlja iz te
diskrecione osnove kombinovanjem privilegija, pogleda i definer/invoker semantike, ili je u MySQL-u
u potpunosti odsutan i mora se rešavati izvan same baze podataka, na nivou aplikacije.

Rad je organizovan tako da svako naredno poglavlje proverava jednu stranu te teze. Drugo poglavlje
izlaže klasične modele kontrole pristupa (DAC i MAC), Bell-LaPadula model i argument o trojanskom
konju koji motiviše prelazak sa DAC na MAC, i time postavlja teorijski okvir prema kome se MySQL
kasnije ocenjuje. Treće poglavlje opisuje sistem privilegija i uloga u MySQL-u: tabele dodele prava,
dvostepenu proveru pristupa, statičke i dinamičke privilegije, i pokazuje u kojoj meri MySQL-ove
uloge odgovaraju modelu kontrole pristupa zasnovanom na ulogama (RBAC) kako ga definišu Sandhu i
saradnici [@sandhu1996]. Četvrto poglavlje razmatra fino-granularnu kontrolu pristupa na nivou
kolona i pogleda, kao i tehnike kojima se u MySQL-u emulira bezbednost na nivou reda, budući da
izvorna podrška za nju ne postoji. Peto poglavlje analizira sprovođenje bezbednosnih politika,
autentifikaciju, lozinke, naloge i mrežne veze, i pokazuje gde tačno u sistemu leži tačka
sprovođenja svake pojedinačne politike. Šesto poglavlje ispituje mogućnosti evidentiranja pristupa
(audit logging) dostupne bez komercijalne licence. Sedmo poglavlje objedinjuje prethodna poglavlja
kroz projektovanje bezbednosti u multi-tenant okruženjima, gde se princip najmanjih privilegija
javlja kao nit koja povezuje čitav rad. Osmo poglavlje sumira nalaze i zaokružuje odgovor na tezu
postavljenu u ovom uvodu.

# 2. Klasični modeli kontrole pristupa

Svaki zahtev za pristup podacima može se opisati trojkom (subjekat, objekat, operacija): subjekat je
korisnik ili aplikacija koja pokreće zahtev, objekat je resurs nad kojim se zahtev izvršava (tabela,
pogled, kolona), a operacija je radnja koja se nad objektom traži (čitanje, upisivanje, brisanje)
[@ramakrishnan2003]. Nad tom trojkom sistem primenjuje politiku pristupa, skup pravila koja određuju
koje trojke su dozvoljene, posredstvom mehanizma sigurnosti, tehničkog sredstva koje tu politiku
sprovodi u svakom pojedinačnom zahtevu; razdvajanje politike od mehanizma omogućava da se ista
implementacija koristi za različita pravila, bez izmene same baze podataka [@ramakrishnan2003]. Ova
trojka je istovremeno i granica klasičnih modela: nijedan od njih ne ume da izrazi pravilo koje zavisi
od same vrednosti podatka (na primer, „dozvoli izmenu samo ako je status različit od 'otkazan'"), jer
vrednost nije deo trojke (subjekat, objekat, operacija) [@ramakrishnan2003]. Ovo ograničenje se
ponovo javlja u četvrtom poglavlju, kada se pokaže da MySQL nema izvornu podršku za bezbednost na
nivou reda upravo zato što grant sistem odlučuje na nivou objekta, ne na nivou vrednosti.

Diskreciona kontrola pristupa (DAC) rešava pitanje ko odlučuje o pristupu na jedan konkretan način:
odluku donosi vlasnik objekta. Kada subjekat kreira objekat, on nad njim automatski dobija sva prava,
uključujući i pravo da ta prava dodeli drugim subjektima; ako je dodela praćena eksplicitnom opcijom
prenosa prava, primalac može dalje dodeljivati isto pravo trećim subjektima, čime nastaje lanac
delegacije čiji je koren uvek vlasnik [@ramakrishnan2003]. Standard SQL propisuje da se takav lanac
ponaša simetrično i pri oduzimanju: kaskadno oduzimanje prava povlači za sobom oduzimanje svih prava
koja su na osnovu njega dalje dodeljena, tako da uklanjanje korena lanca uklanja i sve njegove grane
[@ramakrishnan2003]. Ovde vredi primetiti da opcija prenosa prava nije proizvoljna velikodušnost
sistema prema vlasniku, već nužna posledica same definicije DAC-a: kada bi sistem zabranio vlasniku
da dalje delegira sopstveno pravo, ta zabrana bi sama predstavljala pravilo koje vlasnik ne bi mogao
da zaobiđe, odnosno klicu obavezne kontrole pristupa unutar modela koji je po definiciji diskrecion.

MySQL sledi upravo ovaj obrazac dodele, ali se namerno udaljava od standarda u pitanju oduzimanja:
prema sopstvenom priručniku, oduzimanje privilegije u MySQL-u ne povlači automatski oduzimanje
privilegija koje su na osnovu nje dodeljene drugim korisnicima [@mysql84refman]. To odsustvo kaskade
nije posledica nedostatka podataka o poreklu dodele: MySQL u tabeli `mysql.tables_priv` čuva kolonu
`Grantor`, koju priručnik opisuje kao vrednost koja se postavlja pri dodeli, ali se „inače ne
koristi" [@mysql84refman], što odsustvo kaskadnog oduzimanja čini svesnom projektantskom odlukom, a
ne tehničkim ograničenjem. Ista provera pokazuje i da opcija prenosa prava nadživljava oduzimanje
privilegije na koju se odnosi: nalog kome je oduzeto pravo čitanja i dalje zadržava mogućnost da to
pravo, ako mu bude ponovo dodeljeno, prenosi na druge naloge, sve dok mu se izričito ne oduzme i sama
opcija prenosa [@mysql84refman]. Oba nalaza pokazuju da DAC, kao teorijski model, ne propisuje samo
pravac oduzimanja prava, već da svaka implementacija bira sopstveno tumačenje te tačke modela, što
treće poglavlje razmatra u celini na primeru MySQL-ovog sistema privilegija.

Granica same DAC diskrecije najbolje se vidi kroz argument poznat kao trojanski konj. Subjekat sa
legitimnim pravom čitanja poverljivog objekta može pokrenuti program koji, uz njegovu privilegiju,
pročita sadržaj tog objekta i tajno ga upiše u drugi objekat nad kojim pravo pisanja ima napadač, iako
napadač nikada nije dobio pravo čitanja izvornog objekta; DAC ovaj tok informacija ne sprečava jer se
provera prava vršila u trenutku pristupa legitimnog subjekta, a ne u trenutku kada je informacija
napustila objekat u koji je upisana [@ramakrishnan2003]. Pošto DAC kontroliše ko sme da pristupi
objektu, a ne kuda dalje putuje informacija koja iz njega izađe, ovaj propust nije greška u
implementaciji nego posledica same definicije modela, i predstavlja motivaciju za uvođenje modela
koji nadzire tok informacija nezavisno od volje vlasnika.

Obavezna kontrola pristupa (MAC) tu prazninu popunjava tako što odluku o pristupu prepušta
centralnom autoritetu, a ne vlasniku objekta: svakom subjektu se dodeljuje dozvola (klasa sigurnosti),
a svakom objektu klasa sigurnosti, i nijedan subjekat, uključujući vlasnika, ne može tu klasifikaciju
sam da promeni niti dodeljeno pravo da prenese na drugog subjekta [@ramakrishnan2003]. Najpoznatiji
formalni model MAC-a, Bell-LaPadula, propisuje dva pravila nad uređenim skupom klasa sigurnosti
[@bell1973]. Simple Security Property (pravilo „bez čitanja naviše") dozvoljava subjektu S da čita
objekat O samo ako je klasa(S) ≥ klasa(O), čime se sprečava da subjekat niže dozvole pročita podatak
više poverljivosti. *-Property (pravilo „bez upisa naniže") dozvoljava subjektu S da upisuje u objekat
O samo ako je klasa(S) ≤ klasa(O), čime se sprečava da subjekat koji je pročitao poverljiv podatak taj
podatak dalje prenese upisom u objekat niže klase, i time zatvara upravo onaj tok informacija koji
trojanski konj koristi protiv DAC-a [@bell1973]. Slika 2.1 prikazuje oba pravila za subjekta na
srednjem nivou poverljivosti: čitanje je dozvoljeno samo naniže ili u istom nivou, upis samo naviše
ili u istom nivou, tako da informacija u sistemu sme da teče isključivo naviše.

![Slika 2.1: Bell-LaPadula - informacija sme da teče samo naviše](figures/02-klasicni-modeli-01-bell-lapadula.png){width=70%}

Vredi naglasiti da su oba Bell-LaPadula pravila usmerena na zaštitu tajnosti, ne integriteta:
subjekat niže dozvole nikada ne sme da pročita poverljiviji podatak, ali mu ništa ne brani da upiše u
objekat više klase, takozvani „slepi upis", čime se poverljivi podatak može oštetiti a da ga napadač
nikada nije video; zaštita integriteta u prisustvu MAC-a zahteva poseban, dualan model (Biba), koji
pravila čitanja i upisa okreće u suprotnom smeru [@ramakrishnan2003]. Zbog stroge, sistemski nametnute
klasifikacije i nemogućnosti da je bilo koji korisnik zaobiđe, MAC u praksi znatno otežava svakodnevni
rad, uključujući situacije u kojima nijedan subjekat ne poseduje dovoljno visoku dozvolu za rutinski
zadatak, zbog čega se u komercijalnim sistemima retko sreće i preživljava uglavnom u specijalizovanim,
vojnim primenama [@ramakrishnan2003].

Blisko srodan problem, koji klasična trojka (subjekat, objekat, operacija) takođe ne rešava, jeste
problem statističke baze podataka: sistem koji dozvoljava samo agregirane upite (na primer, prosek ili
broj zapisa koji zadovoljavaju uslov) može otkriti pojedinačnu, poverljivu vrednost ako se napadaču
dozvoli da postavi niz pažljivo odabranih agregiranih upita, na primer tako što uporedi broj zaposlenih
starijih od X godina sa brojem starijih od X+1 godina i iz razlike izvede podatak o tačno jednoj osobi
[@ramakrishnan2003]. Ni DAC ni MAC ovaj problem ne rešavaju, jer oba modela odlučuju o pristupu samom
objektu, a ne o tome šta se iz niza dozvoljenih upita može zaključiti; problem ostaje otvoren i u
savremenim sistemima poput MySQL-a, koji nemaju poseban mehanizam za njegovo sprečavanje.

Kontrola pristupa zasnovana na ulogama (RBAC) uvodi osu koja je nezavisna od para DAC/MAC: umesto da
se pravo dodeljuje direktno subjektu ili da o njemu odlučuje centralni autoritet preko klase
sigurnosti, pravo se dodeljuje ulozi, imenovanom skupu privilegija koji odgovara funkciji u
organizaciji, a subjektu se dodeljuje uloga [@sandhu1996]. Sandhu i saradnici formalizuju RBAC kroz
niz od četiri modela rastuće izražajnosti: RBAC0, osnovni model dodele uloga i privilegija; RBAC1, koji
dodaje hijerarhiju uloga u kojoj viša uloga nasleđuje privilegije nižih; RBAC2, koji dodaje ograničenja
poput razdvajanja dužnosti, pravila da isti subjekat ne sme istovremeno da drži dve međusobno
sukobljene uloge; i RBAC3, koji objedinjuje hijerarhiju i ograničenja [@sandhu1996]. Nezavisno od
Sandhua i saradnika, Ferraiolo i Kuhn dolaze do istog zaključka analizom komercijalnih sistema:
privilegije organizovane oko uloga bolje prate stvarnu strukturu ovlašćenja u jednoj organizaciji nego
privilegije dodeljene pojedinačnim korisnicima, i lakše se održavaju kada zaposleni menja posao ili
napušta organizaciju [@ferraiolokuhn1992]. Ova dva nezavisna izvora kasnije su objedinjena u formalni
standard ANSI/INCITS 359-2004, koji RBAC definiše kroz sesiju u kojoj subjekat aktivira podskup uloga
koje mu je administrator dodelio, tako da su u svakom trenutku na snazi samo privilegije aktivnih
uloga, ne sve privilegije koje subjekat uopšte poseduje [@incits2004]. Upravo ta razlika, između svih
dodeljenih uloga i uloga aktivnih u tekućoj sesiji, jeste tačka na kojoj treće poglavlje proverava da
li MySQL-ove uloge zaista predstavljaju RBAC u ovom, formalnom smislu.

Kroz sve prethodno izložene modele provlači se jedan zajednički zahtev, koji Saltzer i Šreder
formulišu kao princip najmanjih privilegija: „svaki program i svaki korisnik sistema treba da radi
koristeći najmanji skup privilegija neophodan za obavljanje posla" [@saltzerschroeder1975]. Ovaj
princip ne propisuje novi mehanizam kontrole pristupa, već kriterijum za ispravnu upotrebu bilo kog od
prethodno opisanih modela: nalog kome je dovoljno pravo čitanja ne treba da poseduje i pravo
izmene, uloga zadužena za jedan zadatak ne treba da nosi privilegije potrebne za neki drugi. Isti rad
formuliše i princip „bezbednih podrazumevanih vrednosti": „odluke o pristupu treba zasnivati na
dozvoli, a ne na isključenju" [@saltzerschroeder1975], što je tačan opis grant-only modela kakav ima
MySQL, gde odsustvo eksplicitne dodele predstavlja jedini oblik zabrane koji sistem poznaje; ovim se
MySQL-ov projektantski izbor oslanja na princip star pola veka, a ne samo na priručnik proizvođača.
Princip najmanjih privilegija se u ovom radu ne obrađuje kao posebno poglavlje, već kao nit koja se
ponovo imenuje u svakom narednom poglavlju u kojem konkretna projektantska odluka, obim uloge u
trećem poglavlju ili šablon izolacije zakupaca u sedmom poglavlju, tu nit čini opipljivom.

Ovo poglavlje postavlja tezu koju svako naredno poglavlje proverava na jednom njenom delu: MySQL-ov
sistem privilegija je diskrecion u celini, bez ijednog elementa obavezne kontrole pristupa, dok se
savremeniji zahtevi, RBAC u formalnom smislu, bezbednost na nivou reda i izolacija u multi-tenant
okruženjima, moraju ili sastaviti od diskrecionih građevnih blokova opisanih u ovom poglavlju, ili
priznati kao potpuno odsutni iz same baze podataka.
