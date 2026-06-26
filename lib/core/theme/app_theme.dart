import 'package:flutter/material.dart';

/// Central place for the app's visual theme.
///
/// Kept original and distinct from any existing trivia brand (Hard rule #2).
/// We use Material 3 with a single seed color; richer theming comes in the
/// polish phase.
abstract final class AppTheme {
  static const Color seed = Color(0xFFCC1020); // EruMind red

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(seedColor: seed);
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: scheme.surface,
    );
  }
}
