# Scaffold the Tema 1 workspace and initialise git

Type: task
Status: resolved

## Question

Nothing to decide; the layout was settled during charting. AFK. Create, inside
`Tema 1. - Obrada upita (query processing) u MySQL/`:

- `rad.md` - the accumulating paper, with the nine chapter headings as empty stubs.
- `references.bib` - grown incrementally, never retrofitted.
- `examples/` - runnable SQL per chapter.
- `figures/` - captioned screenshots, named to match their chapter.
- Teach-workspace files: `MISSION.md`, `RESOURCES.md`, `NOTES.md`, and the `lessons/`, `reference/`,
  `learning-records/` directories.

`MISSION.md` matters most: the teach skill grounds every lesson in it, and it must say the user is
learning this in order to **write and defend a specific paper**, not for general interest.

Git is already initialised at the repo root with a `.gitignore`, and the map and tickets are
committed - that part is done. This ticket only needs to commit the scaffolding it creates.

## Answer

All created at the Tema 1 root:

- `rad.md` - YAML front matter (`title`, `bibliography: references.bib`, `csl: ieee.csl`, `lang`
  deliberately left unset per ticket 02's finding) plus the nine chapter headings as empty stubs,
  numbered and titled to match issues 10-18, and a trailing `# Reference` heading for the
  citeproc-generated bibliography.
- `references.bib` - empty, header comment only, to be grown incrementally.
- `ieee.csl` - the CSL file proven in ticket 02, moved here from the throwaway test so `rad.md`'s
  front matter resolves it with no path juggling.
- `examples/00-setup/` and an `examples/README.md` explaining the per-chapter subfolder
  convention; `00-setup/` is where ticket 01's synthetic-table generator script belongs once
  written.
- `figures/README.md` documenting the `NN-<chapter-slug>-MM-<what-it-shows>.png` naming
  convention and the manual-numbering-in-caption-text workaround from ticket 02.
- `MISSION.md` - names the concrete goal (write and defend this specific seminar paper), five
  observable success criteria tied to the actual chapters, the five-week/one-chapter-per-session
  constraints from `WORKFLOW.md`, and what's explicitly out of scope (hypergraph demo, the defense
  deck, general MySQL admin, Tema 2/3).
- `RESOURCES.md` - the MySQL reference manual and server blog as primary sources, the lecture
  decks with their confirmed chapter 1-5-only coverage, and the four already-vetted internal
  research reports in `.scratch/obrada-upita/research/`; a `Gaps` section flags the two claims
  (3x row-estimate divergence, `explain_json_format_version = 2`) still needing live-server
  verification.
- `NOTES.md` - seeded with the two facts most likely to get silently "fixed" wrong later: that
  ticket 08 hasn't locked terminology yet, and why `rad.md`'s `lang` field is deliberately unset.
- `lessons/`, `reference/`, `learning-records/` - each with a one-line `README.md` (so git tracks
  the otherwise-empty directory) pointing at the teach skill's own format docs.

Git was already initialised at the repo root; this ticket's new files are what get committed here.
