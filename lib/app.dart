import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/logic/settings_controller.dart';
import 'l10n/app_localizations.dart';

/// Root widget of the app.
///
/// Stateful so the [GoRouter] is created exactly once per app instance (routers
/// must not be rebuilt on every `build`); a fresh instance also keeps widget
/// tests isolated. The locale is driven by [settingsControllerProvider]; null
/// follows the device locale.
class EruMindApp extends ConsumerStatefulWidget {
  const EruMindApp({super.key});

  @override
  ConsumerState<EruMindApp> createState() => _EruMindAppState();
}

class _EruMindAppState extends ConsumerState<EruMindApp> {
  late final GoRouter _router = createAppRouter();

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(settingsControllerProvider);

    return MaterialApp.router(
      title: 'EruMind',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: _router,
    );
  }
}
