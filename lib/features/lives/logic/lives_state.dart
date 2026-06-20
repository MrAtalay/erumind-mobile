/// Tunables for the lives/energy economy (Trivia Crack-style: a life is spent
/// to start a round, and lives refill over time up to a cap).
class LivesConfig {
  const LivesConfig({
    this.maxLives = 5,
    this.refillInterval = const Duration(minutes: 30),
  });

  /// Cap on stored lives.
  final int maxLives;

  /// Wall-clock time it takes to regenerate one life.
  final Duration refillInterval;

  static const LivesConfig defaults = LivesConfig();
}

/// Immutable snapshot of the player's lives.
///
/// [anchor] is the instant from which the *next* life is accruing; it is null
/// exactly when lives are full (the refill clock is stopped). Regeneration is
/// computed lazily from [anchor] rather than ticked, so it survives the app
/// being closed.
class LivesState {
  const LivesState({
    required this.lives,
    required this.anchor,
    required this.max,
  });

  final int lives;
  final DateTime? anchor;
  final int max;

  bool get isFull => lives >= max;
  bool get canPlay => lives > 0;

  /// Time until the next life regenerates, or null when full.
  Duration? timeUntilNext(DateTime now, Duration interval) {
    if (anchor == null) return null;
    final remaining = anchor!.add(interval).difference(now);
    return remaining.isNegative ? Duration.zero : remaining;
  }
}

/// Brings a stored ([lives], [anchor]) pair up to date at [now], applying any
/// lives that have regenerated since [anchor]. Pure: no clock or storage reads,
/// so it is fully unit-testable.
LivesState regenerateLives({
  required int lives,
  required DateTime? anchor,
  required DateTime now,
  LivesConfig config = LivesConfig.defaults,
}) {
  final max = config.maxLives;
  final interval = config.refillInterval;

  if (lives >= max) {
    return LivesState(lives: max, anchor: null, max: max);
  }
  if (anchor == null) {
    // Below the cap but no clock running — start it now (initial/edge case).
    return LivesState(lives: lives, anchor: now, max: max);
  }

  // Guard against the wall clock moving backwards (timezone/manual change).
  final start = now.isBefore(anchor) ? now : anchor;
  final refills = now.difference(start).inMilliseconds ~/ interval.inMilliseconds;
  final newLives = (lives + refills).clamp(0, max);

  if (newLives >= max) {
    return LivesState(lives: max, anchor: null, max: max);
  }
  return LivesState(
    lives: newLives,
    anchor: start.add(interval * refills),
    max: max,
  );
}

/// Spends one life at [now]. Returns the input unchanged when none are left.
/// Starts the refill clock if lives were previously full.
LivesState consumeOneLife(LivesState current, DateTime now) {
  if (current.lives <= 0) return current;
  final wasFull = current.lives >= current.max;
  return LivesState(
    lives: current.lives - 1,
    anchor: wasFull ? now : current.anchor,
    max: current.max,
  );
}
