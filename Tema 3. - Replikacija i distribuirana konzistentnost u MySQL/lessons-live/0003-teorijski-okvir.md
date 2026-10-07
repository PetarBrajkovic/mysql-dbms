> [!quote] YOU
> > [!note] SKILL loaded: teach
>
> Lesson 1 of Tema 3, for the map ticket "Chapter 2 - Teorijski okvir: modeli konzistentnosti, CAP/PACELC i konsenzus" (.scratch/replikacija/issues/14-chapter-2-theory.md). This session teaches only;
>  the Serbian prose for rad.md is written in a separate later session.
>
>    Follow the reading protocol in ../TEACHING.md exactly: MISSION.md, ../TEACHING.md, NOTES.md, learning-records/README.md (index only), GLOSSARY.md term tables plus §2a (Ch. 2) and §3 (theory budget), and
>  ../assets/LESSON-TEMPLATE.html. Also read ticket 14 itself. For sources, read .scratch/replikacija/research/07-theory-and-geo.md and 07b-bibliography-verified.md. They are the backing for this chapter, so
>  the usual .scratch exclusion is lifted for these two files only.
>
>    What the lesson must make me understand, in this order of dependency:
>    1. Consistency models: strong (linearizable), causal, eventual, plus read-your-writes and monotonic reads. These are the vocabulary every later chapter uses without redefining.
>    2. CAP as proved by Gilbert & Lynch, and why it is NOT "pick two". Cover memo 07's four standard misreadings.
>    3. PACELC, and why its else-branch (latency vs consistency with no partition) is what every MySQL knob trades.
>    4. Replication models: single-leader, multi-leader, leaderless. Use the English leader/follower vocabulary in this chapter (GLOSSARY §1d).
>    5. Consensus at conceptual depth only (leader election, log replication, quorum safety), no proofs.
>    6. The consensus-quorum vs Dynamo-quorum distinction, stated explicitly. The professor's bullet says "Quorum-Based sistemi", and I must not confuse the two at the defense.
>
>    I have probably forgotten much of the distributed-systems background, so the lesson may spend as long as it needs on theory (map rule: lessons and the paper have different theory budgets). Probe where my
>  knowledge edge is before teaching. Where it genuinely helps, tie a concept to the live sandbox (start it with examples\00-setup\topology.ps1 start; ports 3307/3308/3309; 3306 is off-limits), e.g. what a
>  "leader" and a "follower" are in our three nodes. This chapter has no MySQL feature content, so live demos are optional.
>
>    Binding rules: lesson HTML is in Serbian (Latin script), terms exactly as locked in GLOSSARY.md, no re-translation. Check every Serbian line with serbian-grammar; this topic is the highest-risk one for
>  Croatianisms. Use pdf-reader for any PDF. Apply the two research rules in ../../NOTES.md: no unverified absence claim, and walk the source ladder and record the rung.
>
>    When done: the lesson in lessons/, a short learning record 0003 plus a line in learning-records/README.md (and under "Standing constraints" if anything constrains later chapters), any measurements in
>  .scratch/replikacija/measurements/0003-<slug>.md. Then add a comment on ticket 14 saying the lesson half is done, leaving the ticket open for the writing session. Commit and push.

> [!question] Question
> Do you want this lesson mirrored live to an Obsidian note?
>
> 1. Yes, new file
> 2. Yes, existing file
> 3. No

> [!example] Answer
> 1. Yes, new file

> [!abstract] PI
> Created `lessons-live/0003-teorijski-okvir.md`. Paste this:
>
> ```
> /md-log C:/Faks/Sistemi Baza/Tema 3. - Replikacija i distribuirana konzistentnost u MySQL/lessons-live/0003-teorijski-okvir.md
> ```
>
> Tell me once it's linked, and I'll start probing where your distributed-systems knowledge is.

> [!quote] YOU
> Continue

> [!abstract] PI
> Linked. Phase 1 is a quick probe on each strand so I know where to start. Answer from memory, and pick "I don't know" whenever it's true. That helps more than a guess.

> [!question] Quiz
> Client A writes x=5 and gets "OK". After that, client B (on a different machine) reads x. Which consistency model guarantees that B sees 5?
>
> 1. Read-your-writes
> 2. Linearizability (strong consistency)
> 3. Causal consistency
> 4. Eventual consistency

> [!question] Quiz — I don't know
> Your answer: I don't know
> Correct answer: 2
>
> Note: I am not sure but I would guess 1.
>
> Only linearizability respects real time across all clients: once a write has completed, every later read by anyone must see it (or something newer). Causal consistency only orders operations that are causally related, and B never saw A's write, so the two are unrelated. Eventual consistency promises convergence only "eventually". Read-your-writes is a per-session guarantee: it protects A's own reads, not B's.

> [!question] Quiz
> An app writes a profile update to the leader, then immediately reloads the page, and that read goes to a lagging follower. The user sees the old profile. Which guarantee was violated?
>
> 1. Causal consistency between two clients
> 2. Eventual consistency
> 3. Monotonic reads
> 4. Read-your-writes

> [!question] Quiz — I don't know
> Your answer: I don't know
> Correct answer: 4
>
> The same session wrote a value and then failed to see its own write. That is read-your-writes (Terry et al. 1994). Eventual consistency is not violated, because the follower will catch up. Monotonic reads is about never moving backwards relative to something you already read; here you never read the new value, you only wrote it.

> [!question] Quiz
> What does the CAP theorem actually say?
>
> 1. Every distributed system must permanently give up one of C, A and P
> 2. Consistency always costs latency, even when the network is healthy
> 3. A system can have all three properties if it uses a majority quorum
> 4. If the network partitions, a node must choose between staying consistent and answering

> [!failure] Quiz — incorrect ✗
> Your answer: 1. Every distributed system must permanently give up one of C, A and P
> Correct answer: 4
>
> Gilbert & Lynch proved that in an asynchronous network that can lose messages, no read/write object can be both atomically consistent (linearizable) and available in every execution. The choice only bites when a partition actually happens. "Pick two, forever" is the classic misreading. The statement about latency on a healthy network is PACELC's else-branch, not CAP.

> [!abstract] PI
> That's the "pick two" misreading, and it's exactly what this lesson has to dislodge. One more question on CAP:

> [!question] Quiz
> Is the "C" in CAP the same thing as the "C" in ACID?
>
> 1. Yes: both mean a transaction is all-or-nothing
> 2. Yes: both mean the database respects its integrity constraints
> 3. No: CAP's C means every read sees the latest write, as with one copy
> 4. No: CAP's C means all replicas eventually hold the same data

> [!success] Quiz — correct ✓
> Your answer: 3. No: CAP's C means every read sees the latest write, as with one copy
> Correct answer: 3
>
> Gilbert & Lynch define CAP's C as atomic (linearizable) consistency: the system behaves as though there were a single copy, and reads see the latest completed write. ACID's C means that a transaction moves the database between states that satisfy its integrity constraints. Same letter, unrelated concepts. "Eventually the same" is eventual consistency, which is exactly what CAP's C is NOT.

> [!question] Quiz
> With no network partition at all, what is the main thing a replicated database trades when it makes a commit wait for a follower's acknowledgement?
>
> 1. It trades higher write latency for stronger consistency
> 2. It trades nothing, since without a partition CAP permits everything
> 3. It trades partition tolerance for stronger consistency
> 4. It trades lower availability for stronger consistency

> [!question] Quiz — I don't know
> Your answer: I don't know
> Correct answer: 1
>
> Note: I am not sure, can we do this session in Serbian
>
> That is PACELC's Else-branch (Abadi 2012): even when the network is healthy, waiting for other replicas costs a network round-trip on every write, so you pay latency to get consistency. You measured exactly this with semisync: 61 → 124 µs with fsync turned off. Availability is not at stake when there is no partition. "Nothing" is correct about CAP but wrong about the system, and that gap is precisely what PACELC fills.

> [!question] Quiz
> Po čemu se multi-leader replikacija suštinski razlikuje od single-leader replikacije?
>
> 1. Upise prima više čvorova, pa dva upisa u isti red mogu da se sukobe
> 2. Upise prima više čvorova, ali konsenzus unapred sprečava svaki sukob
> 3. Čita se sa više čvorova, pa čitanje sa followera može da bude zastarelo
> 4. Upise prima jedan čvor, ali ih šalje većem broju followera odjednom

> [!question] Quiz — I don't know
> Your answer: I don't know
> Correct answer: 1
>
> Single-leader: upise prima tačno jedan čvor, pa postoji jedan redosled upisa i sukobi su nemogući. Multi-leader: upise prima više čvorova nezavisno, pa dva upisa u isti podatak mogu da stignu u različitom redosledu i nastaje sukob koji neko mora da razreši. Zastarela čitanja sa followera postoje već u single-leader modelu, pa to nije razlika. Konsenzus ne „sprečava sve sukobe“ u multi-leaderu; u MySQL multi-primary režimu certification ih otkriva, a gubitnik se poništava.

> [!question] Quiz
> Grupa ima 5 čvorova i mreža je pukla na dva dela: 3 čvora sa jedne strane, 2 sa druge. Pravilo je „upis prolazi samo uz većinu“. Šta se dešava?
>
> 1. Strana sa 2 čvora nastavlja upise, jer ima manje čvorova za usaglašavanje
> 2. Obe strane nastavljaju upise, a razlike se spajaju kad se mreža oporavi
> 3. Obe strane blokiraju upise dok se mreža ne oporavi u potpunosti
> 4. Strana sa 3 čvora nastavlja upise, strana sa 2 čvora blokira upise

> [!success] Quiz — correct ✓
> Your answer: 4. Strana sa 3 čvora nastavlja upise, strana sa 2 čvora blokira upise
> Correct answer: 4
>
> Većina od 5 je 3. Samo jedna strana može da ima 3 čvora, jer dve disjunktne grupe ne mogu obe da imaju više od polovine. Zato upise nastavlja tačno jedna strana i ne nastaje split brain. Manjina blokira upise, tačno kao kod tebe na tiketu 11: kad si ubio dva od tri čvora, upis na preživelom čvoru je i posle 30 s bio blokiran.

> [!question] Quiz
> Zašto je baš većina (više od polovine) prag, a ne, recimo, trećina čvorova?
>
> 1. Većina je najmanji broj čvorova koji i dalje daje prihvatljivo kašnjenje upisa
> 2. Svake dve većine imaju bar jedan zajednički čvor, pa jedna zna za odluku druge
> 3. Većina garantuje da je bar jedan čvor zaista upisao podatak na disk
> 4. Većina garantuje da svaki čvor u grupi vidi sve upise istim redosledom

> [!success] Quiz — correct ✓
> Your answer: 2. Svake dve većine imaju bar jedan zajednički čvor, pa jedna zna za odluku druge
> Correct answer: 2
>
> Ključno svojstvo je presek. Ako su A i B dve većine od N čvorova, onda je |A|+|B| > N, pa A i B moraju da dele bar jedan čvor. Taj zajednički čvor „pamti“ odluku prve većine i prenosi je drugoj. Sa trećinom bi postojale dve disjunktne grupe koje odlučuju nezavisno, a to je split brain. Za postojanost je dovoljan i jedan čvor, pa većina nije potrebna zbog diska. Isti redosled za sve je posledica celog protokola (konsenzusa), a ne samog praga.

> [!abstract] PI
> Presek dve većine ti je jasan. Sad isti princip u drugoj formi:

> [!question] Quiz
> Leaderless sistem (Dynamo stil): N=3 replike, upis se smatra uspešnim kad ga potvrdi W replika, a čitanje pita R replika. Koji uslov garantuje da čitanje dobije bar jednu repliku koja ima poslednji uspešan upis?
>
> 1. R > N / 2
> 2. W > N / 2
> 3. W + R > N
> 4. W = R

> [!success] Quiz — correct ✓
> Your answer: 3. W + R > N
> Correct answer: 3
>
> Isti argument preseka: skup od W replika koje su potvrdile upis i skup od R replika koje čitanje pita moraju da se preseku ako je W+R > N. Na primer, za N=3, W=2, R=2 imamo 4 > 3. W > N/2 daje presek dva upisa, a ne upisa i čitanja. Sa W=2 i R=1 čitanje može da pogodi baš repliku koja još nema upis.

> [!question] Quiz
> Dynamo-sistem sa N=3, W=2, R=2 (dakle W+R > N). Da li to sistem čini linearizabilnim, kao što je grupa sa konsenzusom?
>
> 1. Ne: presek daje svežu repliku, ali ne i jedan dogovoren redosled upisa
> 2. Ne: presek daje svežu repliku samo kad je W = N, a ne kad je W = 2
> 3. Da: presek daje svežu repliku, pa je to isto što i dogovoren redosled upisa
> 4. Da: presek daje svežu repliku, a većina pri upisu daje i potpuni redosled

> [!success] Quiz — correct ✓
> Your answer: 1. Ne: presek daje svežu repliku, ali ne i jedan dogovoren redosled upisa
> Correct answer: 1
>
> Ovo je razlika na koju profesor može da cilja. Dynamo-kvorum garantuje samo da čitanje dodirne bar jednu repliku sa najnovijom verzijom. Ne garantuje da se sve replike slože oko jednog redosleda upisa. Dva istovremena upisa mogu da stignu na različite replike različitim redosledom; Dynamo tada čuva obe verzije (vector clocks) i ostavlja aplikaciji da ih spoji. Konsenzus-kvorum se većinom dogovara o redosledu log-a, ulaz po ulaz. Kleppmann (DDIA, pogl. 9) eksplicitno kaže da Dynamo-kvorumi u opštem slučaju nisu linearizabilni.

> [!abstract] PI
> Kvorum ti je jak. Proveriću još konsenzus:

> [!question] Quiz
> U konsenzus protokolu (npr. Raft) leader šalje ulaz log-a followerima. Kada sme da kaže klijentu „komitovano“?
>
> 1. Kad ulaz upiše leader, a followerima ga pošalje u pozadini
> 2. Kad ulaz upišu svi čvorovi, računajući i samog leadera
> 3. Kad ulaz upiše bar jedan follower, nezavisno od veličine grupe
> 4. Kad ulaz upiše većina čvorova, računajući i samog leadera

> [!success] Quiz — correct ✓
> Your answer: 4. Kad ulaz upiše većina čvorova, računajući i samog leadera
> Correct answer: 4
>
> Ulaz je komitovan kad je repliciran na većinu (Ongaro & Ousterhout 2014, §5.3). Uslov „svi“ bi značio da jedan mrtav čvor blokira ceo sistem. „Samo leader“ je asinhrona replikacija. „Bar jedan follower“ je semisinhrona replikacija sa rpl_semi_sync_source_wait_for_replica_count=1, i to nije konsenzus, jer jedan follower u grupi od pet nije većina.

> [!question] Quiz
> Stari leader je pao. Kandidat traži glasove za novog leadera. Zašto Raft dozvoljava da čvor glasa za kandidata samo ako kandidatov log nije zastareliji od njegovog?
>
> 1. Da izbor bude brži, jer čvorovi sa dužim log-om odgovaraju brže
> 2. Da novi leader sigurno ima svaki već komitovan ulaz log-a
> 3. Da novi leader može da odbaci ulaze koje je stari leader pogrešno poslao
> 4. Da se spreči da dva kandidata u istom mandatu dobiju većinu

> [!success] Quiz — correct ✓
> Your answer: 2. Da novi leader sigurno ima svaki već komitovan ulaz log-a
> Correct answer: 2
>
> Komitovan ulaz postoji na nekoj većini. Kandidat mora da dobije glasove od većine. Te dve većine se seku, pa bar jedan glasač ima komitovan ulaz i odbiće kandidata kome ulaz nedostaje. Zato novi leader sigurno ima sve komitovano (Raft §5.4.1, „election restriction“). Dva leadera u istom mandatu sprečava nešto drugo: svaki čvor daje jedan glas po mandatu, a dve većine ne mogu biti disjunktne.

> [!abstract] PI
> Before I use the Abadi quote, I want to check it myself. The researcher couldn't fetch that PDF directly.

> [!question] Question
> Provera znanja daje ovu sliku: kvorum i konsenzus izvodiš sam iz preseka većina, ali rečnik (modeli konzistentnosti, PACELC, tri modela replikacije) skoro ne postoji, a CAP ti je ostao u obliku „izaberi dva“. Kako da vodim čas?
>
> 1. Pretežno sokratski (Recommended)
> 2. Pretežno izlaganje

> [!example] Answer
> 1. Pretežno sokratski (Recommended)

> [!abstract] PI
> ## Plan časa
>
> **Pristup.** Najpre postavljamo tri bezuslovne istine. Prvu dve će ti verovatno delovati očigledno, a treću si već sam koristio. Sve ostalo izvodimo iz njih ovim redom:
>
> 1. **Modeli konzistentnosti.** Ovo su obećanja o tome šta čitanje sme da vrati. Krećemo od najjačeg („ponaša se kao jedna kopija“) i odatle ga postepeno slabimo.
> 2. **CAP.** Gilbert-Lynch izvodimo sami: šta čvor sme da uradi kad mu stigne zahtev, a mreža je pukla. Odatle direktno pada „izaberi dva“, kao i ostala tri pogrešna čitanja iz memoa 07.
> 3. **PACELC.** Isto pitanje, ali bez particije: čekanje na poruke i dalje košta vremena. Ovde je most ka svakom MySQL podešavanju.
> 4. **Tri modela replikacije.** Pitanje je ko prima upise: jedan čvor, više čvorova ili svi bez leadera. Svaki odgovor ima drugačiju posledicu po redosled i sukobe.
> 5. **Konsenzus.** Pitanje je kako single-leader preživi pad leadera bez split brain-a. Kroz izbor leadera, replikaciju log-a i bezbednost preko preseka većina. To već znaš da izvedeš.
> 6. **Dva kvoruma.** Matematika preseka je ista, ali predmet nije: konsenzus se dogovara o **redosledu**, a Dynamo-kvorum samo o **svežini** čitanja.
>
> Sandbox (3307 kao leader, 3308 i 3309 kao followeri) koristim samo kao primer, bez obaveznog demoa.
>
> Tokom pripreme sam proverio izvore i našao **greške u memou 07** koje će ući u zapis:
> - nivoi `group_replication_consistency` su pogrešno imenovani i opisani;
> - tvrdnja „asinhrona replika tokom particije nastavlja da prima upise“ je preterana;
> - tvrdnja „W > N/2 sprečava split brain“ ne važi za Dynamo (sloppy quorum, §4.6);
> - strane za Lamport 2001 su 51–58, a ne 18–25.
>
> Takođe sam našao **primarni izvor za razliku između dva kvoruma**. Abadi (2012) doslovno piše da Dynamo-sistemi *„cannot achieve full consistency as defined by Gilbert and Lynch, even if R + W > N“*.
>
> ```mermaid
> graph TD
>   T1["Istina 1: poruke kasne<br/>ili se gube"]
>   T2["Istina 2: čvor ne razlikuje<br/>spor čvor od odsečenog"]
>   T3["Istina 3: dve većine<br/>se uvek seku"]
>   M["Modeli konzistentnosti<br/>stroga · uzročna · konačna<br/>+ RYW · monotona čitanja"]
>   CAP["CAP (Gilbert-Lynch)<br/>i 4 pogrešna čitanja"]
>   PAC["PACELC: else-grana<br/>latencija ↔ konzistentnost"]
>   R["Modeli replikacije<br/>single · multi · leaderless"]
>   K["Konsenzus<br/>izbor · log · bezbednost"]
>   Q["Konsenzus-kvorum<br/>≠ Dynamo-kvorum"]
>   G(["Cilj: rečnik pogl. 2<br/>i odbrana"])
>   T1 --> T2
>   T1 --> M
>   T2 --> CAP
>   M --> CAP
>   CAP --> PAC
>   T1 --> PAC
>   M --> R
>   R --> K
>   T3 --> K
>   T3 --> Q
>   K --> Q
>   R --> Q
>   PAC --> G
>   Q --> G
> ```
>
> Da li je ovaj plan u redu, ili nešto da pomerim pre nego što krenemo?


> [!quote] YOU
> jeste nastavi


> [!abstract] PI
> ## Čvor 1: bezuslovne istine
>
> **Zašto počinjemo ovde.** Sve što sledi (CAP, PACELC, konsenzus) postoji samo zato što čvorovi međusobno razgovaraju preko mreže. Ako je ovo tlo čvrsto, ostalo se izvodi.
>
> **Istina 1.** **Sva komunikacija između čvorova odvija se slanjem poruka.** Poruka putuje neko vreme, a može i da se izgubi. Drugi kanal ne postoji: nema zajedničke memorije ni zajedničkog sata. U našem sandbox-u čak i 3307 i 3308, na istoj mašini, razmenjuju binarni log isključivo preko TCP veze.
>
> **Istina 2** (sledi iz prve, ali se prihvata i bez izvođenja). Čvor A je poslao poruku čvoru B i nije dobio odgovor. A **ne može da zna** da li je B mrtav, spor ili odsečen. Sa strane čvora A sva tri slučaja izgledaju isto: tišina.
>
> Proveri da li prva istina zaista stoji:


> [!question] Quiz
> Čvor A je poslao upis čvoru B i čeka potvrdu već 5 sekundi. Šta A u tom trenutku sigurno zna o čvoru B?
>
> 1. Zna da je B živ, jer bi mreža javila grešku da je B pao
> 2. Ne zna ništa sigurno: B je možda pao, možda je spor, a možda je odsečen
> 3. Zna da je B primio upis, ali da je izgubljena samo potvrda
> 4. Zna da je B pao, jer bi živ čvor odgovorio za manje od 5 sekundi


> [!success] Quiz — correct ✓
> Your answer: 2. Ne zna ništa sigurno: B je možda pao, možda je spor, a možda je odsečen
> Correct answer: 2
>
> Tišina je jedini signal, a ista tišina nastaje u sva tri slučaja. Svaki „timeout“ je zato pretpostavka, a ne saznanje. MySQL Group Replication ima podešavanje group_replication_member_expel_timeout baš zato što mora nekako da pogađa. Mreža ne „javlja“ da je udaljeni čvor pao. Upis je možda stigao, a možda nije, i A to ne može da razlikuje.


> [!question] Quiz
> Stroga konzistentnost. Klijent A upiše x=5 i dobije „OK“ u 10:00:00. Klijent B, na drugoj mašini, pročita x u 10:00:01. Šta B sme da dobije?
>
> 1. Samo 5 ili neku noviju vrednost, nikad vrednost od pre upisa
> 2. Bilo 5 bilo staru vrednost, jer B nije video A-ov upis
> 3. Samo 5, a nikakvu noviju vrednost, jer je A-ov upis poslednji
> 4. Staru vrednost, dok replika sa koje B čita ne primi upis


> [!failure] Quiz — incorrect ✗
> Your answer: 3. Samo 5, a nikakvu noviju vrednost, jer je A-ov upis poslednji
> Correct answer: 1
>
> A-ov upis se završio (dobio je OK) pre nego što je B počeo čitanje. Njegova „tačka“ je zato pre B-ove, pa B mora da vidi 5 ili nešto što je upisano posle. Novija vrednost je dozvoljena, jer je neki C mogao da upiše x=7 između. Stara vrednost bi značila da se sistem ne ponaša kao jedna kopija. Zato strogo konzistentan sistem ne sme da pusti B-a da čita sa replike koja zaostaje.


> [!question] Quiz
> Stroga konzistentnost. A upiše x=5 (OK u 10:00:00). C upiše x=7 (OK u 10:00:00.5). B čita u 10:00:01. Šta B sme da dobije?
>
> 1. 5 ili 7, svejedno
> 2. Samo 7
> 3. Samo 5
> 4. Bilo koju od tri vrednosti


> [!failure] Quiz — incorrect ✗
> Your answer: 3. Samo 5
> Correct answer: 2
>
> Oba upisa su se završila pre B-ovog čitanja, i to redom: prvo 5, pa 7. Jedan redosled koji poštuje stvarno vreme glasi upis 5 → upis 7 → čitanje, pa je jedini dozvoljen odgovor 7. Da su se A-ov i C-ov upis preklapali u vremenu, sistem bi smeo da ih poređa bilo kako, ali isto za sve klijente.


> [!quote] YOU
> Pomesao sam sekunde i miliseknude


> [!abstract] PI
> To je greška u čitanju formata vremena, ne u modelu. Proveriću još jednom, sa vremenima koja ne mogu da se pomešaju:


> [!question] Quiz
> Stroga konzistentnost. A upiše x=5 i dobije OK u 10:00:10. C upiše x=7 i dobije OK u 10:00:20. B čita u 10:00:30. Šta B sme da dobije?
>
> 1. Bilo koju od tri vrednosti
> 2. 5 ili 7, svejedno
> 3. Samo 5
> 4. Samo 7


> [!success] Quiz — correct ✓
> Your answer: 4. Samo 7
> Correct answer: 4
>
> Redosled koji poštuje stvarno vreme je upis 5 (:10) → upis 7 (:20) → čitanje (:30). Poslednji završen upis pre čitanja je 7, pa je to jedini dozvoljen odgovor.


> [!question] Quiz
> Sandbox u stanju mirovanja: 3307 je leader, a 3308 i 3309 su followeri, sa običnom asinhronom replikacijom. Na 3309 je postavljen SOURCE_DELAY = 30. Klijent upiše red na 3307 i odmah ga čita sa 3309. Koji model ovaj sistem i dalje ispunjava?
>
> 1. Strogu konzistentnost: 3309 će posle kašnjenja imati isti red
> 2. Konačnu konzistentnost: 3309 će posle kašnjenja imati isti red
> 3. Read-your-writes: 3309 će posle kašnjenja imati isti red
> 4. Nijedan model: 3309 u tom trenutku vraća zastarelu vrednost


> [!success] Quiz — correct ✓
> Your answer: 2. Konačnu konzistentnost: 3309 će posle kašnjenja imati isti red
> Correct answer: 2
>
> Konačna konzistentnost dozvoljava zastarela čitanja u međuvremenu. Obećava samo da će se replike na kraju složiti, a 3309 će posle 30 s zaista imati red. Zastarelo čitanje ne krši konačnu konzistentnost, ali krši strogu konzistentnost i read-your-writes, jer je isti klijent upisao red pa ga nije video. Zato je „nijedan model“ netačno: najslabiji model je ispunjen.


> [!question] Quiz
> Korisnik ništa ne upisuje, samo osvežava stranicu. Prvo čitanje ide na 3308 (ažurna) i vidi 10 komentara. Drugo čitanje ide na 3309 (kasni) i vidi 8 komentara. Koja garancija je prekršena?
>
> 1. Monotona čitanja
> 2. Nijedna, ovo je dozvoljeno
> 3. Read-your-writes
> 4. Konačna konzistentnost


> [!question] Quiz — I don't know
> Your answer: I don't know
> Correct answer: 1
>
> Sesija je već videla stanje sa 10 komentara, a zatim je dobila starije stanje sa 8, pa se vreme vratilo unazad. To krši monotona čitanja. Read-your-writes nije pogođen, jer korisnik ništa nije upisao. Konačna konzistentnost nije prekršena, jer će 3309 sustići ostale. Tipičan uzrok je razdvajanje čitanja i upisa koje svako čitanje šalje na nasumičnu repliku. Uobičajen lek je da se sesija „zalepi“ za jednu repliku.


> [!question] Quiz
> Korisnik promeni lozinku (upis na 3307, leader). Sledeće čitanje njegovog profila ode na 3309, koja kasni, i prikaže staru lozinku. To je njegovo prvo čitanje u sesiji. Koja garancija je prekršena?
>
> 1. Nijedna, ovo je dozvoljeno
> 2. Read-your-writes
> 3. Monotona čitanja
> 4. Konačna konzistentnost


> [!question] Quiz — I don't know
> Your answer: I don't know
> Correct answer: 2
>
> Note: Nisam siguran koja garancija se kako zove i sta garantuje. Jasni su mi primeri ali ne mogu da odgovorim jer mi nisu poznate garancije
>
> Okidač je upis: sesija je promenila lozinku, a zatim nije videla sopstvenu promenu. Monotona čitanja ne mogu da budu prekršena prvim čitanjem, jer ne postoji ranije pročitano stanje od koga bi se išlo unazad. Ovo je tačno ona anomalija koju poglavlje 7 meri.


> [!question] Quiz
> Koja garancija obećava sledeće: „pošto si nešto pročitao, nikad više nećeš videti starije stanje od toga“?
>
> 1. Konačna konzistentnost
> 2. Monotona čitanja
> 3. Stroga konzistentnost
> 4. Read-your-writes


> [!failure] Quiz — incorrect ✗
> Your answer: 3. Stroga konzistentnost
> Correct answer: 2
>
> Okidač je prethodno čitanje, a obećanje je da se ne ide unazad. To su monotona čitanja („monotono“ = samo napred). Stroga konzistentnost to takođe obezbeđuje, ali obećava mnogo više: najnoviju vrednost za sve klijente, a ne samo „ništa starije za mene“.


> [!question] Quiz
> Koji je NAJSLABIJI model koji obećava sledeće: „posle tvog upisa, tvoja kasnija čitanja vide taj upis“?
>
> 1. Stroga konzistentnost
> 2. Read-your-writes
> 3. Monotona čitanja
> 4. Uzročna konzistentnost


> [!success] Quiz — correct ✓
> Your answer: 2. Read-your-writes
> Correct answer: 2
>
> Okidač je tvoj upis, a to je doslovno ime read-your-writes. Uzročna i stroga konzistentnost to takođe obezbeđuju, ali su jače, pa nisu najslabiji odgovor. Monotona čitanja se pokreću prethodnim čitanjem, a ne upisom.


> [!question] Quiz
> Ana objavi „Ko ide na ispit?“. Bojan to pročita i odgovori „Ja“. Čitalac Ceca vidi Bojanov odgovor „Ja“, ali Anino pitanje još ne vidi. Koji je najslabiji model koji ovo zabranjuje?
>
> 1. Read-your-writes
> 2. Uzročna konzistentnost
> 3. Konačna konzistentnost
> 4. Monotona čitanja


> [!success] Quiz — correct ✓
> Your answer: 2. Uzročna konzistentnost
> Correct answer: 2
>
> Bojanov upis je nastao pošto je video Anin, pa Anin upis uzročno prethodi Bojanovom i svako mora prvo da vidi njega. Cecine sesijske garancije nisu prekršene: ona ništa nije upisala, i nije prvo videla Anino pitanje pa ga onda izgubila. Prekršaj je između upisa različitih klijenata, a to vidi tek uzročna konzistentnost. Konačna konzistentnost ovo dozvoljava.


> [!question] Quiz
> Šta 3309 može da uradi sa zahtevom za čitanje x, i šta svaka mogućnost košta?
>
> 1. Odgovori starom vrednošću i izgubi P, ili čeka 3307 i izgubi C
> 2. Odgovori starom vrednošću i izgubi A, ili čeka 3307 i izgubi C
> 3. Odgovori starom vrednošću i izgubi C, ili čeka 3307 i izgubi A
> 4. Odgovori starom vrednošću i ne izgubi ništa, jer je particija privremena


> [!success] Quiz — correct ✓
> Your answer: 3. Odgovori starom vrednošću i izgubi C, ili čeka 3307 i izgubi A
> Correct answer: 3
>
> Ako 3309 odgovori, ne može da zna za x=5, jer poruka nije stigla. Vraća staru vrednost posle završenog upisa, a to krši C. Ako čeka, a particija traje, živ čvor ne odgovara, i to krši A. Treće mogućnosti nema. To je cela teorema 1 Gilbert-Lynch: u mreži koja gubi poruke nijedan algoritam ne garantuje i A i C. P ne može da se „izgubi“, jer ga nismo birali: mreža je pukla. „Privremena“ particija ne pomaže, jer niko ne zna koliko će trajati.


> [!question] Quiz
> Koje od ovih rečenica su TAČNE tvrdnje o CAP-u? (označi sve tačne)
>
> 1. Sistem koji bira C nije dostupan ni dok mreža normalno radi
> 2. Sistem sa konačnom konzistentnošću je tokom particije izabrao dostupnost
> 3. Dok mreža radi, CAP ne sprečava sistem da bude i strogo konzistentan i dostupan
> 4. Sistem može da izabere C i A ako se odrekne tolerancije na particiju


> [!success] Quiz — correct ✓
> Your answer: 2. Sistem sa konačnom konzistentnošću je tokom particije izabrao dostupnost, 3. Dok mreža radi, CAP ne sprečava sistem da bude i strogo konzistentan i dostupan
> Correct answer: 2, 3
>
> Tačne su prve dve. Odricanje od P nije opcija, jer particija nije podešavanje sistema nego događaj u mreži. Takozvani „CA sistem“ samo ne kaže šta radi kad mreža pukne, a pukne svakako. Izbor C košta dostupnost samo tokom particije, a ne stalno.


> [!question] Quiz
> Mreža radi savršeno. 3307 (leader) želi da kaže klijentu „OK“ tek kad je upis sigurno i na 3308, da nijedno čitanje sa 3308 ne bi bilo zastarelo. Šta to košta?
>
> 1. Svaki upis čeka bar jedan povratni put poruke do 3308, pa traje duže
> 2. Dostupnost, jer 3307 tokom tog čekanja ne odgovara klijentima
> 3. Postojanost, jer upis čeka 3308 umesto da ode na disk 3307
> 4. Ništa, jer bez particije CAP dozvoljava i C i A u isto vreme


> [!failure] Quiz — incorrect ✗
> Your answer: 2. Dostupnost, jer 3307 tokom tog čekanja ne odgovara klijentima
> Correct answer: 1
>
> Istina 1: znanje da je 3308 primio upis stiže samo porukom, a poruka putuje. Zato svaki upis plaća povratni put. Ništa nije „nedostupno“: odgovor stiže, samo kasnije. Ovo si izmerio na tiketu 10 sa semisinhronom replikacijom: 61 → 124 µs kad su fsync-ovi isključeni. Cena je kašnjenje (latencija), a ne dostupnost.


> [!question] Quiz
> Mreža radi. Semisinhrona replikacija tera 3307 da pre „OK“ sačeka potvrdu od 3308, pa upis traje 124 µs umesto 61 µs. Šta je sistem ovim platio, rečnikom PACELC-a?
>
> 1. Dostupnost (A) u else-grani, da bi dobio više konzistentnosti
> 2. Dostupnost (A) u P-grani, da bi dobio više konzistentnosti
> 3. Latenciju (L) u else-grani, da bi dobio više konzistentnosti
> 4. Latenciju (L) u P-grani, da bi dobio više konzistentnosti


> [!question] Quiz — I don't know
> Your answer: I don't know
> Correct answer: 3
>
> Note: ne znam sta je else-grana a sta P-grana ali je ili 3. ili 4.
>
> Particije nema, pa smo u else-grani (E), a tamo se trguje latencijom, ne dostupnošću: odgovor je stigao, samo kasnije. P-grana nudi izbor A ili C, a latencija se u njoj ne pojavljuje. Zato je PACELC okvir za ceo rad: sync_binlog, AFTER_SYNC i group_replication_consistency menjaju koliko dugo komit čeka, odnosno pomeraju sistem po E-grani.


> [!question] Quiz
> Group Replication na tiketu 11: tokom particije manjina blokira upise, a bez particije nivo AFTER je podigao medijanu komita sa 16 ms na 29 ms i uklonio zastarela čitanja. Kako ga klasifikuje PACELC?
>
> 1. PA/EC
> 2. PA/EL
> 3. PC/EL
> 4. PC/EC


> [!question] Quiz — I don't know
> Your answer: I don't know
> Correct answer: 4
>
> Note: Ne znam sta su ove skracenice
>
> Tokom particije manjina radije blokira nego da se razdvoji, pa je u if-grani izbor C (PC). Bez particije AFTER plaća 13 ms da bi čitanja bila sveža, pa je u else-grani izbor C (EC). Napomena za rad: sa podrazumevanim EVENTUAL nivoom isti sistem je u else-grani EL. Upravo to znači da MySQL daje podešavanje, a ne model.


> [!question] Quiz
> Tiket 11: kad su dva od tri čvora ubijena, preživeli čvor je blokirao upise umesto da ih prihvati. Koji je PRVI par slova za Group Replication?
>
> 1. EC
> 2. PC
> 3. PA
> 4. EL


> [!question] Quiz — I don't know
> Your answer: I don't know
> Correct answer: 2
>
> Mreža je „pukla“ (manjina je odsečena), pa je to prvi par, koji počinje slovom P. Čvor je radije odbio da odgovori na upis nego da rizikuje razilaženje, dakle izabrao je C: PC. EC i EL su drugi par, za slučaj kad mreža radi.


> [!question] Question
> Hoću da nađem tačno mesto gde zapinje. Šta od ovoga ti nije jasno?
>
> 1. Zašto je ubijanje dva čvora isto što i particija
> 2. Zašto je blokiranje upisa isto što i izbor C
> 3. Ne sećam se šta se dešavalo na tiketu 11
> 4. Sam zapis sa slovima mi je konfuzan


> [!example] Answer
> 4. Sam zapis sa slovima mi je konfuzan


> [!question] Quiz
> Tiket 11: dva od tri čvora su ubijena, a preživeli čvor je odbijao upise. Kako Group Replication odgovara na prvo pitanje („kad mreža pukne, šta radi odsečeni čvor?“)?
>
> 1. Komit čeka druge čvorove
> 2. Komit ne čeka druge čvorove
> 3. Odgovara i rizikuje zastarelo
> 4. Odbija upise i čuva tačnost


> [!question] Quiz — I don't know
> Your answer: I don't know
> Correct answer: 4
>
> Note: Nisam siguran, na osnovu cega treba da znam pravilo za Group Replication. Jel 4 odgovor
>
> Preživeli čvor je u manjini, odsečen od ostalih, i odbio je upise. To je odgovor „odbija i čuva tačnost“ na prvo pitanje. Opcije o čekanju komita su odgovori na drugo pitanje (kad mreža radi), pa ovde ne pripadaju.


> [!question] Quiz
> Činjenica: kod obične asinhrone replikacije 3307 kaže klijentu „OK“ odmah po upisu u svoj binarni log, ne čekajući 3308 ni 3309. Kako ovaj sistem odgovara na drugo pitanje („kad mreža radi, da li komit čeka druge čvorove?“)?
>
> 1. Čeka: sporije, ali bez zastarelog čitanja
> 2. Ne čeka: brzo, uz rizik zastarelog čitanja
> 3. Odgovara i rizikuje zastarelo
> 4. Odbija upise i čuva tačnost


> [!success] Quiz — correct ✓
> Your answer: 2. Ne čeka: brzo, uz rizik zastarelog čitanja
> Correct answer: 2
>
> OK stiže pre nego što ijedan follower ima upis. To je izbor brzine (latencije) umesto konzistentnosti u else-grani. Čitanje sa 3309 odmah posle toga može biti zastarelo. Opcije „odbija/odgovara“ su odgovori na prvo pitanje, o particiji.


> [!question] Quiz
> Činjenica: kod semisinhrone replikacije 3307 kaže „OK“ tek kad 3308 potvrdi da je primio upis, pa upis traje otprilike duplo duže. Mreža radi normalno. Šta je sistem ovim kupio, i čime je platio?
>
> 1. Kupio više dostupnosti, platio latencijom
> 2. Kupio nižu latenciju, platio konzistentnošću
> 3. Kupio više konzistentnosti, platio dostupnošću
> 4. Kupio više konzistentnosti, platio latencijom


> [!success] Quiz — correct ✓
> Your answer: 4. Kupio više konzistentnosti, platio latencijom
> Correct answer: 4
>
> Mreža radi, pa je ovo drugo pitanje (else-grana), a tamo se bira između brzine i konzistentnosti. Odgovor je stigao, samo kasnije, pa dostupnost nije izgubljena. Svako MySQL podešavanje koje kaže „čekaj na X pre OK“ radi upravo ovo, i zato je PACELC-ova else-grana okvir celog rada.


> [!question] Quiz
> Multi-leader: u istom trenutku klijent 1 na 3307 postavi cena=100, a klijent 2 na 3308 postavi cena=200, za isti red. Oba čvora odmah kažu „OK“, pa jedan drugom pošalju svoj upis. Šta je problem koji single-leader nikad nema?
>
> 1. Oba upisa su potvrđena, a čitanje sa followera može da vrati zastarelu vrednost
> 2. Oba upisa su potvrđena, a nijedan čvor neće primiti tuđi upis dok traje particija
> 3. Oba upisa su potvrđena, a binarni log 3307 biće veći od binarnog log-a 3308
> 4. Oba upisa su potvrđena, a ne postoji jedan redosled koji kaže koji je poslednji


> [!success] Quiz — correct ✓
> Your answer: 4. Oba upisa su potvrđena, a ne postoji jedan redosled koji kaže koji je poslednji
> Correct answer: 4
>
> Kod jednog leadera svi upisi prolaze kroz jedan log, pa redosled postoji po konstrukciji. Kod dva leadera 3307 vidi 100 → 200, a 3308 vidi 200 → 100, i bez dodatnog pravila završe sa različitim vrednostima. To je sukob, i neko mora da ga razreši: last-write-wins, aplikacija ili, u MySQL multi-primary režimu, certification. Zastarela čitanja postoje i kod single-leadera, pa to nije nova pojava.


> [!question] Quiz
> Raft: svaki čvor u jednom mandatu (term) glasa za najviše jednog kandidata, a kandidat postaje leader tek kad dobije glasove većine. Zašto u istom mandatu ne mogu postojati dva leadera?
>
> 1. Dve većine se seku, a zajednički čvor prvo proveri da li je stari leader mrtav
> 2. Dve većine se seku, a zajednički čvor ima samo jedan glas u tom mandatu
> 3. Dve većine se seku, a kandidat sa dužim log-om uvek pobedi onog sa kraćim
> 4. Dve većine se seku, a stari leader mora prvo da potvrdi da odustaje od uloge


> [!success] Quiz — correct ✓
> Your answer: 2. Dve većine se seku, a zajednički čvor ima samo jedan glas u tom mandatu
> Correct answer: 2
>
> Da bi dva kandidata pobedila u istom mandatu, oba bi morala da imaju većinu. Dve većine dele bar jedan čvor, a taj čvor bi morao da glasa dvaput, što pravilo zabranjuje. Provera „da li je stari leader mrtav“ je nemoguća (istina 2). Upravo zato protokol ne zavisi od nje, već od preseka većina. Ni pristanak starog leadera nije potreban, jer on može biti odsečen i nikad ne odgovoriti.


> [!question] Quiz
> Na odbrani te profesor pita: „Group Replication je kvorum sistem kao Dynamo, zar ne? Oba traže većinu.“ Koji je odgovor tačan?
>
> 1. Ne: GR većinom dogovara redosled transakcija, a Dynamo-kvorum samo obezbeđuje da čitanje dodirne svežu repliku
> 2. Ne: GR uopšte ne koristi većinu, a Dynamo-kvorum obezbeđuje da čitanje dodirne svežu repliku
> 3. Da: GR većinom dogovara redosled transakcija, a Dynamo-kvorum isto to radi kad je W + R veće od N
> 4. Ne: GR većinom obezbeđuje da čitanje dodirne svežu repliku, a Dynamo-kvorum dogovara redosled transakcija


> [!failure] Quiz — incorrect ✗
> Your answer: 3. Da: GR većinom dogovara redosled transakcija, a Dynamo-kvorum isto to radi kad je W + R veće od N
> Correct answer: 1
>
> Matematika je ista (presek skupova), ali predmet nije. GR (Paxos) se većinom dogovara o mestu svake transakcije u globalnom redosledu (refman: „agree on the order“). Dynamo se ni o čemu ne dogovara: samo bira veličine W i R tako da se skupovi preseku. Istovremeni upisi tada ostaju kao dve verzije, i zato Abadi kaže da Dynamo ne dostiže strogu konzistentnost ni uz R + W > N.


> [!question] Quiz
> Čitalac je dobio 100 (sa r2) i 200 (sa r3). Koja vrednost je „poslednja“?
>
> 1. Ne zna se: nijedan čvor nikad nije odlučio koji je upis bio prvi
> 2. 200, jer je B na r3 stigao poslednji i r3 je većina
> 3. 100, jer je A na r2 stigao poslednji, a r2 ima oba upisa
> 4. Ona koju potvrdi većina, jer je W + R veće od N


> [!success] Quiz — correct ✓
> Your answer: 1. Ne zna se: nijedan čvor nikad nije odlučio koji je upis bio prvi
> Correct answer: 1
>
> Svaka replika je upise poređala po redosledu dolaska, a taj redosled je slučajan (istina 1). Nijedan korak protokola nije rekao „A je pre B“. Zato Dynamo vraća obe verzije (vector clocks pokazuju da su istovremene), a aplikacija mora da ih spoji. U konsenzusu bi leader dodelio A mesto 7, a B mesto 8 u log-u, većina bi to prihvatila, i svaka replika bi primenila 7 pa 8, sa istim krajnjim rezultatom. Tu je razlika: presek daje svežinu, a konsenzus daje redosled.


> [!abstract] PI
> Sad ponovo odbrambeno pitanje, drugačije formulisano:


> [!question] Quiz
> Šta konsenzus-kvorum ima, a Dynamo-kvorum nema, čak ni uz W + R > N?
>
> 1. Odluku većine o tome na kom mestu u redosledu je svaki upis
> 2. Presek skupa koji je potvrdio upis i skupa koji čita
> 3. Mogućnost da nastavi rad kad jedna od tri replike padne
> 4. Potvrdu upisa od više od jedne replike pre nego što klijent dobije OK


> [!success] Quiz — correct ✓
> Your answer: 1. Odluku većine o tome na kom mestu u redosledu je svaki upis
> Correct answer: 1
>
> Ostale tri stvari imaju oba sistema: presek, otpornost na pad jedne od tri replike i potvrdu od više replika. Jedino konsenzus ima dogovor o redosledu, i to je ono što ga čini strogo konzistentnim.


> [!abstract] PI
> Čvor je potvrđen. Pre nego što sve zapišem, još jedno mešovito pitanje na mestu koje je najteže leglo:


> [!question] Quiz
> Korisnik prvo vidi svoje stanje računa: 5 000 din (sa 3308). Ništa ne menja. Osveži stranicu i vidi 4 200 din (sa 3309, koja kasni), jer najnovija uplata još nije stigla do 3309. Koja garancija je prekršena?
>
> 1. Konačna konzistentnost
> 2. Read-your-writes
> 3. Nijedna, ovo je dozvoljeno
> 4. Monotona čitanja


> [!success] Quiz — correct ✓
> Your answer: 4. Monotona čitanja
> Correct answer: 4
>
> Okidač je prethodno čitanje (5 000), a sledeće čitanje je starije (4 200), pa je vreme za sesiju otišlo unazad. To krši monotona čitanja. Korisnik ništa nije upisao, pa read-your-writes ne važi. Konačna konzistentnost je ispunjena, jer će 3309 sustići.


> [!abstract] PI
> Svih sedam čvorova je potvrđeno. Sad pišem lekciju, zapis učenja i belešku o merenjima. Prvo proveravam komponente:


> [!abstract] PI
> Za praktični deo ću proveriti uloge čvorova u živom sandbox-u. To je primer samo za čitanje, bez ikakvog upisa na replike.


> [!abstract] PI
> 3308 ima kanal prema 3307, ali su i nit prijema i nit primene isključene. Proveravam zašto:


> [!abstract] PI
> Sandbox je vraćen u stanje mirovanja. Dodajem komponentu za tabelu poređenja u zajednički CSS, jer je lekcija koristi više puta:


> [!abstract] PI
> Pišem lekciju:


> [!abstract] PI
> Proveravam citat iz refman-a pre nego što ga ostavim u lekciji:


> [!abstract] PI
> Prolazim kroz srpski tekst. Ispravljam tri mesta: naslov (treća istina nije o porukama), „gubitak latencije“ (značenje je obrnuto) i „presek većih skupova“:


> [!abstract] PI
> Sad referentna kartica:


> [!abstract] PI
> Sada zapis učenja, merenja i indeks:


> [!abstract] PI
> Memo 07 dobija kratke napomene na mestima grešaka, da se ne bi prenele u kasnija poglavlja. Zatim dodajem komentar na tiket:


> [!abstract] PI
> Other topics commit their live logs, so this one goes in too. Opening the lesson, then commit and push:
