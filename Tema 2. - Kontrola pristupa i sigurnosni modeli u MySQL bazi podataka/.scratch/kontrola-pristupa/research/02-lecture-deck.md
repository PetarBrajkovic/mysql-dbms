# Research memo 02 — the lecture deck: what it teaches, what it names, what it leaves out

Source: `../../../Predavanja/06_Sigurnost 2016.pdf`, 21 slides, read in full with `pdf-reader`
(text extraction; no page needed rendering — the deck has no equations and only one table).
`04_Tuning 2016.pdf` was skimmed for privilege/user content and has **none** — it is about physical
design and workload tuning, and nothing in it touches access control.

## Summary — the three findings that matter

1. **The deck is Ramakrishnan & Gehrke, chapter 21, in Serbian.** Its PDF metadata still carries
   `author: Raghu Ramakrishnan and Johannes Gehrke` and `title: Relational Query Optimization`
   (a copy-paste leftover from the deck it was built from), and the examples are R&G's own
   `Sailors` / `Boats` schema with Dick, Justin, Horatio, Yuppy and Dustin. Every deck-backed claim
   in the paper therefore has a clean, already-owned published origin: **R&G 3rd ed., ch. 21
   "Security and Authorization"** — the same book Tema 1 already cites, so `references.bib` starts
   with its anchor entry for free.
2. **The professor's frame is DAC vs MAC, and MAC gets a third of the deck.** Slides 14–18 teach
   Bell–LaPadula, security classes, clearances, the Trojan-horse argument for why DAC is not enough,
   and multilevel relations. This is a real constraint on the paper's shape: a paper that is only
   *"here are MySQL's GRANT statements"* does not answer the course this deck belongs to. MySQL has
   **no MAC at all**, which turns out to be an asset — it is the paper's sharpest contrast, and it is
   the professor's own material.
3. **The deck predates every MySQL-specific thing the paper is about**, so chapters 3 onward rest
   entirely on external primary sources. It is a 2016 deck about SQL:1999 and Oracle-flavoured
   `CREATE USER ... DEFAULT TABLESPACE`; there is no MySQL in it anywhere.

---

## 1. The Serbian term list, as the deck itself uses it

This is the professor's own vocabulary and it is the default for `GLOSSARY.md` (ticket 09). Deviate
only with a recorded reason.

| Concept | The deck's Serbian term |
|---|---|
| Database security | sigurnost kod baza podataka |
| Unauthorized / malicious actions | neovlašćene ili zlonamerne radnje |
| User identification | identifikacija korisnika |
| Authorization, access rights | ovlašćenja i prava pristupa |
| Confidentiality | tajnost |
| Integrity | integritet |
| Availability | dostupnost |
| Access control | kontrola pristupa |
| Access policy | politika pristupa |
| Security mechanism | mehanizam sigurnosti |
| Discretionary access control | diskreciona kontrola pristupa (DAC) |
| Mandatory access control | obavezna kontrola pristupa (MAC) |
| Privilege / access right | privilegija / pravo pristupa |
| Granting and revoking rights | dodela i oduzimanje prava |
| Object (table, view) | objekat (tabela, pogled) |
| Subject (user, application) | subjekat (korisnik, korisnička aplikacija) |
| Owner / creator | vlasnik / kreator |
| View | pogled |
| Role | uloga |
| Role-based authorization | Role-Based autorizacija |
| Authorization ID | ID autorizacije (authorization ID) |
| Tuple / row | torka / vrsta |
| Column | kolona |
| Foreign key | strani ključ |
| Field-level security | sigurnost na nivou polja |
| Granularity of control | granularnost kontrole |
| Security class | klasa sigurnosti |
| Clearance | dozvola |
| Simple Security Property | Simple Security Property (kept in English) |
| \*-Property | \*-Property (kept in English) |
| Multilevel relations | višenivovske relacije |
| Statistical database | statistička baza podataka |
| Aggregate query | agregirani upit |
| Database administrator | administrator baze podataka (DBA) |
| Audit trail | audit trail, glossed as *istorija pristupa korisnika bazi podataka* |

**Three terminology observations worth carrying into ticket 09.**

- The deck says **"diskreciona"**, not *diskrecionaÂ­/diskrecijska*, and **"obavezna"** for MAC — with
  the English in parentheses on first use. That is exactly the convention Tema 1 settled on
  independently, so it transfers.
- The deck **never translates** `Simple Security Property`, `*-Property`, `GRANT`, `REVOKE`,
  `WITH GRANT OPTION`, or `Bell-LaPadula`. Keep them in English; there is deck precedent.
- **`audit trail` is left in English and glossed**, not translated. The one place the deck touches
  auditing (slide 20) writes *"izvršava audit trail, ili istoriju pristupa korisnika bazi podataka"*.
  That gloss is a ready-made first-use definition for the audit chapter.

---

## 2. Which of the professor's nine bullets the deck actually backs

The deck is **never cited** (`../../WORKFLOW.md` rule 7). Slide numbers below are for locating the
corresponding R&G passage to cite instead.

| Bullet | Deck coverage | Slides |
|---|---|---|
| Kontrola pristupa i sigurnosni modeli | **Full.** The DAC/MAC frame, policy vs mechanism, CIA triad | 2–5, 14–18 |
| Role-Based Access Control (RBAC) | **Thin but present.** SQL:1999 roles, `CREATE ROLE`, granting roles to users *and to other roles* | 10, 12 |
| Row-Level Security (RLS) | **Absent as a name**, present as an idea — multilevel relations are row-level security done by labels | 18 |
| Fine-grained access control | **Present, under another name**: *"sigurnost na nivou polja"*, done with a scalar-query view, explicitly framed as *"proizvoljna granularnost kontrole"* and admitted to be *"pomalo nezgrapno"* | 13, 8–9 |
| Privilege management | **Full.** `GRANT`/`REVOKE`, the privilege list, `WITH GRANT OPTION`, cascading revoke, ownership | 6–7 |
| Security policy enforcement | **Conceptually only**: policy specifies who is authorized, mechanism enforces it. No authentication, no password policy | 4 |
| Audit logging | **One sentence**, as a DBA responsibility | 20 |
| Least privilege princip | **Not named.** The idea is implicit in the view examples; the principle itself never appears | — |
| Multi-tenant security modeli | **Absent entirely** | — |

Two additional deck topics the bullet list does **not** mention but the professor taught, and which
are worth a decision in ticket 09:

- **The Trojan-horse argument (slide 15)** — the reason MAC exists at all, told as a story with
  Dick and Justin. It is the best available motivation for "why is DAC not enough", and it is the
  professor's own. Strong candidate for the theory chapter.
- **Statistical databases and the inference problem (slide 19)** — aggregate-only access defeated by
  asking *"how many salesmen are older than X?"* repeatedly. Genuinely interesting, entirely absent
  from the bullet list, and MySQL offers nothing for it. Probably a paragraph, not a section, but the
  call belongs to ticket 09.

---

## 3. The gaps — what the paper must source externally

The deck stops in 2016 and never mentions MySQL. **Everything below has zero deck backing** and rests
on the memos from tickets 03–07:

- MySQL's actual privilege architecture: the grant tables, the two-stage connection/request check,
  static vs dynamic privileges, the decomposition of `SUPER`.
- MySQL 8.0 roles *as implemented* — `SET ROLE`, `mandatory_roles`, `activate_all_roles_on_login`,
  and the fact that a role and a user are the same object. The deck's SQL:1999 roles are the
  standard's idea, not MySQL's implementation of it.
- `partial_revokes`, which has no analogue in the deck's grant-only model.
- Everything about authentication and policy enforcement: pluggable authentication,
  `caching_sha2_password`, `validate_password`, password expiry and history, dual passwords,
  `FAILED_LOGIN_ATTEMPTS`, `REQUIRE SSL`.
- Everything about audit logging beyond the phrase itself.
- Row-level security as a modern feature (PostgreSQL policies, Oracle VPD) and its emulation in
  MySQL by views and definers.
- Multi-tenancy in every form, including the connection-pooling collision.
- The least-privilege principle and its Saltzer–Schroeder origin.

**Consequence for the map**: the split is roughly the mirror of Tema 1's. There, chapters 1–5 had
deck backing and 6–8 had none. Here, the *theory* chapters have deck backing and every *MySQL*
chapter has none — but unlike Tema 1, the deck-backed part is only ~2 chapters' worth of material.
Budget lesson-building effort accordingly: the MySQL chapters need to work harder to ground
themselves.

---

## 4. Depth of the classical-model coverage (feeds ticket 07)

The deck teaches DAC and MAC properly and teaches **neither RBAC as a model nor ABAC at all**:

- **DAC** — defined by ownership and delegable privileges, with cascading revoke. Slides 5–9.
- **MAC** — defined by system-wide policy the user cannot change, with security classes and
  clearances. Bell–LaPadula given with both properties stated formally: read requires
  `class(S) >= class(O)`, write requires `class(S) <= class(O)`. Slides 14–18. The deck also notes
  that **most commercial systems do not support MAC** and that it survives in specialised (military)
  deployments — a claim the paper can reuse, cited to R&G.
- **RBAC** — one slide of motivation (SQL:1999, roles reflect how an organisation works, roles can be
  granted to other roles) plus one slide of syntax. **No NIST model, no sessions, no separation of
  duty, no hierarchy semantics.** So ticket 07's Sandhu/NIST research is not redundant: it supplies
  what the deck lacks, and it is what lets the paper judge MySQL's roles instead of just describing
  them.
- **ABAC** — absent. Include it only if the paper needs the contrast; the deck gives no obligation to.

**Recommendation for ticket 09**: the theory chapter should follow the deck's own order — policy vs
mechanism, then DAC, then the Trojan-horse motivation, then MAC and Bell–LaPadula — and then extend
past it with RBAC-as-a-model and least privilege from ticket 07. That keeps the professor on familiar
ground for the first chapter and earns the right to go beyond him in the second.

## Note on extraction fidelity

Slide 18's multilevel-relation table extracts with its columns in reverse order
(`class, color, bname, bid` reading right to left). The intended table is
`bid=101, bname=Salsa, color=Red, class=S` and `bid=102, bname=Pinto, color=Brown, class=C`. If that
table is ever reproduced as a figure, re-read the rendered slide rather than trusting the text dump.
