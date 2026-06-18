import '../models/answer_result.dart';
import '../models/category.dart';
import '../models/question.dart';

/// The single contract between the game core and any question source.
///
/// The game engine depends ONLY on this interface, never on a concrete
/// source. That seam is what lets single-player and multiplayer reuse the
/// exact same engine:
///   * SP  -> LocalQuestionRepository    (bundled assets/questions.json)
///   * MP  -> FirestoreQuestionRepository (later; server-side validation)
///
/// [checkAnswer] is intentionally async and returns an [AnswerResult] rather
/// than exposing the correct index up front, so the MP implementation can
/// validate on the server without ever shipping the answer to the client.
abstract interface class QuestionRepository {
  /// All available categories.
  Future<List<Category>> getCategories();

  /// Questions, optionally filtered by [categoryId] and capped at [limit].
  Future<List<Question>> getQuestions({String? categoryId, int? limit});

  /// Validate [selectedIndex] for the question with [questionId].
  Future<AnswerResult> checkAnswer({
    required String questionId,
    required int selectedIndex,
  });
}
