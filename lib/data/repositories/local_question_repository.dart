import '../models/answer_result.dart';
import '../models/category.dart';
import '../models/question.dart';
import '../sources/local_question_source.dart';
import 'question_repository.dart';

/// Single-player [QuestionRepository] backed by bundled assets.
///
/// Answer validation happens locally here. The multiplayer implementation
/// will instead call a Cloud Function, but the game core won't notice the
/// difference because both honour the same [QuestionRepository] contract.
class LocalQuestionRepository implements QuestionRepository {
  LocalQuestionRepository({LocalQuestionSource? source})
      : _source = source ?? LocalQuestionSource();

  final LocalQuestionSource _source;

  // Cache questions by id so checkAnswer is O(1) and avoids re-reading.
  Map<String, Question>? _byId;

  Future<Map<String, Question>> _index() async {
    final cached = _byId;
    if (cached != null) return cached;

    final questions = await _source.loadQuestions();
    final map = {for (final q in questions) q.id: q};
    _byId = map;
    return map;
  }

  @override
  Future<List<Category>> getCategories() => _source.loadCategories();

  @override
  Future<List<Question>> getQuestions({String? categoryId, int? limit}) async {
    final all = await _source.loadQuestions();
    var result = categoryId == null
        ? all
        : all.where((q) => q.categoryId == categoryId).toList();
    if (limit != null && limit < result.length) {
      result = result.sublist(0, limit);
    }
    return result;
  }

  @override
  Future<AnswerResult> checkAnswer({
    required String questionId,
    required int selectedIndex,
  }) async {
    final index = await _index();
    final question = index[questionId];
    if (question == null) {
      throw ArgumentError.value(questionId, 'questionId', 'Unknown question');
    }
    final correctIndex = question.correctIndex;
    if (correctIndex == null) {
      throw StateError('Question $questionId has no local correct answer');
    }
    return AnswerResult(
      isCorrect: selectedIndex == correctIndex,
      correctIndex: correctIndex,
    );
  }
}
