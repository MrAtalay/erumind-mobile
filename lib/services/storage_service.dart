import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

/// Local persistence entry point (Phase 3).
///
/// First slice: best score + games played. We keep a single key-value [Box]
/// of primitive values (no custom TypeAdapters yet) — the simplest thing that
/// works while the storage schema is still small. As the schema grows
/// (lives/energy, settings, round history) we can split boxes or introduce
/// adapters without changing this seam's callers.
class StorageService {
  StorageService._(this._box);

  /// Builds a service over an already-open [Box]. Used by [init] and by tests
  /// that open a box against a temporary Hive directory.
  @visibleForTesting
  factory StorageService.fromBox(Box box) = StorageService._;

  static const String boxName = 'erumind_stats';
  static const String _bestScoreKey = 'best_score';
  static const String _gamesPlayedKey = 'games_played';

  final Box _box;

  /// Initializes the Hive CE runtime and opens the stats box.
  ///
  /// Call once at app startup (before `runApp`). Returns a ready-to-use
  /// service so it can be injected into Riverpod via a ProviderScope override.
  static Future<StorageService> init() async {
    await Hive.initFlutter();
    final box = await Hive.openBox(boxName);
    return StorageService._(box);
  }

  /// Highest score the player has ever reached in a round. 0 if never played.
  int get bestScore => _box.get(_bestScoreKey, defaultValue: 0) as int;

  /// Total number of rounds the player has finished.
  int get gamesPlayed => _box.get(_gamesPlayedKey, defaultValue: 0) as int;

  /// Records a finished round: bumps [gamesPlayed] and raises [bestScore] when
  /// [score] beats the current best. Returns true if a new best was set.
  Future<bool> recordRound(int score) async {
    final isNewBest = score > bestScore;
    await _box.put(_gamesPlayedKey, gamesPlayed + 1);
    if (isNewBest) {
      await _box.put(_bestScoreKey, score);
    }
    return isNewBest;
  }

  Future<void> close() => Hive.close();
}

/// Provides the app-wide [StorageService].
///
/// This base provider intentionally throws: the real, already-initialized
/// instance is injected in `main()` via a ProviderScope override (Hive must be
/// opened asynchronously before the widget tree builds). Tests override it with
/// a [StorageService.fromBox] backed by a temporary Hive box.
final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError(
    'storageServiceProvider must be overridden in main() (or in tests).',
  );
});
