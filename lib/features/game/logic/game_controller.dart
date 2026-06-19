import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/local_question_repository.dart';
import '../../../data/repositories/question_repository.dart';
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

/// Drives a single round: load questions, accept an answer, advance, restart.
///
/// We use an [AsyncNotifier] because the first thing the round does is load
/// questions asynchronously. The UI observes the resulting `AsyncValue` and
/// renders loading / error / data states accordingly.
class GameController extends AsyncNotifier<GameState> {
  static const int questionsPerRound = 10;

  QuestionRepository get _repo => ref.read(questionRepositoryProvider);
  StorageService get _storage => ref.read(storageServiceProvider);

  @override
  Future<GameState> build() => _newRound();

  Future<GameState> _newRound() async {
    final all = await _repo.getQuestions();
    final shuffled = [...all]..shuffle();
    final picked = shuffled.take(questionsPerRound).toList(growable: false);
    return GameState(questions: picked);
  }

  /// Record the player's choice for the current question.
  Future<void> answer(int selectedIndex) async {
    final current = state.value;
    if (current == null || current.isAnswered) return;

    final result = await _repo.checkAnswer(
      questionId: current.currentQuestion.id,
      selectedIndex: selectedIndex,
    );

    state = AsyncData(GameState(
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
        questions: current.questions,
        currentIndex: current.currentIndex,
        score: current.score,
        isFinished: true,
        bestScore: _storage.bestScore,
        isNewBest: isNewBest,
      ));
      return;
    }

    state = AsyncData(GameState(
      questions: current.questions,
      currentIndex: current.currentIndex + 1,
      score: current.score,
    ));
  }

  /// Start a brand new round.
  Future<void> restart() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_newRound);
  }
}

final gameControllerProvider =
    AsyncNotifierProvider<GameController, GameState>(GameController.new);
