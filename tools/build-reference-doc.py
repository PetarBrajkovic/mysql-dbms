#!/usr/bin/env python3
"""
Builds <course>/assets/reference-paper.docx - the pandoc --reference-doc that controls
Word styling for every topic's exported rad.docx. Runnable from anywhere:

    python tools/build-reference-doc.py

It takes pandoc's own default reference.docx and patches only the paragraph
styles we care about, so we inherit every other default (headings, tables,
bibliography, the Consolas inline-code font in VerbatimChar) untouched:

  * Normal            -> justified (w:jc both). Everything the body uses
                         (BodyText, FirstParagraph, Compact) is based on Normal,
                         so the whole body justifies. The title page is raw
                         OpenXML in naslovna.md with its OWN inline w:jc=center on
                         every line, and inline properties beat the style, so the
                         front page is unaffected - exactly as asked.
  * Figure / CaptionedFigure -> centered (the paragraph that holds the image).
  * ImageCaption      -> centered (the "Slika N: ..." caption under the image).
  * docDefaults spacing-after -> 200 twips (10pt) down to 120 (6pt). Pandoc's
    default puts 10pt under EVERY paragraph, which on a body of ~70 paragraphs
    costs most of a page in whitespace alone. 6pt still separates paragraphs
    clearly in a justified body. Decided 2026-08-31 when Tema 1 hit its page
    ceiling; see that topic's GLOSSARY.md section 4.

SQL/code needs no style patch here: inline code already uses the default
Consolas VerbatimChar, and code BLOCKS are colored by --highlight-style, which
make-docx.ps1 passes. pandoc generates the SourceCode style on demand from that.

Re-run this whenever the styling rules change, then commit the regenerated
the shared assets/reference-paper.docx alongside this script.
"""
import io
import re
import pathlib
import subprocess
import sys
import zipfile

STYLES_PATH = "word/styles.xml"
DOCUMENT_PATH = "word/document.xml"

# A4 with 2.5 cm margins, in twips (1440 per inch, 567 per cm). Pandoc's default
# reference.docx specifies NO page size or margins at all, which means every
# reader's Word supplies its own defaults and the same .docx paginates
# differently on different machines. Pinning it makes the export deterministic,
# and A4/2.5cm is the standard the faculty expects anyway.
PAGE_W, PAGE_H = 11906, 16838
MARGIN = 1417


def default_reference_docx() -> bytes:
    proc = subprocess.run(
        ["pandoc", "--print-default-data-file", "reference.docx"],
        capture_output=True,
    )
    if proc.returncode != 0:
        sys.exit("pandoc failed:\n" + proc.stderr.decode("utf-8", "replace"))
    return proc.stdout


def set_style_jc(xml: str, style_id: str, val: str) -> str:
    """Ensure the paragraph style `style_id` has <w:jc w:val="val"/>, in a
    schema-valid position (jc goes at the END of an existing w:pPr, after
    keepNext/spacing/etc.)."""
    pat = re.compile(
        r'(<w:style\b[^>]*w:styleId="' + re.escape(style_id) + r'"[^>]*>)(.*?)(</w:style>)',
        re.S,
    )
    m = pat.search(xml)
    if not m:
        print(f"  WARN: style {style_id!r} not found, skipped")
        return xml
    head, body, tail = m.group(1), m.group(2), m.group(3)
    jc = f'<w:jc w:val="{val}"/>'
    body = re.sub(r"\s*<w:jc\b[^>]*/>", "", body)  # drop any existing jc
    if "<w:pPr>" in body:
        body = body.replace("</w:pPr>", jc + "</w:pPr>", 1)
    else:
        ppr = f"<w:pPr>{jc}</w:pPr>"
        if "<w:rPr>" in body:  # pPr must precede rPr
            body = body.replace("<w:rPr>", ppr + "<w:rPr>", 1)
        else:
            body = body + ppr
    print(f"  {style_id} -> jc={val}")
    return xml[: m.start()] + head + body + tail + xml[m.end():]


def set_default_spacing_after(xml: str, twips: int) -> str:
    """Patch w:after on the document-wide paragraph default, which every body
    style inherits. Twips: 20 per point, so 120 == 6pt."""
    def repl(m: re.Match) -> str:
        return re.sub(r'w:after="\d+"', f'w:after="{twips}"', m.group(0))

    patched, n = re.subn(r"<w:pPrDefault>.*?</w:pPrDefault>", repl, xml, count=1, flags=re.S)
    if n:
        print(f"  docDefaults -> spacing after={twips} twips ({twips / 20:g}pt)")
    else:
        print("  WARN: pPrDefault not found, spacing left alone")
    return patched


def set_page_setup(xml: str) -> str:
    """Give the body section an explicit A4 page size and margins. Both elements
    are inserted at the START of w:sectPr, which is where the schema requires
    them (pgSz and pgMar precede footnotePr)."""
    pg = (
        f'<w:pgSz w:w="{PAGE_W}" w:h="{PAGE_H}"/>'
        f'<w:pgMar w:top="{MARGIN}" w:right="{MARGIN}" w:bottom="{MARGIN}" '
        f'w:left="{MARGIN}" w:header="708" w:footer="708" w:gutter="0"/>'
    )
    xml = re.sub(r"\s*<w:pgSz\b[^>]*/>|\s*<w:pgMar\b[^>]*/>", "", xml)
    patched, n = re.subn(r"(<w:sectPr\b[^>]*>)", r"\1" + pg, xml, count=1)
    if n:
        print(f"  page setup -> A4, {MARGIN / 567:.1f}cm margins")
    else:
        print("  WARN: sectPr not found, page setup left alone")
    return patched


def main() -> None:
    src = default_reference_docx()
    zin = zipfile.ZipFile(io.BytesIO(src))
    styles = zin.read(STYLES_PATH).decode("utf-8")
    document = set_page_setup(zin.read(DOCUMENT_PATH).decode("utf-8"))

    styles = set_style_jc(styles, "Normal", "both")
    for sid in ("Figure", "CaptionedFigure", "ImageCaption"):
        styles = set_style_jc(styles, sid, "center")
    styles = set_default_spacing_after(styles, 120)

    buf = io.BytesIO()
    with zipfile.ZipFile(buf, "w", zipfile.ZIP_DEFLATED) as zout:
        replacements = {STYLES_PATH: styles, DOCUMENT_PATH: document}
        for item in zin.infolist():
            new = replacements.get(item.filename)
            data = new.encode("utf-8") if new is not None else zin.read(item.filename)
            zout.writestr(item, data)

    out = pathlib.Path(__file__).resolve().parent.parent / "assets" / "reference-paper.docx"
    with open(out, "wb") as fh:
        fh.write(buf.getvalue())
    print(f"Wrote {out}")


if __name__ == "__main__":
    main()
