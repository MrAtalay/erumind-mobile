import 'package:go_router/go_router.dart';

import '../../features/game/presentation/game_screen.dart';
import '../../features/menu/presentation/menu_screen.dart';
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
        GoRoute(path: '/', builder: (context, state) => const MenuScreen()),
        GoRoute(path: '/game', builder: (context, state) => const GameScreen()),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    );
