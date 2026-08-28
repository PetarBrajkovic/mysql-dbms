# Starting a new topic

Every seminar paper in this course shares the same process and differs only in subject matter. This
folder holds the starting files for the subject-matter half; everything else already exists one level
up and does not get copied.

## Scaffold it

```powershell
# from the course root
.\tools\new-topic.ps1 -Name "Tema 2. - Transakcije i konkurentnost" -Slug transakcije
```

That creates the folder, the directory skeleton the teach skill expects
(`lessons/`, `reference/`, `learning-records/`, `examples/`, `figures/`, `tools/`, `.scratch/<slug>/`),
and every template below under its real name, with `{Topic}` and `<topic>` substituted.

## Then, in the first session

1. **`MISSION.md` first.** If you start `/teach` without one, the agent will interview you before
   teaching anything, which is the correct behaviour — a bad mission is worse than no mission.
2. **Lock `GLOSSARY.md`.** The terminology and the chapter skeleton get decided once, deliberately,
   before any chapter is written. This is the single highest-value thing you do up front: it is what
   stops a word choice from having to be fixed across eight chapters later.
3. **Set the title** in `naslovna.md` (three OpenXML runs) and `rad.md`.
4. **Add `mysql-credentials.cnf`** if the topic needs a live server. Gitignored, never passed as a
   CLI argument. The scaffolder does not create it, because it holds a password.

## What is NOT copied, and why

| | |
|---|---|
| `assets/` | Shared, at the course level, so all three papers look like one course. Lessons link `../../assets/lesson.css` — **two** levels up, not one. |
| `ieee.csl`, `tools/make-docx.ps1`, `make-figure.ps1`, `make-table-figure.ps1`, `build-reference-doc.py` | Shared. Run them from inside the topic folder as `..\tools\<script>.ps1`; they treat the current directory as the topic. |
| `TEACHING.md`, `WRITING.md`, `WORKFLOW.md`, `tools/FIGURES.md` | Shared process. A topic never restates these — it references them. |

A topic's own `tools/` is for `make-lessonNN-*.ps1` scripts written for its own figures. If one turns
out to be genuinely topic-agnostic, move it up to the shared `tools/` rather than copying it across.

## The templates

| Template | Becomes |
|---|---|
| `MISSION.md` | `MISSION.md` |
| `NOTES.md` | `NOTES.md` |
| `RESOURCES.md` | `RESOURCES.md` |
| `rad.md` | `rad.md` |
| `naslovna.md` | `naslovna.md` |
| `gitignore` | `.gitignore` |
| `learning-records-README.md` | `learning-records/README.md` |
| `figures-README.md` | `figures/README.md` |

`GLOSSARY.md` and `references.bib` are generated as stubs by the scaffolder rather than templated.
