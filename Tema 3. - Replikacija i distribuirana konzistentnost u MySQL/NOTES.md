# Notes — Replikacija i distribuirana konzistentnost u MySQL-u

Subject-specific working notes. **The process is not here**: how lessons are taught and which files
to read per lesson is `../TEACHING.md`; how the paper is written is `../WRITING.md`. Only add
something here if it is true about *this subject* and not about the course as a whole.

Session findings do not belong here either — they go into a learning record, and
`learning-records/README.md` is the index where they are looked up. **Never append a correction under
a stale claim; correct it in place.**

## Language — binding on every Serbian line

- **Standard Serbian, ekavica, one variant.** Consult `serbian-grammar` before sending *any* Serbian
  text: lesson HTML, quiz stems, figure captions, chat replies, and `rad.md` prose alike — not only
  the paper.
- **No Croatian or Bosnian forms, ever.** Not lexis, not morphology, not syntax. `optimizuje` not
  `optimizira`, `tačno` not `točno`, `deo`/`pre`/`posle` not `dio`/`prije`/`poslije`, `hiljada` not
  `tisuća`, `uticaj` not `utjecaj`, `redosled` not `redoslijed`, `pisaće` not `pisat će`,
  `mora da piše` not `mora pisati`.
- **This topic is the highest-risk one in the course for that.** Temas 1 and 2 had a lecture deck
  supplying the professor's own Serbian; this one has **none** (see `MISSION.md`). Serbian-language
  material on replication and distributed systems is disproportionately Croatian-authored, so
  terminology scraped off the web is exactly where a Croatianism enters. Rule: a Serbian term comes
  from a **Serbian normative source** (Matica srpska / SANU, Pravopis) or from established Serbian
  technical usage that has been checked — otherwise the English term stays, glossed once. Never
  invent a calque and never trust a Serbian-looking page's variant without checking it.
- Carried from Tema 2: the user corrects the agent's Serbian mid-lesson and expects it to stick. He
  rejected *spina* and *sondažno* as not Serbian — use *okosnica* for a chapter's backbone and
  *provera znanja* for probing. Proofread every Serbian sentence before sending; typos in quiz stems
  get flagged.

## Research rules — how a claim earns its place

Both rules below exist because of a real failure in this topic's own charting research, not as general
good practice.

### 1. No absence claim enters a lesson or the paper unverified

Any sentence of the form **"MySQL has no X"**, **"MySQL does not support X"**, **"X must be built
outside the database"** gets checked at the moment it is written, and the check is recorded next to
the claim. Triggered by the *grammatical pattern*, not by whether anyone feels uncertain.

**Why this rule and not a general accuracy rule:** a research memo flags what it knows it is unsure
about. It cannot flag the feature it never thought of. A confident negative sentence is
indistinguishable from a confident fact, so absence claims slip through every checkpoint built on
flagged-claim lists.

**The concrete failure:** charting memo 07 stated *"MySQL does not provide dedicated geo-distribution
features."* False - **InnoDB ClusterSet** is exactly that. It was missed because every URL in the
entire research set pointed at the **reference manual**, and ClusterSet is documented in the **MySQL
Shell manual**, a separate documentation tree. The claim was never flagged as uncertain, so no
checkpoint would have caught it.

**This paper's thesis will be built from absence claims** - "MySQL gives you knobs, not guarantees" is
an absence argument, the same shape as Tema 2's DAC-only spine, whose conclusion rested on six of
them. One missed feature does not cost a paragraph here; it can invert a chapter's verdict. It nearly
inverted the geo-distribution one.

### 2. The source ladder — where to look, in order

A claim is not "unsourced" just because the reference manual is silent. Walk the ladder and **record
which rung the claim came from**:

1. **MySQL 8.4 reference manual** (`dev.mysql.com/doc/refman/8.4/`). Default for server behaviour.
2. **The other Oracle documentation trees** - and this is the rung that was missed: the **MySQL Shell**
   manual (InnoDB Cluster, ClusterSet, AdminAPI), **MySQL Router**, the **worklogs** (`WL#`), and the
   source tree. A feature absent from the refman is routinely documented here. **Before writing any
   absence claim, check this rung explicitly.**
3. **Primary academic literature** for anything theoretical - the paper cites these, never a manual,
   for concepts like quorum, linearizability or CAP.
4. **Practitioner and community sources** when rungs 1-3 are genuinely silent: Percona, MySQL release
   notes and bug reports, conference talks, engineering blogs from people who actually ran it. **Use
   them to learn and to know what to test, and then verify on the live topology.** Cite them in the
   paper only when they are the genuine origin of a claim and nothing higher exists; a measurement of
   your own beats a blog post, and `../WRITING.md` governs what may be cited.
5. **The live topology.** The last word. A local measurement outranks any document, and where the two
   disagree the paper reports the measurement and says which version it was taken on. Tema 2 overturned
   a documented claim this way.

The lecture decks in `../Predavanja/` sit outside this ladder: they are **learning material and a
Serbian terminology source, never citable** (`../WORKFLOW.md` rule 7).

## Subject quirks

- **Nothing in this topic can be shown on one server.** The topology (ports 3307/3308/3309) is a
  prerequisite for almost every measurement, which is why it gets its own task ticket rather than
  being improvised mid-chapter. **Port 3306 is off-limits** — it is Tema 2's `poliklinika` server
  and must keep working.
- **He derives, and will over-derive** (carried from Tema 2, records 0003/0004). Teaching by
  derivation works very well on him, but he assumes every fact must follow from something. Replication
  is full of arbitrary defaults and historical accidents (`binlog_format` defaulting changes,
  `sync_binlog`, the 8.4 removal of the old `MASTER`/`SLAVE` syntax). When a fact is a design
  decision or a legacy artefact, say so explicitly, or he will invent a derivation for it.
- **Restate the topology state inside any question that depends on it.** Same rule as Tema 2's
  sandbox note: which node is primary, what the lag currently is, and which variables are set are not
  shared context unless they are on screen.
- **8.4 terminology changed.** MySQL 8.4 removed the deprecated `MASTER`/`SLAVE` statements and
  variables in favour of `SOURCE`/`REPLICA`. Most material online, and most of the literature, uses
  the old words. The paper uses MySQL 8.4's current vocabulary and says once that the older terms
  name the same thing; lessons should flag the rename the first time it bites.

## Chapter planning

- {Decisions about how chapters split into lessons, and any page-budget calls the user has made.}

## Export state — read before touching `rad.docx`

- Same rule as Temas 1 and 2: **once the DOCX is hand-finished in Word, it is no longer reproducible
  from `rad.md`.** Proofing language, the faculty seals on the title page, and final visual polish
  are done by hand and exist in no source file. Re-running `../tools/make-docx.ps1` silently destroys
  all three. Never re-export after hand-finishing without asking first.
