import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/game/presentation/game_screen.dart';

/// Root widget of the app.
///
/// For the Phase 1 vertical slice we go straight to [GameScreen] with a plain
/// [MaterialApp]. Routing (go_router) and a real menu arrive in Phase 4.
class EruMindApp extends StatelessWidget {
  const EruMindApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EruMind',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const GameScreen(),
    );
  }
}
