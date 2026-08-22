/* Shared across every lesson/reference page: adds a small "Kopiraj" button to
   each block code segment (<pre>). Link with <script src="../assets/copy.js"></script>.
   Button styling lives in assets/lesson.css (.copy-btn / .codewrap). */
document.addEventListener('DOMContentLoaded', function () {
  document.querySelectorAll('pre').forEach(function (pre) {
    // Wrap the <pre> so the button can be positioned in its top-right corner.
    var wrap = document.createElement('div');
    wrap.className = 'codewrap';
    pre.parentNode.insertBefore(wrap, pre);
    wrap.appendChild(pre);

    var btn = document.createElement('button');
    btn.type = 'button';
    btn.className = 'copy-btn';
    btn.textContent = 'Kopiraj';
    wrap.appendChild(btn);

    function flash(text, ok) {
      btn.textContent = text;
      btn.classList.toggle('ok', !!ok);
      setTimeout(function () { btn.textContent = 'Kopiraj'; btn.classList.remove('ok'); }, 1500);
    }

    btn.addEventListener('click', function () {
      var code = pre.innerText;
      if (navigator.clipboard && navigator.clipboard.writeText) {
        navigator.clipboard.writeText(code).then(function () { flash('Kopirano!', true); })
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
        try { document.execCommand('copy'); flash('Kopirano!', true); }
        catch (e) { flash('Greška', false); }
        document.body.removeChild(ta);
      }
    });
  });
});
