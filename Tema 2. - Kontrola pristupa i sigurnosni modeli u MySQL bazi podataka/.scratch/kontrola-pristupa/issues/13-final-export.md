# Final export, bibliography, and consistency pass

Type: task
Status: open
Blocked by: 12

## Question

The last ticket. **It is also blocked by every chapter ticket**, which do not exist yet — they
graduate from the map's fog when ticket 09 locks the skeleton. Wire them into this ticket's
`Blocked by` line at that point.

When every chapter is written:
1. **Bibliography**: every entry cited at least once, every citation resolving to an entry, no dead
   links, IEEE rendering correct. Note Tema 1's finding — `dev.mysql.com` returns 403 to plain
   fetches because it blocks bots, which is not a dead link; check through a browser-shaped fetch
   before deleting anything.
2. **Terminology sweep** across every chapter against this topic's `GLOSSARY.md`. Record accepted
   divergences rather than triggering a six-file rename for a wobble no reader notices.
3. **Figures**: numbered without gaps, every one captioned, every one referenced by number in the
   text, every one with an explicit width chosen for readability. Tema 1 found eight unreferenced
   figures and three unsized ones at this stage — look for exactly that.
4. **Export** with `..\tools\make-docx.ps1` and measure the rendered page count against the soft
   ~20–25 target. If it is over, that is information, not an emergency: the map's length policy
   forbids shrinking unreadable figures to buy a page.
5. **Hand off what only the user can do**: reading the finished paper end to end (which is also
   defense preparation), setting the body's proofing language to Serbian (Latin) in Word, and pasting
   the faculty seals into the title page. Once he has hand-finished the DOCX, **the file is no longer
   reproducible from `rad.md`** — record that in `NOTES.md` and never re-run the export without
   asking, exactly as on Tema 1.
6. Commit and push.
