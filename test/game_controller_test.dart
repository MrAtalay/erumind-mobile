import 'package:erumind/data/models/answer_result.dart';
import 'package:erumind/data/models/category.dart';
import 'package:erumind/data/models/question.dart';
import 'package:erumind/data/repositories/question_repository.dart';
import 'package:erumind/features/game/logic/game_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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

ProviderContainer _container(List<Question> questions) {
  final container = ProviderContainer(overrides: [
    questionRepositoryProvider.overrideWithValue(_FakeRepo(questions)),
  ]);
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('a round is capped at questionsPerRound', () async {
    final container = _container(_makeQuestions(25));
    final state = await container.read(gameControllerProvider.future);
    expect(state.total, GameController.questionsPerRound);
  });

  test('answering every question correctly scores full marks', () async {
    final container = _container(_makeQuestions(5));
    await container.read(gameControllerProvider.future);
    final controller = container.read(gameControllerProvider.notifier);

    while (true) {
      final state = container.read(gameControllerProvider).requireValue;
      if (state.isFinished) break;
      await controller.answer(state.currentQuestion.correctIndex!);
      controller.next();
    }

    final finished = container.read(gameControllerProvider).requireValue;
    expect(finished.isFinished, isTrue);
    expect(finished.score, 5);
  });

  test('answering every question wrong scores zero', () async {
    final container = _container(_makeQuestions(5));
    await container.read(gameControllerProvider.future);
    final controller = container.read(gameControllerProvider.notifier);

    while (true) {
      final state = container.read(gameControllerProvider).requireValue;
      if (state.isFinished) break;
      final wrong = (state.currentQuestion.correctIndex! + 1) % 4;
      await controller.answer(wrong);
      controller.next();
    }

    final finished = container.read(gameControllerProvider).requireValue;
    expect(finished.score, 0);
  });

  test('a second answer on the same question is ignored', () async {
    final container = _container(_makeQuestions(3));
    await container.read(gameControllerProvider.future);
    final controller = container.read(gameControllerProvider.notifier);

    final current = container.read(gameControllerProvider).requireValue;
    final correct = current.currentQuestion.correctIndex!;
    await controller.answer(correct);
    await controller.answer((correct + 1) % 4); // should be a no-op

    final after = container.read(gameControllerProvider).requireValue;
    expect(after.score, 1);
    expect(after.selectedIndex, correct);
  });
}
