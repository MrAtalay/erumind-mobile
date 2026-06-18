import 'package:freezed_annotation/freezed_annotation.dart';

part 'question.freezed.dart';
part 'question.g.dart';

/// A single multiple-choice question with exactly 4 [options].
///
/// IMPORTANT (Hard rule #1 — server-authoritative answers in MP):
/// [correctIndex] is only populated for the single-player flow, where the
/// correct answer legitimately lives on the device. The game core must NOT
/// read [correctIndex] directly to decide right/wrong — it asks
/// `QuestionRepository.checkAnswer(...)` instead. That keeps a single seam
/// so the multiplayer repository can validate the answer on the server and
/// serve questions with [correctIndex] left null (un-cheatable).
@freezed
abstract class Question with _$Question {
  const factory Question({
    required String id,
    required String categoryId,
    required String text,
    required List<String> options,

    /// Local-only correct answer (0-based). Null in multiplayer.
    int? correctIndex,
  }) = _Question;

  factory Question.fromJson(Map<String, dynamic> json) =>
      _$QuestionFromJson(json);
}
