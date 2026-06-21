import 'package:erumind/data/models/answer_result.dart';
import 'package:erumind/data/models/category.dart';
import 'package:erumind/data/models/question.dart';
import 'package:erumind/data/models/question_difficulty.dart';
import 'package:erumind/data/repositories/question_repository.dart';
import 'package:erumind/features/game/logic/game_controller.dart';
import 'package:erumind/features/game/logic/game_state.dart';
import 'package:erumind/features/lives/logic/lives_controller.dart';
import 'package:erumind/features/mastery/logic/crowns.dart';
import 'package:erumind/services/audio_service.dart';
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

Future<ProviderContainer> _container({int crownThreshold = 100}) async {
  final storage = await setUpTempStorage();
  final container = ProviderContainer(overrides: [
    questionRepositoryProvider.overrideWithValue(_FakeRepo()),
    storageServiceProvider.overrideWithValue(storage),
    audioServiceProvider.overrideWithValue(const NoopAudioService()),
    // Exercise the real lives logic (the gate is off by default in debug).
    livesEnabledProvider.overrideWithValue(true),
    // High by default so unrelated tests don't accidentally earn crowns.
    crownThresholdProvider.overrideWithValue(crownThreshold),
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
  test('start does not spend a life and enters the spinning phase', () async {
    final c = await _container();
    await c.read(gameControllerProvider.future);
    final controller = c.read(gameControllerProvider.notifier);
    final before = c.read(livesControllerProvider).lives;

    expect(await controller.start(), isTrue);

    expect(_state(c).phase, RunPhase.spinning);
    expect(c.read(livesControllerProvider).lives, before);
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

  test('a wrong answer costs a life but keeps the pot and banked total',
      () async {
    final c = await _container();
    final controller = await _toQuestion(c);
    await controller.answer(0); // pot 200
    controller.bank(); // banked 200

    await controller.onCategorySelected(_category);
    await controller.answer(0); // pot 200 again, step 1
    controller.risk(); // keep it at risk

    final livesBefore = c.read(livesControllerProvider).lives;
    await controller.onCategorySelected(_category);
    await controller.answer(1); // wrong

    final s = _state(c);
    expect(s.phase, RunPhase.decision);
    expect(s.pot, 200); // preserved, not lost
    expect(s.banked, 200); // preserved
    expect(s.multiplierStep, 0); // streak broken
    expect(c.read(livesControllerProvider).lives, livesBefore - 1);
  });

  test('continuing after a non-fatal wrong answer returns to spinning',
      () async {
    final c = await _container();
    final controller = await _toQuestion(c);
    await controller.answer(1); // wrong

    controller.continueAfterWrong();

    expect(_state(c).phase, RunPhase.spinning);
  });

  test('ending the run after a wrong answer banks the preserved pot',
      () async {
    final c = await _container();
    final controller = await _toQuestion(c);
    await controller.answer(0); // pot 200
    controller.bank(); // banked 200

    await controller.onCategorySelected(_category);
    await controller.answer(1); // wrong, pot stays 0 (nothing was at risk)

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

  test('earning a crown at the threshold surfaces it on the run', () async {
    final c = await _container(crownThreshold: 2);
    await c.read(gameControllerProvider.future);
    final controller = c.read(gameControllerProvider.notifier);
    await controller.start();

    await controller.onCategorySelected(_category);
    await controller.answer(0); // mastery 1 -> no crown yet
    expect(_state(c).newCrowns, isEmpty);

    controller.risk();
    await controller.onCategorySelected(_category);
    await controller.answer(0); // mastery 2 == threshold -> crown earned

    expect(_state(c).newCrowns, contains('Science'));
    expect(c.read(storageServiceProvider).masteryFor('sci'), 2);
  });

  test('running out of time costs a life like a wrong answer', () async {
    final c = await _container();
    final controller = await _toQuestion(c);
    await controller.answer(0); // pot 200, so we can check it's preserved
    controller.risk();
    await controller.onCategorySelected(_category);
    final livesBefore = c.read(livesControllerProvider).lives;

    await controller.timeUp();

    final s = _state(c);
    expect(s.phase, RunPhase.decision);
    expect(s.pot, 200); // preserved
    expect(s.lastResult?.isCorrect, isFalse);
    expect(s.selectedIndex, isNull); // no tap -> it was a timeout
    expect(c.read(livesControllerProvider).lives, livesBefore - 1);
  });

  test('start is blocked once wrong answers exhaust all lives', () async {
    final c = await _container();
    final maxLives = c.read(livesControllerProvider).max;
    final controller = await _toQuestion(c);

    for (var i = 0; i < maxLives; i++) {
      await controller.answer(1); // wrong
      final isLastLife = i == maxLives - 1;
      if (!isLastLife) {
        controller.continueAfterWrong();
        await controller.onCategorySelected(_category);
      }
    }

    expect(c.read(livesControllerProvider).lives, 0);
    expect(await controller.start(), isFalse);
  });
}
