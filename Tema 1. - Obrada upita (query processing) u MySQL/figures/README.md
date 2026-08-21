# figures/

Captioned screenshots for `rad.md`, named `NN-<chapter-slug>-MM-<what-it-shows>.png` where `NN` is
the chapter number and `MM` numbers figures within that chapter (e.g.
`04-explain-01-visual-explain.png`).

Because Pandoc does not auto-number figure captions in the DOCX export (see ticket 02), the
sequential figure number also belongs in the caption text itself wherever the image is referenced
from `rad.md`, e.g. `![Slika 4.1: ...](figures/04-explain-01-visual-explain.png)`.
