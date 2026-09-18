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
