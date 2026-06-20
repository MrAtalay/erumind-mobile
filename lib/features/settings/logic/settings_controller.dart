import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/storage_service.dart';

/// Holds user-facing settings. Phase 4 slice 2 covers the UI language; a null
/// [Locale] means "follow the device locale". Sound lands with the audio slice.
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
