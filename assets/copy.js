/* Shared across every lesson/reference page: adds a small clipboard-icon
   button to code blocks the reader is meant to run — mark those with
   class="run" on the <pre> (e.g. <pre class="sql run">). Blocks that just
   quote source or show sample output (<pre class="out">, or a plain
   <pre class="sql"> without "run") stay plain text with no button, so they
   read as prose rather than looking executable.
   Link with <script src="../assets/copy.js"></script>.
   Button styling lives in assets/lesson.css (.copy-btn / .codewrap). */
document.addEventListener('DOMContentLoaded', function () {
  var ICON_COPY = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" '
    + 'stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">'
    + '<rect x="9" y="9" width="13" height="13" rx="2" ry="2"></rect>'
    + '<path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"></path></svg>';
  var ICON_OK = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" '
    + 'stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">'
    + '<polyline points="20 6 9 17 4 12"></polyline></svg>';
  var ICON_ERR = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" '
    + 'stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">'
    + '<line x1="18" y1="6" x2="6" y2="18"></line><line x1="6" y1="6" x2="18" y2="18"></line></svg>';

  document.querySelectorAll('pre.run').forEach(function (pre) {
    // Wrap the <pre> so the button can be positioned in its top-right corner.
    var wrap = document.createElement('div');
    wrap.className = 'codewrap';
    pre.parentNode.insertBefore(wrap, pre);
    wrap.appendChild(pre);

    var btn = document.createElement('button');
    btn.type = 'button';
    btn.className = 'copy-btn';
    btn.title = 'Kopiraj kod';
    btn.setAttribute('aria-label', 'Kopiraj kod');
    btn.innerHTML = ICON_COPY;
    wrap.appendChild(btn);

    function flash(icon, cls, label) {
      btn.innerHTML = icon;
      btn.classList.remove('ok', 'err');
      btn.classList.add(cls);
      btn.title = label;
      setTimeout(function () {
        btn.innerHTML = ICON_COPY;
        btn.classList.remove('ok', 'err');
        btn.title = 'Kopiraj kod';
      }, 1500);
    }

    btn.addEventListener('click', function () {
      var code = pre.innerText;
      if (navigator.clipboard && navigator.clipboard.writeText) {
        navigator.clipboard.writeText(code).then(function () { flash(ICON_OK, 'ok', 'Kopirano!'); })
          .catch(function () { legacyCopy(); });
      } else {
        legacyCopy();
      }
      function legacyCopy() {
        // Fallback for browsers/contexts where the async clipboard API is blocked.
        var ta = document.createElement('textarea');
        ta.value = code;
        ta.style.position = 'fixed'; ta.style.opacity = '0';
        document.body.appendChild(ta); ta.select();
        try { document.execCommand('copy'); flash(ICON_OK, 'ok', 'Kopirano!'); }
        catch (e) { flash(ICON_ERR, 'err', 'Greška'); }
        document.body.removeChild(ta);
      }
    });
  });
});
