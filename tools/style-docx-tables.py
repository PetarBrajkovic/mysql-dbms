#!/usr/bin/env python3
"""
Post-export step, called by make-docx.ps1 right after pandoc:

    python tools/style-docx-tables.py <path-to-rad.docx>

Why it exists: pandoc 3.x does NOT take the 'Table' style from --reference-doc;
it writes its own built-in definition (one rule under the header, nothing else)
into every exported docx. So the grid that build-reference-doc.py puts on
'Table' never reaches the output, and the only reliable place to apply it is
the exported file itself. The patch is the same function, imported from
build-reference-doc.py, so there is one definition of what a table looks like.

The 'Table' style in word/styles.xml is rewritten. The title page's raw OpenXML
layout table (student / mentor block) names no style, so Word gives it the
default one, 'Table', and with it the bold shaded header row. Its explicit
"no borders" already overrides the grid; to switch the header formatting off
too, a plain table style 'LayoutTable' (cell margins only, no borders, no
conditional formatting) is added to styles.xml, and every table WITHOUT a
w:tblStyle is pointed at it, inserted as the first child of its tblPr as the
schema requires. Pointing at Word's 'TableNormal' does not work: pandoc's
styles.xml does not define it, so Word falls back to the default 'Table'. A tblLook firstRow="0" was tried first
and Word ignored it in this compatibility-mode document.
Added 2026-10-09 for Tema 3's Tabela 3.1.
"""
import importlib.util
import pathlib
import re
import shutil
import sys
import zipfile

HERE = pathlib.Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location("build_reference_doc", HERE / "build-reference-doc.py")
brd = importlib.util.module_from_spec(spec)
spec.loader.exec_module(brd)

STYLES = "word/styles.xml"
DOCUMENT = "word/document.xml"
PLAIN_STYLE = '<w:tblStyle w:val="LayoutTable"/>'
PLAIN_STYLE_DEF = (
    '<w:style w:type="table" w:customStyle="1" w:styleId="LayoutTable">'
    '<w:name w:val="Layout Table"/><w:tblPr><w:tblCellMar>'
    '<w:left w:w="108" w:type="dxa"/><w:right w:w="108" w:type="dxa"/>'
    '</w:tblCellMar></w:tblPr></w:style>'
)


def add_plain_style(xml: str) -> str:
    if 'w:styleId="LayoutTable"' in xml:
        return xml
    return xml.replace("</w:styles>", PLAIN_STYLE_DEF + "</w:styles>", 1)


def unstyle_layout_tables(xml: str) -> str:
    """Tables with no w:tblStyle (raw-OpenXML layout tables) get the plain LayoutTable style."""
    def repl(m: re.Match) -> str:
        ppr = m.group(0)
        if "<w:tblStyle" in ppr:
            return ppr
        return ppr.replace("<w:tblPr>", "<w:tblPr>" + PLAIN_STYLE, 1)
    return re.sub(r"<w:tblPr>.*?</w:tblPr>", repl, xml, flags=re.S)


def main() -> None:
    if len(sys.argv) != 2:
        sys.exit("usage: style-docx-tables.py <docx>")
    path = pathlib.Path(sys.argv[1])
    tmp = path.with_suffix(".docx.tmp")
    with zipfile.ZipFile(path) as zin, zipfile.ZipFile(tmp, "w", zipfile.ZIP_DEFLATED) as zout:
        for item in zin.infolist():
            data = zin.read(item.filename)
            if item.filename == STYLES:
                data = add_plain_style(brd.set_table_style(data.decode("utf-8"))).encode("utf-8")
            elif item.filename == DOCUMENT:
                data = unstyle_layout_tables(data.decode("utf-8")).encode("utf-8")
            zout.writestr(item, data)
    shutil.move(tmp, path)


if __name__ == "__main__":
    main()
