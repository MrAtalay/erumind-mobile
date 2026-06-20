import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/storage_service.dart';
import 'lives_state.dart';

/// Injectable wall clock. Tests override this to control time without waiting.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Lives economy tunables. Overridable in tests (e.g. tiny refill intervals).
final livesConfigProvider = Provider<LivesConfig>((ref) => LivesConfig.defaults);

/// Emits roughly once per second so countdown UIs can rebuild. autoDispose so
/// it only ticks while something (the lobby) is actually listening.
final tickerProvider = StreamProvider.autoDispose<DateTime>((ref) {
  final clock = ref.watch(clockProvider);
  return Stream<DateTime>.periodic(const Duration(seconds: 1), (_) => clock());
});

/// Owns the player's lives: regenerates them lazily from persisted state and
/// spends one to start a round.
class LivesController extends Notifier<LivesState> {
  StorageService get _storage => ref.read(storageServiceProvider);
  LivesConfig get _config => ref.read(livesConfigProvider);
  DateTime Function() get _clock => ref.read(clockProvider);

  @override
  LivesState build() {
    final config = _config;
    final stored = _storage.storedLives;
    // Brand-new player: start full with the clock stopped.
    return regenerateLives(
      lives: stored ?? config.maxLives,
      anchor: stored == null ? null : _storage.refillAnchor,
      now: _clock(),
      config: config,
    );
  }

  /// Re-applies regeneration at the current time. Called on each ticker tick so
  /// a life earned while sitting on the lobby shows up immediately.
  void refresh() {
    state = regenerateLives(
      lives: state.lives,
      anchor: state.anchor,
      now: _clock(),
      config: _config,
    );
  }

  /// Spends one life to start a round. Returns false (without changing storage)
  /// when none are available.
  Future<bool> consumeLife() async {
    final now = _clock();
    final current = regenerateLives(
      lives: state.lives,
      anchor: state.anchor,
      now: now,
      config: _config,
    );
    if (!current.canPlay) {
      state = current;
      return false;
    }
    final next = consumeOneLife(current, now);
    await _storage.saveLives(next.lives, next.anchor);
    state = next;
    return true;
  }
}

final livesControllerProvider =
    NotifierProvider<LivesController, LivesState>(LivesController.new);
