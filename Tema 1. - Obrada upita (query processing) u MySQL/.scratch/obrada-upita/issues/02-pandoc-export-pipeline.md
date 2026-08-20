# Prove the Markdown to DOCX pipeline with IEEE citations

Type: task
Status: open

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

<!-- record: pandoc version, exact working command line, CSL file location, encoding/font caveats -->
