import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/answer_result.dart';
import '../models/category.dart';
import '../models/question.dart';
import 'question_repository.dart';

/// Multiplayer [QuestionRepository] backed by Firestore (Phase 6, first
/// slice — connection + read-side plumbing only).
///
/// Not wired into `questionRepositoryProvider` yet; single-player still runs
/// on [LocalQuestionRepository]. Per Hard rule #1, Firestore question
/// documents never carry `correctIndex` — [getQuestions] strips it even if a
/// document has one by mistake, and [checkAnswer] has nothing to validate
/// against locally. Answer validation here waits on the server-side Cloud
/// Function (Phase 6, continued); calling it now is a clear signal that
/// piece isn't built yet rather than a silent insecure fallback.
class FirestoreQuestionRepository implements QuestionRepository {
  FirestoreQuestionRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  @override
  Future<List<Category>> getCategories() async {
    final snapshot = await _db.collection('categories').get();
    return snapshot.docs
        .map((doc) => Category.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  @override
  Future<List<Question>> getQuestions({String? categoryId, int? limit}) async {
    Query<Map<String, dynamic>> query = _db.collection('questions');
    if (categoryId != null) {
      query = query.where('categoryId', isEqualTo: categoryId);
    }
    if (limit != null) {
      query = query.limit(limit);
    }
    final snapshot = await query.get();
    return snapshot.docs.map((doc) {
      final data = {...doc.data(), 'id': doc.id};
      data.remove('correctIndex');
      return Question.fromJson(data);
    }).toList();
  }

  @override
  Future<AnswerResult> checkAnswer({
    required String questionId,
    required int selectedIndex,
  }) {
    throw UnimplementedError(
      'FirestoreQuestionRepository.checkAnswer needs the server-side Cloud '
      'Function (Phase 6, continued) — MP answers must be validated there, '
      'never on the client.',
    );
  }
}
