# Scaffold the Tema 2 workspace and write MISSION.md

Type: task
Status: resolved

## Question

Nothing exists in this folder yet except the professor's screenshot and this map. Everything the
teach skill and the writing pipeline expect has to be there before a single lesson is built.

1. **Run the scaffolder**, `..\tools\new-topic.ps1`, with `-Slug kontrola-pristupa`. **It refuses to
   write into a folder that already exists**, and this one does (it holds the screenshot and
   `.scratch/`). Work around it rather than deleting anything: scaffold into a temporary sibling name
   and move the contents in, or create the skeleton by hand from `../templates/` — see
   `../templates/README.md` for the file-to-file mapping. Verify afterwards that the directory
   skeleton matches what the scaffolder makes (`lessons/`, `reference/`, `learning-records/`,
   `examples/`, `figures/`, `figures/raw/`, `tools/`) and that every templated file landed under its
   real name, **UTF-8 without a BOM**.
2. **Write `MISSION.md`** — not the template's placeholders, the real thing. It is the file `/teach`
   reads first, and a bad mission is worse than none. Model it on Tema 1's: *Why* (this exact paper,
   this exact defense), *Success looks like* (what he must be able to explain without notes and
   defend live), *Constraints* (the free-only rule, the loop in `../WORKFLOW.md`, short lessons,
   every lesson pointing at something runnable), *Out of scope* (mirroring the map). **Show it to the
   user and let him correct it** — it is his defense, not the agent's.
3. **Set the title** in `naslovna.md` (three OpenXML runs) and in `rad.md`'s front matter. Leave
   `lang` unset in `rad.md`, per Tema 1's finding: setting it forces the IEEE reference list into
   Serbian Cyrillic.
4. **`mysql-credentials.cnf`** — the user writes it himself; it holds a password and is gitignored.
   Confirm the Tema 1 file can simply be copied across, or that a new dedicated account is wanted
   (a *security* paper arguably should not connect as root; flag it, but the decision belongs to
   ticket 10).
5. Leave `GLOSSARY.md` as the scaffolder's stub. Locking it is ticket 09 and must not be pre-empted.
6. Commit.

Not part of this ticket: creating the sandbox schema, choosing the running example, or writing any
prose into `rad.md` beyond the front matter.
