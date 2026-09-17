# Notes — Tema 2. - Kontrola pristupa i sigurnosni modeli u MySQL bazi podataka

Subject-specific working notes. **The process is not here**: how lessons are taught and which files
to read per lesson is `../TEACHING.md`; how the paper is written is `../WRITING.md`. Only add
something here if it is true about *this subject* and not about the course as a whole.

Session findings do not belong here either — they go into a learning record, and
`learning-records/README.md` is the index where they are looked up. **Never append a correction under
a stale claim; correct it in place.**

## Subject quirks

- **Live teaching runs in Serbian** for this topic (chosen at ch. 3): the defense is in Serbian, so
  terminology should lock in the language he will use. MySQL keywords, system variable names and
  error codes stay English per `GLOSSARY.md` §1. Workspace bookkeeping stays English as usual.
- **He derives, and will over-derive.** Teaching by derivation works very well on him (records 0003
  and 0004), but the side effect is that he assumes every fact must follow from something. When a
  fact is an arbitrary design decision — e.g. `partial_revokes` being schema-level only — say so
  explicitly, or he will invent a derivation for it.
- **Two words he rejected as not Serbian, in live teaching: *spina* and *sondažno*.** Use *okosnica*
  for a chapter's backbone and *provera znanja* for probing. He corrects the agent's Serbian
  mid-lesson and expects it to stick — typos in quiz stems get flagged too (*povećati* for
  *povezati*). Proofread every Serbian sentence before sending, not only lesson HTML.
- **Restate the sandbox state inside any question that depends on it.** He correctly objected that
  a quiz about `role_doctor`'s privileges was unanswerable from the four statements shown, because
  the relevant `GRANT` lived in `00-setup/04-roles-and-accounts.sql`. Prior setup is not shared
  context unless it is on screen.

## Chapter planning

- {Decisions about how chapters split into lessons, and any page-budget calls the user has made.}

## Export state — read before touching `rad.docx`

- **Once the DOCX is hand-finished in Word, it is no longer reproducible from `rad.md`.** The final
  pass (ticket 13) leaves `rad.docx` at 23 rendered pages, generated cleanly by
  `../tools/make-docx.ps1`. After that export, three things are done **by hand in Word** and exist
  in no source file: the body's proofing language set to Serbian (Latin), the faculty seals pasted
  into the title page, and any final visual polish. Re-running the export **silently destroys all
  three**. Never re-run `make-docx.ps1` without asking first — same rule as Tema 1.
- If a late prose fix is unavoidable after hand-finishing, the cost is real: edit `rad.md`, re-export,
  and redo the three manual steps. Weigh that before agreeing to a wording change.

## Accepted terminology divergences (final pass, ticket 13)

Checked across all eight chapters against `GLOSSARY.md` §1. Terminology is consistent; three
divergences were found, judged, and **deliberately kept** rather than triggering a rename:

- **`fino-granularna kontrola pristupa`, not the deck's `sigurnost na nivou polja`.** The deck's term
  names field-level security specifically; the chapter covers columns *and* views *and* row-level
  emulation, which the narrower deck term would mis-describe. Already baked into the locked ch. 4
  title at ticket 09, so this was a decision, not drift.
- **`princip najmanjih privilegija` carries no `(least privilege)` gloss.** The glossary asked for one
  on first use; ch. 2 instead introduces the term with Saltzer & Schroeder's exact 1975 wording in
  quotation marks plus the citation, which identifies the concept more precisely than a parenthetical
  English gloss would.
- **Ch. 6 glosses the audit term in the reverse order** — `Evidencioni zapis pristupa bazi (audit
  log/trail)` where the glossary wrote `audit log/trail (evidencioni zapis pristupa bazi)`. Same
  pairing, same single gloss; the Serbian-first order reads better as a chapter's opening sentence.
