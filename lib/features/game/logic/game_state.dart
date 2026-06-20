import '../../../data/models/answer_result.dart';
import '../../../data/models/category.dart';
import '../../../data/models/question.dart';

/// Steps of a single Momentum run.
///
/// [lobby] is the pre-run gate. A run then cycles [spinning] (pick a category
/// on the wheel) -> [question] (answer it) -> [decision] (bank or risk the pot),
/// and ends in [finished].
enum RunPhase { lobby, spinning, question, decision, finished }

/// Immutable snapshot of a Momentum run.
///
/// Scoring: a correct answer adds `difficulty points x multiplier` to the
/// at-risk [pot]. Banking moves the pot into [banked] (safe) and resets the
/// multiplier; a wrong answer loses the pot and ends the run. The final score
/// is [banked].
class GameState {
  const GameState({
    this.phase = RunPhase.lobby,
    this.category,
    this.question,
    this.selectedIndex,
    this.lastResult,
    this.banked = 0,
    this.pot = 0,
    this.multiplierStep = 0,
    this.correctCount = 0,
    this.bestScore = 0,
    this.isNewBest = false,
    this.newCrowns = const [],
  });

  const GameState.lobby() : this();

  /// The multipliers earned by consecutive correct answers without banking.
  static const List<double> multiplierCurve = [1.0, 1.5, 2.0, 2.5, 3.0];

  final RunPhase phase;

  /// Category the wheel landed on for the current question.
  final Category? category;

  /// The question currently being asked.
  final Question? question;

  /// The option the player tapped for the current question, or null.
  final int? selectedIndex;

  /// Validation result for the current question, or null if unanswered.
  final AnswerResult? lastResult;

  /// Points already secured this run (the final score).
  final int banked;

  /// At-risk points: kept on a bank, lost on a wrong answer.
  final int pot;

  /// Index into [multiplierCurve] for the current streak.
  final int multiplierStep;

  /// Correct answers so far this run.
  final int correctCount;

  /// Persisted best score, populated when the run finishes. 0 otherwise.
  final int bestScore;

  /// True when this run set a new best score (for a "New best!" badge).
  final bool isNewBest;

  /// Names of categories whose crown was earned during this run (for the
  /// results screen). Empty otherwise.
  final List<String> newCrowns;

  bool get isLobby => phase == RunPhase.lobby;
  bool get isSpinning => phase == RunPhase.spinning;
  bool get isQuestion => phase == RunPhase.question;
  bool get isDecision => phase == RunPhase.decision;
  bool get isFinished => phase == RunPhase.finished;

  /// Current multiplier, e.g. 1.5.
  double get multiplier => multiplierCurve[multiplierStep];

  /// Total at stake if the next answer is wrong (the pot).
  int get atRisk => pot;

  GameState copyWith({
    RunPhase? phase,
    Category? category,
    Question? question,
    int? selectedIndex,
    AnswerResult? lastResult,
    int? banked,
    int? pot,
    int? multiplierStep,
    int? correctCount,
    int? bestScore,
    bool? isNewBest,
    List<String>? newCrowns,
    bool clearQuestion = false,
    bool clearAnswer = false,
  }) {
    return GameState(
      phase: phase ?? this.phase,
      category: clearQuestion ? null : (category ?? this.category),
      question: clearQuestion ? null : (question ?? this.question),
      selectedIndex: clearAnswer || clearQuestion
          ? null
          : (selectedIndex ?? this.selectedIndex),
      lastResult:
          clearAnswer || clearQuestion ? null : (lastResult ?? this.lastResult),
      banked: banked ?? this.banked,
      pot: pot ?? this.pot,
      multiplierStep: multiplierStep ?? this.multiplierStep,
      correctCount: correctCount ?? this.correctCount,
      bestScore: bestScore ?? this.bestScore,
      isNewBest: isNewBest ?? this.isNewBest,
      newCrowns: newCrowns ?? this.newCrowns,
    );
  }
}
