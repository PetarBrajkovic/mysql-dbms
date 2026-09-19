# Terminology rationale and budget history

Split out of `GLOSSARY.md` so the glossary itself stays cheap to read every lesson. `GLOSSARY.md`
carries the **binding one-line rule** for each decision below; this file carries the reasoning behind
it. Read this only when you are tempted to change a locked term, or when the user asks why a word was
chosen.

All decisions here were taken at **ticket 09** (`issues/09-terminology-and-skeleton.md`), in one
session, with the six research memos in hand.

## The master rule, and why it is inherited rather than invented

Checked against both finished papers before deciding. Tema 1 (`Tema 1. .../GLOSSARY.md`) splits terms
into a deck-derived table (Serbian only) and a no-precedent table under the stated convention
*"Serbian term, English original in parentheses on first use only, Serbian-only after that"*, keeping
English only for identifiers and code-level names (`handler`, `optimizer_trace`). Tema 2 does the same
with a `Source` column, keeping English in four places, each for a stated reason (`GRANT`/`REVOKE` as
keywords, `audit log` extending the deck's own gloss, `tenant`/`definer`/`invoker` as MySQL keywords,
`red-level security` as a comparison concept rather than a MySQL feature name).

So the house rule is **translate by default; English only for identifiers, SQL keywords, and
product/feature proper nouns; record every non-choice**. Tema 3 keeps it. The alternative considered
and rejected was a looser "mechanisms English, properties Serbian" rule derived from the professor's
own habit in the recovery deck - rejected because it would break with two finished papers in the same
course, which a reader holding all three would notice.

## Why there is a deck column at all

This topic has no deck about replication (verified across all six decks, memos 02 and 02b). But
`05_Oporavak` is Ramakrishnan & Gehrke ch. 20 in the professor's own Serbian and yielded 26 logging,
transaction and recovery terms. Those are inherited as §1a and used Serbian-only, exactly as Tema 1's
§1 was used.

The reason is not convenience. The map names Croatianism as this topic's specific hazard, because
Serbian-language replication material online is predominantly Croatian-authored. That was **confirmed
empirically at this ticket**: a search for Serbian renderings of *failover*, *replication lag* and
related terms returned almost exclusively Croatian and Bosnian sources (`hrcak.srce.hr`,
`bs.answers-technology.com`, `security.foi.hr`, `hr.answers-technology.com` - *vrijeme*, *poslužitelj*,
*robove*). Nothing from the open web was harvested for this glossary. Deck terms are therefore the only
professor-authored Serbian available, and the alternative (treating all 26 as fresh decisions) would
throw away the paper's best available defence.

One positive result from the same search: **kvorum** is attested in ordinary Serbian institutional
usage (the Narodna skupština's own pojmovnik defines it), so it is a settled borrowing in standard
Serbian rather than a technical calque.

## Locked non-choices

Recorded so they are not "fixed" later.

- **"eventual consistency" is never *eventualna konzistentnost*.** This is a false friend, and a bad
  one: Serbian *eventualno* means "possibly / should it happen", while the English term means "in the
  end, given no further writes". *Eventualna konzistentnost* therefore asserts something close to the
  opposite of the concept - that consistency might happen. The paper uses **konačna konzistentnost**,
  with the English glossed once. The form *eventualna* is common in regional IT writing, which is
  exactly the Croatian-authored corpus this topic is told not to harvest from, so its familiarity is
  evidence against it rather than for it.

- **"certification" is never *sertifikacija*** (and certainly never the Croatian *certifikacija*). Two
  points. (a) In ordinary Serbian, *sertifikacija* means issuing or awarding a certificate - a
  conformity-assessment word. Group Replication's certification does nothing of the kind: it compares
  the write-sets of concurrent transactions and rejects the loser. The compound parses and misleads,
  which is the same collocation failure Tema 1 recorded when it rejected *skladišni motor* for
  *storage engine*. (b) It is a MySQL Group Replication feature term the reader will meet verbatim in
  the manual. So it stays English, glossed once as *provera saglasnosti transakcija*, and the
  surrounding vocabulary is Serbian (*skup upisa*, *sukob*) because those are transparent and carry no
  wrong sense.

- **"split brain" is never *podeljeni mozak*.** A literal calque of an English idiom, unattested in
  Serbian technical writing, and it reads as anatomy rather than as a failure mode. Kept English,
  glossed once as *razdvajanje grupe na dve nezavisne celine*. Rejecting the term entirely (describing
  the condition instead) was considered and refused: it is the name the literature uses and the name
  the professor may use at defense, and ch. 5's whole quorum argument is about what does **not**
  happen - the word has to be sayable to be denied.

- **"replication lag" is never *latencija replikacije*.** *Latencija* is the practitioners' word, but
  ch. 6 discusses genuine network latency between datacenters, and the two senses would collide inside
  one paper. **Kašnjenje replikacije** is standard Serbian, unambiguous, and collocates naturally in
  captions and with verbs (*replika kasni za izvorom*). *Zaostajanje replike* was the close runner-up -
  semantically nearest to "lag" - but its verb forms are less usual in Serbian technical prose.

- **"master/slave" are never working terms.** MySQL renamed the roles to source/replica in 8.0 and the
  8.4 manual - which this paper cites on nearly every page - uses the new names throughout. The old
  pair appears exactly once, in a footnote at the ch. 3 vocabulary switch, explaining the rename.

- **Two role vocabularies are used on purpose** (glossary §1d). *leader/follower* in ch. 2, because
  that is the literature's term and the professor's bullet #2 is written in those exact English words;
  *izvor/replika* from ch. 3 on, because that is MySQL's own current vocabulary. The switch is stated
  in the text rather than performed silently - the user's explicit instruction at this ticket: the
  reader is told the paper adopts *izvor/replika* **because MySQL changed the names**, so the two
  vocabularies read as a deliberate two-level distinction and not as inconsistency.

- **Product proper nouns are never declined or translated**: `InnoDB Cluster`, `InnoDB ClusterSet`,
  `Group Replication`, `MySQL Shell`, `MySQL Router`. The generic noun *klaster* is Serbian and is
  declined normally; the capitalised product names are not. When a sentence needs a case form, the
  case is carried by a Serbian head noun (*u okviru InnoDB Cluster konfiguracije*), never by bending
  the product name.

## The spine, and why the charting hunch was not adopted as written

The map's hunch was *"MySQL replicira log, ne stanje; svaka jača garancija je pravilo o tome kada se
piscu sme reći da je uspeo, plaćeno latencijom na primarnom čvoru."* Ticket 09 required attacking it,
and two objections stuck:

1. **It is descriptive, not arguable.** Nobody would dispute it, so it cannot organise chapters or be
   defended - a spine has to be a claim someone could contest.
2. **It does not survive ClusterSet.** The hunch says stronger guarantees are bought with latency; at
   ClusterSet scope MySQL does not buy the guarantee at all, and says so.

The locked spine keeps the hunch as the **mechanism underneath it**: because what ships is a log and
not a state, consistency is assembled from acknowledgement points, and the assembling is done by the
operator. The evidence that this is contestable and true is that **the same product takes opposite CAP
positions at two scopes in its own documentation** - Group Replication blocks a minority rather than
diverging, while ClusterSet *"prioritizes availability over data consistency in order to maximize
disaster tolerance."*

## Skeleton decisions and their losing alternatives

- **Geo-distribution is a chapter, not a section.** Memo 07's demotion was withdrawn (its strongest
  reason was the false "MySQL has no dedicated geo feature"), so the call was re-taken from scratch.
  Its four surviving reasons - thematic overlap with multi-leader, thin novel theory, ~2-3 page
  density, reading flow - were outweighed by: it is professor bullet #4 and a bullet without a chapter
  is a defense risk; InnoDB ClusterSet is a concrete, free, named feature to explain; and the
  CAP-at-two-scopes argument is the paper's best single piece of evidence and would be buried inside
  another chapter. The rejected third option was merging bullets #4 and #5 into one "globally
  distributed reads" chapter - economical, but it blurs two different mechanisms.

- **Async and semisync split.** Rejected: one combined chapter ("od asinhrone do semisinhrone"), which
  reads as a single arc but puts the paper's sharpest argument in the same chapter as setup mechanics;
  and a three-way split with the binary log standing alone, which risks a thin async chapter that is
  mostly `CHANGE REPLICATION SOURCE TO`.

- **Group Replication stays one chapter.** Rejected: two chapters mirroring the two halves of bullet
  #3, which reads well against the professor's list but duplicates the certification machinery, since
  quorum and conflict detection are the same mechanism viewed twice; and splitting InnoDB Cluster +
  Router into a short operational chapter, a clean seam but Router is capped at a paragraph by scope.

- **Theory chapter is second, before any MySQL.** Rejected: placing it after ch. 3 so the reader meets
  the shipped log before the vocabulary (attractive - the spine lands on concrete ground - but ch. 3
  would then either avoid the theory terms or forward-reference them); and folding theory into the
  Uvod, which stops being an Uvod at three pages and hides the material the professor's bullets are
  written in.

- **Theory budget made numeric** because "a paragraph or a quotation" is unenforceable at writing
  time: ~3 pages / 10-12 paragraphs for ch. 2, and one paragraph plus one citation for any concept
  introduced later, with the next paragraph obliged to be MySQL. The test for a violation is
  mechanical: a second consecutive theory paragraph outside ch. 2 means the concept belonged in ch. 2.

- **Voice and citation unchanged** from Temas 1 and 2 (impersonal *se*, per-paragraph citation) - a
  change on the third paper of one course buys nothing and costs consistency. The one addition is
  topic-specific and lives in glossary §5: induced-lag captions must say the lag was induced.
