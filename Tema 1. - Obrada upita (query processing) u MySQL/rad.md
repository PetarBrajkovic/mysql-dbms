---
title: "Obrada upita (Query Processing) u MySQL-u"
author: "Petar Brajković"
bibliography: references.bib
csl: ieee.csl
---

# 1. Uvod

Relacione baze podataka nude korisniku deklarativan jezik: SQL upitom opisuje se *šta* se traži
kao rezultat, ali ne i *kako* se do tog rezultata dolazi. Sistem za upravljanje bazom podataka
(SUBP), s druge strane, ume da izvrši isključivo konkretne fizičke procedure — čitanje i upisivanje
stranica na disku, prolazak kroz B+ stablo, sken tabele nad neuređenim fajlom. Obrada upita (query
processing) obuhvata sve što SUBP radi da bi premostio taj jaz između deklarativnog opisa i fizičkog
izvršenja; upravo je teret efikasnog odgovaranja na upite time prebačen sa korisnika na sistem
[@stoimenov_optimizacija; @stoimenov_evaluacija].

Jaz se premošćuje optimizacijom na dva nivoa jednog istog problema [@stoimenov_optimizacija]. Na
višem, logičkom nivou, polazni izraz relacione algebre preformuliše se u ekvivalentan izraz koji se
brže izvršava: spuštanjem selekcija naniže, izmenom redosleda spoja ili sažimanjem operacija menja se
*oblik* izračunavanja, ali nikada sam rezultat. Na nižem, fizičkom nivou, za svaki operator bira se
konkretan algoritam i pristupni put — sken tabele naspram skena preko indeksa, odnosno spoj sa
ugnježdenom petljom, Sort-Merge spoj ili Hash spoj. Pošto ne postoji univerzalno superiorna tehnika,
najpovoljniji izbor zavisi od svojstava samih podataka [@stoimenov_evaluacija]. Oba nivoa vođena su
istim merilom — cenom, procenom količine posla, pre svega ulazno-izlaznih operacija — i taj
zajednički cilj čini ih dvama nivoima jednog problema, a ne dvama odvojenim problemima
[@stoimenov_optimizacija; @ramakrishnan2003].

Kombinovanjem logičkih i fizičkih izbora jedan nepromenjen SQL upit grana se na više planova
izvršenja koji vraćaju identičan rezultat, ali čija se cena razlikuje za nekoliko redova veličine:
selektivan indeks dodirne šačicu stranica, dok sken cele tabele pročita milione redova. Zadatak
SUBP-a jeste da među tim ekvivalentnim planovima pronađe i izabere najefikasniji
[@stoimenov_optimizacija]. MySQL taj izbor poverava optimizatoru upita zasnovanom na ceni
(cost-based optimizer), koji procenjuje cenu razmatranih planova i zadržava najjeftiniji
[@mysql84refman].

![Slika 1.1: Jedan SQL upit, dva ekvivalentna plana izvršenja različite cene. Slobodan izbor
optimizatora (A) koristi indeks `idx_country_code` (procenjena cena ≈ 499373), dok zabranjivanje tog
indeksa (B) daje skuplji sken cele tabele (procenjena cena ≈ 575645); oba plana vraćaju isti rezultat
od približno 3,5 miliona torki.](figures/01-uvod-01-jedan-upit-dva-plana.png)

Slika 1.1 prikazuje ovu pojavu na konkretnom upitu nad sintetičkom tabelom `wide_events`. Isti upit
`SELECT notes FROM wide_events WHERE country_code = 'US'` MySQL izvršava skenom preko indeksa
`idx_country_code`, dok se zabranjivanjem tog indeksa dobija sken cele tabele — skuplji plan koji
vraća isti skup od približno 3,5 miliona torki. Iako oba plana daju istovetan rezultat, optimizator
zadržava jeftiniju varijantu; upravo je ta logika izbora predmet poglavlja koja slede.

Ostatak rada prati istu nit — put od deklarativnog SQL upita do njegovog fizičkog izvršenja u
MySQL-u:

- U poglavlju 2 opisuje se **arhitektura obrade upita u MySQL-u**: komponente koje premošćuju jaz
  (parser, optimizator, izvršni mehanizam i katalog) i način na koji ih MySQL povezuje.
- U poglavlju 3 dva nivoa optimizacije prikazuju se opipljivo — kao **put od SQL-a do plana
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
- Poglavlje 8 obrađuje **keširanje i ponovnu upotrebu planova** — pitanje može li se izabrani plan
  ponovo iskoristiti umesto da se računa iznova i šta MySQL zapravo kešira (keš plana, plan cache).
- Poglavlje 9 donosi **zaključak**, provlačeći nit do kraja, od deklarativnog SQL-a nazad do
  fizičkog izvršenja.

# 2. Arhitektura obrade upita u MySQL-u

# 3. Od SQL-a do plana izvršavanja

# 4. EXPLAIN i EXPLAIN ANALYZE

# 5. Iterator model i pipeline operatora

# 6. Vektorizovano izvršavanje

# 7. Paralelno izvršavanje upita

# 8. Keširanje i ponovna upotreba planova

# 9. Zaključak

# Reference
