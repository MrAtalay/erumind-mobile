import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/settings/logic/settings_controller.dart';

/// Short sound effects the game core can trigger. The asset behind each one
/// lives at `assets/audio/<name>.wav`.
enum SoundEffect { correct, wrong, spin, crown }

/// Sound-effect playback seam (Phase 5 audio slice).
///
/// Like [StorageService], this sits behind an interface so the game core
/// never depends on a concrete backend. Production uses [AudioPlayerService];
/// tests use [NoopAudioService] (no plugin channel calls, so widget/unit
/// tests stay deterministic — see docs/lessons-and-pitfalls.md L2).
abstract class AudioService {
  /// Plays [effect], or does nothing if sound is currently disabled.
  Future<void> play(SoundEffect effect);

  /// Mutes/unmutes future [play] calls. Kept in sync with the sound setting.
  void setEnabled(bool enabled);

  /// Releases backend resources. No-op for the noop backend.
  Future<void> dispose();
}

/// Production backend: a single reusable [AudioPlayer] that restarts on each
/// [play] call. Short SFX never overlap in this game, so one player is enough.
class AudioPlayerService implements AudioService {
  AudioPlayerService() : _player = AudioPlayer();

  static const Map<SoundEffect, String> _assetPaths = {
    SoundEffect.correct: 'audio/correct.wav',
    SoundEffect.wrong: 'audio/wrong.wav',
    SoundEffect.spin: 'audio/spin.wav',
    SoundEffect.crown: 'audio/crown.wav',
  };

  final AudioPlayer _player;
  bool _enabled = true;

  @override
  void setEnabled(bool enabled) => _enabled = enabled;

  @override
  Future<void> play(SoundEffect effect) async {
    if (!_enabled) return;
    await _player.stop();
    await _player.play(AssetSource(_assetPaths[effect]!));
  }

  @override
  Future<void> dispose() => _player.dispose();
}

/// Test/fake backend: does nothing, completes immediately.
class NoopAudioService implements AudioService {
  const NoopAudioService();

  @override
  void setEnabled(bool enabled) {}

  @override
  Future<void> play(SoundEffect effect) async {}

  @override
  Future<void> dispose() async {}
}

/// Provides the app-wide [AudioService].
///
/// This base provider intentionally throws: the real backend is wired up in
/// `main()` via a ProviderScope override so it can stay in sync with the
/// sound setting from the start. Tests override it with [NoopAudioService].
final audioServiceProvider = Provider<AudioService>((ref) {
  throw UnimplementedError(
    'audioServiceProvider must be overridden in main() (or in tests).',
  );
});

/// Builds the real [AudioPlayerService] and keeps it in sync with
/// [soundEnabledProvider]. Used as the `main()` override for
/// [audioServiceProvider].
AudioService createAudioService(Ref ref) {
  final service = AudioPlayerService();
  ref.listen<bool>(
    soundEnabledProvider,
    (_, enabled) => service.setEnabled(enabled),
    fireImmediately: true,
  );
  ref.onDispose(service.dispose);
  return service;
}
