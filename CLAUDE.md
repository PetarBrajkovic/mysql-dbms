# Sistemi baza podataka — course workspace

This folder is the **shared layer** for every seminar paper in this course. Each topic gets its own
subfolder (`Tema 1. - ...`, `Tema 2. - ...`, `Tema 3. - ...`) and **that topic folder is the working
directory** — always start Claude from inside it, never from here.

The split, and the whole point of this layout: **process lives up here, subject matter lives down
there.** A topic folder holds only what is true about its own subject. Everything about *how* to
learn a topic and write it up is shared, so all three papers come out consistent and Tema 2 starts
with the process already solved.

## Shared, at this level

| | |
|---|---|
| `TEACHING.md` | how a lesson is built, and **which files to read per lesson**. Read when teaching. |
| `WRITING.md` | how the paper is written: language, voice, citations, export. Read when writing prose. |
| `WORKFLOW.md` | the per-chapter loop and the rules that do not bend. Read when asked about process. |
| `assets/` | the lesson component library: `lesson.css`, `quiz.js`, `copy.js`, `LESSON-TEMPLATE.html`, logos, the pandoc reference doc. Lessons link these as `../../assets/…`. |
| `tools/` | topic-agnostic pipeline: `make-docx.ps1`, `make-figure.ps1`, `make-table-figure.ps1`, `build-reference-doc.py`, plus `FIGURES.md`. Run them from a topic folder; they treat the current directory as the topic. |
| `templates/` | starting files for a new topic. See `templates/README.md`. |
| `ieee.csl` | citation style, shared by every paper. |
| `Predavanja/` | the course lecture decks. Learning material for every topic, **never cited** — see `WRITING.md`. |

## Topic-specific, inside a topic folder

`MISSION.md` (why this paper exists), `GLOSSARY.md` (its locked terminology and chapter skeleton),
`NOTES.md` (its own quirks), `rad.md` / `naslovna.md` / `references.bib` / `rad.docx`,
`learning-records/`, `lessons/`, `reference/`, `examples/`, `figures/`, `.scratch/`, and any
`tools/make-lessonNN-*.ps1` written for one of its figures.

## Before you read anything else

**Do not load the whole workspace.** `TEACHING.md` opens with a reading protocol naming exactly which
files a lesson needs; the topic's `learning-records/README.md` is an index built so you can skip the
records behind it. Read by pointer, not by habit.
