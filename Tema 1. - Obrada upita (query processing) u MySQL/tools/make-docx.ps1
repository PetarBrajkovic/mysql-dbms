<#
.SYNOPSIS
  Exports the whole paper to rad.docx: title page (naslovna.md) + body (rad.md),
  with IEEE citations resolved. This is the ONE canonical way to regenerate the
  Word document - use it instead of calling pandoc by hand, so the title page is
  never dropped again.

.DESCRIPTION
  Runs pandoc over naslovna.md THEN rad.md, in that order, so page 1 is the raw
  OpenXML title page and chapter 1 starts on page 2 (naslovna.md ends with a page
  break). Two things are load-bearing and easy to get wrong by hand:

    * naslovna.md must come first, or there is no title page.
    * -M title="" -M author="" suppresses rad.md's own YAML title block, which
      would otherwise render a second, pandoc-generated title on top of the custom
      title page.

  Locked pipeline facts (ticket 02, .scratch/obrada-upita/issues/02-pandoc-export-pipeline.md):
    * --citeproc + ieee.csl turn [@key] into IEEE [1], [2], ... with a matching
      reference list; bibliography is references.bib (set in rad.md front matter).
    * Do NOT set lang: sr in rad.md - it forces the bibliography into Cyrillic.
    * Figure captions are numbered by hand in the caption text (Slika N: ...).

  Styling:
    * --reference-doc=assets/reference-paper.docx justifies the body, centers
      figures and their captions, and leaves the front page (raw OpenXML with its
      own inline centering) alone. Rebuild that file with
      tools/build-reference-doc.py if the rules change.
    * --syntax-highlighting colors fenced code blocks (```sql). Inline `code`
      already renders in Consolas via the reference doc's VerbatimChar style.

  After opening in Word: select the body and set its proofing language to Serbian
  (Latin) once, so the spell-checker stops flagging every word (the English
  reference list is correct as-is). Logos: paste the two faculty seals into the
  empty band at the top of the title page.

.EXAMPLE
  .\tools\make-docx.ps1
#>
param(
    [string]$Out = 'rad.docx'
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Push-Location $root
try {
    pandoc naslovna.md rad.md --citeproc --csl=ieee.csl `
        --reference-doc=assets/reference-paper.docx --syntax-highlighting=tango `
        -M title="" -M author="" -o $Out --resource-path=.
    if ($LASTEXITCODE -ne 0) { throw "pandoc exited with code $LASTEXITCODE" }
    Write-Host "Exported $Out (title page + body, IEEE citations)." -ForegroundColor Green
}
finally {
    Pop-Location
}
