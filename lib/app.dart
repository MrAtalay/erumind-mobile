import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

/// Root widget of the app.
///
/// Stateful so the [GoRouter] is created exactly once per app instance (routers
/// must not be rebuilt on every `build`); a fresh instance also keeps widget
/// tests isolated.
class EruMindApp extends StatefulWidget {
  const EruMindApp({super.key});

  @override
  State<EruMindApp> createState() => _EruMindAppState();
}

class _EruMindAppState extends State<EruMindApp> {
  late final GoRouter _router = createAppRouter();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'EruMind',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: _router,
    );
  }
}
