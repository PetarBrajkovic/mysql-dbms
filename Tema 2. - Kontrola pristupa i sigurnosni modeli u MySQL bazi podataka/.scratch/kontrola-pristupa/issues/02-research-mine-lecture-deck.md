# Research: mine the lecture deck for required content and Serbian terminology

Type: research
Status: resolved

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

## Answer

Findings: [`research/02-lecture-deck.md`](../research/02-lecture-deck.md)

**The deck is Ramakrishnan & Gehrke ch. 21 in Serbian** - its own PDF metadata still names R&G, and
the examples are R&G's `Sailors`/`Boats` with Dick, Justin and Horatio. So every deck-backed claim
has a clean published origin the paper already owns from Tema 1. 21 slides, read in full;
`04_Tuning` skimmed and holds nothing on access control.

**~36 Serbian terms harvested** and tabulated, including the professor's own words for concepts the
bullet list names only in English: *diskreciona kontrola pristupa (DAC)*, *obavezna kontrola
pristupa (MAC)*, *klasa sigurnosti*, *dozvola*, *visenivovske relacije*, and - the useful one -
**fine-grained access control taught as "sigurnost na nivou polja" with "proizvoljna granularnost
kontrole"**. `GRANT`, `REVOKE`, `Simple Security Property`, `*-Property` and `audit trail` are left
in English by the deck itself, so there is precedent for keeping them.

**The frame is DAC vs MAC, and MAC takes a third of the deck** (Bell-LaPadula with both properties
stated formally, the Trojan-horse argument for why DAC is insufficient, multilevel relations).
MySQL has no MAC whatsoever, which makes the professor's own material the paper's sharpest contrast
rather than a problem.

**The gap is everything MySQL.** A 2016 deck about SQL:1999 has zero coverage of MySQL 8 roles,
dynamic privileges, `partial_revokes`, authentication and password policy, audit logging beyond one
sentence, RLS, multi-tenancy, or the least-privilege principle by name. The split mirrors Tema 1's
but reversed: the *theory* chapters have deck backing, every *MySQL* chapter has none - and the
deck-backed part is only ~2 chapters' worth.

**Two topics the professor taught that are not on the bullet list**: the Trojan-horse argument
(slide 15) and statistical databases / the inference problem (slide 19). Ticket 09 decides whether
either earns space.
