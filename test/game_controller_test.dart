import 'package:erumind/data/models/answer_result.dart';
import 'package:erumind/data/models/category.dart';
import 'package:erumind/data/models/question.dart';
import 'package:erumind/data/models/question_difficulty.dart';
import 'package:erumind/data/repositories/question_repository.dart';
import 'package:erumind/features/game/logic/game_controller.dart';
import 'package:erumind/features/game/logic/game_state.dart';
import 'package:erumind/features/lives/logic/lives_controller.dart';
import 'package:erumind/services/storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_storage.dart';

/// One Science category with a single medium-difficulty question (200 points,
/// correct = option 0), so the wheel/question flow is deterministic.
const _category = Category(id: 'sci', name: 'Science', colorValue: 0xFF000000);
final _question = Question(
  id: 'q1',
  categoryId: 'sci',
  text: 'Q',
  options: const ['a', 'b', 'c', 'd'],
  correctIndex: 0,
  difficulty: QuestionDifficulty.medium,
);

class _FakeRepo implements QuestionRepository {
  @override
  Future<List<Category>> getCategories() async => const [_category];

  @override
  Future<List<Question>> getQuestions({String? categoryId, int? limit}) async =>
      categoryId == null
          ? [_question]
          : [_question].where((q) => q.categoryId == categoryId).toList();

  @override
  Future<AnswerResult> checkAnswer({
    required String questionId,
    required int selectedIndex,
  }) async =>
      AnswerResult(isCorrect: selectedIndex == 0, correctIndex: 0);
}

Future<ProviderContainer> _container() async {
  final storage = await setUpTempStorage();
  final container = ProviderContainer(overrides: [
    questionRepositoryProvider.overrideWithValue(_FakeRepo()),
    storageServiceProvider.overrideWithValue(storage),
    // Exercise the real lives logic (the gate is off by default in debug).
    livesEnabledProvider.overrideWithValue(true),
  ]);
  addTearDown(container.dispose);
  return container;
}

GameState _state(ProviderContainer c) =>
    c.read(gameControllerProvider).requireValue;

/// Drives start -> spin -> question, leaving the state at an unanswered
/// question.
Future<GameController> _toQuestion(ProviderContainer c) async {
  await c.read(gameControllerProvider.future);
  final controller = c.read(gameControllerProvider.notifier);
  await controller.start();
  await controller.onCategorySelected(_category);
  return controller;
}

void main() {
  test('start spends a life and enters the spinning phase', () async {
    final c = await _container();
    await c.read(gameControllerProvider.future);
    final controller = c.read(gameControllerProvider.notifier);
    final before = c.read(livesControllerProvider).lives;

    expect(await controller.start(), isTrue);

    expect(_state(c).phase, RunPhase.spinning);
    expect(c.read(livesControllerProvider).lives, before - 1);
  });

  test('a correct answer adds difficulty-weighted points to the pot', () async {
    final c = await _container();
    final controller = await _toQuestion(c);

    await controller.answer(0);

    final s = _state(c);
    expect(s.phase, RunPhase.decision);
    expect(s.pot, 200); // medium (200) x1.0
    expect(s.multiplierStep, 1);
    expect(s.correctCount, 1);
  });

  test('banking secures the pot and resets the multiplier', () async {
    final c = await _container();
    final controller = await _toQuestion(c);
    await controller.answer(0);

    controller.bank();

    final s = _state(c);
    expect(s.phase, RunPhase.spinning);
    expect(s.banked, 200);
    expect(s.pot, 0);
    expect(s.multiplierStep, 0);
  });

  test('risking keeps the pot and grows the multiplier', () async {
    final c = await _container();
    final controller = await _toQuestion(c);
    await controller.answer(0); // pot 200, step 1

    controller.risk();
    expect(_state(c).phase, RunPhase.spinning);
    expect(_state(c).pot, 200);

    await controller.onCategorySelected(_category);
    await controller.answer(0); // +200 x1.5 = 300 -> pot 500

    final s = _state(c);
    expect(s.pot, 500);
    expect(s.multiplierStep, 2);
  });

  test('a wrong answer loses the pot but keeps the banked total', () async {
    final c = await _container();
    final controller = await _toQuestion(c);
    await controller.answer(0); // pot 200
    controller.bank(); // banked 200

    await controller.onCategorySelected(_category);
    await controller.answer(1); // wrong

    expect(_state(c).phase, RunPhase.decision);
    expect(_state(c).pot, 0);

    await controller.endRun();

    final s = _state(c);
    expect(s.phase, RunPhase.finished);
    expect(s.banked, 200);
  });

  test('finishing banks the pot and records a new best', () async {
    final c = await _container();
    final controller = await _toQuestion(c);
    await controller.answer(0); // pot 200

    await controller.endRun();

    final s = _state(c);
    expect(s.phase, RunPhase.finished);
    expect(s.banked, 200);
    expect(s.bestScore, 200);
    expect(s.isNewBest, isTrue);
  });

  test('start is blocked when out of lives', () async {
    final c = await _container();
    await c.read(gameControllerProvider.future);
    final controller = c.read(gameControllerProvider.notifier);
    final maxLives = c.read(livesControllerProvider).max;

    for (var i = 0; i < maxLives; i++) {
      expect(await controller.start(), isTrue);
    }
    expect(c.read(livesControllerProvider).lives, 0);
    expect(await controller.start(), isFalse);
  });
}
