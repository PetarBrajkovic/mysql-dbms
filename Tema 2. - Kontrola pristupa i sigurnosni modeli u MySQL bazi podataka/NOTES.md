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
- **Restate the sandbox state inside any question that depends on it.** He correctly objected that
  a quiz about `role_doctor`'s privileges was unanswerable from the four statements shown, because
  the relevant `GRANT` lived in `00-setup/04-roles-and-accounts.sql`. Prior setup is not shared
  context unless it is on screen.

## Chapter planning

- {Decisions about how chapters split into lessons, and any page-budget calls the user has made.}
