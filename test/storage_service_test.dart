import 'package:flutter_test/flutter_test.dart';

import 'support/test_storage.dart';

void main() {
  test('a fresh store reports zero best score and games played', () async {
    final storage = await setUpTempStorage();
    expect(storage.bestScore, 0);
    expect(storage.gamesPlayed, 0);
  });

  test('the first finished round sets the best score', () async {
    final storage = await setUpTempStorage();

    final isNewBest = await storage.recordRound(7);

    expect(isNewBest, isTrue);
    expect(storage.bestScore, 7);
    expect(storage.gamesPlayed, 1);
  });

  test('a lower score keeps the best but still counts the game', () async {
    final storage = await setUpTempStorage();
    await storage.recordRound(7);

    final isNewBest = await storage.recordRound(3);

    expect(isNewBest, isFalse);
    expect(storage.bestScore, 7);
    expect(storage.gamesPlayed, 2);
  });

  test('a higher score raises the best', () async {
    final storage = await setUpTempStorage();
    await storage.recordRound(4);

    final isNewBest = await storage.recordRound(9);

    expect(isNewBest, isTrue);
    expect(storage.bestScore, 9);
    expect(storage.gamesPlayed, 2);
  });
}
