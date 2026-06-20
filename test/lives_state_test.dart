import 'package:erumind/features/lives/logic/lives_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final t0 = DateTime(2024, 1, 1, 12, 0, 0);
  const config = LivesConfig(); // 5 lives, 30 min refill

  group('regenerateLives', () {
    test('full lives stay full with the clock stopped', () {
      final s = regenerateLives(lives: 5, anchor: null, now: t0, config: config);
      expect(s.lives, 5);
      expect(s.anchor, isNull);
      expect(s.isFull, isTrue);
    });

    test('below cap with no anchor starts the clock now', () {
      final s = regenerateLives(lives: 3, anchor: null, now: t0, config: config);
      expect(s.lives, 3);
      expect(s.anchor, t0);
    });

    test('adds elapsed lives and advances the anchor by whole intervals', () {
      final s = regenerateLives(
        lives: 2,
        anchor: t0,
        now: t0.add(const Duration(minutes: 65)),
        config: config,
      );
      expect(s.lives, 4); // 65 min => 2 refills
      expect(s.anchor, t0.add(const Duration(minutes: 60)));
    });

    test('caps at max and clears the anchor', () {
      final s = regenerateLives(
        lives: 4,
        anchor: t0,
        now: t0.add(const Duration(minutes: 90)),
        config: config,
      );
      expect(s.lives, 5);
      expect(s.anchor, isNull);
    });

    test('a backwards clock never removes lives', () {
      final s = regenerateLives(
        lives: 3,
        anchor: t0,
        now: t0.subtract(const Duration(minutes: 10)),
        config: config,
      );
      expect(s.lives, 3);
    });
  });

  group('timeUntilNext', () {
    test('is null when full', () {
      final s = regenerateLives(lives: 5, anchor: null, now: t0, config: config);
      expect(s.timeUntilNext(t0, config.refillInterval), isNull);
    });

    test('counts down within the current interval', () {
      final s = regenerateLives(
        lives: 2,
        anchor: t0,
        now: t0.add(const Duration(minutes: 65)),
        config: config,
      );
      // anchor advanced to t0+60; next life at t0+90; now is t0+65 => 25 min.
      expect(
        s.timeUntilNext(t0.add(const Duration(minutes: 65)), config.refillInterval),
        const Duration(minutes: 25),
      );
    });
  });

  group('consumeOneLife', () {
    test('spending from full starts the clock', () {
      final full = LivesState(lives: 5, anchor: null, max: 5);
      final s = consumeOneLife(full, t0);
      expect(s.lives, 4);
      expect(s.anchor, t0);
    });

    test('spending below full keeps the running clock', () {
      final partial = LivesState(lives: 3, anchor: t0, max: 5);
      final s = consumeOneLife(partial, t0.add(const Duration(minutes: 5)));
      expect(s.lives, 2);
      expect(s.anchor, t0); // unchanged
    });

    test('spending with no lives is a no-op', () {
      final empty = LivesState(lives: 0, anchor: t0, max: 5);
      final s = consumeOneLife(empty, t0);
      expect(s.lives, 0);
      expect(s.anchor, t0);
    });
  });
}
