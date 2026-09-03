# Decide the Serbian terminology glossary and lock the paper skeleton

Type: grilling
Status: resolved
Blocked by: 02, 03, 04, 05, 06, 07

## Question

The highest-leverage decision in this effort, exactly as it was on Tema 1: once chapters start
getting written, changing a core term means rewriting everything already committed. Do it once,
deliberately, with the research in hand.

1. **Serbian technical terminology.** For each key term decide: Serbian translation, English in
   parentheses on first use, or English kept throughout. At minimum: *access control*, *privilege*,
   *grant* / *revoke*, *role*, *RBAC*, *DAC* / *MAC*, *row-level security*, *fine-grained access
   control*, *authentication* vs *authorization* (Serbian blurs these more readily than English —
   decide it explicitly), *least privilege*, *audit log* / *audit trail*, *tenant* and
   *multi-tenancy*, *definer* / *invoker*, *policy*, *enforcement*. The deck terminology from ticket
   02 is the default; deviate only with a reason, and record the reason in
   `../terminology-rationale.md` as Tema 1 did.
2. **Lock the chapter skeleton** — the chapter list, order, and a soft page budget per chapter, now
   that research has shown what actually exists to write about. The nine bullets are **not** nine
   chapters; expect ~7 plus intro and conclusion. Specific calls this ticket must make, each fed by a
   research memo: does row-level security stand as its own chapter (ticket 04), is multi-tenancy a
   chapter or the closing synthesis (ticket 07), is least privilege a chapter or a thread (ticket
   07), and does audit logging survive as a chapter given how little is free (ticket 06).
3. **The paper's spine.** One sentence the whole paper is an argument for. The map's hunch — MySQL's
   access control is discretionary and object-based, and everything else is either composed out of
   that or is absent and named as absent — is a starting point to attack, not to adopt.
4. **Citation density and voice.** Tema 1 settled on the impersonal *se*-construction and
   per-paragraph citation; confirm or change deliberately rather than by default.
5. Write the outcome into this topic's `GLOSSARY.md`, binding on every chapter, and consult
   `serbian-grammar` while doing it.

**On closing this ticket, graduate the fog**: create the chapter tickets in one pass (create, then
wire blocking in a second pass), and clear the corresponding entry from the map's *Not yet
specified*.

## Answer

Resolved 2026-09-03, in one grilling round (all four frontier questions accepted as recommended,
no pushback).

1. **Terminology** — written into `../../GLOSSARY.md` §1. The deck's ~36 terms (memo 02) stand as
   the default; seven concepts the deck never named get fresh decisions (authentication vs.
   authorization, least privilege, audit log/trail, tenant/multi-tenancy, definer/invoker,
   policy/enforcement, RBAC spelled out). Reasoning for each in
   `../terminology-rationale.md`.
2. **Chapter skeleton locked** — 6 body chapters + intro + conclusion, `../../GLOSSARY.md` §2:
   Uvod, Klasični modeli, Sistem privilegija i uloga, FGAC i RLS, Sprovođenje politika, Audit
   logging, Multi-tenant (synthesis), Zaključak. 22.5 pages budgeted, within the ~20–25 soft target.
   RLS stays a section of ch. 4, not its own chapter (memo 04's verdict); least privilege stays a
   thread, not a chapter (memo 07's verdict); audit logging survives as its own short chapter
   (memo 06 has real content — the instruments-vs-trail argument and a live measurement); the
   Trojan-horse argument becomes ch. 2's DAC→MAC hinge; the inference problem gets one paragraph in
   ch. 2 and nothing more.
3. **The paper's spine** — adopted as charted, written into `../../GLOSSARY.md` §0: MySQL is DAC
   only, and every modern requirement on the professor's list is either composed from that or
   absent and built outside the DBMS.
4. **Citation density and voice** — confirmed unchanged from Tema 1 (impersonal *se*-construction,
   per-paragraph citation). No memo argued for a change.

**Fog graduated**: chapter tickets 14–21 created (`issues/14-uvod.md` through
`issues/21-zakljucak.md`), blocking wired to their grounding research tickets, to ticket 09 itself,
and to ticket 10 where a chapter's examples need the live sandbox. Ticket 13 (final export)
updated to block on all eight. The map's *Not yet specified* section is cleared of the chapter-list,
spine, and Trojan-horse/inference-problem entries; what remains genuinely open (comparison-system
weight, the defense angle, which claims need live verification) is unchanged by this ticket and
stays in the map.
