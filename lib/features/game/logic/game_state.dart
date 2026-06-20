import '../../../data/models/answer_result.dart';
import '../../../data/models/question.dart';

/// Where a round currently sits in its lifecycle.
///
/// [lobby] is the pre-round gate (shows lives + a Play button); no questions
/// are loaded yet. [playing] is an active round; [finished] is the summary.
enum GamePhase { lobby, playing, finished }

/// Immutable snapshot of one round of play.
///
/// Plain immutable class (not freezed): this is short-lived UI state local to
/// the game feature, so we keep it dependency-free and easy to read. Domain
/// data models (Question, Category) use freezed.
class GameState {
  const GameState({
    this.phase = GamePhase.lobby,
    this.questions = const [],
    this.currentIndex = 0,
    this.score = 0,
    this.correctCount = 0,
    this.selectedIndex,
    this.lastResult,
    this.bestScore = 0,
    this.isNewBest = false,
  });

  /// The pre-round lobby: no active round yet.
  const GameState.lobby() : this();

  /// Lifecycle phase of this round.
  final GamePhase phase;

  /// The questions for this round, already ordered. Empty in the lobby.
  final List<Question> questions;

  /// Index of the question currently shown.
  final int currentIndex;

  /// Difficulty-weighted points earned so far.
  final int score;

  /// Number of questions answered correctly so far (for the "x / total" line).
  final int correctCount;

  /// The option the player tapped for the current question, or null.
  final int? selectedIndex;

  /// Validation result for the current question, or null if unanswered.
  final AnswerResult? lastResult;

  /// Persisted best score, populated when the round finishes. 0 otherwise.
  final int bestScore;

  /// True when this round set a new best score (for a "New best!" badge).
  final bool isNewBest;

  bool get isLobby => phase == GamePhase.lobby;
  bool get isPlaying => phase == GamePhase.playing;
  bool get isFinished => phase == GamePhase.finished;

  Question get currentQuestion => questions[currentIndex];

  bool get isAnswered => lastResult != null;

  bool get isLastQuestion => currentIndex == questions.length - 1;

  int get total => questions.length;

  /// Human-friendly position, e.g. "3 / 10".
  int get questionNumber => currentIndex + 1;
}
