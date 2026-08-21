# Prove the Markdown to DOCX pipeline with IEEE citations

Type: task
Status: resolved

## Question

Nothing to decide; this de-risks the end of the project. Pandoc is not installed and the user has
never used it, so the export must be proven **now** on a throwaway document rather than discovered
broken in week five with 20 pages written.

Must demonstrate, end to end:
- Pandoc installed and callable.
- A Markdown file with Serbian diacritics surviving intact, and a `[@key]` citation.
- A `references.bib` entry rendering as a correct **IEEE** reference via `--citeproc` and an IEEE CSL
  file.
- Embedded images with numbered captions.
- Output as `.docx` that opens cleanly in Word and stays editable, since the user adds the title page
  there afterward.

## Answer

Proven end to end on a throwaway document (built, checked, then deleted; only the CSL file
survives as a real deliverable).

- **Pandoc 3.10.2**, installed via `winget install --id JohnMacFarlane.Pandoc`. It lands at
  `%LOCALAPPDATA%\Pandoc\pandoc.exe` and winget adds that to the user `PATH` - a **new terminal**
  (opened after the install) picks it up; sessions already open at install time will not.
- **CSL file**: the official Zotero/CSL-project IEEE style, pulled from
  `https://raw.githubusercontent.com/citation-style-language/styles/master/ieee.csl` and kept at
  `ieee.csl` in the Tema 1 root, next to `rad.md` and `references.bib`.
- **Working command**, run from the Tema 1 root:
  ```
  pandoc rad.md --citeproc --csl=ieee.csl -o rad.docx --resource-path=.
  ```
  `--citeproc` resolves `[@key]` citations against `references.bib` (set via the `bibliography:`
  front-matter field) into numbered IEEE in-text markers `[1]`, `[2]`, ... with a matching
  reference list under a `# Reference` (or `# Reference` / `# Literatura`) heading at the end of
  the source file.
- **Serbian diacritics** (č ć đ š ž and uppercase) survive perfectly with no extra flags, as long
  as the `.md` file is saved UTF-8 (the normal case).
- **Real gotcha - do not set `lang: sr` (or `sr-Latn`) in the YAML front matter.** citeproc-lua's
  bundled Serbian CSL locale is **Cyrillic-only**; `sr-Latn` falls back to it rather than to a
  Latin variant. The result: body text in Latin script but bibliography terms silently rendered in
  Cyrillic ("Приступљено: 21. Август 2026." instead of "Accessed: Aug. 21, 2026."). Fix: leave
  `lang` unset (or set it to `en`), which yields correct English IEEE bibliography wording. Pandoc
  has no way to give the body and the bibliography different languages in one pass, so after
  export, select the body text in Word and set its proofing language to Serbian (Latin) by hand -
  a one-time, few-second fix, worth doing so Word's spell-checker stops flagging every Serbian
  word.
- **Figure captions are not auto-numbered.** An `![caption](path)` image on its own line embeds
  cleanly and Word applies its built-in "Caption" paragraph style to the caption text, but Pandoc
  does not insert a "Slika 1:" prefix or a `SEQ Figure` field - renumbering on reorder is not
  automatic. Since chapters are appended to `rad.md` in order and figures will not be reordered,
  the fix is to write the number into the caption text itself, e.g.
  `![Slika 1: opis...](figures/....png)`.
- **Output**: a well-formed `.docx` (valid OOXML zip, verified by unpacking and inspecting
  `word/document.xml`, `styles.xml`, and the media relationships) that stays fully editable, which
  is where the user adds the title page afterward.
