import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/storage_service.dart';

/// Whether the player has completed (or skipped) the first-launch onboarding.
/// Drives the home gate in the router between [OnboardingScreen] and
/// [MenuScreen].
class OnboardingController extends Notifier<bool> {
  StorageService get _storage => ref.read(storageServiceProvider);

  @override
  bool build() => _storage.hasSeenOnboarding;

  /// Marks onboarding as done and persists it.
  Future<void> complete() async {
    await _storage.saveOnboardingSeen(true);
    state = true;
  }
}

final onboardingSeenProvider =
    NotifierProvider<OnboardingController, bool>(OnboardingController.new);
