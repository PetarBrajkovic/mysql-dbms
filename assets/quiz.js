/* Shared across every lesson: turns a `.quiz` block into a self-graded,
   multiple-choice check with immediate per-question feedback. Markup contract:

   <div class="quiz">
     <p>intro line</p>
     <div class="q" data-correct="1">                  <!-- 0-based index of the correct label -->
       <p class="stem">1. Question text?</p>
       <label><input type="radio"> Option A</label>
       <label><input type="radio"> Option B</label>     <!-- this one is correct -->
       <label><input type="radio"> Option C</label>
       <label><input type="radio"> Option D</label>
       <p class="why">One line on why that's the answer.</p>
     </div>
     ... more .q blocks ...
     <p class="quiz-score">Rezultat: <span class="got">0</span> / <span class="total">0</span></p>
   </div>

   Radio `name` attributes are assigned here at runtime, so lesson authors never have to hand-manage
   uniqueness across questions. Styling lives in assets/lesson.css (.quiz / .q / .why / .quiz-score).
   Link with <script src="../assets/quiz.js"></script>. */
document.addEventListener('DOMContentLoaded', function () {
  document.querySelectorAll('.quiz').forEach(function (quiz, quizIndex) {
    var questions = quiz.querySelectorAll('.q');
    var score = 0;
    var gotEl = quiz.querySelector('.quiz-score .got');
    var totalEl = quiz.querySelector('.quiz-score .total');
    if (totalEl) totalEl.textContent = questions.length;

    questions.forEach(function (q, qIndex) {
      var correct = parseInt(q.dataset.correct, 10);
      var labels = q.querySelectorAll('label');
      var name = 'quiz' + quizIndex + '-q' + qIndex;

      labels.forEach(function (label, optIndex) {
        var input = label.querySelector('input[type="radio"]');
        input.name = name;

        input.addEventListener('change', function () {
          if (q.classList.contains('answered')) return;
          q.classList.add('answered');

          var right = optIndex === correct;
          if (right) {
            score++;
            if (gotEl) gotEl.textContent = score;
          }
          q.classList.add(right ? 'q--right' : 'q--wrong');

          labels.forEach(function (otherLabel, otherIndex) {
            otherLabel.querySelector('input').disabled = true;
            if (otherIndex === correct) otherLabel.classList.add('correct');
            else if (otherIndex === optIndex) otherLabel.classList.add('wrong');
          });

          var why = q.querySelector('.why');
          if (why) why.classList.add('show');
        });
      });
    });
  });
});
