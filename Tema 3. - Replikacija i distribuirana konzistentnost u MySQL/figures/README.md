# figures/

Captioned figures for `rad.md`, named `NN-<chapter-slug>-MM-<what-it-shows>.png` where `NN` is the
chapter number and `MM` numbers figures within that chapter.

Because pandoc does not auto-number figure captions in the DOCX export, the figure number also
belongs in the caption text itself wherever the image is referenced from `rad.md`, e.g.
`![Slika 4.1: ...](figures/04-explain-01-visual-explain.png)`.

**The pipeline is shared and documented in `../../tools/FIGURES.md`** — how figures are generated,
when to write a dedicated script, the self-verifying pattern, the capture standard, sourcing rules,
and the traps already hit. This file holds only what is specific to this paper.

## Per-chapter budget (soft guidance, not a hard cap)

| Chapter | Expected | What it's for |
|---|---|---|
| 1 | 0 | |

{Total} figures total. A chapter may go over if it genuinely needs both a diagram and a live example;
this guards against one chapter swallowing every figure, it is not a quota to hit exactly.

## Dedicated scripts written for this paper

| Script | Figures it builds | What it asserts |
|---|---|---|
| `tools/make-lessonNN-<what>.ps1` | | |
