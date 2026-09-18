# Final export, bibliography, and consistency pass

Type: task
Status: open
Blocked by: 12

## Question

The last ticket. Its blocking is rewired to the chapter tickets when ticket 09 graduates them out of
the fog; until then it hangs off ticket 12 as a placeholder.

Run the same final pass Temas 1 and 2 ran:

1. **Bibliography**: every entry cited, every citation resolving, nothing dangling. Check each URL,
   and note from both prior topics that `dev.mysql.com` and `bugs.mysql.com` return 403 to automated
   checks because of bot-blocking, which is **not** a dead link. Watch for the BibTeX bug Tema 2 hit,
   where an institution name containing `and` gets split into two authors.
2. **Figures**: numbering with no gaps, every figure captioned, every figure referenced by number in
   the text, every one explicitly sized, and the per-chapter count matching `figures/README.md`.
3. **Terminology**: every chapter against `GLOSSARY.md` §1. Divergences are judged, not auto-renamed -
   Tema 2 kept three deliberately and recorded why in `NOTES.md`. **Additionally, for this topic: a
   full Croatianism sweep** with `serbian-grammar`, since the terminology had no lecture deck to
   anchor it (`../../NOTES.md`). Also confirm `SOURCE`/`REPLICA` vocabulary is used consistently, and
   that the note explaining the older `MASTER`/`SLAVE` terms appears exactly once.
4. **Claim audit**: any claim resting on a research memo that the live topology never confirmed is
   either verified now or softened. Tema 2's final pass found that a chapter had tested a claim
   against the wrong kind of object; here, look specifically for a measurement taken on the wrong node
   or with a variable left set by a previous chapter.
5. **Reconcile Uvod against Zaključak** - the roadmap in chapter 1 must still describe the paper that
   actually got written.
6. **Export** with `../tools/make-docx.ps1`. Report page count and word count against the ~20-25 soft
   target, and confirm no figure was squeezed to hit it.
7. Commit and push, then hand over. The Word-only steps - proofing language, faculty seals, final
   polish - are the user's own, and after them the DOCX is no longer reproducible from source. See
   `NOTES.md`.
