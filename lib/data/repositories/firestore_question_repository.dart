import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../models/answer_result.dart';
import '../models/category.dart';
import '../models/question.dart';
import 'question_repository.dart';

/// Multiplayer [QuestionRepository] backed by Firestore (Phase 6).
///
/// Not wired into `questionRepositoryProvider` yet; single-player still runs
/// on [LocalQuestionRepository]. Per Hard rule #1, Firestore question
/// documents never carry `correctIndex` — [getQuestions] strips it even if a
/// document has one by mistake. [checkAnswer] calls the `checkAnswer` Cloud
/// Function (`functions/index.js`), which is the only thing with admin
/// access to the locked `answers/{questionId}` collection. The function is
/// written but **not deployed yet** — deploying requires the Firebase
/// project to be on the Blaze plan, which is a billing decision left to the
/// team, not something to flip on automatically.
class FirestoreQuestionRepository implements QuestionRepository {
  FirestoreQuestionRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

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
  }) async {
    final callable = _functions.httpsCallable('checkAnswer');
    final response = await callable.call<Map<String, dynamic>>({
      'questionId': questionId,
      'selectedIndex': selectedIndex,
    });
    return AnswerResult(
      isCorrect: response.data['isCorrect'] as bool,
      correctIndex: response.data['correctIndex'] as int,
    );
  }
}
