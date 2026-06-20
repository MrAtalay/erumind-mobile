import 'package:erumind/data/models/answer_result.dart';
import 'package:erumind/data/models/category.dart';
import 'package:erumind/data/models/question.dart';
import 'package:erumind/data/models/question_difficulty.dart';
import 'package:erumind/data/repositories/question_repository.dart';
import 'package:erumind/features/game/logic/game_controller.dart';
import 'package:erumind/features/lives/logic/lives_controller.dart';
import 'package:erumind/services/storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_storage.dart';

/// Fake repository with deterministic, local validation for scoring tests.
class _FakeRepo implements QuestionRepository {
  _FakeRepo(this.questions);

  final List<Question> questions;

  @override
  Future<List<Category>> getCategories() async => const [];

  @override
  Future<List<Question>> getQuestions({String? categoryId, int? limit}) async =>
      questions;

  @override
  Future<AnswerResult> checkAnswer({
    required String questionId,
    required int selectedIndex,
  }) async {
    final q = questions.firstWhere((e) => e.id == questionId);
    return AnswerResult(
      isCorrect: selectedIndex == q.correctIndex,
      correctIndex: q.correctIndex!,
    );
  }
}

List<Question> _makeQuestions(int n) => [
      for (var i = 0; i < n; i++)
        Question(
          id: 'q$i',
          categoryId: 'science',
          text: 'Q$i',
          options: const ['a', 'b', 'c', 'd'],
          correctIndex: i % 4,
        ),
    ];

Future<ProviderContainer> _container(List<Question> questions) async {
  final storage = await setUpTempStorage();
  final container = ProviderContainer(overrides: [
    questionRepositoryProvider.overrideWithValue(_FakeRepo(questions)),
    storageServiceProvider.overrideWithValue(storage),
  ]);
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('a round is capped at questionsPerRound', () async {
    final container = await _container(_makeQuestions(25));
    await container.read(gameControllerProvider.future); // lobby
    final controller = container.read(gameControllerProvider.notifier);
    await controller.start();

    final state = container.read(gameControllerProvider).requireValue;
    expect(state.total, GameController.questionsPerRound);
  });

  test('answering every question correctly scores full marks', () async {
    final container = await _container(_makeQuestions(5));
    await container.read(gameControllerProvider.future);
    final controller = container.read(gameControllerProvider.notifier);
    await controller.start();

    while (true) {
      final state = container.read(gameControllerProvider).requireValue;
      if (state.isFinished) break;
      await controller.answer(state.currentQuestion.correctIndex!);
      await controller.next();
    }

    final finished = container.read(gameControllerProvider).requireValue;
    expect(finished.isFinished, isTrue);
    expect(finished.correctCount, 5);
    expect(finished.score, 5 * 200); // default difficulty is medium (200)
  });

  test('answering every question wrong scores zero', () async {
    final container = await _container(_makeQuestions(5));
    await container.read(gameControllerProvider.future);
    final controller = container.read(gameControllerProvider.notifier);
    await controller.start();

    while (true) {
      final state = container.read(gameControllerProvider).requireValue;
      if (state.isFinished) break;
      final wrong = (state.currentQuestion.correctIndex! + 1) % 4;
      await controller.answer(wrong);
      await controller.next();
    }

    final finished = container.read(gameControllerProvider).requireValue;
    expect(finished.score, 0);
  });

  test('a second answer on the same question is ignored', () async {
    final container = await _container(_makeQuestions(3));
    await container.read(gameControllerProvider.future);
    final controller = container.read(gameControllerProvider.notifier);
    await controller.start();

    final current = container.read(gameControllerProvider).requireValue;
    final correct = current.currentQuestion.correctIndex!;
    await controller.answer(correct);
    await controller.answer((correct + 1) % 4); // should be a no-op

    final after = container.read(gameControllerProvider).requireValue;
    expect(after.score, 200); // one correct medium-difficulty answer
    expect(after.selectedIndex, correct);
  });

  test('finishing a round records the score as a new best', () async {
    final container = await _container(_makeQuestions(3));
    await container.read(gameControllerProvider.future);
    final controller = container.read(gameControllerProvider.notifier);
    await controller.start();

    while (true) {
      final state = container.read(gameControllerProvider).requireValue;
      if (state.isFinished) break;
      await controller.answer(state.currentQuestion.correctIndex!);
      await controller.next();
    }

    final finished = container.read(gameControllerProvider).requireValue;
    expect(finished.score, 3 * 200);
    expect(finished.bestScore, 3 * 200);
    expect(finished.isNewBest, isTrue);
  });

  test('score is weighted by question difficulty', () async {
    // A single hard question scores 300, not the default-medium 200 — proving
    // the score is difficulty-weighted. (A single question avoids the shuffle
    // making order non-deterministic.)
    final container = await _container([
      Question(
        id: 'hard',
        categoryId: 'science',
        text: 'hard one',
        options: const ['a', 'b', 'c', 'd'],
        correctIndex: 0,
        difficulty: QuestionDifficulty.hard,
      ),
    ]);
    await container.read(gameControllerProvider.future);
    final controller = container.read(gameControllerProvider.notifier);
    await controller.start();

    await controller.answer(0); // hard, correct -> +300
    await controller.next();

    final finished = container.read(gameControllerProvider).requireValue;
    expect(finished.score, 300);
    expect(finished.correctCount, 1);
  });

  test('starting spends a life and is blocked when out of lives', () async {
    final container = await _container(_makeQuestions(5));
    await container.read(gameControllerProvider.future);
    final controller = container.read(gameControllerProvider.notifier);
    final maxLives = container.read(livesControllerProvider).max;

    for (var i = 0; i < maxLives; i++) {
      expect(await controller.start(), isTrue);
    }
    expect(container.read(livesControllerProvider).lives, 0);

    // No lives left: start is refused and the previous round is left intact.
    expect(await controller.start(), isFalse);
  });
}
