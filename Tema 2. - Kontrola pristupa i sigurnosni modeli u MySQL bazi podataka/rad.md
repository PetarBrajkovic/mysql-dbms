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
