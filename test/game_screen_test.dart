import 'package:flutter/material.dart';

import 'package:erumind/data/models/answer_result.dart';
import 'package:erumind/data/models/category.dart';
import 'package:erumind/data/models/question.dart';
import 'package:erumind/data/repositories/question_repository.dart';
import 'package:erumind/features/game/logic/game_controller.dart';
import 'package:erumind/features/game/presentation/game_screen.dart';
import 'package:erumind/services/storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_storage.dart';

class _FakeRepo implements QuestionRepository {
  @override
  Future<List<Category>> getCategories() async => const [];

  @override
  Future<List<Question>> getQuestions({String? categoryId, int? limit}) async =>
      const [
        Question(
          id: 'q1',
          categoryId: 'science',
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
  // Open Hive outside the test body: openBox does real file I/O, which never
  // completes inside testWidgets' fake-async zone.
  late StorageService storage;
  setUp(() async {
    storage = await setUpTempStorage();
  });

  // Pump GameScreen in isolation (the full app now opens on the menu).
  Widget app() => ProviderScope(
        overrides: [
          questionRepositoryProvider.overrideWithValue(_FakeRepo()),
          storageServiceProvider.overrideWithValue(storage),
        ],
        child: const MaterialApp(home: GameScreen()),
      );

  testWidgets('opens on the lives-gated lobby', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.text('Ready to play?'), findsOneWidget);
    expect(find.text('Play'), findsOneWidget);
    // Five filled hearts in the lobby + one in the app-bar badge.
    expect(find.byIcon(Icons.favorite), findsNWidgets(6));
  });

  testWidgets('starts a round and scores a correct answer', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Play'));
    await tester.pumpAndSettle();

    expect(find.text('What is 2 + 2?'), findsOneWidget);
    expect(find.text('Score: 0'), findsOneWidget);

    // "4" also appears in the lives badge (a life was just spent), so target
    // the answer option specifically by its tappable tile.
    await tester.tap(find.widgetWithText(InkWell, '4'));
    await tester.pumpAndSettle();

    // One correct answer at default (medium) difficulty scores 200 points.
    expect(find.text('Score: 200'), findsOneWidget);
    // Single question -> the round can be finished from here.
    expect(find.text('See results'), findsOneWidget);
  });
}
