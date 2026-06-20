import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/local_question_repository.dart';
import '../../../data/repositories/question_repository.dart';
import '../../../features/lives/logic/lives_controller.dart';
import '../../../services/storage_service.dart';
import 'game_state.dart';

/// Provides the active [QuestionRepository] implementation.
///
/// Today it's the local (single-player) one. When multiplayer lands we swap
/// this single line for the Firestore-backed repository and nothing else in
/// the game core changes — that's the whole point of the interface seam.
final questionRepositoryProvider = Provider<QuestionRepository>((ref) {
  return LocalQuestionRepository();
});

/// Drives a single round: gate on lives, load questions, accept an answer,
/// advance, and return to the lobby.
///
/// We use an [AsyncNotifier] because loading a round is asynchronous. The app
/// opens in the [GamePhase.lobby] state; [start] spends a life and loads the
/// questions, moving into [GamePhase.playing].
class GameController extends AsyncNotifier<GameState> {
  static const int questionsPerRound = 10;

  QuestionRepository get _repo => ref.read(questionRepositoryProvider);
  StorageService get _storage => ref.read(storageServiceProvider);

  @override
  Future<GameState> build() async => const GameState.lobby();

  Future<GameState> _newRound() async {
    final all = await _repo.getQuestions();
    final shuffled = [...all]..shuffle();
    final picked = shuffled.take(questionsPerRound).toList(growable: false);
    return GameState(phase: GamePhase.playing, questions: picked);
  }

  /// Spends one life and starts a fresh round. Returns false (leaving the state
  /// untouched) when no life is available — the UI keeps showing the lobby gate
  /// with its countdown. Loads the round before spending the life so a load
  /// failure never burns a life.
  Future<bool> start() async {
    if (!ref.read(livesControllerProvider).canPlay) return false;

    final round = await AsyncValue.guard(_newRound);
    if (round.hasError) {
      state = round;
      return true;
    }

    final consumed = await ref.read(livesControllerProvider.notifier).consumeLife();
    if (!consumed) return false;

    state = round;
    return true;
  }

  /// Returns to the pre-round lobby (e.g. after a round, with no life cost).
  void toLobby() => state = const AsyncData(GameState.lobby());

  /// Record the player's choice for the current question.
  Future<void> answer(int selectedIndex) async {
    final current = state.value;
    if (current == null || !current.isPlaying || current.isAnswered) return;

    final result = await _repo.checkAnswer(
      questionId: current.currentQuestion.id,
      selectedIndex: selectedIndex,
    );

    state = AsyncData(GameState(
      phase: GamePhase.playing,
      questions: current.questions,
      currentIndex: current.currentIndex,
      score: current.score + (result.isCorrect ? 1 : 0),
      selectedIndex: selectedIndex,
      lastResult: result,
    ));
  }

  /// Move to the next question, or finish the round on the last one.
  Future<void> next() async {
    final current = state.value;
    if (current == null || !current.isAnswered) return;

    if (current.isLastQuestion) {
      // Persist the result before showing the summary so the results screen
      // reads a settled best score (no race with the async write).
      final isNewBest = await _storage.recordRound(current.score);
      state = AsyncData(GameState(
        phase: GamePhase.finished,
        questions: current.questions,
        currentIndex: current.currentIndex,
        score: current.score,
        bestScore: _storage.bestScore,
        isNewBest: isNewBest,
      ));
      return;
    }

    state = AsyncData(GameState(
      phase: GamePhase.playing,
      questions: current.questions,
      currentIndex: current.currentIndex + 1,
      score: current.score,
    ));
  }
}

final gameControllerProvider =
    AsyncNotifierProvider<GameController, GameState>(GameController.new);
