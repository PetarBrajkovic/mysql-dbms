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

Only the 'Table' style in word/styles.xml is rewritten. The title page's raw
OpenXML layout table sets its own explicit borders (none) and is unaffected.
Added 2026-10-09 for Tema 3's Tabela 3.1.
"""
import importlib.util
import pathlib
import shutil
import sys
import zipfile

HERE = pathlib.Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location("build_reference_doc", HERE / "build-reference-doc.py")
brd = importlib.util.module_from_spec(spec)
spec.loader.exec_module(brd)

STYLES = "word/styles.xml"


def main() -> None:
    if len(sys.argv) != 2:
        sys.exit("usage: style-docx-tables.py <docx>")
    path = pathlib.Path(sys.argv[1])
    tmp = path.with_suffix(".docx.tmp")
    with zipfile.ZipFile(path) as zin, zipfile.ZipFile(tmp, "w", zipfile.ZIP_DEFLATED) as zout:
        for item in zin.infolist():
            data = zin.read(item.filename)
            if item.filename == STYLES:
                data = brd.set_table_style(data.decode("utf-8")).encode("utf-8")
            zout.writestr(item, data)
    shutil.move(tmp, path)


if __name__ == "__main__":
    main()
