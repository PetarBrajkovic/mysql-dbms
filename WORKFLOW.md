# How to work through a paper in this course

A short operating manual, shared by every topic. Installation of the subject's own tooling (a
database server, a runtime, whatever the topic needs) is a one-time thing you do yourself and is not
covered here.

---

## Rule zero: start Claude from the TOPIC folder

```
cd "C:\Faks\Sistemi Baza\Tema 1. - Obrada upita (query processing) u MySQL"
claude
```

This matters. The `teach` skill treats your **current directory** as its workspace and will scatter
`MISSION.md`, `lessons/` and `learning-records/` wherever you launch it. Each topic gets its own
folder so its subject matter stays separate; the shared process layer one level up
(`TEACHING.md`, `WRITING.md`, `assets/`, `tools/`) is found from there automatically. Git is one
repository at the course level and works fine from inside a topic folder.

---

## The per-chapter loop

One chapter per session. This is the loop you run for every chapter of every paper.

**Step 1 - Learn it.** Invoke the teach skill yourself; the agent cannot launch it for you (it is
marked `disable-model-invocation: true`).

```
/teach <topic>
```

This is a personal wrapper (`~/.claude/skills/teach/SKILL.md`) around `mattpocock-skills:teach` —
same mechanics, but the lesson ends with a self-graded multiple-choice quiz instead of open recall
cards. Use `/teach`, not `/mattpocock-skills:teach`.

You get a short HTML lesson in `lessons/`, which opens in your browser. Work through it, finishing
with its quiz. **Ask follow-up questions in the chat** — the lesson is a starting point, not the whole
teaching.

What the agent reads to build that lesson is capped on purpose: the reading and writing protocols at
the top of `TEACHING.md` say which files load per lesson and where a session's leftovers go. If a
session ever feels like it is re-reading the whole workspace, that is the thing to fix.

**Step 2 - Run it yourself.** Run the chapter's examples against your own setup. Do not skip this —
it is how the chapter's content stays something you actually understand rather than something the
agent produced.

**Step 3 - Write it.** Then in the same session:

```
/mattpocock-skills:wayfinder .scratch/<topic>/map.md
```

It picks up the chapter ticket, writes the Serbian prose into `rad.md` using the
`academic-research-writer` skill under the rules in `WRITING.md`, generates the chapter's figures
(`tools/FIGURES.md`), files them alongside the example scripts, and commits.

**A chapter is done when** the lesson exists, its scripts are in `examples/`, at least one captioned
figure is in `figures/`, the Serbian text is appended to `rad.md`, and the citations are in
`references.bib`.

---

## How many lessons per chapter

Not one-to-one. Short lessons stick better than long ones. Expect roughly 7-9 lessons for a nine-chapter
paper: an introduction and a conclusion need no teaching at all, an ordinary chapter takes one lesson,
the paper's centrepiece chapter may take two or three, and two thin adjacent chapters can share one.
Each topic's own `GLOSSARY.md` chapter skeleton is where the actual split gets recorded.

---

## Rules

The rules that do not bend are in **`WRITING.md`** (paper: language, citations, figures, em dash,
lecture-deck policy) and **`TEACHING.md`** (lessons: language, quiz, components, and the reading
protocol). Do not restate them per topic.

Whatever a topic's own research has already settled belongs in that topic's
`learning-records/README.md`, under "Standing constraints" — one line per fact, pointing at the record
that settled it. Read that table rather than the records behind it, and do not re-litigate what is in
it mid-chapter.

---

## Quick reference

```powershell
# start a session (always from the topic folder)
cd "C:\Faks\Sistemi Baza\Tema N. - ..."
claude

# learn a topic
/teach <topic>

# write the chapter / advance the plan
/mattpocock-skills:wayfinder .scratch/<topic>/map.md

# export the paper to Word (title page + body + IEEE citations)
..\tools\make-docx.ps1

# see where you are
cat .scratch/<topic>/map.md
```

The map in the topic's `.scratch/` is the source of truth for what is decided and what is left. If you
forget where you are, read that first.

**Starting a new topic?** See `templates/README.md`.
