# How to work through this paper

A short operating manual. Installation (ticket 01) is not covered here - that is a one-time thing you
do yourself.

---

## Rule zero: start Claude from THIS folder

```
cd "C:\Faks\Sistemi Baza\Tema 1. - Obrada upita (query processing) u MySQL"
claude
```

This matters. The `teach` skill treats your **current directory** as its workspace and will scatter
`MISSION.md`, `lessons/` and `learning-records/` wherever you launch it. Tema 2 and Tema 3 get their
own folders, so everything for this topic must stay in this one. Git still works fine from here.

---

## Order of work

Do these in order. Each is one Claude session.

| Ticket | What | Who |
|---|---|---|
| 01 | Install MySQL 8.4 + Workbench + Sakila + synthetic table | **you** |
| 02 | Prove the pandoc export pipeline works | agent |
| 03 | Scaffold the workspace, write `MISSION.md` | agent |
| 08 | Lock the Serbian glossary and chapter skeleton | **you + agent** |
| 09 | Decide the figure strategy | **you + agent** |
| 10-18 | The nine chapters, one per session | **you + agent** |
| 19 | Final export to Word | agent |

Ticket 08 is the important one. It settles the Serbian terminology *before* any chapter is written,
so a word choice never has to be fixed across eight chapters later.

---

## The per-chapter loop

This is the loop you will run nine times. One chapter per session.

**Step 1 - Learn it.** Invoke the teach skill yourself; I cannot launch it for you (it is marked
`disable-model-invocation: true`).

```
/mattpocock-skills:teach EXPLAIN ANALYZE in MySQL
```

You get a short HTML lesson in `lessons/`, which opens in your browser. Work through it. **Ask
follow-up questions in the chat** - the lesson is a starting point, not the whole teaching. If
something does not click, say so and ask for it again differently.

**Step 2 - Run it yourself.** Open Workbench, run the chapter's queries against your own database.
Do not skip this. The professor wants examples and pictures, and the figures come from here.

**Step 3 - Write it.** Then in the same session:

```
/mattpocock-skills:wayfinder .scratch/obrada-upita/map.md
```

It picks up the chapter ticket, writes the Serbian prose into `rad.md` using the
`academic-research-writer` skill, files the figures and SQL, and commits.

**A chapter is done when** the lesson exists, the SQL is in `examples/`, at least one captioned figure
is in `figures/`, the Serbian text is appended to `rad.md`, and the citations are in `references.bib`.

---

## How many lessons per chapter

Not one-to-one. Short lessons stick better than long ones.

| Chapter | Lessons |
|---|---|
| 1 Uvod, 9 Zakljucak | none - you do not need teaching to write an intro |
| 2 Arhitektura, 3 Od SQL-a do plana | 1 each |
| 4 EXPLAIN | 2-3 (the big one) |
| 5 Iterator model | 1-2 |
| 6 Vektorizovano + 7 Paralelno | 1 shared |
| 8 Plan cache | 1 |

Roughly 7-9 lessons total.

---

## Rules that do not bend

1. **The paper is written with the `academic-research-writer` skill.** Every time. Not hand-written
   and tidied up afterwards.
2. **Serbian prose, written as you go.** Never draft in English intending to translate later.
3. **Every substantive chapter needs a real figure** from a query you actually ran.
4. **Citations go into `references.bib` as you use them**, never retrofitted at the end.
5. **Never invent a citation.** Research turned up two facts about the hypergraph optimizer with no
   verifiable source. Leaving a claim uncited is fine; a fabricated reference is not.

---

## Things research already settled

Do not re-litigate these mid-chapter:

- MySQL has **five** pipeline stages, and transformations live inside **resolution**.
- The **hypergraph optimizer cannot run** on your stock 8.4 build - it is compile-gated to debug
  builds. Do not plan a demo.
- MySQL does **not** vectorize, and `innodb_parallel_read_threads` does **not** speed up an ordinary
  `SELECT`.
- MySQL has **no shared plan cache**, but it does cache prepared-statement **parse trees** per
  session. Draw that line carefully in chapter 8.
- `optimizer_search_depth` defaults to **62**.

Two things still need checking against your live server once it is installed: the "estimates off by
3x" rule of thumb, and whether `explain_json_format_version = 2` works on 8.4.

---

## Quick reference

```
# start a session (always from this folder)
cd "C:\Faks\Sistemi Baza\Tema 1. - Obrada upita (query processing) u MySQL"
claude

# learn a topic
/mattpocock-skills:teach <topic>

# write the chapter / advance the plan
/mattpocock-skills:wayfinder .scratch/obrada-upita/map.md

# see where you are
cat .scratch/obrada-upita/map.md
```

The map at `.scratch/obrada-upita/map.md` is the source of truth for what is decided and what is
left. If you forget where you are, read that first.
