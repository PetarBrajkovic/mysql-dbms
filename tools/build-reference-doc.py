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


def main() -> None:
    src = default_reference_docx()
    zin = zipfile.ZipFile(io.BytesIO(src))
    styles = zin.read(STYLES_PATH).decode("utf-8")

    styles = set_style_jc(styles, "Normal", "both")
    for sid in ("Figure", "CaptionedFigure", "ImageCaption"):
        styles = set_style_jc(styles, sid, "center")

    buf = io.BytesIO()
    with zipfile.ZipFile(buf, "w", zipfile.ZIP_DEFLATED) as zout:
        for item in zin.infolist():
            data = styles.encode("utf-8") if item.filename == STYLES_PATH else zin.read(item.filename)
            zout.writestr(item, data)

    out = pathlib.Path(__file__).resolve().parent.parent / "assets" / "reference-paper.docx"
    with open(out, "wb") as fh:
        fh.write(buf.getvalue())
    print(f"Wrote {out}")


if __name__ == "__main__":
    main()
