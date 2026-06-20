import '../../../data/models/question_difficulty.dart';

/// Points awarded for answering a question correctly, weighted by difficulty.
/// A wrong answer scores 0; the round score is the sum over correct answers.
extension QuestionDifficultyScore on QuestionDifficulty {
  int get points => switch (this) {
        QuestionDifficulty.easy => 100,
        QuestionDifficulty.medium => 200,
        QuestionDifficulty.hard => 300,
      };
}
