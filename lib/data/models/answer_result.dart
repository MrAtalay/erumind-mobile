/// Outcome of validating a single answer.
///
/// Returned by `QuestionRepository.checkAnswer(...)` so the game core never
/// has to know *where* the validation happened (local in SP, server in MP).
class AnswerResult {
  const AnswerResult({
    required this.isCorrect,
    required this.correctIndex,
  });

  /// Whether the selected option was correct.
  final bool isCorrect;

  /// The correct option index, so the UI can reveal it after answering.
  final int correctIndex;
}
