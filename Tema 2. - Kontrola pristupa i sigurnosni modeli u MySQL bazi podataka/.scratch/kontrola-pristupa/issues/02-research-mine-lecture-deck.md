# Research: mine the lecture deck for required content and Serbian terminology

Type: research
Status: open

## Question

The professor's own material is the paper's structural spine, and the Serbian terminology should
match what was taught rather than being invented. **Use the `pdf-reader` skill** — the user requires
it for every PDF in this project.

Read, in `C:\Faks\Sistemi Baza\Predavanja\`:
- `06_Sigurnost 2016.pdf` — **the** deck for this topic, read in full.
- `04_Tuning 2016.pdf` — skim only, for anything touching users, privileges or workload isolation.

Tema 1 ruled `06_Sigurnost` out of scope and never opened it, so nothing is known about its contents
yet. That is the first thing to establish.

Produce a memo at `../research/02-lecture-deck.md` answering:
1. **The Serbian term list as the deck uses it** — the professor's own words for privilege, grant,
   role, access control, authentication, authorization, audit, discretionary/mandatory access
   control, and anything else the deck names. This seeds `GLOSSARY.md` (ticket 09).
2. **Which of the professor's nine bullets the deck actually backs**, slide by slide, precisely
   enough to locate the corresponding passage in Ramakrishnan & Gehrke — the deck itself is
   **never cited** (`../../WORKFLOW.md` rule 7), so every deck-backed claim needs a published origin.
3. **The gaps.** A 2016 deck predates MySQL 8.0 roles entirely, so RBAC-in-MySQL, dynamic privileges,
   `partial_revokes`, `caching_sha2_password` and every modern audit option are certainly missing.
   Name what is missing so the map knows which chapters rest **entirely** on external sources — this
   was the single most useful thing ticket 07 produced on Tema 1.
4. Whether the deck teaches the classical models (DAC / MAC / Bell-LaPadula / RBAC) and at what
   depth, since that decides how much of ticket 07's theory research the paper actually needs.
