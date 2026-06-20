import 'package:erumind/data/models/question_difficulty.dart';
import 'package:erumind/features/game/logic/scoring.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('points scale with difficulty', () {
    expect(QuestionDifficulty.easy.points, 100);
    expect(QuestionDifficulty.medium.points, 200);
    expect(QuestionDifficulty.hard.points, 300);
  });
}
