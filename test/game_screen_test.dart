import 'package:erumind/app.dart';
import 'package:erumind/data/models/answer_result.dart';
import 'package:erumind/data/models/category.dart';
import 'package:erumind/data/models/question.dart';
import 'package:erumind/data/repositories/question_repository.dart';
import 'package:erumind/features/game/logic/game_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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
  testWidgets('shows a question and scores a correct answer', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          questionRepositoryProvider.overrideWithValue(_FakeRepo()),
        ],
        child: const EruMindApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('What is 2 + 2?'), findsOneWidget);
    expect(find.text('Score: 0'), findsOneWidget);

    await tester.tap(find.text('4'));
    await tester.pumpAndSettle();

    expect(find.text('Score: 1'), findsOneWidget);
    // Single question -> the round can be finished from here.
    expect(find.text('See results'), findsOneWidget);
  });
}
