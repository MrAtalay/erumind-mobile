import '../../../data/models/answer_result.dart';
import '../../../data/models/question.dart';

/// Immutable snapshot of one round of play.
///
/// Plain immutable class (not freezed): this is short-lived UI state local to
/// the game feature, so we keep it dependency-free and easy to read. Domain
/// data models (Question, Category) use freezed.
class GameState {
  const GameState({
    required this.questions,
    this.currentIndex = 0,
    this.score = 0,
    this.selectedIndex,
    this.lastResult,
    this.isFinished = false,
    this.bestScore = 0,
    this.isNewBest = false,
  });

  /// The questions for this round, already ordered.
  final List<Question> questions;

  /// Index of the question currently shown.
  final int currentIndex;

  /// Number of correct answers so far.
  final int score;

  /// The option the player tapped for the current question, or null.
  final int? selectedIndex;

  /// Validation result for the current question, or null if unanswered.
  final AnswerResult? lastResult;

  /// True once the round is over (results screen).
  final bool isFinished;

  /// Persisted best score, populated when the round finishes. 0 otherwise.
  final int bestScore;

  /// True when this round set a new best score (for a "New best!" badge).
  final bool isNewBest;

  Question get currentQuestion => questions[currentIndex];

  bool get isAnswered => lastResult != null;

  bool get isLastQuestion => currentIndex == questions.length - 1;

  int get total => questions.length;

  /// Human-friendly position, e.g. "3 / 10".
  int get questionNumber => currentIndex + 1;
}
