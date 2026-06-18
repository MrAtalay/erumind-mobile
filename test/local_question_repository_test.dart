import 'package:erumind/data/models/category.dart';
import 'package:erumind/data/models/question.dart';
import 'package:erumind/data/repositories/local_question_repository.dart';
import 'package:erumind/data/sources/local_question_source.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory source so tests don't touch the asset bundle.
class _FakeSource extends LocalQuestionSource {
  _FakeSource(this.questions);

  final List<Question> questions;

  @override
  Future<List<Question>> loadQuestions() async => questions;

  @override
  Future<List<Category>> loadCategories() async => const [];
}

void main() {
  final questions = [
    const Question(
      id: 'q1',
      categoryId: 'science',
      text: 'Q1',
      options: ['a', 'b', 'c', 'd'],
      correctIndex: 2,
    ),
    const Question(
      id: 'q2',
      categoryId: 'history',
      text: 'Q2',
      options: ['a', 'b', 'c', 'd'],
      correctIndex: 0,
    ),
  ];

  LocalQuestionRepository repo() =>
      LocalQuestionRepository(source: _FakeSource(questions));

  group('checkAnswer', () {
    test('returns correct=true and the right index for a correct pick',
        () async {
      final result =
          await repo().checkAnswer(questionId: 'q1', selectedIndex: 2);
      expect(result.isCorrect, isTrue);
      expect(result.correctIndex, 2);
    });

    test('returns correct=false but still exposes the right index', () async {
      final result =
          await repo().checkAnswer(questionId: 'q1', selectedIndex: 0);
      expect(result.isCorrect, isFalse);
      expect(result.correctIndex, 2);
    });

    test('throws for an unknown question id', () async {
      expect(
        () => repo().checkAnswer(questionId: 'nope', selectedIndex: 0),
        throwsArgumentError,
      );
    });
  });

  group('getQuestions', () {
    test('filters by category', () async {
      final result = await repo().getQuestions(categoryId: 'history');
      expect(result, hasLength(1));
      expect(result.single.id, 'q2');
    });

    test('respects limit', () async {
      final result = await repo().getQuestions(limit: 1);
      expect(result, hasLength(1));
    });
  });
}
