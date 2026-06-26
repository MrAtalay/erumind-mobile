import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/game/presentation/game_screen.dart';
import '../../features/menu/presentation/menu_screen.dart';
import '../../features/onboarding/logic/onboarding_controller.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';

/// Builds a fresh [GoRouter] for the app.
///
/// A factory (not a global) so each app instance — including each widget test —
/// starts from a clean navigation stack at '/'.
///
/// Top-level routes are pushed (`context.push`) so child screens get an app-bar
/// back button automatically.
GoRouter createAppRouter() => GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (context, state) => const _HomeGate()),
        GoRoute(path: '/game', builder: (context, state) => const GameScreen()),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => OnboardingScreen(
            onDone: () => Navigator.of(context).pop(),
          ),
        ),
      ],
    );

/// The '/' route: shows the first-launch [OnboardingScreen] until it's been
/// completed (or skipped), then the [MenuScreen] from then on.
class _HomeGate extends ConsumerWidget {
  const _HomeGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seen = ref.watch(onboardingSeenProvider);
    if (!seen) {
      return OnboardingScreen(
        onDone: () => ref.read(onboardingSeenProvider.notifier).complete(),
      );
    }
    return const MenuScreen();
  }
}
