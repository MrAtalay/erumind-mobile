import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

/// Local persistence seam (Phase 3).
///
/// Like [QuestionRepository], storage sits behind an interface so the game core
/// never depends on a concrete backend. Production uses [HiveStorageService];
/// tests use [InMemoryStorageService] (no real file I/O, so widget tests stay
/// deterministic). All typed accessors live here and delegate to three tiny
/// primitives, so a backend only implements key-value read/write/delete.
abstract class StorageService {
  static const String _bestScoreKey = 'best_score';
  static const String _gamesPlayedKey = 'games_played';
  static const String _livesKey = 'lives';
  static const String _refillAnchorKey = 'lives_refill_anchor_ms';
  static const String _localeKey = 'locale_code';

  @protected
  Object? readValue(String key);

  @protected
  Future<void> writeValue(String key, Object value);

  @protected
  Future<void> deleteValue(String key);

  /// Releases backend resources. No-op for the in-memory backend.
  Future<void> close();

  /// Highest score the player has ever reached in a round. 0 if never played.
  int get bestScore => (readValue(_bestScoreKey) as int?) ?? 0;

  /// Total number of rounds the player has finished.
  int get gamesPlayed => (readValue(_gamesPlayedKey) as int?) ?? 0;

  /// Records a finished round: bumps [gamesPlayed] and raises [bestScore] when
  /// [score] beats the current best. Returns true if a new best was set.
  Future<bool> recordRound(int score) async {
    final isNewBest = score > bestScore;
    await writeValue(_gamesPlayedKey, gamesPlayed + 1);
    if (isNewBest) {
      await writeValue(_bestScoreKey, score);
    }
    return isNewBest;
  }

  /// Stored life count, or null if the player has never been initialized.
  /// Regeneration is applied by the lives controller, not here.
  int? get storedLives => readValue(_livesKey) as int?;

  /// Anchor for the regeneration clock: the moment the current pending life
  /// started refilling. Null when never set (e.g. lives are full).
  DateTime? get refillAnchor {
    final ms = readValue(_refillAnchorKey) as int?;
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  /// Persists the lives count and its regeneration [anchor] together. Passing a
  /// null [anchor] clears it (used when lives are full and the clock stops).
  Future<void> saveLives(int lives, DateTime? anchor) async {
    await writeValue(_livesKey, lives);
    if (anchor == null) {
      await deleteValue(_refillAnchorKey);
    } else {
      await writeValue(_refillAnchorKey, anchor.millisecondsSinceEpoch);
    }
  }

  /// Selected UI language code (e.g. 'en', 'tr'), or null to follow the device.
  String? get localeCode => readValue(_localeKey) as String?;

  /// Persists the language code, or clears it (null) to follow the device.
  Future<void> saveLocaleCode(String? code) async {
    if (code == null) {
      await deleteValue(_localeKey);
    } else {
      await writeValue(_localeKey, code);
    }
  }
}

/// Production backend: a single Hive CE box of primitive values.
class HiveStorageService extends StorageService {
  HiveStorageService._(this._box);

  static const String boxName = 'erumind_stats';

  final Box _box;

  /// Initializes the Hive CE runtime and opens the stats box. Call once at app
  /// startup (before `runApp`) so the ready instance can be injected.
  static Future<HiveStorageService> init() async {
    await Hive.initFlutter();
    final box = await Hive.openBox(boxName);
    return HiveStorageService._(box);
  }

  @override
  Object? readValue(String key) => _box.get(key);

  @override
  Future<void> writeValue(String key, Object value) => _box.put(key, value);

  @override
  Future<void> deleteValue(String key) => _box.delete(key);

  @override
  Future<void> close() => Hive.close();
}

/// In-memory backend for tests: a plain map, no file I/O. Writes complete on a
/// microtask, so `pump`/`pumpAndSettle` settle normally in widget tests.
class InMemoryStorageService extends StorageService {
  final Map<String, Object> _data = {};

  @override
  Object? readValue(String key) => _data[key];

  @override
  Future<void> writeValue(String key, Object value) async => _data[key] = value;

  @override
  Future<void> deleteValue(String key) async => _data.remove(key);

  @override
  Future<void> close() async {}
}

/// Provides the app-wide [StorageService].
///
/// This base provider intentionally throws: the real, already-initialized
/// instance is injected in `main()` via a ProviderScope override (Hive must be
/// opened asynchronously before the widget tree builds). Tests override it with
/// an [InMemoryStorageService].
final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError(
    'storageServiceProvider must be overridden in main() (or in tests).',
  );
});
