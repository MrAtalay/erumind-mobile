import 'package:flutter/material.dart';

/// Settings screen.
///
/// Skeleton for Phase 4: sound on/off and language (TR/EN) land in the next
/// slice (they need a persistence-backed settings controller, and the language
/// switch needs a localization decision).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Sound and language settings are coming soon.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
