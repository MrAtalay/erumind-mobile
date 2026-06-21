import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/storage_service.dart';

/// Holds the UI language. Phase 4 slice 2. A null [Locale] means "follow the
/// device locale".
class SettingsController extends Notifier<Locale?> {
  StorageService get _storage => ref.read(storageServiceProvider);

  @override
  Locale? build() {
    final code = _storage.localeCode;
    return code == null ? null : Locale(code);
  }

  /// Selects the UI language (or null to follow the device) and persists it.
  Future<void> setLocale(Locale? locale) async {
    await _storage.saveLocaleCode(locale?.languageCode);
    state = locale;
  }
}

final settingsControllerProvider =
    NotifierProvider<SettingsController, Locale?>(SettingsController.new);

/// Holds the sound on/off setting (Phase 5 audio slice). [audioServiceProvider]
/// listens to this and mutes/unmutes accordingly.
class SoundSettingsController extends Notifier<bool> {
  StorageService get _storage => ref.read(storageServiceProvider);

  @override
  bool build() => _storage.soundEnabled;

  /// Toggles sound on/off and persists it.
  Future<void> setEnabled(bool enabled) async {
    await _storage.saveSoundEnabled(enabled);
    state = enabled;
  }
}

final soundEnabledProvider =
    NotifierProvider<SoundSettingsController, bool>(SoundSettingsController.new);
