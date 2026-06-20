import 'package:flutter/material.dart';

import 'package:erumind/data/models/answer_result.dart';
import 'package:erumind/data/models/category.dart';
import 'package:erumind/data/models/question.dart';
import 'package:erumind/data/repositories/question_repository.dart';
import 'package:erumind/features/game/logic/game_controller.dart';
import 'package:erumind/features/game/presentation/game_screen.dart';
import 'package:erumind/l10n/app_localizations.dart';
import 'package:erumind/services/storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_storage.dart';

const _category = Category(id: 'sci', name: 'Science', colorValue: 0xFF112233);

class _FakeRepo implements QuestionRepository {
  @override
  Future<List<Category>> getCategories() async => const [_category];

  @override
  Future<List<Question>> getQuestions({String? categoryId, int? limit}) async =>
      const [
        Question(
          id: 'q1',
          categoryId: 'sci',
          text: 'What is 2 + 2?',
          options: ['3', '4', '5', '6'],
          correctIndex: 1,
        ),
      ];

  @override
  Future<AnswerResult> checkAnswer({
    required String questionId,
    required int selectedIndex,
  }) async =>
      AnswerResult(isCorrect: selectedIndex == 1, correctIndex: 1);
}

void main() {
  late StorageService storage;
  setUp(() async {
    storage = await setUpTempStorage();
  });

  Widget app() => ProviderScope(
        overrides: [
          questionRepositoryProvider.overrideWithValue(_FakeRepo()),
          storageServiceProvider.overrideWithValue(storage),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: GameScreen(),
        ),
      );

  testWidgets('opens on the lives-gated lobby', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.text('Ready to play?'), findsOneWidget);
    expect(find.text('Play'), findsOneWidget);
  });

  testWidgets('a Momentum run: spin, answer, then decide', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    // Start the run -> the wheel.
    await tester.tap(find.text('Play'));
    await tester.pumpAndSettle();
    expect(find.text('Spin'), findsOneWidget);

    // Spin -> the wheel animates and lands on a category, loading a question.
    await tester.tap(find.text('Spin'));
    await tester.pumpAndSettle();
    expect(find.text('What is 2 + 2?'), findsOneWidget);

    // Answer correctly -> the bank/risk decision appears. ("4" is also in the
    // lives badge, so target the option tile.)
    await tester.tap(find.widgetWithText(InkWell, '4'));
    await tester.pumpAndSettle();

    expect(find.text('Bank'), findsOneWidget);
    expect(find.text('Risk it'), findsOneWidget);
    expect(find.text('Finish'), findsOneWidget);
  });
}
