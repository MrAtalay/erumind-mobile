import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/category.dart';
import '../../../data/repositories/local_question_repository.dart';
import '../../../data/repositories/question_repository.dart';
import '../../../features/lives/logic/lives_controller.dart';
import '../../../features/mastery/logic/crowns.dart';
import '../../../services/storage_service.dart';
import 'game_state.dart';
import 'scoring.dart';

/// Provides the active [QuestionRepository] implementation.
///
/// Today it's the local (single-player) one. When multiplayer lands we swap
/// this single line for the Firestore-backed repository and nothing else in
/// the game core changes — that's the whole point of the interface seam.
final questionRepositoryProvider = Provider<QuestionRepository>((ref) {
  return LocalQuestionRepository();
});

/// The categories shown on the wheel.
final categoriesProvider = FutureProvider<List<Category>>((ref) {
  return ref.read(questionRepositoryProvider).getCategories();
});

/// Drives a "Momentum" run: spin the wheel for a category, answer one question,
/// then bank the pot or risk it for a bigger multiplier. A wrong answer loses
/// the unbanked pot and ends the run; the banked total is the final score.
class GameController extends AsyncNotifier<GameState> {
  QuestionRepository get _repo => ref.read(questionRepositoryProvider);
  StorageService get _storage => ref.read(storageServiceProvider);

  /// Questions already asked this run, so a run doesn't repeat one.
  final Set<String> _asked = {};

  @override
  Future<GameState> build() async => const GameState.lobby();

  /// Spends one life and begins a run at the wheel. Returns false (state
  /// untouched) when no life is available.
  Future<bool> start() async {
    if (!ref.read(livesControllerProvider).canPlay) return false;
    final consumed = await ref.read(livesControllerProvider.notifier).consumeLife();
    if (!consumed) return false;

    _asked.clear();
    state = const AsyncData(GameState(phase: RunPhase.spinning));
    return true;
  }

  /// Returns to the pre-run lobby (no life cost).
  void toLobby() => state = const AsyncData(GameState.lobby());

  /// Called by the wheel once it lands: loads a question for [category].
  Future<void> onCategorySelected(Category category) async {
    final current = state.value;
    if (current == null || current.phase != RunPhase.spinning) return;

    final all = await _repo.getQuestions(categoryId: category.id);
    final fresh = all.where((q) => !_asked.contains(q.id)).toList();
    final pool = fresh.isEmpty ? all : fresh;
    final question = (pool.toList()..shuffle()).first;
    _asked.add(question.id);

    state = AsyncData(current.copyWith(
      phase: RunPhase.question,
      category: category,
      question: question,
      clearAnswer: true,
    ));
  }

  /// Records the player's choice for the current question.
  Future<void> answer(int selectedIndex) async {
    final current = state.value;
    if (current == null ||
        current.phase != RunPhase.question ||
        current.question == null) {
      return;
    }

    final result = await _repo.checkAnswer(
      questionId: current.question!.id,
      selectedIndex: selectedIndex,
    );

    if (result.isCorrect) {
      final gained = (current.question!.difficulty.points * current.multiplier)
          .round();
      final nextStep =
          (current.multiplierStep + 1).clamp(0, GameState.multiplierCurve.length - 1);

      // Grow category mastery; earning the crown exactly at the threshold.
      final category = current.category!;
      final mastery = await _storage.incrementMastery(category.id);
      final justEarnedCrown = mastery == ref.read(crownThresholdProvider);
      final newCrowns = justEarnedCrown
          ? [...current.newCrowns, category.name]
          : current.newCrowns;

      state = AsyncData(current.copyWith(
        phase: RunPhase.decision,
        selectedIndex: selectedIndex,
        lastResult: result,
        pot: current.pot + gained,
        multiplierStep: nextStep,
        correctCount: current.correctCount + 1,
        newCrowns: newCrowns,
      ));
    } else {
      // Wrong: the unbanked pot is lost and the run is over (shown on decision).
      state = AsyncData(current.copyWith(
        phase: RunPhase.decision,
        selectedIndex: selectedIndex,
        lastResult: result,
        pot: 0,
      ));
    }
  }

  /// Secures the pot, resets the multiplier, and spins again. Only valid after
  /// a correct answer.
  void bank() {
    final s = state.value;
    if (!_canDecideAfterCorrect(s)) return;
    state = AsyncData(s!.copyWith(
      phase: RunPhase.spinning,
      banked: s.banked + s.pot,
      pot: 0,
      multiplierStep: 0,
      clearQuestion: true,
    ));
  }

  /// Keeps the pot at risk, grows the multiplier, and spins again. Only valid
  /// after a correct answer.
  void risk() {
    final s = state.value;
    if (!_canDecideAfterCorrect(s)) return;
    state = AsyncData(s!.copyWith(
      phase: RunPhase.spinning,
      clearQuestion: true,
    ));
  }

  /// Ends the run: banks any remaining pot and records the score. Used both by
  /// "Finish" (after a correct answer) and "See results" (after a wrong one).
  Future<void> endRun() async {
    final s = state.value;
    if (s == null || s.phase != RunPhase.decision) return;
    final settled = s.copyWith(banked: s.banked + s.pot, pot: 0);
    final isNewBest = await _storage.recordRound(settled.banked);
    state = AsyncData(settled.copyWith(
      phase: RunPhase.finished,
      bestScore: _storage.bestScore,
      isNewBest: isNewBest,
    ));
  }

  bool _canDecideAfterCorrect(GameState? s) =>
      s != null &&
      s.phase == RunPhase.decision &&
      (s.lastResult?.isCorrect ?? false);
}

final gameControllerProvider =
    AsyncNotifierProvider<GameController, GameState>(GameController.new);
